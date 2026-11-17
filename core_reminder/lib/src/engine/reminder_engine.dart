import 'dart:async';

import 'package:base_utils/base_utils.dart';
import 'package:core_model/core_model.dart';
import 'package:core_profile/core_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../clock/reminder_clock.dart';
import '../copy/reminder_copy_provider.dart';
import '../store/local_stores.dart';

/// 单类提醒的运行相位（首页状态矩阵直接映射）。
enum ReminderPhase {
  /// 倒计时中。
  counting,

  /// 静音期（剩余时长冻结，恢复后继续）。
  pausedMute,

  /// 冷却中（剩余已到 0，但距上次触发不足 90 分）。
  cooldown,

  /// 已稍后（到点重新触发）。
  snoozed,

  /// 今天别提醒。
  mutedToday,

  /// 别再提醒这类（持久禁用）。
  disabled,

  /// 设置页开关关闭（喝水/护眼）。
  off,
}

/// 单类快照。
@immutable
class KindSnapshot {
  const KindSnapshot({
    required this.kind,
    required this.phase,
    this.remaining,
    this.nextFireAt,
  });

  final ReminderKind kind;
  final ReminderPhase phase;

  /// 剩余时长（pausedMute 时为冻结值）。
  final Duration? remaining;

  /// 预计触发时刻（静音已按「暂停」积分跳过）。
  final DateTime? nextFireAt;
}

/// 引擎整体状态（首页「下次提醒」与 chips 的唯一数据源）。
@immutable
class EngineState {
  const EngineState({required this.kinds, this.deEscalated = false});

  final Map<ReminderKind, KindSnapshot> kinds;

  /// 自动降频是否生效（近 7 天负面 > 50% 且样本 ≥ 4）。
  final bool deEscalated;

  static const empty = EngineState(kinds: {});
}

/// 触发信号（协调器收到后发通知；单测直接收集断言）。
@immutable
class FireSignal {
  const FireSignal({
    required this.kind,
    required this.adviceId,
    required this.copy,
    required this.at,
  });

  final ReminderKind kind;
  final String adviceId;
  final ReminderCopy copy;
  final DateTime at;
}

/// 三类本地倒计时引擎（技术设计文档 §9.3；纯 Dart、假时钟可测）。
///
/// 评审决策（2026-11-09）：
/// - 静音 = 暂停：静音窗内剩余时长冻结，恢复后继续（防三连发）；
/// - 变更次轮生效：档位/开关/静音变更不打断进行中的倒计时，
///   自下一次触发起按新配置起算。
@LazySingleton()
class ReminderEngine {
  ReminderEngine(
    this._clock,
    this._configRepo,
    this._tags,
    this._persistence,
    this._copyProvider,
  );

  /// 单测注入：非 null 时不启动周期定时器，经 [debugTick] 手动驱动
  /// （不能做构造参数——injectable 会把 Duration 识别为待注入依赖）。
  @visibleForTesting
  Duration? tickPeriodOverride;

  final ReminderClock _clock;
  final ReminderConfigRepository _configRepo;
  final HealthTagStore _tags;
  final ReminderPersistence _persistence;
  final ReminderCopyProvider _copyProvider;

  final _stateController = StreamController<EngineState>.broadcast();
  final _fireController = StreamController<FireSignal>.broadcast();

  Timer? _timer;
  DateTime _lastTick = DateTime(2000);
  var _running = false;
  var _lastEmitKey = '';

  ReminderConfig _config = const ReminderConfig();
  Set<String> _tagsLoaded = {};
  final Map<ReminderKind, RuleState> _rule = {};
  var _deEscalated = false;

  /// 状态流（同展示值去重，避免每秒重建 UI）。
  Stream<EngineState> get states => _stateController.stream;

  /// 触发流（App 存活期到点触发）。
  Stream<FireSignal> get fires => _fireController.stream;

  EngineState get state => EngineState(
        kinds: _snapshotKinds(),
        deEscalated: _deEscalated,
      );

  bool get isRunning => _running;

