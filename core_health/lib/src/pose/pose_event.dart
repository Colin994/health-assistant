import 'package:flutter/foundation.dart';

import 'pose_sample.dart';

/// 姿态流一次性事件(《慢植物小游戏设计方案》§3.1/§9)。
///
/// 事件由数据源产生、表现层消费;设计上仅描述「发生了什么」,
/// 不携带处罚语义(离画暂停是安全机制,不是失败判定,§2 红线 2)。
@immutable
sealed class PoseEvent {
  const PoseEvent();
}

/// 校准完成:[zero] 为本次校准周期的姿态零点均值。
class PoseCalibrated extends PoseEvent {
  const PoseCalibrated(this.zero);

  final PoseSample zero;
}

/// 人脸离开画面超过阈值(1 秒),数据源进入暂停态。
class PoseFaceLost extends PoseEvent {
  const PoseFaceLost();
}

/// 人脸重新入画,数据源从暂停态恢复。
class PoseFaceBack extends PoseEvent {
  const PoseFaceBack();
}

/// 数据源错误(相机不可用 / 权限拒绝 / 推理异常)。
class PoseSourceError extends PoseEvent {
  const PoseSourceError(this.message);

  final String message;
}
