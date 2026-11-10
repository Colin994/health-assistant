import 'package:core_model/core_model.dart';
import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'reminder_settings_intent.dart';
import 'reminder_settings_state.dart';

/// 提醒设置页状态持有者（W2 起读写 ReminderConfigRepository 持久化）。
///
/// 变更口径（评审决策）：档位/开关/静音修改不打断进行中的倒计时，
/// **次轮生效**——经引擎 `onSettingsChanged` 重载配置。
class ReminderSettingsViewModel extends Notifier<ReminderSettingsState> {
  @override
  ReminderSettingsState build() {
    _load();
    return const ReminderSettingsState();
  }

  Future<void> _load() async {
    final config = await GetIt.I<ReminderConfigRepository>().load();
    if (!ref.mounted) return;
    state = _map(config);
  }

  ReminderSettingsState _map(ReminderConfig config) {
    return ReminderSettingsState(
      density: RemindDensity.fromMinutes(config.sedentaryMinutes),
      waterReminderEnabled: config.waterEnabled,
      eyeReminderEnabled: config.eyeEnabled,
      nightMuteStart: config.nightMuteStart,
      nightMuteEnd: config.nightMuteEnd,
      lunchMuteEnabled: config.lunchMuteEnabled,
      sedentaryDisabled: config.disabledKinds.contains(ReminderKind.sedentary),
    );
  }

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  Future<void> handleIntent(ReminderSettingsIntent intent) async {
    final repo = GetIt.I<ReminderConfigRepository>();
    final engine = GetIt.I<ReminderEngine>();
    final config = await repo.load();
    switch (intent) {
      case DensitySelected(:final density):
        // 重选档位即恢复被「别再提醒」禁用的久坐类（设置内自愈路径）。
        final disabled = {...config.disabledKinds}
          ..remove(ReminderKind.sedentary);
        await repo.save(config.copyWith(
          sedentaryMinutes: density.minutes,
          disabledKinds: disabled,
        ));
        state = state.copyWith(density: density, sedentaryDisabled: false);
      case WaterReminderToggled(:final enabled):
        await repo.save(config.copyWith(waterEnabled: enabled));
        state = state.copyWith(waterReminderEnabled: enabled);
      case EyeReminderToggled(:final enabled):
        await repo.save(config.copyWith(eyeEnabled: enabled));
        state = state.copyWith(eyeReminderEnabled: enabled);
      case MuteWindowChanged(:final startMinutes, :final endMinutes):
        await repo.save(config.copyWith(
          nightMuteStart: startMinutes,
          nightMuteEnd: endMinutes,
        ));
        state = state.copyWith(
          nightMuteStart: startMinutes,
          nightMuteEnd: endMinutes,
        );
      case LunchMuteToggled(:final enabled):
        await repo.save(config.copyWith(lunchMuteEnabled: enabled));
        state = state.copyWith(lunchMuteEnabled: enabled);
    }
    // 次轮生效：引擎重读配置（进行中的倒计时不受影响）。
    await engine.onSettingsChanged();
  }
}

/// 提醒设置页状态容器（push 进入：pop 后状态随 provider 自动销毁）。
final reminderSettingsViewModelProvider =
    NotifierProvider<ReminderSettingsViewModel, ReminderSettingsState>(
      ReminderSettingsViewModel.new,
    );
