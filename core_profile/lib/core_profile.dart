/// core_profile：画像域数据层。
///
/// W2 落地：ReminderConfigRepository（提醒配置）与 HealthTagStore（健康标签）
/// 本地持久化（SharedPreferences）；云端 profile 同步在 Pro 后引入。
library;

export 'src/health_tag_store.dart';
export 'src/injector.module.dart';
export 'src/reminder_config_repository.dart';
