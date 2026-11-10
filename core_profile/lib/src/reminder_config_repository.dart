import 'package:core_model/core_model.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 提醒配置仓库（档位/开关/静音/禁用类；SharedPreferences 持久化）。
///
/// 引擎与设置页均经此读写；变更后由调用方触发引擎 `onSettingsChanged`
/// （次轮生效语义在引擎内保证）。
abstract class ReminderConfigRepository {
  Future<ReminderConfig> load();

  Future<void> save(ReminderConfig config);
}

@LazySingleton(as: ReminderConfigRepository)
class PrefsReminderConfigRepository implements ReminderConfigRepository {
  static const _key = 'reminder_config_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<ReminderConfig> load() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const ReminderConfig();
      final parts = raw.split('|');
      final disabled = <ReminderKind>{};
      for (final name in (parts.length > 6 ? parts[6].split(',') : const <String>[])) {
        final kind = ReminderKind.values
            .where((k) => k.name == name)
            .firstOrNull;
        if (kind != null) disabled.add(kind);
      }
      return ReminderConfig(
        sedentaryMinutes: int.tryParse(parts[0]) ?? 55,
        waterEnabled: parts[1] == '1',
        eyeEnabled: parts[2] == '1',
        nightMuteStart: int.tryParse(parts[3]) ?? 22 * 60,
        nightMuteEnd: int.tryParse(parts[4]) ?? 7 * 60,
        lunchMuteEnabled: parts.length > 5 ? parts[5] == '1' : true,
        disabledKinds: disabled,
        demoRhythm: parts.length > 7 ? parts[7] == '1' : false,
        deEscalationAckDay: parts.length > 8 ? parts[8] : '',
      );
    } catch (_) {
      // 配置损坏 → 回退默认，不打断引擎启动。
      return const ReminderConfig();
    }
  }

  @override
  Future<void> save(ReminderConfig config) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(
        _key,
        [
          config.sedentaryMinutes,
          config.waterEnabled ? '1' : '0',
          config.eyeEnabled ? '1' : '0',
          config.nightMuteStart,
          config.nightMuteEnd,
          config.lunchMuteEnabled ? '1' : '0',
          config.disabledKinds.map((k) => k.name).join(','),
          config.demoRhythm ? '1' : '0',
          config.deEscalationAckDay,
        ].join('|'),
      );
    } catch (_) {
      // 持久化失败（如测试环境无插件）静默：内存配置照常生效。
    }
  }
}

extension<T extends Enum> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
