/// domain_all：领域层模块，存放全部 UseCase。
///
/// UseCase 只含一个 `call` 函数，依赖全部走构造函数注入，
/// 统一 `@injectable` 注解（架构文档 3.3）。
/// （W2 起陆续入驻倒计时引擎相关 UseCase；W1 的 FetchSegmentsUseCase
/// 随 demo 页移除——活动分段读取 Pro 期随手表连接回归。）
library;

export 'src/injector.module.dart';
export 'src/record_feedback_use_case.dart';
