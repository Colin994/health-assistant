import 'dart:async';

import 'package:core_database/core_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_event.dart';
import 'game_screen.dart';
import 'game_view_model.dart';

/// 游戏页跳转入口与 Screen/ViewModel 通信中间件(架构文档 3.2)。
///
/// 事件流订阅保持「initState 订阅 / dispose 取消」语义;
/// VM 生命周期交给 provider(页面 pop 后自动销毁并释放相机)。
class GameScreenRoute extends ConsumerStatefulWidget {
  const GameScreenRoute({super.key});

  /// 跳转到游戏页(dev 入口;正式入口 M3 接花园首页)。
  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const GameScreenRoute()),
    );
  }

  @override
  ConsumerState<GameScreenRoute> createState() => _GameScreenRouteState();
}

class _GameScreenRouteState extends ConsumerState<GameScreenRoute> {
  StreamSubscription<GameEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription =
        ref.read(gameViewModelProvider.notifier).onEvent.listen(_handleEvent);
  }

  void _handleEvent(GameEvent event) {
    if (!mounted) {
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    switch (event) {
      case GameExited():
        Navigator.of(context).maybePop();
      case PlotHarvested(:final species, :final count):
        final matches = seedCatalog.where((s) => s.id == species);
        final name = matches.isEmpty ? species : matches.first.name;
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/game/plant_${species}_stage4.png',
                  height: 96,
                ),
                const SizedBox(height: 8),
                Text('$name 入册!押花册 $count',
                    style: Theme.of(dialogContext).textTheme.titleMedium),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('好耶'),
              ),
            ],
          ),
        );
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(gameViewModelProvider.notifier);
    final state = ref.watch(gameViewModelProvider);
    return GameScreen(state: state, onIntent: viewModel.handleIntent);
  }
}
