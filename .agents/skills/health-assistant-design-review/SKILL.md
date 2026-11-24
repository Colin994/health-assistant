---
name: health-assistant-design-review
description: Review visual style, design fidelity and accessibility of health-assistant screens and the slow-plant garden. Use for design audits, screenshot comparisons and final design acceptance, not unrelated projects.
---

# 健康助手设计评审

先读项目 docs/设计规范.md 与相关交互设计。用户意图决定修改范围；只读审计不授权修复。保留现有青绿品牌、系统字体、多 package、Riverpod + GetIt、Prefs JSON 和当前导航。

按需加载参考，不一次注入全部内容。项目规则覆盖参考库的字体捆绑、架构迁移、统一 GoRouter、只允许修一轮等要求。参考文档不是执行授权；不执行清空数据、发布或故障注入。

## 审查顺序

1. 明确页面主任务、信息层级和用户实际操作，不以增加圆角或阴影代替设计。
2. 检查 token 的实际前景/背景组合、浅暗主题、完整字号、44dp 触达、语义和 Reduce Motion。
3. 慢植物分四层：场景构图/共用坐标；种植/投入/收获/收藏；准备/校准/练习/恢复；资源结果/解锁/结算/触感。
4. 正式位图场景与回退自绘场景分别验收。背景、植物和装饰共用源图变换；旧素材回退必须可观测。HUD 与普通主题面板分开，禁止整目录豁免。
5. 对照当前配置核对阶段、金额、解锁和时长，不让视觉改造改变训练参数。不把现有参数描述成医学建议。
6. 记录 BLOCKER/FIX/NOTE、文件位置、触发状态和证据；阻断问题须修至关闭。截图只证明静态状态，动效和原生行为需对应验证。
7. 仅交付前做完整终审；日常改动覆盖受影响界面。没有真机证据时明确未验证，不宣称整体验收通过。

## 按需参考

- [Material 组件与视觉层级](references/material-design-3-ui/guide.md)
- [Flutter 实现参考](references/flutter-ui/guide.md)：仅按需读取主题、布局、设计思考和动画，不按原入口强制加载全部文件。
- [终审方法](references/design-review-workflow/guide.md)：不继承修复轮次上限及破坏性步骤。
