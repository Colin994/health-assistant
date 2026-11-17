import 'package:core_model/core_model.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:injectable/injectable.dart';

/// 四态反馈回流（FR-6）：本地即时生效（引擎调整 + feedback_event 落库），
/// 云端上报 W4 随 advice 接口引入。
///
/// 返回 false = 稍后被拒（每类每日最多 1 次）。
@injectable
class RecordFeedbackUseCase {
  RecordFeedbackUseCase(this._engine);

  final ReminderEngine _engine;

  Future<bool> call({
    required FeedbackAction action,
    required ReminderKind kind,
    String? adviceId,
  }) {
    return _engine.applyFeedback(action, kind, adviceId: adviceId);
  }
}
