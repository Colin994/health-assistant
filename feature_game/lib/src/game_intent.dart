/// GameScreen 的用户意图(统一经 onIntent 转发给 VM)。
sealed class GameIntent {
  const GameIntent();
}

/// 开始接阳光/接雨滴(§6.1)。
class StartCatchDropPressed extends GameIntent {
  const StartCatchDropPressed();
}

/// 开始看星星(§6.2.1;未解锁时给解锁条件文案)。
class StartStarGazingPressed extends GameIntent {
  const StartStarGazingPressed();
}

/// 提前完成(达目标分后出现,§6.1)。
class FinishEarlyPressed extends GameIntent {
  const FinishEarlyPressed();
}

/// 空地种下种子(基础免费;高级需星屑兑换,§5.1)。
class SeedSelected extends GameIntent {
  const SeedSelected(this.plotIndex, this.species);

  final int plotIndex;
  final String species;
}

/// 向地块投入阳光(每次 30)。
class InvestPressed extends GameIntent {
  const InvestPressed(this.plotIndex);

  final int plotIndex;
}

/// 收获待收植物(押花册 +1,地块清空)。
class HarvestPressed extends GameIntent {
  const HarvestPressed(this.plotIndex);

  final int plotIndex;
}

/// 商店:购买装饰(阳光定价,买了即显示)。
class BuyDecorationPressed extends GameIntent {
  const BuyDecorationPressed(this.decorationId);

  final String decorationId;
}

/// 星屑兑换高级种子(100 星屑,§5.1)。
class ExchangeAdvancedSeedPressed extends GameIntent {
  const ExchangeAdvancedSeedPressed();
}

/// 结算后回到花园。
class BackToGardenPressed extends GameIntent {
  const BackToGardenPressed();
}

/// 退出游戏页(任何阶段,随时可停,§3.1)。
class ExitPressed extends GameIntent {
  const ExitPressed();
}
