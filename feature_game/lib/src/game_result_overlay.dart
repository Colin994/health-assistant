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
      color: g.hud.withValues(alpha: .8),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GardenHud(
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
                      star
                          ? '获得 ${state.resultStardust} 星屑'
                          : '获得 ${state.resultSunshine} 阳光',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: g.sunshine),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      star
                          ? '收集 ${state.resultStars} 颗星'
                          : '接住 ${state.resultCaughtNormal} 个普通阳光 · ${state.resultCaughtGolden} 个金阳光',
                    ),
                    const SizedBox(height: 8),
                    Text('总分 ${state.resultScore}'),
                    const SizedBox(height: 8),
                    Text(
                      star
                          ? '当前余额 ${state.stardustTotal} 星屑'
                          : '当前余额 ${state.todaySunshineTotal} 阳光',
                    ),
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
                      onPressed: () => onIntent(const BackToGardenPressed()),
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
