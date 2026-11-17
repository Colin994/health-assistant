import 'package:injectable/injectable.dart';

/// 引擎时钟抽象（测试注入假时钟驱动全部场景）。
abstract class ReminderClock {
  DateTime now();
}

@LazySingleton(as: ReminderClock)
class SystemReminderClock implements ReminderClock {
  @override
  DateTime now() => DateTime.now();
}
