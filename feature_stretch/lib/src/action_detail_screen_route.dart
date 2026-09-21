import 'dart:async';

import 'package:flutter/material.dart';

import 'action_detail_screen.dart';
import 'stretch_state.dart';

/// 动作详情跳转入口（设计稿 06）。
///
/// 倒计时归 Route State 持有（与 PageController 同一归属先例）；
/// 时长从动作条目解析（「40 秒 · 每侧 2 次」→ 40s）。
class ActionDetailScreenRoute extends StatefulWidget {
  const ActionDetailScreenRoute({super.key, required this.action});

  final StretchAction action;

  /// 跳转到动作详情。
  static Future<void> push(BuildContext context, StretchAction action) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ActionDetailScreenRoute(action: action),
      ),
    );
  }

  @override
  State<ActionDetailScreenRoute> createState() =>
      _ActionDetailScreenRouteState();
}

class _ActionDetailScreenRouteState extends State<ActionDetailScreenRoute> {
  late int _remaining;
  bool _running = false;
  Timer? _timer;

  int get _totalSeconds =>
      int.tryParse(
        widget.action.durationLabel.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      40;

  @override
  void initState() {
    super.initState();
    _remaining = _totalSeconds;
  }

  void _toggleRunning() {
    if (_remaining == 0) {
      return;
    }
    setState(() => _running = !_running);
    if (_running) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remaining > 0) {
            _remaining -= 1;
            if (_remaining == 0) {
              _running = false;
              timer.cancel();
            }
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActionDetailScreen(
      action: widget.action,
      remainingSeconds: _remaining,
      running: _running,
      onStartPressed: _toggleRunning,
      onBackPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
