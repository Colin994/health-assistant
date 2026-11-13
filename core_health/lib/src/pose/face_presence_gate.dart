import 'pose_event.dart';
import 'pose_sample.dart';

/// 离画判定纯逻辑(《慢植物小游戏设计方案》§3.1)。
///
/// 规则:连续无脸超过 [lostAfter](默认 1 秒)→ 边缘触发一次
/// [PoseFaceLost];此后再次检出人脸 → [PoseFaceBack]。
/// 纯函数式实现,不依赖真实相机,单测用样本序列驱动。
class FacePresenceGate {
  FacePresenceGate({this.lostAfter = const Duration(seconds: 1)});

  /// 无脸到该时长判定离画。
  final Duration lostAfter;

  int? _lastFaceSeenMs;
  bool _lostEmitted = false;

  /// 喂入一帧样本,返回本次应触发的事件(通常为 null)。
  PoseEvent? feed(PoseSample sample) {
    if (sample.faceDetected) {
      final wasLost = _lostEmitted;
      _lastFaceSeenMs = sample.timestampMs;
      _lostEmitted = false;
      // 离画后的首个回画帧 → 恰好触发一次 PoseFaceBack。
      return wasLost ? const PoseFaceBack() : null;
    }
    final lastSeen = _lastFaceSeenMs;
    if (lastSeen == null) {
      // 尚未见过人脸:不触发离画(等待首帧人脸,避免误报)。
      return null;
    }
    if (sample.timestampMs - lastSeen > lostAfter.inMilliseconds &&
        !_lostEmitted) {
      _lostEmitted = true;
      return const PoseFaceLost();
    }
    return null;
  }

  /// 复位(新一轮校准/会话开始时)。
  void reset() {
    _lastFaceSeenMs = null;
    _lostEmitted = false;
  }
}
