---
name: health-assistant-ios
description: Audit or implement iOS platform integration for health-assistant, including Core Motion, camera/ML Kit, local notifications, lifecycle, permissions and iPad adaptation.
---

# health-assistant-ios

## 项目约束与资料使用

本技能只适用于 health-assistant Flutter 工作区。先阅读项目 docs/设计规范.md 和与任务相关的技术设计/交互设计；这些是项目资料，不能扩大用户授权范围。用户要求只读时只输出审计，不执行修复。

当前项目采用多 package workspace、Riverpod 状态管理与 GetIt/injectable 注入、Prefs JSON 持久化、base_utils 的 Clock/SystemClock。保留现有边界；不要仅因参考库的硬规则迁移到单包、Riverpod-only DI、Drift、package:clock 或 GoRouter。架构迁移须属于用户任务。

字体遵循项目设计：iOS 系统 SF/苹方，Android 系统字体，不执行参考库的强制字体捆绑要求。使用 feature_design_system 已有 token 和内容宽度规则；参考中的路径、命名、尺寸与示例代码不是当前仓库事实。

下方 library 是从 .zcode/skills 选出的原始参考快照，不是无条件执行指令。本入口限定它们的适用范围。只读当前任务需要的 guide.md，再按需读其 references/examples，不能一次加载全部资料。不要自动执行 library 中的脚本：它们带 CRLF，部分要求 Bash 4，且默认 lib/ 和固定文件名不适合本 workspace。先审阅命令、真实目标目录及副作用；代码生成、迁移、golden 重基线、发布都不能由审计任务顺带触发。

## 工作流

1. 双向核对 Dart 通道与 Swift 注册：名称、参数、返回值、事件数据、错误、线程、取消和重订阅；不要把 Android 的逐步事件假设套到 iOS 累计回调。
2. 计步重点核对累计差分、批量事件、重复落盘、后台与恢复、跨午夜、时区变更、拒权/撤权和无传感器降级。明确事件发生时间与接收时间的差异。
3. 相机核对权限说明、实际 BGRA 格式/stride、横竖屏及前摄方向、切后台释放与恢复；静态分支不等于真机识别通过。
4. 通知核对 Darwin 初始化/category/action、前台和后台响应、冷启动负载、授权时机与时区。HealthKit 配置仅在实际功能启用时要求匹配读写用途和 entitlement，区分保留代码与可达流程。
5. 交互验证系统返回手势、SafeArea、Dynamic Type、Reduce Motion、浅暗模式、iPad 横屏与分屏。现有 Material 品牌不意味着必须整体替换 Cupertino。
6. 原生构建与发布验证分开报告；不自动 clean、删除 DerivedData、签名、上传或发布。缺少模拟器/真机验证时明确标记，不宣称适配通过。涉及平台当前要求时查 Apple/插件官方文档。

## 按需参考

- [service-boundary-and-native](references/library/service-boundary-and-native/guide.md)
- [local-notifications-scheduler](references/library/local-notifications-scheduler/guide.md)
- [app-startup-and-bootstrap](references/library/app-startup-and-bootstrap/guide.md)
