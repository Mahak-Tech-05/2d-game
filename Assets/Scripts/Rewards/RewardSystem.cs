using System;
using System.Collections.Generic;
using TheLastYodha.Cards;
using TheLastYodha.Core;
using TheLastYodha.Relics;

namespace TheLastYodha.Rewards
{
    [Serializable] public sealed class RewardBundle { public int Gold; public int Experience; public List<CardDefinition> Cards=new List<CardDefinition>(); public Relic Relic; }
    public sealed class RewardSystem
    {
        readonly Random _rng=new Random();
        public RewardBundle CreateCombatReward(int floor,bool elite){ var r=new RewardBundle{Gold=10+floor*2+(elite?20:0),Experience=20+floor*5+(elite?30:0)}; r.Cards.Add(_rng.Next(3)==0?StarterDeckFactory.Flame():StarterDeckFactory.Strike()); if(elite) r.Relic=RelicCatalog.AshenLotus(); return r; }
    }
}
