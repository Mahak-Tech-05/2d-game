using System;
using System.Collections.Generic;
using System.Linq;
using TheLastYodha.Core;
using TheLastYodha.Combat;

namespace TheLastYodha.Cards
{
    public enum CardType { Attack, Defense, Magic, Buff, Debuff, Skill }
    [Serializable] public sealed class CardDefinition : IIdentifiable { public string Id{get;set;} public string Name{get;set;} public string Description{get;set;} public CardType Type; public Rarity Rarity; public int EnergyCost; public int ManaCost; public ICardEffect Effect; }
    public interface ICardEffect { void Resolve(Combatant source, Combatant target, CombatState state); }
    public sealed class DamageEffect : ICardEffect { public int Amount; public DamageType Type; public DamageEffect(int amount,DamageType type){Amount=amount;Type=type;} public void Resolve(Combatant s,Combatant t,CombatState st)=>t.ReceiveDamage(new DamagePacket(s,Amount+s.Stats.Get(StatType.Strength),Type)); }
    public sealed class BlockEffect : ICardEffect { public int Amount; public BlockEffect(int amount){Amount=amount;} public void Resolve(Combatant s,Combatant t,CombatState st)=>s.GainBlock(Amount+s.Stats.Get(StatType.Dexterity)); }
    public sealed class StatusEffectCard : ICardEffect { readonly StatusEffect _effect; public StatusEffectCard(StatusEffect effect){_effect=effect;} public void Resolve(Combatant s,Combatant t,CombatState st)=>t.AddStatus(_effect.Clone()); }
    [Serializable] public sealed class Deck { readonly List<CardDefinition> _cards; public IReadOnlyList<CardDefinition> Cards=>_cards; public List<string> CardIds=>_cards.Select(c=>c.Id).ToList(); public Deck(IEnumerable<CardDefinition> cards){_cards=cards.ToList();} public void Add(CardDefinition c)=>_cards.Add(c); public void Remove(CardDefinition c)=>_cards.Remove(c); }
    public static class StarterDeckFactory
    {
        public static Deck CreateYodhaDeck()=>new Deck(new[]{Strike(),Strike(),Strike(),Guard(),Guard(),Flame(),Weaken()});
        public static CardDefinition Strike()=>new CardDefinition{Id="strike",Name="Cursed Talwar",Description="Deal blade damage.",Type=CardType.Attack,Rarity=Rarity.Common,EnergyCost=1,Effect=new DamageEffect(7,DamageType.Physical)};
        public static CardDefinition Guard()=>new CardDefinition{Id="guard",Name="Ashen Guard",Description="Gain block.",Type=CardType.Defense,Rarity=Rarity.Common,EnergyCost=1,Effect=new BlockEffect(6)};
        public static CardDefinition Flame()=>new CardDefinition{Id="flame_mantra",Name="Flame Mantra",Description="Spend mana to burn an enemy.",Type=CardType.Magic,Rarity=Rarity.Uncommon,EnergyCost=1,ManaCost=1,Effect=new DamageEffect(10,DamageType.Magical)};
        public static CardDefinition Weaken()=>new CardDefinition{Id="evil_eye",Name="Evil Eye",Description="Apply weakness.",Type=CardType.Debuff,Rarity=Rarity.Common,EnergyCost=1,Effect=new StatusEffectCard(new StatusEffect("weak",2, -2, StatType.Strength))};
    }
}
