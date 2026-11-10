import 'dart:async';
import 'dart:convert';

import 'package:base_utils/base_utils.dart';
import 'package:core_model/core_model.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_stores.dart';

/// 三仓合一的本地持久化（技术设计文档 §9.4 的轻量实现）。
///
/// 存储介质说明（2026-11-09 实施决策）：原方案 drift/SQLite 在本机
/// 工具链不可用（sqlite3 build hook 需从 GitHub 下载 dll，本机 TLS 到
/// GitHub 失败；drift 2.35 两段式 codegen 在当前 build_runner 组合下
/// 不产出 part 文件）。三类数据量小（日志/反馈限长队列、状态单键），
/// 以 SharedPreferences JSON 等价落地：**表结构与语义不变**，
/// 读写全部降级容错（宿主无插件 → 内存态）。
abstract class ReminderPersistence
    implements ReminderLogStore, FeedbackLogStore, RuleStateStore {
  /// 清空全部持久化数据（dev 演示/测试用）。
  Future<void> clear();
}

@LazySingleton(as: ReminderPersistence)
class PrefsReminderPersistence implements ReminderPersistence {
  static const _stateKey = 'reminder_rule_state_v1';
  static const _fireKey = 'reminder_fire_log_v1';
  static const _feedbackKey = 'reminder_feedback_log_v1';

  /// 队列上限（触发日志 500 / 反馈 2000：7 天窗口统计绰绰有余）。
  static const _fireCap = 500;
  static const _feedbackCap = 2000;

  final _counts = StreamController<({int fired, int done})>.broadcast();

  // 内存镜像（首次加载后常驻；写入双写 prefs，读取零 IO）。
  List<Map<String, Object?>> _fires = [];
  List<Map<String, Object?>> _feedbacks = [];
  final Map<ReminderKind, RuleState> _states = {};

  @override
  Future<void> appendFire({
    required ReminderKind kind,
    required DateTime firedAt,
    String adviceId = '',
    String copyText = '',
  }) async {
    _fires.add({
      'kind': kind.name,
      'at': firedAt.millisecondsSinceEpoch,
      'adviceId': adviceId,
      'copy': copyText,
    });
    if (_fires.length > _fireCap) {
      _fires = _fires.sublist(_fires.length - _fireCap);
    }
    await _write(_fireKey, _fires);
    _pushCounts();
  }

  @override
  Stream<({int fired, int done})> watchDayCounts(DateTime day) {
    final controller = StreamController<({int fired, int done})>();
    final sub = _counts.stream.listen(controller.add);
    controller.onListen = () {
      if (!controller.isClosed) controller.add(_countsFor(day));
    };
    controller.onCancel = () async => sub.cancel();
    return controller.stream;
  }

  @override
  Future<void> add({
    required ReminderKind kind,
    required FeedbackAction action,
    required DateTime at,
    String? adviceId,
  }) async {
    _feedbacks.add({
      'kind': kind.name,
      'action': action.name,
      'at': at.millisecondsSinceEpoch,
      'adviceId': adviceId,
    });
    if (_feedbacks.length > _feedbackCap) {
      _feedbacks = _feedbacks.sublist(_feedbacks.length - _feedbackCap);
    }
    await _write(_feedbackKey, _feedbacks);
    _pushCounts();
  }

  @override
  Future<({int total, int negative})> stats7d(DateTime now) async {
    await _ensureLoaded();
    final from = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final recent =
        _feedbacks.where((e) => (e['at'] as int) >= from).toList();
    final negative = recent
        .where((e) => e['action'] != FeedbackAction.done.name)
        .length;
    return (total: recent.length, negative: negative);
  }

  @override
  Future<Map<ReminderKind, RuleState>> loadAll() async {
    await _ensureLoaded();
    return Map.of(_states);
  }

  @override
  Future<void> save(RuleState state) async {
    await _ensureLoaded();
    _states[state.kind] = state;
    await _write(
      _stateKey,
      [
        for (final s in _states.values)
          {
            'kind': s.kind.name,
            'remainingMs': s.remainingMs,
            'savedAt': s.savedAt?.millisecondsSinceEpoch,
            'lastFiredAt': s.lastFiredAt?.millisecondsSinceEpoch,
            'snoozedUntil': s.snoozedUntil?.millisecondsSinceEpoch,
            'snoozeCountToday': s.snoozeCountToday,
            'dayKey': s.dayKey,
            'mutedToday': s.mutedToday,
            'disabled': s.disabled,
          },
      ],
    );
  }

  @override
  Future<void> clear() async {
    _fires = [];
    _feedbacks = [];
    _states.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stateKey);
      await prefs.remove(_fireKey);
      await prefs.remove(_feedbackKey);
    } catch (_) {
      // 内存态已清即可。
    }
    _pushCounts();
  }

  // ----------------------------------------------------------------------

  var _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _fires = _readList(prefs, _fireKey);
      _feedbacks = _readList(prefs, _feedbackKey);
      final rawStates = _readList(prefs, _stateKey);
      for (final e in rawStates) {
        final kind = ReminderKind.values
            .where((k) => k.name == e['kind'])
            .firstOrNull;
        if (kind == null) continue;
        _states[kind] = RuleState(
          kind: kind,
          remainingMs: e['remainingMs'] as int?,
          savedAt: _dt(e['savedAt']),
          lastFiredAt: _dt(e['lastFiredAt']),
          snoozedUntil: _dt(e['snoozedUntil']),
          snoozeCountToday: (e['snoozeCountToday'] as int?) ?? 0,
          dayKey: (e['dayKey'] as String?) ?? '',
          mutedToday: (e['mutedToday'] as bool?) ?? false,
          disabled: (e['disabled'] as bool?) ?? false,
        );
      }
    } catch (error) {
      AppLogger.error('提醒持久化读取降级（内存态）', tag: 'reminder', error: error);
    }
  }

  Future<void> _write(String key, List<Map<String, Object?>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode([for (final r in rows) r]),
      );
    } catch (error) {
      AppLogger.error('提醒持久化写入降级（$key）', tag: 'reminder', error: error);
    }
  }

  static List<Map<String, Object?>> _readList(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map<String, Object?>) e,
      ];
    } catch (_) {
      return [];
    }
  }

  static DateTime? _dt(Object? ms) =>
      ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

  ({int fired, int done}) _countsFor(DateTime day) {
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end =
        DateTime(day.year, day.month, day.day + 1).millisecondsSinceEpoch;
    final fired = _fires.where((e) {
      final at = e['at'] as int;
      return at >= start && at < end;
    }).length;
    final done = _feedbacks.where((e) {
      final at = e['at'] as int;
      return at >= start && at < end && e['action'] == FeedbackAction.done.name;
    }).length;
    return (fired: fired, done: done);
  }

  void _pushCounts() {
    if (!_counts.isClosed) {
      _counts.add(_countsFor(DateTime.now()));
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
