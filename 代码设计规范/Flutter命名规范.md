# Flutter 命名规范

> 依据：Dart 官方《Effective Dart: Style》（dart.dev/effective-dart/style）+ Flutter 社区通用实践
> 适用：本项目全部 Dart 代码、目录、资源与测试文件
> 关系：与《Flutter项目架构设计文档.md》配套使用——架构文档定"放哪里"，本文档定"怎么取名"

---

## 1. 三种命名法总览

| 命名法 | 形式 | 示例 |
|---|---|---|
| UpperCamelCase（大驼峰） | 每个单词首字母大写 | `HttpRequest` |
| lowerCamelCase（小驼峰） | 首词小写，其余首字母大写 | `httpRequest` |
| lowercase_with_underscores（蛇形小写） | 全小写，下划线分隔 | `file_system.dart` |

> SCREAMING_CAPS（全大写下划线）在 Dart 中**不使用**（仅在与既有代码保持一致时例外，如 protobuf 生成代码）。

## 2. 标识符规则（官方强制）

| 对象 | 命名法 | 示例 |
|---|---|---|
| 类、枚举、typedef、类型参数 | UpperCamelCase | `class ActivitySegment`、`enum FeedbackAction` |
| extension | UpperCamelCase | `extension ListX<T>` |
| 包名（package）、目录、源文件 | 蛇形小写 | `core_health`、`health_repository.dart` |
| import 前缀 | 蛇形小写 | `import 'dart:math' as math;` |
| 变量、函数、参数、类成员 | lowerCamelCase | `continuousSedentaryMinutes`、`fetchSegments()` |
| 常量（const/final）与枚举值 | lowerCamelCase | `const defaultTimeout = 1000;`、`FeedbackAction.done` |

要点：

- **常量不用大写**：`defaultTimeout` ✅，`DEFAULT_TIMEOUT` ❌（这是 Dart 与 Java/C 习惯最大的差异点）；
- **不用匈牙利前缀**：`defaultTimeout` ✅，`kDefaultTimeout` ❌（Flutter 框架源码中的 `k` 前缀是历史遗留，新代码不效仿）；
- **私有成员以 `_` 开头**：`_currentStreak`；非私有标识符不要以 `_` 开头（局部变量、参数、库前缀均不加）；
- **库命名**：不写 `library my_library;`，只用 `library;` 加文档注释；
- **未使用的匿名参数用 `_`**：`future.then((_) {...})`。

## 3. 缩写词规则

- 超过两个字母的缩写词按单词首字母大写：`Http`、`Nasa`、`Uri` ✅；`HTTP`、`NASA`、`URI` ❌；
- 两个字母的缩写保持全大写（英文中大写时）：`ID`→类成员中写 `userId`、类型中写 `TV`/`UI`（如 `UiState` 还是 `UIState`？按此规则两字母缩写在 UpperCamelCase 中全大写：`UIState`——**项目内统一取 `UiState` 形式亦可，但必须全局一致**）；
- lowerCamelCase 开头的缩写全小写：`httpConnection`、`tvSet`。

## 4. import 顺序

每个文件按以下分组排序，组间空行，组内字母序：

```dart
// 1. dart: 核心
import 'dart:async';
// 2. package: （含本项目包）
import 'package:core_model/core_model.dart';
import 'package:flutter/material.dart';
// 3. 相对导入
import '../widgets/action_card.dart';
// 4. export（单独分组）
export 'src/xxx.dart';
```

- 优先 `package:` 自包路径，避免相对导入跨包；
- import 前缀仅在有命名冲突时添加。

## 5. 文件与目录组织

- **文件名 = 蛇形小写 + `.dart`**，与文件内主类对应：`home_screen.dart` ↔ `class HomeScreen`；
- 一个文件一个主类；紧相关的小型私有辅助类/组件可同文件；
- **目录名蛇形小写**：`models/`、`widgets/`、`repositories/`；
- 测试文件与源文件同目录（或镜像目录），后缀 `_test.dart`：`evaluate_sedentary_use_case_test.dart`；
- 生成代码（injectable/JsonSerializable 等）输出到 `.g.dart` / `.gen.dart`，不手改。

## 6. Flutter 组件命名实践（社区通用）

### 6.1 Widget 类后缀

