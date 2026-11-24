import 'package:flutter/material.dart';
import 'game_state.dart';
import 'game_intent.dart';
import 'garden/garden_ui_theme.dart';

class GameResultOverlay extends StatelessWidget {
  const GameResultOverlay({
    super.key,
    required this.state,
    required this.onIntent,
  });
  final GameState state;
  final ValueChanged<GameIntent> onIntent;
  @override
  Widget build(BuildContext context) {
    final g = GardenUiTheme.of(context);
    final star = state.kind == GameKind.starGazing;
    return ColoredBox(
      color: g.hud.withValues(alpha: star ? .8 : .45),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: star
                  ? GardenHud(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '本次练习完成',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(color: g.onHud),
                          ),
                          const SizedBox(height: 16),
                          Text('练习时长 ${state.resultElapsedSeconds} 秒'),
                          const SizedBox(height: 12),
                          Text(
                            '获得 ${state.resultStardust} 星屑',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(color: g.sunshine),
                          ),
                          const SizedBox(height: 20),
                          Text('收集 ${state.resultStars} 颗星'),
                          const SizedBox(height: 8),
                          Text('总分 ${state.resultScore}'),
                          const SizedBox(height: 8),
                          Text('当前余额 ${state.stardustTotal} 星屑'),
                          if (state.resultFinishedEarly) ...[
                            const SizedBox(height: 8),
                            const Text('已达标，提前完成'),
                          ],
                          if (state.resultUnlockedSeed != null) ...[
                            const SizedBox(height: 12),
                            const Text('已解锁高级种子，可以回花园种下了'),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () =>
                                onIntent(const BackToGardenPressed()),
                            child: const Text('返回花园'),
                          ),
                        ],
                      ),
                    )
                  : GardenPaper(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '本次练习完成',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: GardenUiTheme.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '获得 ${state.resultSunshine} 阳光',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: GardenUiTheme.sunInk,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '左右颈侧有没有松一点？阳光已存入你的小院。',
                            style: TextStyle(
                              color: GardenUiTheme.mutedInk,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('练习时长 ${state.resultElapsedSeconds} 秒'),
                          const SizedBox(height: 6),
                          Text(
                            '接住 ${state.resultCaughtNormal} 个普通阳光 · ${state.resultCaughtGolden} 个金阳光',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '总分 ${state.resultScore} · 当前余额 ${state.todaySunshineTotal} 阳光',
                          ),
                          if (state.resultFinishedEarly) ...[
                            const SizedBox(height: 6),
                            const Text(
                              '已达标，提前完成',
                              style: TextStyle(color: GardenUiTheme.leaf),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: GardenUiTheme.leaf,
                              foregroundColor: GardenUiTheme.paper,
                              minimumSize: const Size(0, 50),
                            ),
                            onPressed: () =>
                                onIntent(const BackToGardenPressed()),
                            child: const Text('返回花园'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
