import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

/// 主壳 dev 渠道工具 ViewModel（2026-11-12 架构审计 F1 修复）。
///
/// 架构文档 3.1 双容器边界：View 不直调 Service/Repository——此前
/// MainShell 两处 dev 工具（测试提醒 / 演示节奏）经 `GetIt.I` 直达
/// 领域层，属越层；现一律经本 ViewModel 转发，View 只做渲染。
/// 无状态命令对象：动作结果以返回值交给 View 呈现（SnackBar）。
class DevToolsViewModel {
  /// dev 渠道「发送测试提醒」：直接发一条本地通知（v8 自用户页面移入）。
  Future<void> sendTestReminder() async {
    await GetIt.I<ReminderNotificationService>().showNow(
      id: ReminderNotificationIds.testId,
      title: '测试提醒',
      body: '这是一条测试提醒——倒计时到点后，会像这样提醒你',
    );
  }

  /// dev 渠道「演示节奏」：三类间隔一律 1 分钟（忽略静音），真机 E2E 用。
  ///
  /// 返回结果文案（开启/关闭），供 View 以 SnackBar 呈现。
  Future<String> toggleDemoRhythm() async {
    final repo = GetIt.I<ReminderConfigRepository>();
    final engine = GetIt.I<ReminderEngine>();
    final config = await repo.load();
    final next = config.copyWith(demoRhythm: !config.demoRhythm);
    await repo.save(next);
    await engine.onSettingsChanged();
    return next.demoRhythm
        ? '演示节奏已开启：1 分钟间隔（静音忽略）'
        : '演示节奏已关闭，恢复正常间隔';
  }
}

/// 主壳 dev 工具注入点（provider 即 DI；测试 override 假实现）。
final devToolsViewModelProvider = Provider<DevToolsViewModel>(
  (ref) => DevToolsViewModel(),
);