| 后缀 | 用途 | 示例 |
|---|---|---|
| `Screen` / `Page` | 路由级整页 | `HomeScreen`、`StretchScreen` |
| `Widget`（仅通用时） | 跨模块复用组件 | `PillButtonWidget` → 更常见直接 `PillButton` |
| `Card` / `Tile` / `Item` | 列表项/卡片 | `ActionCard`、`ArticleTile` |
| `Dialog` / `BottomSheet` | 弹层 | `FeedbackDialog` |
| `Bar` / `Button` / `Chip` / `Field` | 功能控件 | `TabBar`、`PillButton`、`TagChip`、`SearchField` |
| `View` | 组合型局部视图 | `CountCardView`（项目内建议用 `Card/Widget` 代替） |

通用小组件（无业务语义）直接用名词，不加后缀：`PillButton`、`SectionTitle`。

### 6.2 变量与回调

- **布尔值用判断性前缀**：`is/has/can/should/need` → `isAuthorized`、`hasPendingReminder`、`canSnoozeAgain`；
- **事件回调 `on` + 名词/过去式**：`onPressed`、`onFeedbackSelected`、`onAdviceReady`；
- **处理函数 `handle` + 名词**（ViewModel 内）：`handleFeedbackSelected`；
- Widget 构造参数与字段同名：`PillButton({required this.label})`；
- 通知/流事件对象以名词结尾或 `Event`：`HealthUpdateEvent`、`TriggerEvent`。

### 6.3 本项目架构组件后缀（对齐架构文档）

| 后缀 | 示例 | 说明 |
|---|---|---|
| `ScreenRoute` / `Screen` / `ViewModel` | `StretchScreenRoute` | 视图层三件套，架构文档 3.2 |
| `State` / `Intent` / `Event` | `StretchState`、`StretchIntent`、`StretchEvent` | 同上 |
| `UseCase` | `EvaluateSedentaryUseCase` | 领域层，仅含 `call()` |
| `Repository` / `RepositoryImpl` | `HealthRepository` / `HealthRepositoryImpl` | 数据层接口与实现 |
| `DataSource` / `DataSourceImpl` | `HealthDataSource` | 数据源 |
| `Api` | `AdviceApi` | core_network 接口定义 |
| 模块包名 | `feature_stretch`、`core_health`、`domain_all`、`base_utils` | 前缀即目录，架构文档 2.2 |

### 6.4 资源（assets）

- 文件与目录全蛇形小写：`assets/images/watch_icon.png`、`assets/animations/neck_stretch.json`；
- 按类型分目录：`images/`、`icons/`、`animations/`、`fonts/`；
- 分辨率目录用倍率后缀：`2.0x/`、`3.0x/`；
- 图标语义命名：`ic_` 前缀可选，保持一致即可。

### 6.5 国际化与路由

- l10n key 按 `页面.控件.语义` 层级蛇形或点分：`stretch.btn.done`、`home.card.reminder_count`；
- 路由名小写 + 斜杠：`/onboarding/tags`、`/stretch`；深链 scheme 小写：`healthassistant://stretch`。

## 7. 反例速查表

| ❌ 错误 | ✅ 正确 | 违反规则 |
|---|---|---|
| `HomeScreen.dart` | `home_screen.dart` | 文件蛇形小写 |
| `class home_screen` | `class HomeScreen` | 类大驼峰 |
| `const MaxRetryCount = 3` | `const maxRetryCount = 3` | 常量小驼峰 |
| `String URL;` | `String url;` | 缩写词规则 |
| `bool _isReady = ...`（公有 API） | `bool isReady` | 非私有不加 `_` |
| `kUserInfo` | `userInfo` | 匈牙利前缀 |
| `void clickButton()` | `void onPressed()` / `handleXxx` | 回调命名习惯 |
| `assets/WatchIcon.png` | `assets/icons/watch_icon.png` | 资源蛇形小写 |
| `getUserName_test.dart` | `get_user_name_test.dart` | 测试文件命名 |

## 8. 参考来源

- Dart 官方风格指南（Effective Dart: Style）：https://dart.dev/effective-dart/style
- Flutter 官方架构指南（views/widgets 组织）：https://docs.flutter.dev/app-architecture/guide
- 社区实践综述：[A Simple Way to Organize Your Code in Flutter（Medium）](https://medium.com/@kanellopoulos.leo/a-simple-way-to-organize-your-code-in-flutter-e175e7004fb5)、[Professional Flutter Project Structure](https://fluttersensei.com/blog/professional-flutter-project-structure)
