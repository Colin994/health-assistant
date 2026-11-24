import 'dart:math' as math;
import 'package:core_database/core_database.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_intent.dart';
import '../game_state.dart';
import '../game_view_model.dart';
import 'garden_asset_catalog.dart';
import 'garden_scene_layout.dart';
import 'garden_ui_theme.dart';

enum GardenPanel { seed, plant, shop, herbarium }

enum GardenPanelFollowUp { practice }

/// Only the route subscribes to application state; panel views remain pure.
class GardenPanelResult {
  const GardenPanelResult({
    this.followUp,
    this.harvestedSpecies,
    this.harvestedCount = 0,
  });
  final GardenPanelFollowUp? followUp;
  final String? harvestedSpecies;
  final int harvestedCount;
}

Future<GardenPanelFollowUp?> showGardenPanel(
  BuildContext context,
  GardenPanel panel, {
  int? plotIndex,
}) async {
  final result = await showModalBottomSheet<GardenPanelResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => GardenPanelRoute(panel: panel, plotIndex: plotIndex),
  );
  if (context.mounted && result?.harvestedSpecies != null) {
    await showHarvestCelebration(
      context,
      result!.harvestedSpecies!,
      result.harvestedCount,
    );
  }
  return result?.followUp;
}

class GardenPanelRoute extends ConsumerStatefulWidget {
  const GardenPanelRoute({super.key, required this.panel, this.plotIndex});
  final GardenPanel panel;
  final int? plotIndex;
  @override
  ConsumerState<GardenPanelRoute> createState() => _GardenPanelRouteState();
}

