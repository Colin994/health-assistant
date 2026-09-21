/// domain_all：领域层模块，存放全部 UseCase。
///
/// UseCase 只含一个 `call` 函数，依赖全部走构造函数注入，
/// 统一 `@injectable` 注解（架构文档 3.3）。
library;

export 'src/fetch_segments_use_case.dart';
export 'src/injector.module.dart';
