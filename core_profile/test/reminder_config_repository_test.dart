import 'package:core_model/core_model.dart';
import 'package:core_profile/core_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _legacyKey = 'reminder_config_v1';
const _legacyConfig = ReminderConfig(
  sedentaryMinutes: 75,
  waterEnabled: false,
  nightMuteStart: 23 * 60,
  nightMuteEnd: 6 * 60 + 30,
  lunchMuteEnabled: false,
  disabledKinds: {ReminderKind.sedentary, ReminderKind.eye},
  demoRhythm: true,
  deEscalationAckDay: '2026-11-17',
);

void main() {
  const legacyValue = '75|0|1|1380|390|0|sedentary,eye|1|2026-11-17';

  test('读取完整 v1 配置，保留所有非默认字段', () async {
    SharedPreferences.setMockInitialValues({_legacyKey: legacyValue});
    expect(await PrefsReminderConfigRepository().load(), _legacyConfig);
  });

  test('旧记录缺少尾部字段时沿用默认值', () async {
    SharedPreferences.setMockInitialValues({_legacyKey: '45|1|0|1320|420'});
    expect(
      await PrefsReminderConfigRepository().load(),
      const ReminderConfig(sedentaryMinutes: 45, eyeEnabled: false),
    );
  });

  test('忽略未知禁用类别并保留已识别类别', () async {
    SharedPreferences.setMockInitialValues({
      _legacyKey: '55|1|1|1320|420|1|futureKind,water',
    });
    expect(
      await PrefsReminderConfigRepository().load(),
      const ReminderConfig(disabledKinds: {ReminderKind.water}),
    );
  });

  test('空库和无法解析的旧记录使用默认配置', () async {
    for (final values in <Map<String, Object>>[
      {},
      {_legacyKey: ''},
      {_legacyKey: 'broken'},
    ]) {
      SharedPreferences.setMockInitialValues(values);
      expect(
        await PrefsReminderConfigRepository().load(),
        const ReminderConfig(),
      );
    }
  });

  test('修改单个开关后仍可读回其余旧配置', () async {
    SharedPreferences.setMockInitialValues({_legacyKey: legacyValue});
    final repository = PrefsReminderConfigRepository();
    final previous = await repository.load();
    await repository.save(previous.copyWith(waterEnabled: true));

    expect(
      await PrefsReminderConfigRepository().load(),
      _legacyConfig.copyWith(waterEnabled: true),
    );
  });
}
