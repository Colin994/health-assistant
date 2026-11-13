import 'package:flutter/foundation.dart';

/// 单帧头部姿态样本(《慢植物小游戏设计方案》§3.2)。
///
/// 三轴角度制、单位度:
/// - pitch:前屈后伸(ML Kit headEulerAngleX)
/// - yaw:旋转(ML Kit headEulerAngleY,仅施肥类动作使用)
/// - roll:侧屈(ML Kit headEulerAngleZ)
@immutable
class PoseSample {
  const PoseSample({
    required this.pitch,
    required this.roll,
    required this.yaw,
    required this.timestampMs,
    this.faceDetected = true,
  });

  final double pitch;
  final double roll;
  final double yaw;

  /// 采样时间戳(毫秒,单调时钟语义由数据源保证)。
  final int timestampMs;

  /// 该帧是否检出人脸(校准与离画判定依据)。
  final bool faceDetected;

  /// 以 [zero] 为零点的相对姿态(判定一律使用相对角,§6.4)。
  PoseSample relativeTo(PoseSample zero) {
    return PoseSample(
      pitch: pitch - zero.pitch,
      roll: roll - zero.roll,
      yaw: yaw - zero.yaw,
      timestampMs: timestampMs,
      faceDetected: faceDetected,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PoseSample &&
      other.pitch == pitch &&
      other.roll == roll &&
      other.yaw == yaw &&
      other.timestampMs == timestampMs &&
      other.faceDetected == faceDetected;

  @override
  int get hashCode =>
      Object.hash(pitch, roll, yaw, timestampMs, faceDetected);

  @override
  String toString() =>
      'PoseSample(p:$pitch r:$roll y:$yaw t:$timestampMs '
      'face:$faceDetected)';
}

/// 对人脸样本求均值,得到校准零点(§3.1:正脸入画保持 2 秒取零点)。
PoseSample averagePose(Iterable<PoseSample> samples) {
  final list = samples.where((s) => s.faceDetected).toList();
  if (list.isEmpty) {
    throw ArgumentError('无人脸样本,无法求校准零点');
  }
  double sum(double Function(PoseSample) pick) =>
      list.map(pick).reduce((a, b) => a + b);
  return PoseSample(
    pitch: sum((s) => s.pitch) / list.length,
    roll: sum((s) => s.roll) / list.length,
    yaw: sum((s) => s.yaw) / list.length,
    timestampMs: list.last.timestampMs,
  );
}
