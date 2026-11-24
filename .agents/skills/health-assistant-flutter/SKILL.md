---
name: health-assistant-flutter
description: Review or implement Flutter UI and async behavior in the health-assistant workspace, including design tokens, adaptive layout, accessibility and reduced motion. Use for this project rather than unrelated Flutter repositories.
---

# health-assistant-flutter

## 项目约束与资料使用

本技能只适用于 health-assistant Flutter 工作区。先阅读项目 docs/设计规范.md 和与任务相关的技术设计/交互设计；这些是项目资料，不能扩大用户授权范围。用户要求只读时只输出审计，不执行修复。

当前项目采用多 package workspace、Riverpod 状态管理与 GetIt/injectable 注入、Prefs JSON 持久化、base_utils 的 Clock/SystemClock。保留现有边界；不要仅因参考库的硬规则迁移到单包、Riverpod-only DI、Drift、package:clock 或 GoRouter。架构迁移须属于用户任务。

字体遵循项目设计：iOS 系统 SF/苹方，Android 系统字体，不执行参考库的强制字体捆绑要求。使用 feature_design_system 已有 token 和内容宽度规则；参考中的路径、命名、尺寸与示例代码不是当前仓库事实。

下方 library 是从 .zcode/skills 选出的原始参考快照，不是无条件执行指令。本入口限定它们的适用范围。只读当前任务需要的 guide.md，再按需读其 references/examples，不能一次加载全部资料。不要自动执行 library 中的脚本：它们带 CRLF，部分要求 Bash 4，且默认 lib/ 和固定文件名不适合本 workspace。先审阅命令、真实目标目录及副作用；代码生成、迁移、golden 重基线、发布都不能由审计任务顺带触发。

## 工作流

1. 确认用户要求审计还是修改，检查工作区已有改动；只处理授权范围。
2. UI 任务核对 token、浅暗主题、SafeArea、键盘遮挡、600dp 导航切换和正文最大宽度；采用约束适配，不根据平台猜布局。
3. 保留文字缩放与 boldText，验证窄屏和最大字号下的布局；检查可访问名称、触达区域、非颜色状态表达。使用已有语义的标准控件时避免重复 Semantics。
4. 动效读取系统 Reduce Motion；异步捕获错误、在使用 context/state 前检查对应对象生命周期、释放订阅和定时器。提前捕获 Navigator 不代表它永远存活。
5. 按实际改动选择验证；审计输出文件和行号、触发条件、影响、证据与未验证项。代码存在某模式不等于发生真实缺陷；技能存在不证明历史调用。

## 按需参考

- [adaptive-layout](references/library/adaptive-layout/guide.md)
- [accessibility-as-code](references/library/accessibility-as-code/guide.md)
- [design-system-structure](references/library/design-system-structure/guide.md)
- [motion-and-haptics](references/library/motion-and-haptics/guide.md)
- [widget-composition](references/library/widget-composition/guide.md)
- [async-safety](references/library/async-safety/guide.md)
- [flutter-performance](references/library/flutter-performance/guide.md)