  bool get deEscalated => _deEscalated;

  ReminderConfig get config => _config;

  /// 当前生效规则（含降频放宽；演示节奏覆盖间隔为 1 分钟）。
  ReminderRule get rule {
    var rule = ReminderRule(
      thresholds: {
        ReminderKind.sedentary: Duration(minutes: _config.sedentaryMinutes),
        ReminderKind.water: const Duration(minutes: 45),
        ReminderKind.eye: const Duration(minutes: 20),
      },
      sedentaryCooldown: const Duration(minutes: 90),
      nightMute: MuteWindow(
        startMinutes: _config.nightMuteStart,
        endMinutes: _config.nightMuteEnd,
      ),
      lunchMute:
          _config.lunchMuteEnabled ? const MuteWindow.clock(12, 30, 13, 30) : null,
    );
    if (_deEscalated) {
      rule = rule.widen(
        thresholdDelta: const Duration(minutes: 15),
        cooldownDelta: const Duration(minutes: 30),
      );
    }
    if (_config.demoRhythm) {
      rule = ReminderRule(
        thresholds: {
          for (final k in ReminderKind.values) k: const Duration(minutes: 1),
        },
        sedentaryCooldown: const Duration(seconds: 90),
        nightMute: null,
        lunchMute: null,
      );
    }
    return rule;
  }

  /// 启动：载配置/标签/状态 → 被杀期重算 → 起 1s tick。
  Future<void> start() async {
    if (_running) return;
    _running = true;
    final now = _clock.now();
    try {
      _config = await _configRepo.load();
    } catch (error) {
      AppLogger.error('提醒配置读取失败，用默认', tag: 'engine', error: error);
    }
    try {
      _tagsLoaded = await _tags.load();
    } catch (_) {
      _tagsLoaded = {};
    }
    await _refreshDeEscalation();
    await _restoreStates(now);
    _lastTick = now;
    _timer = tickPeriodOverride == null
        ? Timer.periodic(const Duration(seconds: 1), (_) => _tick())
        : null;
    _emit(force: true);
    AppLogger.info(
      '引擎启动：久坐 ${rule.thresholds[ReminderKind.sedentary]!.inMinutes} 分'
      '·降频=${_deEscalated ? '开' : '关'}',
      tag: 'engine',
    );
  }

  /// 设置变更（次轮生效）：重读配置并重估相位，不打断进行中的倒计时。
  Future<void> onSettingsChanged() async {
    if (!_running) return;
    try {
      _config = await _configRepo.load();
    } catch (_) {
      return;
    }
    await _refreshDeEscalation();
    // 次轮生效：进行中的倒计时不重置；off/disabled 由快照即时反映，
    // 重开后从既有剩余值继续倒数。
    _emit(force: true);
  }

  /// 活动打断（仅久坐）：倒计时重置为当前阈值。
  ///
  /// 静音中也可重置（用户活动了就别再等着提醒）。
  Future<void> onActivityBurst() async {
    if (!_running) return;
    final kind = ReminderKind.sedentary;
    if (_isOff(kind)) return;
    final s = _rule[kind];
    if (s == null || s.disabled || s.mutedToday) return;
    _rule[kind] = s.copyWith(
      remainingMs: rule.thresholds[kind]!.inMilliseconds,
      savedAt: _clock.now(),
    );
    await _persist(kind);
    _emit(force: true);
  }

