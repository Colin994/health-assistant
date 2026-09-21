/// core_model：全局通用业务对象。
///
/// 只存放业务对象的类设计，供各层做数据转换；
/// 严禁在此模块写入任何业务逻辑（技术设计文档 §3.2）。
library;

export 'src/activity_segment.dart';
export 'src/feedback_event.dart';
export 'src/health_tag.dart';
export 'src/trigger_context.dart';
