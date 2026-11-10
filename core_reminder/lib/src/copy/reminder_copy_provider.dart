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
    '颈椎不适': '低头一小时了，抬头看看远处吧——顺便做个收下巴，30 秒就够',
    '肩颈僵硬': '肩膀又硬成石头了吧？画个圈放松一下，60 秒就好',
    '腰部劳损': '腰有点僵了——站起来轻轻侧个身，40 秒',
    '眼疲劳': '坐了这么久，眼睛也歇歇——先收个下巴，再看看远处',
    '咽干易上火': '坐久了容易上火——起来倒杯温水，顺便抿两口',
    '只是久坐，没特殊不适': '坐满 55 分钟啦——起来活动 1 分钟就好',
  };

  static const _sedentaryDefault = '坐了一个多小时啦——起来倒杯水，顺便活动 1 分钟';

  static const _waterByTag = {
    '常忘喝水': '到点啦——起来接杯水，顺便走两步，一小口就好',
    '咽干易上火': '嗓子有点干吧？抿两口温水，别喝烫的',
  };

  static const _waterDefault = '喝口水的工夫——起来接杯水，顺便走两步';

  static const _eyeByTag = {
    '眼疲劳': '盯屏 20 分钟了——看看 6 米外的远处，坚持 20 秒',
    '近视': '眼睛该休息了——摘掉眼镜看看远处，20 秒',
  };

  static const _eyeDefault = '20-20-20 到点——看看 6 米外的远处，20 秒';

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
