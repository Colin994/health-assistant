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
                  // 花园/练习场景均为彩色画面,统一深色透明 HUD 风格。
                  onDark: true,
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

/// iso 场景开关(true=位图背景+花畦锚点,false=扁平 painter+网格,降级回退用)。
const bool _useIsoScene = true;

/// 四花畦归一化锚点(图内坐标,edit_iso B 锚点实测;顺序=plots[0..3])。
const _isoBedSpecs = [
  _IsoBedSpec(Offset(0.525, 0.495), Size(0.32, 0.095)), // 后
  _IsoBedSpec(Offset(0.29, 0.58), Size(0.32, 0.095)), // 左
  _IsoBedSpec(Offset(0.745, 0.575), Size(0.32, 0.095)), // 右
  _IsoBedSpec(Offset(0.505, 0.64), Size(0.32, 0.095)), // 前
];

/// 单块花畦锚点规格(图内归一化中心+宽高)。
class _IsoBedSpec {
  const _IsoBedSpec(this.center, this.size);

  final Offset center;
  final Size size;
}

// ============ 花园 ============

class _GardenView extends StatelessWidget {
  const _GardenView({required this.state, required this.onIntent});

  final GameState state;
  final void Function(GameIntent intent) onIntent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 时段由本地时钟驱动,场景图与花畦锚点随时段切换(构图锁定)。
    final timeOfDay = GardenTimeOfDay.fromClock(DateTime.now());
    final busy =
        state.phase == GamePhase.countdown ||
        state.phase == GamePhase.calibrating;
    final showPlots = !busy && state.phase != GamePhase.error;
    final heading = switch (state.phase) {
      GamePhase.countdown => '${state.countdownSeconds}',
      GamePhase.calibrating => '校准中',
      GamePhase.error => '出了点问题',
      _ => '我的花园',
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        // iso 场景位图背景(edit_iso B 锚点四时段);扁平 painter 留作降级。
        if (_useIsoScene)
          GardenIsoBackdrop(timeOfDay: timeOfDay)
        else
          GardenScene(timeOfDay: timeOfDay),
        // 花畦锚点地块层(全屏坐标,与 backdrop cover 映射一致)。
        if (showPlots)
          _IsoPlotsLayer(plots: state.plots, onTap: _onPlotTapped),
        _DecorationsLayer(owned: state.decorations),
        SafeArea(
          child: busy || state.phase == GamePhase.error
              ? Center(
                  child: _BusyCard(state: state, heading: heading),
                )
              : Column(
                  children: [
                    // 顶部 HUD:深色胶囊保证任意场景下的对比度。
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 68, 4),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '☀️ ${state.todaySunshineTotal}'
                                  '  ✨ ${state.stardustTotal}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                // 押花册入口(可点查看已收集物种)。
                                TextButton(
                                  onPressed: () => _openHerbarium(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: const Size(0, 40),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    '📖 ${state.harvestedCount}',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '今日可练 ${state.quotaRemaining}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (state.statusText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.30),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Text(
                                  state.statusText,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      // 地块已落位到 iso 场景花畦(见 _IsoPlotsLayer),
                      // 此处仅占位把按钮区压到底部。
                      child: const SizedBox.shrink(),
                    ),
                    // 底部 HUD:深色圆角条承托玩法按钮,提升对比度。
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
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
                              icon: const Icon(
                                Icons.storefront_outlined,
                                color: Colors.white,
                              ),
                              tooltip: '商店',
                            ),
                          ],
                        ),
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

/// 花畦锚点地块层:全屏 Stack,按 [GardenIsoMetrics] 把 plots[0..3]
/// 落位到场景四块白框花畦上;点击回调复用原有 seed/plant sheet 流程。
class _IsoPlotsLayer extends StatelessWidget {
  const _IsoPlotsLayer({required this.plots, required this.onTap});

  final List<PlotState?> plots;

  final void Function(BuildContext, int) onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = GardenIsoMetrics(
            screenSize: Size(constraints.maxWidth, constraints.maxHeight),
          );
          return Stack(
            children: [
              for (var i = 0; i < plots.length; i++)
                Positioned.fromRect(
                  rect: metrics.rect(
                    _isoBedSpecs[i].center,
                    _isoBedSpecs[i].size,
                  ),
                  child: _IsoPlotView(
                    plot: plots[i],
                    onTap: () => onTap(context, i),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 单块花畦上的地块视图:空地=呼吸脉动的游戏风徽章提示;
/// 有植物=位图落畦(整体上移,土丘基座对齐花畦下半部) + 细进度条 +
/// 收获角标;整体响应点击(触控区=花畦矩形)。
class _IsoPlotView extends StatelessWidget {
  const _IsoPlotView({required this.plot, required this.onTap});

  final PlotState? plot;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bed = LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          if (plot == null)
            const Center(
              // 极淡高亮勾出可点区域(不遮花畦细节)。
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x14FFFFFF),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: SizedBox.expand(),
              ),
            )
          else ...[
            // 植物整体上移:土丘基座落位花畦中下部,株体朝上生长。
            Align(
              alignment: const Alignment(0, -0.35),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.asset(
                  'assets/game/plant_iso_${plot!.species}_stage${plot!.stage}.png',
                  key: ValueKey('iso_${plot!.species}_${plot!.stage}'),
                  fit: BoxFit.contain,
                  // iso 植物图缺失时回退旧贴纸(过渡期容错)。
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/game/plant_${plot!.species}_stage${plot!.stage}.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: constraints.maxHeight * 0.10,
              child: LinearProgressIndicator(
                value: plot!.progressToNext,
                minHeight: 4,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            if (plot!.harvestable)
              Positioned(
                top: constraints.maxHeight * 0.06,
                right: 4,
                child: Text('🌸 收', style: theme.textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // 空畦在淡高亮上叠加脉动徽章;有植物时整畦点击进植物详情。
      child: plot == null
          ? Stack(
              children: [bed, const _IsoBedHint()],
            )
          : bed,
    );
  }
}

/// 游戏风空畦提示:呼吸脉动的深色胶囊徽章(加号+文字),置于花畦中心。
class _IsoBedHint extends StatefulWidget {
  const _IsoBedHint();

  @override
  State<_IsoBedHint> createState() => _IsoBedHintState();
}

class _IsoBedHintState extends State<_IsoBedHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.12).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                '种花',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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

class _DecorationsLayer extends StatelessWidget {
  const _DecorationsLayer({required this.owned});

  final List<String> owned;

  static const Map<String, Alignment> _align = {
    // iso 场景锚点:贴平台四周草地与前景,避开中央花畦带(y≈0.49-0.62)。
    'pavilion': Alignment(0.85, 0.30), // 右后丘陵
    'fence': Alignment(-0.62, 0.88), // 左前草地(场景自带背景栅栏,此为近景段)
    'hanging_pot': Alignment(0.10, 0.34), // 左侧树冠下
    'gnome': Alignment(0.10, 0.66), // 左前草地
    'path': Alignment(0.50, 0.84), // 前景平台前缘
    'lantern': Alignment(0.87, 0.66), // 右前草地
    'bench': Alignment(-0.85, 0.88), // 左下前景
    'wheelbarrow': Alignment(0.84, 0.92), // 右下前景
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final id in owned)
          Align(
            alignment: _align[id] ?? const Alignment(0, 0),
            child: Image.asset(
              'assets/game/deco_iso_$id.png',
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
            // 图 72 + 名称/价格两行 ≈ 162,150 会溢出 10px(黄黑警告条)。
            height: 170,
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
                          'assets/game/deco_iso_${deco.id}.png',
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
