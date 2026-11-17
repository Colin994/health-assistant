import 'package:core_model/core_model.dart';
import 'package:core_profile/core_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('保存及清空健康标签后，新仓库实例能读回结果', () async {
    final store = PrefsHealthTagStore();
    await store.save({'颈椎不适', '常忘喝水'});
    expect(await PrefsHealthTagStore().load(), {'颈椎不适', '常忘喝水'});

    await store.save({});
    expect(await PrefsHealthTagStore().load(), isEmpty);
  });

  test('健康标签仅开启对应提醒并保留其他配置', () async {
    final repository = PrefsReminderConfigRepository();
    const original = ReminderConfig(
      sedentaryMinutes: 75,
      waterEnabled: false,
      eyeEnabled: false,
      disabledKinds: {ReminderKind.water, ReminderKind.eye},
    );
    await repository.save(original);

    final updated = await enableRemindersForTags({'常忘喝水'}, repository);

    expect(
      updated,
      original.copyWith(waterEnabled: true, disabledKinds: {ReminderKind.eye}),
    );
    expect(await PrefsReminderConfigRepository().load(), updated);
    expect(await enableRemindersForTags({}, repository), updated);
  });
}
