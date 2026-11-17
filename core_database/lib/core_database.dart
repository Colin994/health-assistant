/// core_database：数据库支撑模块。
///
/// W2 实施决策（2026-11-09）：本机工具链不可用 drift/sqlite3（GitHub TLS
/// 阻断 sqlite3 build hook + drift 2.35 codegen 兼容问题），持久化以
/// SharedPreferences JSON 等价落地（表结构与语义不变）。
///
/// M2 起（2026-11-12）：游戏经济（阳光/种子/每日额度）在本模块落盘
/// （[GameEconomyStore]），沿用同一决策;Pro 期关系型需求（advice 缓存/
/// 分析类数据）继续预留。
library;

export 'src/game_economy_models.dart';
export 'src/game_economy_store.dart';
export 'src/injector.module.dart';
