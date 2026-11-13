import 'dart:async';
import 'dart:ui' show Size;

import 'package:base_utils/base_utils.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:injectable/injectable.dart';

import 'face_presence_gate.dart';
import 'pose_event.dart';
import 'pose_sample.dart';
import 'pose_stream.dart';

/// 摄像头头姿数据源(《慢植物小游戏设计方案》§3.2 MVP 唯一实现)。
///
/// 前置摄像头逐帧人脸检测,ML Kit 欧拉角 → [PoseSample]:
/// - pitch = headEulerAngleX(前屈后伸)
/// - yaw = headEulerAngleY(旋转)
/// - roll = headEulerAngleZ(侧屈)
///
/// 以接口 [PoseStream] 注册(消费方只依赖抽象,§3.2)。
/// 隐私:图像仅端上推理,不存储、不上传(§3.2/§8)。
/// M0 无相机预览:游戏界面不回显画面,只消费姿态与事件(§9)。
@LazySingleton(as: PoseStream)
class CameraPoseSource implements PoseStream {
  CameraPoseSource({Clock? clock}) : _clock = clock ?? const SystemClock();

  /// 注入时钟：姿态帧打时刻可测（不读墙钟）。
  final Clock _clock;

  CameraController? _controller;
  FaceDetector? _detector;
  StreamSubscription<CameraImage>? _imageSub;
  FacePresenceGate _gate = FacePresenceGate();
  bool _processing = false;

  /// 欧拉角中值滤波窗口(3 帧):滤掉单帧跳变,延迟约 1 帧(~40ms)。
  /// 窗口越大越稳但越迟钝;3 帧是「稳」与「跟手」的平衡点。
  static const int _filterWindow = 3;
  final List<double> _pitchWin = [];
  final List<double> _rollWin = [];
  final List<double> _yawWin = [];

  double _medianWith(List<double> window, double value) {
    window.add(value);
    if (window.length > _filterWindow) {
      window.removeAt(0);
    }
    final sorted = List<double>.from(window)..sort();
    return sorted[sorted.length ~/ 2];
  }

  // 校准状态
  bool _calibrating = false;
  Completer<void>? _calibCompleter;
  Timer? _calibTimer;
  final List<PoseSample> _calibSamples = [];

  final StreamController<PoseSample> _poses =
      StreamController<PoseSample>.broadcast();
  final StreamController<PoseEvent> _events =
      StreamController<PoseEvent>.broadcast();

  @override
  Stream<PoseSample> get poses => _poses.stream;

  @override
  Stream<PoseEvent> get events => _events.stream;

