using System;
using TheLastYodha.Core;

namespace TheLastYodha.Relics
{
    [Serializable] public sealed class Relic : IIdentifiable { public string Id{get;set;} public string Name{get;set;} public string Description{get;set;} public Rarity Rarity; public StatModifier Modifier; }
    public static class RelicCatalog { public static Relic AshenLotus()=>new Relic{Id="ashen_lotus",Name="Ashen Lotus",Description="Vitality blooms from ruin.",Rarity=Rarity.Rare,Modifier=new StatModifier(StatType.Vitality,3)}; }
}
