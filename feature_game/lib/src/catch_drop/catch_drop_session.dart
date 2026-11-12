import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// 接住掉落物参数(《慢植物小游戏设计方案》§6.1 v0.5,集中调优)。
///
/// 判定只看倾斜方向(死区),不要求角度精度——真机实测结论:
/// 颈椎侧屈时视线随头偏离屏幕,角度校准类判定物理上不可行。
@immutable
class CatchDropConfig {
  const CatchDropConfig({
    this.sessionDuration = const Duration(seconds: 40),
    this.targetScore = 40,
    this.deadZoneDeg = 7,
    this.maxTiltDeg = 55,
    this.containerHalfWidthRatio = 0.075,
    this.containerSpeedCapPerSec = 0.45,
    this.normalDropInterval = const [Duration(milliseconds: 2500), Duration(milliseconds: 4500)],
    this.normalDropScore = 5,
    this.normalDropZone = const [0.15, 0.85],
    this.goldenDropCount = 2,
    this.goldenTiltDeg = 20,
    this.goldenHoldDuration = const Duration(milliseconds: 2500),
    this.goldenDropScore = 25,
    this.goldenFirstAt = const Duration(seconds: 10),
    this.goldenInterval = const Duration(seconds: 15),
    this.sunshineBase = 10,
    this.sunshinePerScore = 0.1,
    this.sunshineCap = 30,
    this.comboThreshold = 3,
    this.comboMultiplier = 1.2,
    this.tickInterval = const Duration(milliseconds: 50),
  });

  /// 单局硬限时(§6.1)。
  final Duration sessionDuration;

  /// 目标分:达成后可点「提前完成」(§6.1)。
  final int targetScore;

  /// 死区(±度):静止区域,容器不动。
  final double deadZoneDeg;

  /// 头部角对应的最大倾斜范围(线性映射到半屏宽)。
  final double maxTiltDeg;

  /// 容器半宽(占屏幕宽度比例,碰撞判定用)。
  final double containerHalfWidthRatio;

  /// 容器移动速度上限(屏宽/秒):头甩得再快容器也不会更快
  /// ——「速度不加分」红线的物理化(§6.1 验收)。
  final double containerSpeedCapPerSec;

  /// 普通掉落物间隔区间(随机)。
  final List<Duration> normalDropInterval;

  /// 普通掉落物分值。
  final int normalDropScore;

  /// 普通掉落物生成的横向区域(屏幕宽度比例,中段)。
  final List<double> normalDropZone;

  /// 金阳光单局数量。
  final int goldenDropCount;

  /// 金阳光所需的深倾角(≥该角度并保持充能)。
  final double goldenTiltDeg;

  /// 金阳光充能时长(保持深倾),中断进度保留。
  final Duration goldenHoldDuration;

  /// 金阳光分值。
  final int goldenDropScore;

  /// 首个金阳光出现时刻。
  final Duration goldenFirstAt;

  /// 金阳光间隔。
  final Duration goldenInterval;

  /// 阳光换算:基础 + 分数 × 系数,封顶。
  final int sunshineBase;
  final double sunshinePerScore;
  final int sunshineCap;

  /// 连击阈值(达到即享受倍率)。
  final int comboThreshold;

  /// 连击倍率(≥阈值时普通掉落分数乘此系数)。
  final double comboMultiplier;

  /// 推进节拍。
  final Duration tickInterval;

  static const CatchDropConfig standard = CatchDropConfig();

  /// 分数 → 阳光(§6.1:10 + 分数÷10,封顶 30)。
  int sunshineFor(int score) {
    final raw = sunshineBase + (score * sunshinePerScore);
    return raw.clamp(0, sunshineCap).round();
  }
}

/// 掉落物类型。
enum DropKind { normal, golden }

/// 单个掉落物。
@immutable
class Drop {
  const Drop({
    required this.id,
    required this.kind,
    required this.x,
    required this.spawnedAt,
    required this.fallDuration,
  });