  @override
  Future<void> start() async {
    if (_controller != null) {
      return;
    }
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        // 中等分辨率足够人脸检测(§3.2 精度 ±5° 量级)。
        ResolutionPreset.medium,
        enableAudio: false,
        // Android 直接输出 NV21,喂 ML Kit 免转码;iOS 走平台默认格式。
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.startImageStream(_onImage);
      _controller = controller;
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          // 跨帧跟踪:逐帧独立检测的欧拉角有 ±2~3° 随机抖动,
          // 开启 tracking 后 ML Kit 会跨帧关联,角度显著更稳
          // (治「跟随一直晃」的源头层;位置层另有低通与插值)。
          enableTracking: true,
        ),
      );
      _gate = FacePresenceGate();
    } catch (e) {
      // 失败清理:controller 可能已初始化但 detector 未建(或 startImageStream
      // 抛错),不回收会留下占用的相机句柄。
      await stop();
      debugPrint('[pose] 相机启动失败: $e');
      _events.add(PoseSourceError('相机启动失败,请检查相机权限后重试'));
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _calibTimer?.cancel();
    final calib = _calibCompleter;
    if (calib != null && !calib.isCompleted) {
      calib.completeError(StateError('stopped during calibration'));
      calib.future.ignore();
    }
    _calibCompleter = null;
    _calibrating = false;
    _calibSamples.clear();
    await _imageSub?.cancel();
    _imageSub = null;
    await _controller?.dispose();
    _controller = null;
    await _detector?.close();
    _detector = null;
  }

  @override
  Future<void> calibrate({Duration hold = const Duration(seconds: 2)}) async {
    if (_controller == null) {
      throw StateError('calibrate 前需先 start()');
    }
    _calibrating = true;
    _calibSamples.clear();
    final completer = _calibCompleter = Completer<void>();
    _calibTimer = Timer(hold, _finishCalibration);
    return completer.future;
  }

  void _finishCalibration() {
    if (!_calibrating) {
      return;
    }
    _calibrating = false;
    final samples = List<PoseSample>.from(_calibSamples);
    _calibSamples.clear();
    if (samples.isEmpty) {
      _events.add(const PoseSourceError('校准期间未检出人脸'));
      final completer = _calibCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.completeError(StateError('校准期间未检出人脸'));
      }
    } else {
      final zero = averagePose(samples);
      _gate.reset();
      _events.add(PoseCalibrated(zero));
      final completer = _calibCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
    _calibCompleter = null;
  }

  Future<void> _onImage(CameraImage image) async {
    if (_processing) {
      return; // 上一帧仍在推理:丢弃本帧,天然限频
    }
    _processing = true;
    try {
      final detector = _detector;
      if (detector == null) {
        return;
      }
      final input = _toInputImage(image);
      if (input == null) {
        return;
      }
      final faces = await detector.processImage(input);
      final now = _clock.now().millisecondsSinceEpoch;
      final PoseSample sample;
      if (faces.isNotEmpty) {
        final face = faces.first;
        sample = PoseSample(
          pitch: _medianWith(_pitchWin, face.headEulerAngleX ?? 0),
          yaw: _medianWith(_yawWin, face.headEulerAngleY ?? 0),
          roll: _medianWith(_rollWin, face.headEulerAngleZ ?? 0),
          timestampMs: now,
          faceDetected: true,
        );
        if (_calibrating) {
          _calibSamples.add(sample);
        }
      } else {
        sample = PoseSample(
          pitch: 0,
          yaw: 0,
          roll: 0,
          timestampMs: now,
          faceDetected: false,
        );
      }
      _poses.add(sample);
      final event = _gate.feed(sample);
      if (event != null) {
        _events.add(event);
      }
    } catch (e) {
      // 详细异常只进日志;UI 只展示可读文案(不走 raw 堆栈)。
      debugPrint('[pose] 推理异常: $e');
      _events.add(PoseSourceError('相机出了点问题,请重试'));
    } finally {
      _processing = false;
    }
  }

  /// CameraImage → ML Kit InputImage。
  ///
  /// iOS(BGRA8888):planes[0] + bgra 格式标记。
  /// Android(NV21/YUV420):统一重建为「规范 NV21」(偶数宽高、无行填充),
  /// 规避部分机型(nv21 缓冲带 stride 填充 / 宽高为奇数 / 三平面 YUV420)
  /// 直接喂原缓冲时 ML Kit 转换器崩溃的问题。
  InputImage? _toInputImage(CameraImage image) {
    final controller = _controller;
    if (controller == null || image.planes.isEmpty) {
      return null;
    }
    final rotation = InputImageRotationValue.fromRawValue(
          controller.description.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;

    if (image.format.group == ImageFormatGroup.bgra8888) {
      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    final normalized = _canonicalNv21(image);
    if (normalized == null) {
      return null;
    }
    final (bytes, size) = normalized;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: size.width.toInt(),
      ),
    );
  }

  /// 任意 YUV 帧 → 规范 NV21(偶数宽高,紧密排列无行填充)。
  ///
  /// 支持:单平面 NV21(含 stride 填充)、三平面 YUV420。
  /// 无法识别时返回 null(该帧跳过,不喂给 ML Kit)。
  (Uint8List, Size)? _canonicalNv21(CameraImage image) {
    final w = image.width & ~1;
    final h = image.height & ~1;
    if (w <= 0 || h <= 0) {
      return null;
    }
    final out = Uint8List(w * h * 3 ~/ 2);
    final group = image.format.group;
    final planes = image.planes;

    if (group == ImageFormatGroup.nv21 && planes.length == 1) {
      final src = planes.first.bytes;
      final rowStride = planes.first.bytesPerRow;
      if (src.length < h * rowStride) {
        return null;
      }
      // Y 平面:逐行去 stride。
      var dst = 0;
      for (var y = 0; y < h; y++) {
        out.setRange(dst, dst + w, src, y * rowStride);
        dst += w;
      }
      // VU 交织面:位于 Y 平面之后,同样逐行去 stride。
      final uvStart = h * rowStride;
      for (var y = 0; y < h ~/ 2; y++) {
        final srcStart = uvStart + y * rowStride;
        if (srcStart + w > src.length) {
          return null;
        }
        out.setRange(dst, dst + w, src, srcStart);
        dst += w;
      }
      return (out, Size(w.toDouble(), h.toDouble()));
    }

    if (group == ImageFormatGroup.yuv420 && planes.length >= 3) {
      final yPlane = planes[0];
      final uPlane = planes[1];
      final vPlane = planes[2];
      var dst = 0;
      for (var y = 0; y < h; y++) {
        var si = y * yPlane.bytesPerRow;
        for (var x = 0; x < w; x++) {
          if (si >= yPlane.bytes.length) {
            return null;
          }
          out[dst++] = yPlane.bytes[si];
          si += yPlane.bytesPerPixel ?? 1;
        }
      }
      // NV21 chroma 顺序:先 V 后 U,交织。
      for (var y = 0; y < h ~/ 2; y++) {
        var vIdx = y * vPlane.bytesPerRow;
        var uIdx = y * uPlane.bytesPerRow;
        for (var x = 0; x < w ~/ 2; x++) {
          if (vIdx >= vPlane.bytes.length || uIdx >= uPlane.bytes.length) {
            return null;
          }
          out[dst++] = vPlane.bytes[vIdx];
          out[dst++] = uPlane.bytes[uIdx];
          vIdx += vPlane.bytesPerPixel ?? 1;
          uIdx += uPlane.bytesPerPixel ?? 1;
        }
      }
      return (out, Size(w.toDouble(), h.toDouble()));
    }

    return null;
  }
}
