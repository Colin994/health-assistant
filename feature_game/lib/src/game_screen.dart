import 'package:core_database/core_database.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catch_drop/catch_drop_board.dart';
import 'catch_drop/catch_drop_session.dart';
import 'game_intent.dart';
import 'game_state.dart';
import 'garden_scene.dart';
import 'star_gazing/star_gazing_board.dart';
import 'star_gazing/star_gazing_session.dart';

/// 游戏页视图(v0.5:花园 + 接阳光 + 看星星 + 结算)。
///
/// 纯视图:只渲染 [state] 并回调 [onIntent],不持有逻辑。
class GameScreen extends StatelessWidget {
  const GameScreen({required this.state, required this.onIntent, super.key});

  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final inSession =
        state.phase == GamePhase.playing ||
        state.phase == GamePhase.paused ||
        state.phase == GamePhase.result;
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          switch (state.phase) {
            GamePhase.playing ||
            GamePhase.paused ||
            GamePhase.result => _PlayArea(state: state, onIntent: onIntent),
            _ => _GardenView(state: state, onIntent: onIntent),
          },
          // 沉浸式:不占版面,悬浮圆形按钮替代 AppBar(游戏风)。
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GameRoundButton(
                  icon: Icons.close_rounded,
                  semanticLabel: '退出',
                  onTap: () => onIntent(const ExitPressed()),
                  onDark: inSession,
                ),
              ),
            ),
          ),
          if (state.phase == GamePhase.result)
            _ResultOverlay(state: state, onIntent: onIntent),
        ],
      ),
    );
  }
}

/// 游戏风圆形按钮:半透明底 + 白/深 icon + 细描边 + 按下缩放。
///
/// 用于沉浸式页面(替代 AppBar 的返回/退出)。
class GameRoundButton extends StatefulWidget {
  const GameRoundButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
    this.onDark = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  /// 深色背景上(onDark=true 用白字/浅底,浅色背景反之)。
  final bool onDark;

  @override
  State<GameRoundButton> createState() => _GameRoundButtonState();
}