class _GardenPanelRouteState extends ConsumerState<GardenPanelRoute> {
  String? _species;
  bool _closing = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameViewModelProvider);
    final index = widget.plotIndex;
    if (index != null && state.plots[index] != null) {
      _species = state.plots[index]!.species;
    }
    ref.listen(gameViewModelProvider.select((s) => s.feedback), (
      previous,
      next,
    ) {
      if (next == null ||
          next.sequence == previous?.sequence ||
          !next.success ||
          _closing) {
        return;
      }
      if (next.target == '$index' &&
          ((widget.panel == GardenPanel.seed &&
                  next.action == GardenAction.plant) ||
              (widget.panel == GardenPanel.plant &&
                  next.action == GardenAction.harvest))) {
        _closing = true;
        final result = next.action == GardenAction.harvest && _species != null
            ? GardenPanelResult(
                harvestedSpecies: _species,
                harvestedCount: ref.read(gameViewModelProvider).harvestedCount,
              )
            : null;
        Navigator.of(context).pop(result);
      }
    });
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          key: const ValueKey('garden-panel-surface'),
          color: dark ? context.tokens.surface : GardenUiTheme.paper,
          borderRadius: BorderRadius.circular(dark ? 4 : 24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .9,
            ),
            child: Theme(
              data: dark
                  ? Theme.of(context).copyWith(
                      filledButtonTheme: FilledButtonThemeData(
                        style: FilledButton.styleFrom(
                          backgroundColor: context.tokens.primaryText,
                          foregroundColor: context.tokens.onPrimary,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    )
                  : Theme.of(context).copyWith(
                      filledButtonTheme: FilledButtonThemeData(
                        style: FilledButton.styleFrom(
                          backgroundColor: GardenUiTheme.leaf,
                          foregroundColor: GardenUiTheme.paper,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: GardenPanelView(
                  panel: widget.panel,
                  plotIndex: index,
                  state: state,
                  onIntent: (intent) {
                    ref
                        .read(gameViewModelProvider.notifier)
                        .handleIntent(intent);
                  },
                  onPractice: () => Navigator.of(context).pop(
                    const GardenPanelResult(
                      followUp: GardenPanelFollowUp.practice,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showHarvestCelebration(
  BuildContext context,
  String species,
  int count,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('已收入押花册'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: GardenPlantSprite(species: species, stage: 4),
          ),
          const SizedBox(height: 16),
          Text(
            '${seedCatalog.firstWhere((s) => s.id == species).name} · 累计收获 $count 次',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('回到花园'),
      ),
    ],
  ),
);

class GardenPanelView extends StatelessWidget {
  const GardenPanelView({
    super.key,
    required this.panel,
    required this.state,
    required this.onIntent,
    required this.onPractice,
    this.plotIndex,
  });
  final GardenPanel panel;
  final int? plotIndex;
  final GameState state;
  final ValueChanged<GameIntent> onIntent;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final feedback = state.feedback;
    final relevant =
        feedback != null &&
        switch (panel) {
          GardenPanel.seed ||
          GardenPanel.plant => feedback.target == '$plotIndex',
          GardenPanel.shop =>
            feedback.action == GardenAction.buyDecoration ||
                feedback.action == GardenAction.exchange,
          GardenPanel.herbarium => false,
        };
    final plot = plotIndex == null ? null : state.plots[plotIndex!];
    final title = panel == GardenPanel.plant && plot != null
        ? '${seedCatalog.firstWhere((s) => s.id == plot.species).name} · ${plantStageLabel(plot)}'
        : switch (panel) {
            GardenPanel.seed => '选一颗种子',
            GardenPanel.plant => '植物详情',
            GardenPanel.shop => '花园商店',
            GardenPanel.herbarium => '押花册',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (panel == GardenPanel.plant && plot != null) ...[
          Text(
            '植物详情',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.tokens.primaryText,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              tooltip: '关闭',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (relevant)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                feedback.message,
                style: TextStyle(
                  color: feedback.success
                      ? context.tokens.primaryText
                      : context.tokens.dangerText,
                ),
              ),
            ),
          ),
        switch (panel) {
          GardenPanel.seed => _SeedOptions(
            state: state,
            index: plotIndex!,
            onIntent: onIntent,
          ),
          GardenPanel.plant => _PlantDetails(
            state: state,
            index: plotIndex!,
            onIntent: onIntent,
            onPractice: onPractice,
          ),
          GardenPanel.shop => _Shop(state: state, onIntent: onIntent),
          GardenPanel.herbarium => _Herbarium(state: state),
        },
      ],
    );
  }
}

class GardenCards extends StatelessWidget {
  const GardenCards({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scaled = MediaQuery.textScalerOf(context).scale(14) / 14;
      final minWidth = scaled > 1.5 ? 220.0 : 140.0;
      final columns = math.max(
        1,
        ((c.maxWidth + 12) / (minWidth + 12)).floor(),
      );
      final width = (c.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _SeedOptions extends StatelessWidget {
  const _SeedOptions({
    required this.state,
    required this.index,
    required this.onIntent,
  });
  final GameState state;
  final int index;
  final ValueChanged<GameIntent> onIntent;
  @override
  Widget build(BuildContext context) => GardenCards(
    children: [
      for (final seed in seedCatalog.where(
        (s) => s.basic || state.unlockedAdvancedSeeds.contains(s.id),
      ))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  height: 108,
                  width: 120,
                  child: GardenPlantSprite(species: seed.id, stage: 4),
                ),
                const SizedBox(height: 12),
                Text(seed.name, style: Theme.of(context).textTheme.titleMedium),
                Text(seed.basic ? '基础种 · 免费种植' : '高级种 · 已解锁'),
                const SizedBox(height: 12),
                FilledButton(
                  key: ValueKey('plant-${seed.id}'),
                  onPressed: state.pendingPlotIndices.contains(index)
                      ? null
                      : () => onIntent(SeedSelected(index, seed.id)),
                  child: Text(
                    state.pendingPlotIndices.contains(index) ? '正在种植…' : '种下',
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _PlantDetails extends StatelessWidget {
  const _PlantDetails({
    required this.state,
    required this.index,
    required this.onIntent,
    required this.onPractice,
  });
  final GameState state;
  final int index;
  final ValueChanged<GameIntent> onIntent;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) {
    final plot = state.plots[index];
    if (plot == null) return const Text('这块花畦已空出，可以种下一株植物了。');
    final actual = math.max(
      0,
      math.min(
        30,
        math.min(
          state.todaySunshineTotal,
          PlotState.fullCourse - plot.invested,
        ),
      ),
    );
    final busy = state.pendingPlotIndices.contains(index);
    final stageAmount = plot.harvestable ? 75 : plot.invested % 75;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: GardenUiTheme.paperSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GardenUiTheme.paperEdge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 72,
                  height: 84,
                  child: GardenPlantSprite(
                    species: plot.species,
                    stage: plot.stage,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                plot.harvestable ? '已经盛开，可以收入押花册。' : '用阳光照顾它，陪它慢慢长大。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('当前阶段 $stageAmount / 75 阳光'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: plot.harvestable ? 1 : plot.progressToNext,
          color: context.tokens.primaryText,
          backgroundColor: context.tokens.primarySurface,
        ),
        const SizedBox(height: 16),
        Text('全程累计 ${plot.invested} / ${PlotState.fullCourse} 阳光'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (plot.invested / PlotState.fullCourse).clamp(0, 1),
          color: context.tokens.primaryText,
          backgroundColor: context.tokens.primarySurface,
        ),
        const SizedBox(height: 16),
        Text('可用阳光 ${state.todaySunshineTotal}'),
        const SizedBox(height: 16),
        if (plot.harvestable)
          FilledButton(
            key: const ValueKey('harvest'),
            onPressed: busy ? null : () => onIntent(HarvestPressed(index)),
            child: Text(busy ? '正在收获…' : '收获并收入押花册'),
          )
        else ...[
          FilledButton(
            key: const ValueKey('invest'),
            onPressed: busy || actual == 0
                ? null
                : () => onIntent(InvestPressed(index)),
            child: Text(busy ? '正在投入…' : '投入 $actual 阳光'),
          ),
          if (actual == 0) ...[
            const SizedBox(height: 8),
            const Text('暂时没有阳光，完成一局练习后再来照顾它。'),
            TextButton(
              onPressed: busy ? null : onPractice,
              child: const Text('去接阳光'),
            ),
          ],
        ],
      ],
    );
  }
}

class _Shop extends StatelessWidget {
  const _Shop({required this.state, required this.onIntent});
  final GameState state;
  final ValueChanged<GameIntent> onIntent;
  @override
  Widget build(BuildContext context) {
    final next = seedCatalog
        .where((s) => !s.basic && !state.unlockedAdvancedSeeds.contains(s.id))
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '当前余额 · 阳光 ${state.todaySunshineTotal} · 星屑 ${state.stardustTotal}',
        ),
        const SizedBox(height: 16),
        Text('高级种子', style: Theme.of(context).textTheme.titleMedium),
        if (next == null)
          const Text('高级种子已全部解锁')
        else ...[
          const SizedBox(height: 8),
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: GardenUiTheme.paperSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GardenUiTheme.paperEdge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 52,
                    height: 58,
                    child: GardenPlantSprite(species: next.id, stage: 4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${next.name} · 需要 100 星屑'),
                    if (state.stardustTotal < 100) ...[
                      const SizedBox(height: 4),
                      Text(
                        '星屑还不够，慢慢积累就好。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.isExchangingSeed || state.stardustTotal < 100
                ? null
                : () => onIntent(const ExchangeAdvancedSeedPressed()),
            child: Text(state.isExchangingSeed ? '正在兑换…' : '兑换${next.name}种子'),
          ),
        ],
        const SizedBox(height: 24),
        Text('花园装饰', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GardenCards(
          children: [
            for (final d in decorationCatalog)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Image.asset(
                        GardenAssetCatalog.decoration(d.id),
                        height: 96,
                        excludeFromSemantics: true,
                      ),
                      Text(d.name),
                      Text('${d.priceSunshine} 阳光'),
                      const SizedBox(height: 8),
                      if (state.decorations.contains(d.id))
                        const Text('已拥有')
                      else
                        FilledButton(
                          key: ValueKey('buy-${d.id}'),
                          onPressed:
                              state.pendingDecorationIds.contains(d.id) ||
                                  state.todaySunshineTotal < d.priceSunshine
                              ? null
                              : () => onIntent(BuyDecorationPressed(d.id)),
                          child: Text(
                            state.pendingDecorationIds.contains(d.id)
                                ? '正在购买…'
                                : '购买',
                          ),
                        ),
                      if (!state.decorations.contains(d.id) &&
                          state.todaySunshineTotal < d.priceSunshine)
                        const Text('阳光不足'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Herbarium extends StatelessWidget {
  const _Herbarium({required this.state});
  final GameState state;
  @override
  Widget build(BuildContext context) {
    final entries = seedCatalog
        .where((s) => (state.harvestCounts[s.id] ?? 0) > 0)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('已收集 ${entries.length} 种 · 累计收获 ${state.harvestedCount} 次'),
        const SizedBox(height: 16),
        if (entries.isEmpty) ...[
          const Text('还没有收获过花。种下一株，养到盛开后收入押花册吧。'),
          const SizedBox(height: 16),
        ],
        GardenCards(
          children: [
            for (final seed in seedCatalog)
              Builder(
                builder: (context) {
                  final count = state.harvestCounts[seed.id] ?? 0;
                  final collected = count > 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Opacity(
                            opacity: collected ? 1 : .28,
                            child: SizedBox(
                              height: 108,
                              child: GardenPlantSprite(
                                species: seed.id,
                                stage: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            seed.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(collected ? '收获 $count 次' : '待培育'),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
