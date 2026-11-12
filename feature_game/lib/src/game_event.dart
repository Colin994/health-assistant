/// GameViewModel → ScreenRoute 的一次性事件。
sealed class GameEvent {
  const GameEvent();
}

/// 退出游戏页(pop)。
class GameExited extends GameEvent {
  const GameExited();
}

/// 收获完成(Route 弹庆祝;species 为植物 id)。
class PlotHarvested extends GameEvent {
  const PlotHarvested(this.species, this.count);

  /// 收获的物种 id(seedCatalog 之一)。
  final String species;

  /// 收获后押花册累计数。
  final int count;
}