  final int id;
  final DropKind kind;

  /// 横向位置(0~1,屏幕宽度比例)。
  final double x;

  final Duration spawnedAt;

  /// 从顶部落到底部容器高度所需时长。
  final Duration fallDuration;

  /// 该掉落物在 [elapsed] 时刻的纵向进度(0=顶部,1=落底)。
  double progressAt(Duration elapsed) {
    final t = (elapsed - spawnedAt).inMilliseconds / fallDuration.inMilliseconds;
    return t.clamp(0.0, 1.0);
  }

  /// 是否已落底。
  bool landedAt(Duration elapsed) =>
      elapsed - spawnedAt >= fallDuration;

  Drop copyWith({double? x}) => Drop(
        id: id,
        kind: kind,
        x: x ?? this.x,
        spawnedAt: spawnedAt,
        fallDuration: fallDuration,
      );
}

/// 局内事件(UI 每次 tick 后 drain,驱动动效与音效)。
@immutable
sealed class CatchEvent {
  const CatchEvent();
}

/// 接住掉落物。
class DropCaught extends CatchEvent {
  const DropCaught({
    required this.kind,
    required this.gained,
    required this.combo,
    required this.x,
  });

  final DropKind kind;
  final int gained;

  /// 接住后的连击数。
  final int combo;

  /// 掉落物横向位置(0~1,飘字/粒子定位用)。
  final double x;
}

/// 漏接(不扣分,仅视觉/音效提示 + 连击清零)。
class DropMissed extends CatchEvent {
  const DropMissed({required this.x});

  final double x;
}

/// 连击中断(漏接且此前有连击)。
class ComboBroken extends CatchEvent {
  const ComboBroken({required this.previousCombo});

  final int previousCombo;
}

/// 局内快照(渲染消费)。
@immutable
class CatchDropSnapshot {
  const CatchDropSnapshot({
    required this.phase,
    required this.containerX,
    required this.elapsed,
    required this.score,
    required this.caughtNormal,
    required this.caughtGolden,
    required this.activeDrops,
    required this.goldenChargeProgress,
    required this.goldenCharging,
    required this.canFinishEarly,
    this.combo = 0,
    this.goldenPresent = false,
    this.goldenTiltOk = false,
    this.goldenAligned = false,
    this.goldenSide = 0,
  });

  final CatchDropPhase phase;

  /// 容器中心横向位置(0~1)。
  final double containerX;

  final Duration elapsed;
  final int score;
  final int caughtNormal;
  final int caughtGolden;

  /// 未落底的掉落物(渲染用)。
  final List<Drop> activeDrops;

  /// 金阳光充能进度 0~1(暂无金阳光在场则为 0)。
  final double goldenChargeProgress;

  /// 当前是否正在充能(头部深倾中)。
  final bool goldenCharging;

  /// 达目标分可提前完成(§6.1)。
  final bool canFinishEarly;

  /// 当前连击数(连续接住)。
  final int combo;

  // ---- 金阳光引导(§6.1:让用户知道「要做什么」) ----
  /// 场上是否有金阳光。
  final bool goldenPresent;

  /// 倾角是否达标(≥ goldenTiltDeg)。
  final bool goldenTiltOk;

  /// 篮子是否对准金阳光。
  final bool goldenAligned;

  /// 金阳光在屏幕哪一侧:1 右 / -1 左 / 0 中。
  final int goldenSide;
}

/// 会话阶段。
enum CatchDropPhase {
  /// 引导中(计时、掉落、计分)。
  playing,

  /// 达成目标分后用户点了提前完成,或时间到。
  finished,
}