  /// 四态反馈（拉伸页 + W3 通知快捷操作复用）。
  ///
  /// 返回 false = 稍后被拒（每类每日最多 1 次）。
  Future<bool> applyFeedback(
    FeedbackAction action,
    ReminderKind kind, {
    String? adviceId,
  }) async {
    final now = _clock.now();
    final dayKey = _dayKeyOf(now);
    var s = _ensureState(kind, now);
    await _persistence.add(kind: kind, action: action, at: now, adviceId: adviceId);
    switch (action) {
      case FeedbackAction.done:
        // 完成不改倒计时（PRD：当日下次提醒阈值不变）。
        break;
      case FeedbackAction.snooze:
        // 每类每日最多 1 次（FR-6）；跨日由 dayKey 判定，回卷在 tick 兜底。
        if (s.dayKey == dayKey && s.snoozeCountToday >= 1) {
          return false;
        }
        s = s.copyWith(
          snoozedUntil: now.add(const Duration(hours: 1)),
          snoozeCountToday: s.dayKey == dayKey ? s.snoozeCountToday + 1 : 1,
          dayKey: dayKey,
        );
      case FeedbackAction.stopToday:
        s = s.copyWith(mutedToday: true, dayKey: dayKey);
      case FeedbackAction.neverAgain:
        s = s.copyWith(disabled: true, dayKey: dayKey);
        final disabled = {..._config.disabledKinds, kind};
        _config = _config.copyWith(disabledKinds: disabled);
        await _configRepo.save(_config);
    }
    _rule[kind] = s.copyWith(savedAt: now);
    await _persist(kind);
    await _refreshDeEscalation();
    _emit(force: true);
    return true;
  }