class _GameRoundButtonState extends State<GameRoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.onDark
                  ? Colors.black.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: radius,
              border: Border.all(
                color: widget.onDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : context.tokens.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: AppShadows.cardSubtle,
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: widget.onDark ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

const _stageNames = ['发芽', '幼苗', '成长', '花苞', '盛开', '待收'];

// ============ 花园 ============

class _GardenView extends StatelessWidget {
  const _GardenView({required this.state, required this.onIntent});

  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 时段与天空区文字色(呈现层视觉决策,夜景转白保对比度)。
    final timeOfDay = GardenTimeOfDay.fromClock(DateTime.now());
    final skyText = GardenScene.skyTextPrimary(timeOfDay);
    final skyTextSecondary = GardenScene.skyTextSecondary(timeOfDay);
    final busy =
        state.phase == GamePhase.countdown ||
        state.phase == GamePhase.calibrating;
    final heading = switch (state.phase) {
      GamePhase.countdown => '${state.countdownSeconds}',
      GamePhase.calibrating => '校准中',
      GamePhase.error => '出了点问题',
      _ => '我的花园',
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        // 程序化矢量场景背景(同构图,随本地时钟四时段变化)。
        GardenScene(timeOfDay: timeOfDay),
        _DecorationsLayer(owned: state.decorations),
        SafeArea(
          child: busy || state.phase == GamePhase.error
              ? Center(
                  child: _BusyCard(state: state, heading: heading),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 68, 4),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '☀️ ${state.todaySunshineTotal}'
                                '  ✨ ${state.stardustTotal}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: skyText,
                                ),
                              ),
                              // 押花册入口(可点查看已收集物种)。
                              TextButton(
                                onPressed: () => _openHerbarium(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '📖 ${state.harvestedCount}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: skyText,
                                  ),
                                ),
                              ),
                              Text(
                                '今日可练 ${state.quotaRemaining}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: skyText,
                                ),
                              ),
                            ],
                          ),
                          if (state.statusText.isNotEmpty)
                            Text(
                              state.statusText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: skyTextSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: state.plots.length,
                        itemBuilder: (context, index) => _PlotTile(
                          plot: state.plots[index],
                          onTap: () => _onPlotTapped(context, index),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilledButton(
                            onPressed: () => _startWithConsent(
                              context,
                              const StartCatchDropPressed(),
                            ),
                            child: const Text('☀️ 接阳光'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _startWithConsent(
                              context,
                              const StartStarGazingPressed(),
                            ),
                            child: Text(
                              state.starGazeUnlocked ? '🌙 看星星' : '🔒 看星星',
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openShop(context),
                            icon: const Icon(Icons.storefront_outlined),
                            tooltip: '商店',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// 开局前置:首次使用相机前做应用内预说明(合规)。
  ///
  /// 系统权限弹窗措辞有限,先在本应用内讲清「画面仅本机处理、不保存不上传」,
  /// 用户同意后才触发系统相机授权(VM 内 start → camera 插件请求)。
  static const String _consentKey = 'l4_camera_consent_shown';

  Future<void> _startWithConsent(
    BuildContext context,
    GameIntent intent,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_consentKey) ?? false) {
      onIntent(intent);
      return;
    }
    if (!context.mounted) {
      return;
    }
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.videocam_outlined),
        title: const Text('需要用前置摄像头'),
        content: const Text(
          '练习时用前置摄像头识别头部动作,把颈部动作变成游戏操作。\n\n'
          '画面只在手机本机实时分析,不保存、不上传,也不做人脸识别——'
          '只读取点头 / 侧倾的角度数值。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('先不玩'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('同意并开始'),
          ),
        ],
      ),
    );
    if (agreed != true) {
      return;
    }
    await prefs.setBool(_consentKey, true);
    onIntent(intent);
  }

  void _onPlotTapped(BuildContext context, int index) {
    final plot = state.plots[index];
    if (plot == null) {
      _openSeedSheet(context, index);
    } else {
      _openPlantSheet(context, index, plot);
    }
  }

  void _openSeedSheet(BuildContext context, int plotIndex) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) =>
          _SeedSheet(plotIndex: plotIndex, state: state, onIntent: onIntent),
    );
  }

  void _openPlantSheet(BuildContext context, int plotIndex, PlotState plot) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _PlantSheet(
        plotIndex: plotIndex,
        plot: plot,
        state: state,
        onIntent: onIntent,
      ),
    );
  }

  void _openShop(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _ShopSheet(state: state, onIntent: onIntent),
    );
  }

  /// 押花册:已收获物种的收集视图。
  void _openHerbarium(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _HerbariumSheet(counts: state.harvestCounts),
    );
  }
}

