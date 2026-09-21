/// core_reminder：提醒域数据层。
///
/// W1 为空壳；W2 落地 ReminderRepository（规则配置 CRUD、触发状态读写、
/// advice 日志追加、反馈事件 7 天窗口统计），实现经 core_database。
library;
