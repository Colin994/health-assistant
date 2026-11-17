import 'package:core_model/core_model.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_config_repository.dart';

/// 健康标签目录（引导 02 与我的页编辑共用；v6 互斥规则）。
abstract final class HealthTagCatalog {
  static const noConditionTag = '只是久坐，没特殊不适';

  /// 身体状况类（与 [noConditionTag] 互斥）。
  static const bodyConditionTags = {
    '颈椎不适',
    '肩颈僵硬',
    '腰部劳损',
    '眼疲劳',
    '咽干易上火',
  };

  static const options = [
    '颈椎不适',
    '肩颈僵硬',
    '腰部劳损',
    '眼疲劳',
    '常忘喝水',
    '咽干易上火',
    noConditionTag,
  ];

  /// 标签 → 自动开启的提醒类别（PRD FR-2 映射；只做加法：开启对应类，
  /// 不关闭用户已手动开启的其他类——v8 评审口径）。
  static Set<ReminderKind> reminderKindsFor(Set<String> tags) {
    final kinds = <ReminderKind>{};
    for (final tag in tags) {
      if (tag == '眼疲劳') kinds.add(ReminderKind.eye);
      if (tag == '常忘喝水' || tag == '咽干易上火') {
        kinds.add(ReminderKind.water);
      }
      if (bodyConditionTags.contains(tag) || tag == noConditionTag) {
        kinds.add(ReminderKind.sedentary);
      }
    }
    return kinds;
  }
}

/// 标签保存后的联动：自动开启对应提醒类别（加法式），返回新配置。
///
/// 调用方负责触发引擎 `onSettingsChanged`（core_profile 不依赖 core_reminder）。
Future<ReminderConfig> enableRemindersForTags(
  Set<String> tags,
  ReminderConfigRepository repo,
) async {
  final config = await repo.load();
  final kinds = HealthTagCatalog.reminderKindsFor(tags);
  final disabled = <ReminderKind>{...config.disabledKinds}..removeAll(kinds);
  final next = config.copyWith(
    waterEnabled: config.waterEnabled || kinds.contains(ReminderKind.water),
    eyeEnabled: config.eyeEnabled || kinds.contains(ReminderKind.eye),
    disabledKinds: disabled,
  );
  if (next != config) await repo.save(next);
  return next;
}

/// 健康标签仓库（引导页选择、我的页展示、提醒文案按标签子集匹配）。
///
/// PRD FR-2：标签仅存于画像（本地），用于文案生成与动作匹配；
/// 修改后下次提醒生效。标签编辑流为 W3 待办。
abstract class HealthTagStore {
  Future<Set<String>> load();

  Future<void> save(Set<String> tags);
}

@LazySingleton(as: HealthTagStore)
class PrefsHealthTagStore implements HealthTagStore {
  static const _key = 'health_tags_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<Set<String>> load() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getStringList(_key);
      return raw?.toSet() ?? <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  @override
  Future<void> save(Set<String> tags) async {
    try {
      final prefs = await _prefs;
      await prefs.setStringList(_key, tags.toList());
    } catch (_) {
      // 持久化失败静默：本次会话内仍可用内存值。
    }
  }
}
