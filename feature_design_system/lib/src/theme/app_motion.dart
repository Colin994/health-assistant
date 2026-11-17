import 'package:flutter/widgets.dart';

/// Durations describe feedback roles, never business/session timing.
abstract final class AppMotion {
  static const feedback = Duration(milliseconds: 100);
  static const standard = Duration(milliseconds: 200);
  static const emphasis = Duration(milliseconds: 350);
}

/// Read OS preferences where motion is rendered, including runtime changes.
Duration resolveMotion(BuildContext context, Duration normalDuration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : normalDuration;
