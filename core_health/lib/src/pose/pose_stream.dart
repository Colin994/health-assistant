import 'pose_event.dart';
import 'pose_sample.dart';

/// 头部姿态流抽象(《慢植物小游戏设计方案》§3.2 输入源)。
///
/// 消费方(feature_game)只依赖本接口,不关心数据来自摄像头、
/// 陀螺仪还是录制回放;实现可替换、可并存。
abstract interface class PoseStream {
  /// 原始姿态样本流(已过滤无人脸帧;采样率随实现,约 25~30Hz)。
  Stream<PoseSample> get poses;

  /// 事件流(校准完成 / 离画 / 回画 / 错误)。
  Stream<PoseEvent> get events;

  /// 启动数据源(相机实现内含权限申请)。
  Future<void> start();

  /// 停止数据源并释放相机等资源。
  Future<void> stop();

  /// 发起校准:在 [hold] 时长内收集人脸样本,均值作为零点,
  /// 完成时在 [events] 发出 [PoseCalibrated]。
  /// 期间若始终无人脸,以 [PoseSourceError] 收尾。
  Future<void> calibrate({Duration hold = const Duration(seconds: 2)});
}
