/// 注入式时钟抽象（2026-11-12 架构审计 F2 修复：时钟纪律全工作区统一）。
///
/// 业务代码一切「现在」取自 [Clock.now]，禁止直读墙钟 `DateTime.now()`
/// （架构规则：副作用走注入接口——墙钟是全局副作用，直读即不可测）。
/// 生产注入 [SystemClock]；测试注入假时钟驱动跨日、冷却边界等场景。
/// core_reminder 的 [ReminderClock] 为引擎内既有时钟，语义与本接口一致。
abstract class Clock {
  const Clock();

  /// 当前时刻（本地时区，语义与 `DateTime.now()` 一致）。
  DateTime now();
}

/// 生产实现：设备墙钟。全工作区唯一直读 `DateTime.now()` 的地方。
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
