import 'package:flutter/foundation.dart';

/// SettingsScreen 的视图数据类（不可变，变更经 copyWith 重建）。
@immutable
class SettingsState {
  const SettingsState({this.version = '0.1.0'});

  /// 应用版本（关于行；W2 接 PackageInfo）。
  final String version;

  SettingsState copyWith({String? version}) {
    return SettingsState(version: version ?? this.version);
  }
}
