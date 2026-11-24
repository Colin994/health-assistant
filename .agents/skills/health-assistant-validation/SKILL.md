---
name: health-assistant-validation
description: Validate changes or audit test and CI coverage in the health-assistant Flutter workspace, including widget geometry, text scaling, accessibility, deterministic game logic and iOS build evidence.
---

# health-assistant-validation

## 项目约束与资料使用

本技能只适用于 health-assistant Flutter 工作区。先阅读项目 docs/设计规范.md 和与任务相关的技术设计/交互设计；这些是项目资料，不能扩大用户授权范围。用户要求只读时只输出审计，不执行修复。

当前项目采用多 package workspace、Riverpod 状态管理与 GetIt/injectable 注入、Prefs JSON 持久化、base_utils 的 Clock/SystemClock。保留现有边界；不要仅因参考库的硬规则迁移到单包、Riverpod-only DI、Drift、package:clock 或 GoRouter。架构迁移须属于用户任务。

字体遵循项目设计：iOS 系统 SF/苹方，Android 系统字体，不执行参考库的强制字体捆绑要求。使用 feature_design_system 已有 token 和内容宽度规则；参考中的路径、命名、尺寸与示例代码不是当前仓库事实。

下方 library 是从 .zcode/skills 选出的原始参考快照，不是无条件执行指令。本入口限定它们的适用范围。只读当前任务需要的 guide.md，再按需读其 references/examples，不能一次加载全部资料。不要自动执行 library 中的脚本：它们带 CRLF，部分要求 Bash 4，且默认 lib/ 和固定文件名不适合本 workspace。先审阅命令、真实目标目录及副作用；代码生成、迁移、golden 重基线、发布都不能由审计任务顺带触发。

## 工作流

1. 从仓库 pubspec.yaml、各 package pubspec 和 .github/workflows/ci.yml 确认真实命令与工具链。测试范围随修改风险，不为纯技能安装运行应用测试。
2. widget 测试固定逻辑视口与 DPR 并在结束还原；覆盖窄手机、600dp 两侧、iPad 横屏/分屏、最大字号、粗体、Reduce Motion、浅暗主题。按项目支持范围覆盖语言。
3. 优先使用现有 harness 与布局/行为断言；不吞掉 overflow，不用缩字或截断来伪造通过，不把 golden 图片等同功能或 VoiceOver 验收。
4. 计步/游戏/时间逻辑使用现有可注入 Clock，验证边界和独立预期；持久化测试使用项目实际存储，不能为了匹配参考引入 Drift。
5. 区分 Dart/widget 测试、iOS 原生编译、模拟器集成、真机权限/传感器测试；Ubuntu CI 无法证明 Swift 编译和真机功能通过。
6. 仅运行适合当前任务的已有检查。代码生成和 golden 重基线会修改文件，审计任务不得触发；不为绿灯覆盖参考图。报告实际执行命令、结果及未覆盖范围。

## 按需参考

- [testing-strategy](references/library/testing-strategy/guide.md)
- [widget-golden-and-a11y-testing](references/library/widget-golden-and-a11y-testing/guide.md)
- [seeded-determinism-and-golden-vectors](references/library/seeded-determinism-and-golden-vectors/guide.md)
- [ci-pipeline-and-gates](references/library/ci-pipeline-and-gates/guide.md)