/// 押花册弹层:网格显示已收集物种与数量。
class _HerbariumSheet extends StatelessWidget {
  const _HerbariumSheet({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = seedCatalog
        .where((s) => (counts[s.id] ?? 0) > 0)
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('📖 押花册', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(
                  '共 ${counts.values.fold(0, (a, b) => a + b)} 朵',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.tokens.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    '还没有收获过花。\n种下一株,养到盛开后收获吧。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final seed in entries)
                    SizedBox(
                      width: 84,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/game/plant_${seed.id}_stage4.png',
                            height: 72,
                          ),
                          Text(
                            seed.name,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '×${counts[seed.id]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.tokens.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BusyCard extends StatelessWidget {
  const _BusyCard({required this.state, required this.heading});

  final GameState state;
  final String heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(heading, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              state.phase == GamePhase.countdown ? '保持自然坐姿…' : state.statusText,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlotTile extends StatelessWidget {
  const _PlotTile({required this.plot, required this.onTap});

  final PlotState? plot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (plot == null) {
      return Card(
        color: context.tokens.primarySurfaceDim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 30,
                  color: context.tokens.textSecondary,
                ),
                Text('种花', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }
    final stage = plot!.stage;
    return Card(
      color: context.tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.asset(
                  'assets/game/plant_${plot!.species}_stage$stage.png',
                  key: ValueKey('${plot!.species}_$stage'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: LinearProgressIndicator(
                value: plot!.progressToNext,
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: AppColors.primarySurfaceDim,
              ),
            ),
            if (plot!.harvestable)
              Positioned(
                top: 6,
                right: 8,
                child: Text('🌸 收', style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _DecorationsLayer extends StatelessWidget {
  const _DecorationsLayer({required this.owned});

  final List<String> owned;

  static const Map<String, Alignment> _align = {
    'pavilion': Alignment(0.62, -0.88),
    'fence': Alignment(-0.85, -0.6),
    'hanging_pot': Alignment(0.85, -0.62),
    'gnome': Alignment(-0.88, -0.05),
    'path': Alignment(0.88, 0.0),
    'lantern': Alignment(-0.86, 0.68),
    'bench': Alignment(0.86, 0.7),
    'wheelbarrow': Alignment(-0.42, 0.86),
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final id in owned)
          Align(
            alignment: _align[id] ?? const Alignment(0, 0),
            child: Image.asset(
              'assets/game/deco_$id.png',
              width: id == 'pavilion' ? 88 : 60,
            ),
          ),
      ],
    );
  }
}

/// 种子选择:基础 4 种免费;已兑换的高级种子也出现在这里(§5.1)。
class _SeedSheet extends StatelessWidget {
  const _SeedSheet({
    required this.plotIndex,
    required this.state,
    required this.onIntent,
  });

  final int plotIndex;
  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plantable = seedCatalog
        .where((s) => state.unlockedAdvancedSeeds.contains(s.id) || s.basic)
        .toList();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('选一颗种子', style: theme.textTheme.titleMedium),
          ),
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final seed in plantable)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        onIntent(SeedSelected(plotIndex, seed.id));
                        Navigator.of(context).pop();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/game/plant_${seed.id}_stage4.png',
                            height: 90,
                          ),
                          Text(
                            seed.basic ? seed.name : '${seed.name} ✨',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '☀️ ${state.todaySunshineTotal} · 种下用阳光投入成长',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.tokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantSheet extends StatelessWidget {
  const _PlantSheet({
    required this.plotIndex,
    required this.plot,
    required this.state,
    required this.onIntent,
  });

  final int plotIndex;
  final PlotState plot;
  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = seedCatalog.where((s) => s.id == plot.species);
    final name = matches.isEmpty ? plot.species : matches.first.name;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/game/plant_${plot.species}_stage${plot.stage}.png',
                  height: 88,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge),
                    Text(
                      _stageNames[plot.stage],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: plot.invested / PlotState.fullCourse,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${plot.invested} / ${PlotState.fullCourse} ☀️'
              ' · 当前阳光 ${state.todaySunshineTotal}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.tokens.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            if (plot.harvestable)
              FilledButton.icon(
                onPressed: () {
                  onIntent(HarvestPressed(plotIndex));
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.local_florist),
                label: const Text('收获入押花册'),
              )
            else
              FilledButton(
                onPressed: () => onIntent(InvestPressed(plotIndex)),
                child: const Text('☀️ 投入 30 阳光'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 商店:装饰(阳光)+ 高级种子兑换(星屑,§5.1)。
class _ShopSheet extends StatelessWidget {
  const _ShopSheet({required this.state, required this.onIntent});

  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '商店  ☀️${state.todaySunshineTotal} · ✨${state.stardustTotal}',
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (state.shopHint.isNotEmpty)
            Text(
              state.shopHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.tokens.textTertiary,
              ),
            ),
          // 星屑兑换入口(§5.1:100 星屑 = 1 颗高级种子)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✨ 高级种子兑换', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      onIntent(const ExchangeAdvancedSeedPressed()),
                  child: const Text('100 ✨ 兑换'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              children: [
                for (final deco in decorationCatalog)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/game/deco_${deco.id}.png',
                          height: 72,
                          opacity: state.decorations.contains(deco.id)
                              ? const AlwaysStoppedAnimation(1)
                              : const AlwaysStoppedAnimation(0.45),
                        ),
                        Text(deco.name, style: theme.textTheme.bodySmall),
                        state.decorations.contains(deco.id)
                            ? Text(
                                '已拥有',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.tokens.textTertiary,
                                ),
                              )
                            : TextButton(
                                onPressed: () =>
                                    onIntent(BuyDecorationPressed(deco.id)),
                                child: Text('☀️${deco.priceSunshine}'),
                              ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 练习区 ============

class _PlayArea extends StatelessWidget {
  const _PlayArea({required this.state, required this.onIntent});

  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paused = state.phase == GamePhase.paused;
    final catchSnap = state.catchSnapshot;
    final starSnap = state.starSnapshot;
    final total = switch (state.kind) {
      GameKind.catchDrop => CatchDropConfig.standard.sessionDuration.inSeconds,
      GameKind.starGazing =>
        StarGazingConfig.standard.sessionDuration.inSeconds,
    };
    final elapsed =
        catchSnap?.elapsed.inSeconds ?? starSnap?.elapsed.inSeconds ?? 0;
    final remaining = (total - elapsed).clamp(0, total);
    final canFinishEarly =
        catchSnap?.canFinishEarly ?? starSnap?.canFinishEarly ?? false;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 68, 0),
          child: Row(
            children: [
              Text(
                '${remaining}s',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: remaining <= 10
                      ? AppColors.danger
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (canFinishEarly && !paused)
                FilledButton.tonal(
                  onPressed: () => onIntent(const FinishEarlyPressed()),
                  child: const Text('✓ 提前完成'),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            state.statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.tokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Center(
            child: state.kind == GameKind.catchDrop && catchSnap != null
                ? CatchDropBoard(
                    snapshot: catchSnap,
                    remainingSeconds: remaining,
                    totalSeconds: total,
                    events: state.catchEvents,
                    eventSeq: state.catchEventSeq,
                    tickMs:
                        CatchDropConfig.standard.tickInterval.inMilliseconds,
                  )
                : starSnap != null
                ? StarGazingBoard(
                    snapshot: starSnap,
                    headPitch: state.latestPitch,
                    remainingSeconds: remaining,
                    totalSeconds: total,
                  )
                : const SizedBox.shrink(),
          ),
        ),
        if (paused)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('已暂停 · 回到画面前保持放松', style: theme.textTheme.titleMedium),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }
}

// ============ 结算遮罩 ============

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.state, required this.onIntent});

  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStar = state.kind == GameKind.starGazing;
    final unlockedName = state.resultUnlockedSeed == null
        ? null
        : seedCatalog
              .where((s) => s.id == state.resultUnlockedSeed)
              .map((s) => s.name)
              .firstOrNull;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isStar ? '🌙 本局结算' : '☀️ 本局结算',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  '完成用时 ${state.resultElapsedSeconds} 秒'
                  '${state.resultFinishedEarly ? ' · 提前完成' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  isStar
                      ? '收集 ${state.resultStars} 颗星 · 总分 ${state.resultScore}'
                      : '接住 太阳 ${state.resultCaughtNormal}'
                            ' · 金阳光 ${state.resultCaughtGolden}'
                            ' · 总分 ${state.resultScore}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isStar
                      ? '✨ +${state.resultStardust} 星屑'
                      : '☀️ +${state.resultSunshine} 阳光',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  isStar
                      ? '星屑累计 ${state.stardustTotal}'
                      : '阳光累计 ${state.todaySunshineTotal}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.tokens.textTertiary,
                  ),
                ),
                if (unlockedName != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '🎉 星屑兑换:解锁「$unlockedName」种子!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.tokens.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => onIntent(const BackToGardenPressed()),
                  child: const Text('回到花园'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// firstOrNull(仓库惯例:不为此引入 collection)。
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