/// 接住掉落物会话(纯逻辑,外部时钟驱动,可任意回放)。
///
/// 输入:每拍 roll 相对角(度)。映射:死区 ±[deadZoneDeg] 内不动,
/// 之外按 [maxTiltDeg] 线性映射到 0~1 屏宽,目标位置经**弹簧阻尼**追踪
/// (有跟随延迟与轻微过冲,手感非硬连接),速度仍受上限约束。
/// 判定:掉落物落底时其 x 落在容器 ±[containerHalfWidthRatio] 内即接住。
/// 连击:连续接住 ≥[comboThreshold] 时分数乘 [comboMultiplier];
/// 漏接清零(漏接本身不扣分)。
/// 金阳光:需头部 ≥[goldenTiltDeg] 并持续 [goldenHoldDuration] 充能,
/// 中断进度保留(无惩罚,§6.1)。
class CatchDropSession {
  CatchDropSession({CatchDropConfig? config, int? seed})
      : config = config ?? CatchDropConfig.standard,
        _rng = math.Random(seed ?? 20261112);

  final CatchDropConfig config;
  final math.Random _rng;

  final List<Drop> _drops = [];
  final List<Drop> _landed = [];

  Duration _elapsed = Duration.zero;
  Duration _nextNormalAt = const Duration(milliseconds: 800);
  Duration? _nextGoldenAt;
  int _goldenSpawned = 0;
  int _nextId = 0;

  double _containerX = 0.5;
  double _rawContainerX = 0.5;

  /// 容器横向速度(屏宽/秒),临界阻尼弹簧的状态。
  double _containerV = 0;

  /// EMA 低通后的目标位置:抑制摄像头逐帧随机噪声。
  double _filteredTarget = 0.5;

  /// 上一拍头姿(供快照输出金阳光引导状态)。
  double _lastHeadRoll = 0;

  int _score = 0;
  int _caughtNormal = 0;
  int _caughtGolden = 0;
  int _combo = 0;

  /// 待消费的事件(UI 层 drain 后做动效/音效)。
  final List<CatchEvent> _events = [];

  // 金阳光充能状态
  DropKind? _chargeKind;
  Duration _chargeElapsed = Duration.zero;
  int? _chargingDropId;

  CatchDropPhase _phase = CatchDropPhase.playing;

  double get containerX => _containerX;

  /// 取出并清空事件(供 UI 消费)。
  List<CatchEvent> drainEvents() {
    final out = List<CatchEvent>.from(_events);
    _events.clear();
    return out;
  }

  CatchDropSnapshot get snapshot {
    final golden = _currentGolden();
    final goldenTiltOk =
        golden != null && _lastHeadRoll.abs() >= config.goldenTiltDeg;
    final goldenAligned = golden != null &&
        (golden.x - _containerX).abs() <=
            config.containerHalfWidthRatio * 1.6;
    return CatchDropSnapshot(
      phase: _phase,
      containerX: _containerX,
      elapsed: _elapsed,
      score: _score,
      caughtNormal: _caughtNormal,
      caughtGolden: _caughtGolden,
      activeDrops: List.unmodifiable(_drops),
      goldenChargeProgress: golden == null
          ? 0
          : (_chargeElapsed.inMilliseconds /
                  config.goldenHoldDuration.inMilliseconds)
              .clamp(0.0, 1.0),
      goldenCharging: golden != null && _chargeKind == DropKind.golden,
      canFinishEarly: _score >= config.targetScore,
      combo: _combo,
      goldenPresent: golden != null,
      goldenTiltOk: goldenTiltOk,
      goldenAligned: goldenAligned,
      goldenSide: golden == null ? 0 : (golden.x < 0.5 ? -1 : 1),
    );
  }

  Drop? _currentGolden() {
    final golden = _drops.where((d) => d.kind == DropKind.golden);
    return golden.isEmpty ? null : golden.first;
  }

  /// 提前完成(仅当达目标分;§6.1)。
  bool finishEarly() {
    if (_score < config.targetScore) {
      return false;
    }
    _phase = CatchDropPhase.finished;
    _drops.clear();
    return true;
  }

