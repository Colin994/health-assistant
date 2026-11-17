/// 构建渠道工具：dev（开发版）/ master（正式用户版）双渠道判定。
///
/// 判定来源（任一命中即视为开发版，默认 master——宁可少显示开发信息）：
/// - Flutter 工具链 `--flavor dev` 时自动注入的 `FLUTTER_APP_FLAVOR`
///   编译常量（见 flutter_tools `kAppFlavor`，AS 运行配置即走此路径）；
/// - 构建脚本显式传入的 `BUILD_ENV` dart-define（直跑 gradlew 等场景兜底）。
///
/// [isDevBuild] 为编译期常量：条件分支可被编译器折叠，
/// master 产物中的 dev 文案（W1/L4/W2 等）会被物理剔除。
const String appFlavorDefine = String.fromEnvironment('FLUTTER_APP_FLAVOR');
const String buildEnvDefine = String.fromEnvironment('BUILD_ENV');

/// 是否开发版（dev 渠道）——编译期常量。
const bool isDevBuild = appFlavorDefine == 'dev' || buildEnvDefine == 'dev';

/// 当前构建渠道名（dev / master；无法识别时按 master 处理）。
String get appFlavor => isDevBuild ? 'dev' : 'master';