  /// 生命周期暂停前持久化（协调器在 AppLifecycleState.paused 调用）。
  Future<void> persistAll() async {
    for (final kind in ReminderKind.values) {
      await _persist(kind);
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
    await persistAll();
  }

  // ----------------------------------------------------------------------

  Future<void> _restoreStates(DateTime now) async {
    final loaded = await _persistence.loadAll();
    final dayKey = _dayKeyOf(now);
    for (final kind in ReminderKind.values) {
      var s = loaded[kind] ?? _ensureState(kind, now);
      // 跨日重置每日字段。
      if (s.dayKey != dayKey) {
        s = s.copyWith(
          snoozeCountToday: 0,
          mutedToday: false,
          dayKey: dayKey,
        );
      }
      // 被杀期重算：剩余 -= 期间活跃时长（剔除静音）。
      final savedAt = s.savedAt;
      if (savedAt != null && savedAt.isBefore(now) && !s.disabled && !_isOff(kind)) {
        final active = activeBetween(savedAt, now, rule);
        final base = s.remainingMs ?? rule.thresholds[kind]!.inMilliseconds;
        final recalced = base - active.inMilliseconds;
        if (s.snoozedUntil != null && !now.isBefore(s.snoozedUntil!)) {
          // 被杀期跨越了稍后时刻：按已送达记账并开新一轮。
          await _recordMissedFire(kind, s.snoozedUntil!);
          s = s.copyWith(
            remainingMs: rule.thresholds[kind]!.inMilliseconds,
            clearSnoozedUntil: true,
          );
        } else if (recalced <= 0) {
          final cooldownOk = kind != ReminderKind.sedentary ||
              s.lastFiredAt == null ||
              now.difference(s.lastFiredAt!) >= rule.sedentaryCooldown;
          if (cooldownOk) {
            // 系统闹钟已在估算时刻响过：补记账，开新一轮。
            await _recordMissedFire(kind, now);
            s = s.copyWith(remainingMs: rule.thresholds[kind]!.inMilliseconds);
          } else {
            // 冷却期跨过来：剩余清 0，进入冷却相位。
            s = s.copyWith(remainingMs: 0);
          }
        } else {
          s = s.copyWith(remainingMs: recalced);
        }
      }
      _rule[kind] = s;
    }
  }

  RuleState _ensureState(ReminderKind kind, DateTime now) {
    return _rule[kind] ??= RuleState(
      kind: kind,
      remainingMs: rule.thresholds[kind]!.inMilliseconds,
      savedAt: now,
      dayKey: _dayKeyOf(now),
    );
  }

  Future<void> _refreshDeEscalation() async {
    final stats = await _persistence.stats7d(_clock.now());
    _deEscalated = stats.total >= 4 && stats.negative * 2 > stats.total;
  }

  bool _isOff(ReminderKind kind) {
    if (_config.disabledKinds.contains(kind)) return true;
    return switch (kind) {
      ReminderKind.sedentary => false,
      ReminderKind.water => !_config.waterEnabled,
      ReminderKind.eye => !_config.eyeEnabled,
    };
  }

  bool _inMute(DateTime t) {
    final minuteOfDay = t.hour * 60 + t.minute;
    final r = rule;
    return (r.nightMute?.contains(minuteOfDay) ?? false) ||
        (r.lunchMute?.contains(minuteOfDay) ?? false);
  }

  /// 单测手动驱动一次 tick（fake clock 前进后调用）。
  @visibleForTesting
  void debugTick() => _tick();

  void _tick() {
    final now = _clock.now();
    final dt = now.difference(_lastTick);
    _lastTick = now;
    if (dt <= Duration.zero) {
      // 时钟回拨（NTP 校时等）：倒计时按暂停处理并重置锚点，
      // 待时钟追上后继续——不回补、不误触发。
      return;
    }
    var changed = false;
    for (final kind in ReminderKind.values) {
      var s = _rule[kind];
      if (s == null) {
        s = _ensureState(kind, now);
        changed = true;
      }
      final dayKey = _dayKeyOf(now);
      if (s.dayKey != dayKey) {
        s = s.copyWith(snoozeCountToday: 0, mutedToday: false, dayKey: dayKey);
        changed = true;
      }
      if (_isOff(kind) || s.mutedToday) {
        // 关闭/禁用：停摆；今天别提醒：冻结（次日恢复继续倒数）。
        _rule[kind] = s;
        continue;
      }
      // 稍后到点 → 直接重新触发。
      final snoozedUntil = s.snoozedUntil;
      if (snoozedUntil != null && !now.isBefore(snoozedUntil)) {
        _fire(kind, now);
        _rule[kind] = _rule[kind]!.copyWith(clearSnoozedUntil: true);
        changed = true;
        continue;
      }
      if (snoozedUntil != null) {
        _rule[kind] = s;
        continue; // 稍等期，倒计时冻结。
      }
      // 静音=暂停完全由 activeBetween 积分表达（含进入/离开静音的边界步），
      // 不做整段早退——否则边界步的活跃前缀会被丢掉。
      final activeDt = activeBetween(
        now.subtract(dt),
        now,
        rule,
      );
      final remainingMs =
          (s.remainingMs ?? rule.thresholds[kind]!.inMilliseconds) -
              activeDt.inMilliseconds;
      if (remainingMs <= 0) {
        // 静音期内不触发：剩余停在 0，静音结束的第一个 tick 补发。
        if (_inMute(now)) {
          _rule[kind] = s.copyWith(remainingMs: 0, savedAt: now);
          continue;
        }
        final lastFired = s.lastFiredAt;
        final cooldownBlock = kind == ReminderKind.sedentary &&
            lastFired != null &&
            now.difference(lastFired) < rule.sedentaryCooldown;
        if (!cooldownBlock) {
          _fire(kind, now);
          changed = true;
          continue;
        }
        _rule[kind] = s.copyWith(remainingMs: 0, savedAt: now);
        changed = true;
        continue;
      }
      _rule[kind] = s.copyWith(remainingMs: remainingMs, savedAt: now);
    }
    _emit();
    if (changed) {
      // 触发即持久化（崩溃恢复锚点）；另由协调器在 paused 时全量落盘。
      unawaited(_persistDirty());
    }
  }

  void _fire(ReminderKind kind, DateTime now) {
    final adviceId = '${kind.name}-${now.millisecondsSinceEpoch}';
    final copy = _copyProvider.copyFor(kind, _tagsLoaded);
    _fireController.add(
      FireSignal(kind: kind, adviceId: adviceId, copy: copy, at: now),
    );
    unawaited(
      _persistence.appendFire(
        kind: kind,
        firedAt: now,
        adviceId: adviceId,
        copyText: copy.body,
      ),
    );
    final r = rule;
    _rule[kind] = (_rule[kind] ?? _ensureState(kind, now))
        .copyWith(
          remainingMs: r.thresholds[kind]!.inMilliseconds,
          lastFiredAt: now,
          savedAt: now,
        );
    unawaited(_persist(kind));
    AppLogger.info('触发 ${kind.name} → ${copy.body}', tag: 'engine');
  }

  Future<void> _recordMissedFire(ReminderKind kind, DateTime at) async {
    final adviceId = '${kind.name}-missed-${at.millisecondsSinceEpoch}';
    final copy = _copyProvider.copyFor(kind, _tagsLoaded);
    await _persistence.appendFire(
      kind: kind,
      firedAt: at,
      adviceId: adviceId,
      copyText: copy.body,
    );
    _rule[kind] = (_rule[kind] ?? _ensureState(kind, at))
        .copyWith(lastFiredAt: at, savedAt: _clock.now());
  }

  Future<void> _persistDirty() async {
    for (final kind in ReminderKind.values) {
      await _persist(kind);
    }
  }

  Future<void> _persist(ReminderKind kind) async {
    final s = _rule[kind];
    if (s == null) return;
    await _persistence.save(s);
  }

  Map<ReminderKind, KindSnapshot> _snapshotKinds() {
    final now = _clock.now();
    final out = <ReminderKind, KindSnapshot>{};
    for (final kind in ReminderKind.values) {
      final s = _rule[kind];
      if (s == null) continue;
      if (_isOff(kind)) {
        out[kind] = KindSnapshot(
          kind: kind,
          phase: _config.disabledKinds.contains(kind)
              ? ReminderPhase.disabled
              : ReminderPhase.off,
        );
        continue;
      }
      if (s.mutedToday) {
        out[kind] = KindSnapshot(kind: kind, phase: ReminderPhase.mutedToday);
        continue;
      }
      if (s.snoozedUntil != null) {
        out[kind] = KindSnapshot(
          kind: kind,
          phase: ReminderPhase.snoozed,
          nextFireAt: s.snoozedUntil,
        );
        continue;
      }
      final remaining = Duration(
        milliseconds: s.remainingMs ?? rule.thresholds[kind]!.inMilliseconds,
      );
      // 下次触发 = max(倒计时剩余, 久坐冷却剩余)，再按静音窗跳过投影。
      var effective = remaining;
      var inCooldown = false;
      final lastFired = s.lastFiredAt;
      if (kind == ReminderKind.sedentary && lastFired != null) {
        final untilCooldown = lastFired.add(rule.sedentaryCooldown).difference(now);
        if (untilCooldown > effective) {
          effective = untilCooldown;
          inCooldown = remaining <= Duration.zero;
        }
      }
      var phase = ReminderPhase.counting;
      if (_inMute(now)) {
        phase = ReminderPhase.pausedMute;
      } else if (inCooldown) {
        phase = ReminderPhase.cooldown;
      }
      out[kind] = KindSnapshot(
        kind: kind,
        phase: phase,
        remaining: remaining,
        nextFireAt: projectNextFireAt(now, effective, rule),
      );
    }
    return out;
  }

  /// 展示级去重发射（相位 + 下次时刻到分钟 + 剩余到分钟）。
  void _emit({bool force = false}) {
    final s = state;
    final key =
        '${s.kinds.entries.map((e) => '${e.key.name}:${e.value.phase.name}:${e.value.nextFireAt?.millisecondsSinceEpoch ?? 0}:${e.value.remaining?.inMinutes ?? -1}').join('|')}|de=${s.deEscalated}';
    if (!force && key == _lastEmitKey) return;
    _lastEmitKey = key;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  static String _dayKeyOf(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  // ---- 纯函数（单测直接覆盖） -------------------------------------------

  /// [from, to) 期间的活跃时长（剔除静音窗；静音 = 暂停语义的积分）。
  @visibleForTesting
  static Duration activeBetween(DateTime from, DateTime to, ReminderRule rule) {
    if (!to.isAfter(from)) return Duration.zero;
    final mutes = [rule.nightMute, rule.lunchMute].whereType<MuteWindow>().toList();
    if (mutes.isEmpty) return to.difference(from);
    var muteMs = 0;
    // 从前一天起迭代：跨零点窗口的「尾巴段」落在窗口起点次日清晨，
    // 早间区间需回看前一晚的窗口才能命中（如 06:00–08:00 的前 1 小时）。
    for (var day = DateTime(from.year, from.month, from.day)
            .subtract(const Duration(days: 1));
        !day.isAfter(to);
        day = day.add(const Duration(days: 1))) {
      for (final w in mutes) {
        muteMs += _overlapMs(from, to, day.add(Duration(minutes: w.startMinutes)),
            day.add(Duration(minutes: w.endMinutes)));
        if (w.wrapsOvernight) {
          // 跨零点窗口 = 当日 [start,24:00) + 次日 [00:00,end)。
          muteMs += _overlapMs(from, to, day.add(Duration(minutes: w.startMinutes)),
              day.add(const Duration(days: 1)));
          muteMs += _overlapMs(
              from, to, day.add(const Duration(days: 1)), day.add(Duration(days: 1, minutes: w.endMinutes)));
          muteMs -= _overlapMs(from, to, day.add(Duration(minutes: w.startMinutes)),
              day.add(Duration(minutes: w.endMinutes)));
        }
      }
    }
    final active = to.difference(from).inMilliseconds - muteMs;
    return Duration(milliseconds: active.clamp(0, to.difference(from).inMilliseconds));
  }

  static int _overlapMs(DateTime a, DateTime b, DateTime s, DateTime e) {
    final start = a.isAfter(s) ? a : s;
    final end = b.isBefore(e) ? b : e;
    return end.isAfter(start) ? end.difference(start).inMilliseconds : 0;
  }

  /// 由「剩余时长」投影下次触发时刻：逐段跳过静音窗（暂停语义）。
  @visibleForTesting
  static DateTime projectNextFireAt(
    DateTime now,
    Duration remaining,
    ReminderRule rule,
  ) {
    var cursor = now;
    var left = remaining;
    final mutes = [rule.nightMute, rule.lunchMute].whereType<MuteWindow>().toList();
    if (mutes.isEmpty) return cursor.add(left);
    // 最多迭代若干轮防死循环（静音窗覆盖 < 24h 恒成立）。
    for (var i = 0; i < 64 && left > Duration.zero; i++) {
      // 若此刻在静音内 → 跳到窗口结束。
      final inWin = _windowEnd(cursor, mutes);
      if (inWin != null) {
        cursor = inWin;
        continue;
      }
      // 到下一个窗口起点的距离。
      DateTime? nextStart;
      for (final w in mutes) {
        final cand = _nextStart(cursor, w);
        if (cand != null && (nextStart == null || cand.isBefore(nextStart))) {
          nextStart = cand;
        }
      }
      if (nextStart == null) return cursor.add(left);
      final step = nextStart.difference(cursor);
      if (step >= left) return cursor.add(left);
      left -= step;
      cursor = nextStart;
    }
    return cursor.add(left);
  }

  static DateTime? _windowEnd(DateTime t, List<MuteWindow> mutes) {
    final minuteOfDay = t.hour * 60 + t.minute;
    DateTime? earliest;
    for (final w in mutes) {
      if (!w.contains(minuteOfDay)) continue;
      final day = DateTime(t.year, t.month, t.day);
      final end = w.wrapsOvernight && minuteOfDay >= w.startMinutes
          ? day.add(Duration(days: 1, minutes: w.endMinutes))
          : day.add(Duration(minutes: w.endMinutes));
      if (end.isAfter(t) && (earliest == null || end.isBefore(earliest))) {
        earliest = end;
      }
    }
    return earliest;
  }

  static DateTime? _nextStart(DateTime t, MuteWindow w) {
    final day = DateTime(t.year, t.month, t.day);
    final minuteOfDay = t.hour * 60 + t.minute;
    if (minuteOfDay < w.startMinutes) {
      return day.add(Duration(minutes: w.startMinutes));
    }
    return day.add(Duration(days: 1, minutes: w.startMinutes));
  }
}