  /// 推进一拍。[headRoll] 为头部相对侧屈角(度)。
  CatchDropSnapshot advance({
    required Duration dt,
    required double headRoll,
  }) {
    if (_phase == CatchDropPhase.finished) {
      return snapshot;
    }
    _elapsed += dt;
    if (_elapsed >= config.sessionDuration) {
      _phase = CatchDropPhase.finished;
      _drops.clear();
      return snapshot;
    }

    _lastHeadRoll = headRoll;
    _moveContainer(dt, headRoll);
    _spawnDrops();
    _resolveLandings();
    _updateGoldenCharge(dt, headRoll);

    return snapshot;
  }

  /// **位置控制 + 三级滤波**(v0.6):治抖不牺牲停位精度。
  ///
  /// 为什么不用速度积分:接物玩法需要「精确停位」(金阳光要保持在容差内
  /// 2.5 秒),速度模型下容器会一路滑到边界,反而更难操作。
  ///
  /// 三级滤波(摄像头中值 → 目标 EMA → 临界阻尼弹簧):
  /// 1. 摄像头层:ML Kit 欧拉角 5 帧中值(见 CameraPoseSource);
  /// 2. 目标层:EMA,时间常数 250ms——把逐帧随机噪声压到不可见,
  ///    代价是约 0.25s 跟随延迟(远小于人可感知的「不跟手」阈值);
  /// 3. 运动层:临界阻尼弹簧(c=2√k),无过冲振荡,只有平滑趋近。
  /// 速度仍受 [CatchDropConfig.containerSpeedCapPerSec] 硬约束。
  void _moveContainer(Duration dt, double headRoll) {
    final abs = headRoll.abs();
    double target;
    if (abs <= config.deadZoneDeg) {
      target = _rawContainerX; // 死区内保持
    } else {
      final sign = headRoll.isNegative ? -1.0 : 1.0;
      final norm = ((abs - config.deadZoneDeg) /
              (config.maxTiltDeg - config.deadZoneDeg))
          .clamp(0.0, 1.0);
      target = 0.5 + sign * norm * 0.5;
      _rawContainerX = target;
    }

    final dtSec = dt.inMicroseconds / 1000000.0;

    // 2. 目标 EMA(120ms):抑制残留噪声,同时保持跟手
    //    (中值 3 帧 ~40ms + EMA 120ms ≈ 总延迟 160ms,低于可感知阈值)。
    final alpha = 1 - math.exp(-dtSec / 0.12);
    _filteredTarget += alpha * (target - _filteredTarget);

    // 3. 临界阻尼弹簧:k=80, c=2√k —— 无过冲。
    const stiffness = 80.0;
    final damping = 2 * math.sqrt(stiffness);
    final accel =
        stiffness * (_filteredTarget - _containerX) - damping * _containerV;
    _containerV += accel * dtSec;
    final maxV = config.containerSpeedCapPerSec;
    _containerV = _containerV.clamp(-maxV, maxV);

    // 静止吸附:彻底消除残余微动。
    if ((_filteredTarget - _containerX).abs() < 0.004 &&
        _containerV.abs() < 0.03) {
      _containerX = _filteredTarget;
      _containerV = 0;
      return;
    }

    final next = (_containerX + _containerV * dtSec).clamp(0.0, 1.0);
    if (next == 0.0 || next == 1.0) {
      _containerV = 0;
    }
    _containerX = next;
  }

  void _spawnDrops() {
    // 普通掉落物
    if (_elapsed >= _nextNormalAt) {
      _drops.add(Drop(
        id: _nextId++,
        kind: DropKind.normal,
        x: _randomIn(config.normalDropZone),
        spawnedAt: _elapsed,
        fallDuration: const Duration(milliseconds: 5200),
      ));
      _scheduleNextNormal();
    }
    // 金阳光(数量与间隔受控;首个在 goldenFirstAt 之后)
    final goldenAt = _nextGoldenAt ??= config.goldenFirstAt;
    if (_goldenSpawned < config.goldenDropCount && _elapsed >= goldenAt) {
      const sides = [0.18, 0.82];
      _drops.add(Drop(
        id: _nextId++,
        kind: DropKind.golden,
        x: sides[_goldenSpawned % 2],
        spawnedAt: _elapsed,
        fallDuration: const Duration(seconds: 7), // 悬停时间长,够充能
      ));
      _goldenSpawned++;
      _nextGoldenAt = _elapsed + config.goldenInterval;
    }
  }

