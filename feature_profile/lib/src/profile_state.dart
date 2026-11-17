import 'package:flutter/foundation.dart';

/// ProfileScreen 的视图数据类（不可变，变更经 copyWith 重建）。
@immutable
class ProfileState {
  const ProfileState({this.tags = const [], this.version = '0.1.0'});

  /// 我的健康标签（W2 接 ProfileRepository）。
  final List<String> tags;

  /// 应用版本（关于行）。
  final String version;

  ProfileState copyWith({List<String>? tags, String? version}) {
    return ProfileState(
      tags: tags ?? this.tags,
      version: version ?? this.version,
    );
  }
}
