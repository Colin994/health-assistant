# Android and iOS design and walkthrough contract

Both platforms ship the same Flutter product. They use the same approved Pixso revision, screen states, content hierarchy, interaction outcomes and walkthrough cases. The shared implementation lives in the Flutter feature packages, with tokens and adaptive layout in [feature_design_system](../feature_design_system/lib/src). Coordinate shared changes there.

This is the standing workflow for every change that can affect either mobile app. For each change, identify the affected behavior and shared case IDs, implement the change, run applicable automated checks, then record the Android and iOS walkthrough status separately. Use the current approved design as the baseline when a change leaves the interface and interactions unchanged. When the change alters a screen or user flow, identify the reviewed revision for that scope before implementing it. Select device checks by impact. For example, a permissions change calls for the affected system scenarios, and adjusting static copy calls for checking the affected screen. Documentation-only and developer tooling changes with no effect on either app can record mobile checks as not applicable.

System permission dialogs, system fonts and text scaling, safe areas, and native back gestures follow the platform. Record any other intentional difference with the affected screen and case ID, the reason, and the expected result on each platform. An Android-only permission such as exact alarms is an Android sub-step of the common notification case.

## Design handoff

The [design baseline](design-baseline.md) is the source of truth for approved revisions by screen and state. [Design proposals](design-proposals/) hold candidate work. Record approval for the specific scope, then promote only those entries to the baseline with a fixed design reference. A Pixso page or frame ID locates the design. A named revision or dated reviewed snapshot and an explicit approval record establish the baseline.

For each UI change record the following in the PR or accompanying design handoff:

| Field | What to record |
| --- | --- |
| Design revision | Pixso file and page, named version or dated reviewed export, and frame IDs. Retain a snapshot accessible to reviewers when the editable canvas can change. Use the same reference for both platforms. |
| Screen and states | Flutter route or widget, default and affected alternate states, and each changed action's expected destination or effect. |
| Checks | Shared case IDs, visual checkpoints and any explicitly reviewed platform exception. |

## One common test suite

Use the [whole-app walkthrough](app-walkthrough.md) for per-case steps, expected results and evidence.

[mobile-walkthrough.json](mobile-walkthrough.json) holds the shared case IDs. Both Android and iOS use the same [Flutter integration test](../app/integration_test/walkthrough_test.dart) and [memory fixture](../app/integration_test/fixtures/walkthrough_seed.dart). Keep platform-only sub-steps under the corresponding case. Use locale, display mode, text size, orientation and permissions that match the scenario under review; note differences in the report.

The automatic fixture starts after onboarding and does not run the notification coordinator or test disk persistence. Do the manual cases through the normal app entry on a dedicated test installation. Use the app's dev channel for test reminders when indicated. The runner deploys a test binary and explicitly passes `--no-uninstall` because Flutter otherwise uninstalls it after the test. The iOS dev and master Dart channels share a bundle ID. Restore the normal app entry after the run, and use a dedicated device or app identifier when the installed app or its data must be preserved without replacement.

From the repository root, list devices with `flutter devices`, then repeat this command for each physical device with the same design reference and code revision:

```sh
python3 tools/device_walkthrough.py --device <device-id> --design-ref '<approved-design-revision>'
```

The runner defaults to `master`. Use `--flutter <path>` if Flutter is outside PATH and `--flavor dev` for a dev-specific run. Both devices require a trusted development connection and the appropriate SDK and signing setup.

## Acceptance

1. Run shared Flutter analysis and relevant widget/integration checks, then build for each target. Check narrow widths, dark mode, large text, touch targets and the system accessibility settings applicable to the changed screens.
2. Run the shared physical-device suite on Android and iOS. Use the same reviewed source revision, design reference and fixture version. If using a local build with uncommitted source changes, identify the exact shared snapshot used for both runs; matching Git HEAD alone is insufficient.
3. Verify the applicable manual cases on each device. In each `report.json` record actual results and screenshot, recording, or log references. Keep the design reference, device and OS, build/channel, locale, theme, text size, orientation, and permission state with the evidence. Compare screenshots to the same Pixso frame or approved export.
4. Mark each platform as passed, failed, blocked, or pending in the handoff. Claim cross-platform acceptance only when both device reports have passing shared automated cases, passing applicable manual checks, and evidence for the reviewed design and build. Simulator, CI, and single-platform results may be reported independently.

`python3 tools/device_walkthrough.py --check-contract` checks the shared case registry against the Flutter test markers in CI. The two physical-device reports and manual evidence establish device acceptance.

## 提醒配置存储变更

验收范围为保留应用数据的同渠道覆盖升级。卸载重装和清除应用数据后的恢复暂不纳入。

- **代码回归**：通过 [配置仓库测试](../core_profile/test/reminder_config_repository_test.dart) 核对旧格式全量读取、缺字段、未知类别、空或损坏数据及单项更新。这些用例通过 `melos run test` 执行，使用内存 Prefs。
- **W03**：从「我的」打开「提醒设置」，核对久坐和免打扰内容，点击返回后确认「健康标签」再次可见。
- **M07-disk-persistence**：在两端的专用测试安装上，使用真实磁盘和正常入口执行下表步骤。自动套件可能替换当前渠道的调试应用，单独完成旧版到新版的连续升级取证。
- **M04-notification**：在 dev 渠道使用覆盖升级后的配置，核对启用类别的实际送达和点击落点，并在记录的观察窗口核对关闭类别和静音时段。Android 记录通知授权状态及非精确调度的实际送达；iOS 记录通知授权状态及前台、后台、结束进程后的实际送达和点击落点。

| M07 步骤 | 通过条件与证据 |
| --- | --- |
| 在旧版保存基准 | 久坐 75 分钟、喝水关、护眼开、夜间静音 23:00–06:30、午休关。记录实际值及截图，记录可通过正常流程设置的永久禁用类别、演示节奏和降频提示确认状态。 |
| 使用相同应用标识覆盖更新，首次启动进入提醒设置 | 逐项与旧版记录一致。保留旧版和新版构建标识、渠道、覆盖安装结果及配置截图。 |
| 结束进程并冷启动 | 配置仍与旧版记录一致，保留结果截图或日志。 |
| 仅打开喝水开关，再结束进程并冷启动 | 喝水保持开启，其余记录项保持原值。保留结果截图或日志。 |

Android 和 iOS 各自在 `report.json` 的 M07 和 M04 下填写状态及证据引用，并在 M04
记录通知的预期时间、实际时间及点击落点。设计引用按[批准基线](design-baseline.md)
填写，缺少批准记录时标为 pending。