  void _scheduleNextNormal() {
    final lo = config.normalDropInterval.first.inMilliseconds;
    final hi = config.normalDropInterval.last.inMilliseconds;
    _nextNormalAt = _elapsed +
        Duration(milliseconds: lo + _rng.nextInt(hi - lo + 1));
  }

  double _randomIn(List<double> range) {
    final lo = range.first;
    final hi = range.last;
    return lo + _rng.nextDouble() * (hi - lo);
  }

  /// 落底判定:普通掉落物横向距离 ≤ 容器半宽即接住(计入连击);
  /// 漏接清零连击但不扣分;
  /// 金阳光由充能判定给分,落底未充满则静默失效(不扣分,§6.1)。
  void _resolveLandings() {
    final half = config.containerHalfWidthRatio;
    final still = <Drop>[];
    for (final drop in _drops) {
      if (!drop.landedAt(_elapsed)) {
        still.add(drop);
        continue;
      }
      _landed.add(drop);
      if (drop.kind == DropKind.normal) {
        final caught = (drop.x - _containerX).abs() <= half;
        if (caught) {
          _combo++;
          final gain = _combo >= config.comboThreshold
              ? (config.normalDropScore * config.comboMultiplier).round()
              : config.normalDropScore;
          _score += gain;
          _caughtNormal++;
          _events.add(DropCaught(
            kind: DropKind.normal,
            gained: gain,
            combo: _combo,
            x: drop.x,
          ));
        } else {
          if (_combo > 0) {
            _events.add(ComboBroken(previousCombo: _combo));
          }
          _combo = 0;
          _events.add(DropMissed(x: drop.x));
        }
      } else if (drop.kind == DropKind.golden) {
        // 未完成充能就落底:清空充能状态,不计分不惩罚。
        if (_chargingDropId == drop.id) {
          _chargingDropId = null;
          _chargeElapsed = Duration.zero;
          _chargeKind = null;
        }
      }
    }
    _drops
      ..clear()
      ..addAll(still);
  }

  /// 金阳光充能:头部 ≥ 阈值且容器对齐 → 累计;中断保留进度。
  void _updateGoldenCharge(Duration dt, double headRoll) {
    final golden = _currentGolden();
    if (golden == null) {
      _chargeKind = null;
      _chargingDropId = null;
      return;
    }
    final tiltOk = headRoll.abs() >= config.goldenTiltDeg;
    final aligned = (golden.x - _containerX).abs() <=
        config.containerHalfWidthRatio * 1.6;
    if (tiltOk && aligned) {
      _chargeKind = DropKind.golden;
      _chargingDropId = golden.id;
      _chargeElapsed += dt;
      if (_chargeElapsed >= config.goldenHoldDuration) {
        _score += config.goldenDropScore;
        _caughtGolden++;
        _drops.removeWhere((d) => d.id == golden.id);
        _chargeElapsed = Duration.zero;
        _chargeKind = null;
        _chargingDropId = null;
        _events.add(DropCaught(
          kind: DropKind.golden,
          gained: config.goldenDropScore,
          combo: _combo,
          x: golden.x,
        ));
      }
    } else {
      // 中断:进度保留(§6.1 无惩罚),仅状态不再「充能中」。
      _chargeKind = null;
    }
  }

  // ---- 只读(测试与渲染) ----

  Duration get elapsed => _elapsed;
  int get score => _score;
  int get caughtNormal => _caughtNormal;
  int get caughtGolden => _caughtGolden;
  CatchDropPhase get phase => _phase;
  List<Drop> get activeDrops => List.unmodifiable(_drops);
  List<Drop> get landedDrops => List.unmodifiable(_landed);
}
