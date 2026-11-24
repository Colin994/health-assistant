import 'package:core_model/core_model.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// 提醒文案（通知标题 + 正文）。
@immutable
class ReminderCopy {
  const ReminderCopy({required this.title, required this.body});

  final String title;
  final String body;
}

/// 静态文案仓库（W2）：按提醒类型 × 健康标签子集匹配；
/// W4 由 `GenerateAdviceUseCase`（云端 LLM + Result 兜底）替换，
/// 兜底文案即本表（PRD FR-4：≤60 字、禁诊断/用药表述）。
@LazySingleton()
class ReminderCopyProvider {
  static const _sedentaryByTag = {
    '颈椎不适': '放下手机，放松肩膀，轻轻收一下下巴。',
    '肩颈僵硬': '起来活动一下，放松肩膀，慢慢转动几圈。',
    '腰部劳损': '先起身走几步，按自己舒服的幅度活动。',
    '眼疲劳': '起来走几步，顺便把视线移向远处。',
    '咽干易上火': '起身活动一下，顺便接杯水。',
    '只是久坐，没特殊不适': '离开座位，走动一分钟。',
  };

  static const _sedentaryDefault = '起来走几步，活动一下身体。';

  static const _waterByTag = {
    '常忘喝水': '手边有水的话，现在喝几口。',
    '咽干易上火': '喝几口温水，休息一下。',
  };

  static const _waterDefault = '给自己接杯水，喝几口。';

  static const _eyeByTag = {
    '眼疲劳': '让眼睛休息一下，看看约 6 米外的地方，持续 20 秒。',
    '近视': '把视线从屏幕移开，看看远处，持续 20 秒。',
  };

  static const _eyeDefault = '放下手头的屏幕，看看约 6 米外的地方，持续 20 秒。';

  ReminderCopy copyFor(ReminderKind kind, Set<String> tags) {
    return switch (kind) {
      ReminderKind.sedentary => ReminderCopy(
          title: '久坐拉伸',
          body: _match(tags, _sedentaryByTag) ?? _sedentaryDefault,
        ),
      ReminderKind.water => ReminderCopy(
          title: '喝水提醒',
          body: _match(tags, _waterByTag) ?? _waterDefault,
        ),
      ReminderKind.eye => ReminderCopy(
          title: '护眼提醒',
          body: _match(tags, _eyeByTag) ?? _eyeDefault,
        ),
    };
  }

  static String? _match(Set<String> tags, Map<String, String> table) {
    for (final tag in tags) {
      final copy = table[tag];
      if (copy != null) return copy;
    }
    return null;
  }
}
