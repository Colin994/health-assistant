/// core_database：数据库支撑模块。
///
/// W2 实施决策（2026-11-09）：本机工具链不可用 drift/sqlite3（GitHub TLS
/// 阻断 sqlite3 build hook + drift 2.35 codegen 兼容问题），提醒域持久化
/// 以 SharedPreferences JSON 等价落地在 core_reminder（表结构与语义不变）。
/// 本模块保留给 Pro 期关系型需求（advice 缓存/分析类数据）。
library;
