using System;
using System.Collections.Generic;
using TheLastYodha.Core;
using TheLastYodha.Cards;

namespace TheLastYodha.Combat
{
    public enum CombatPhase { NotStarted, PlayerTurn, EnemyTurn, Reward, Complete }
    public readonly struct DamagePacket { public readonly Combatant Source; public readonly int Amount; public readonly DamageType Type; public DamagePacket(Combatant source,int amount,DamageType type){Source=source;Amount=amount;Type=type;} }
    [Serializable] public sealed class StatusEffect { public string Id; public int Turns; public int StatDelta; public StatType Stat; public StatusEffect(string id,int turns,int statDelta,StatType stat){Id=id;Turns=turns;StatDelta=statDelta;Stat=stat;} public StatusEffect Clone()=>new StatusEffect(Id,Turns,StatDelta,Stat); }
    public sealed class Combatant
    {
        public string Name { get; } public ResourcePool Health { get; } public CharacterStats Stats { get; } public int Block { get; private set; } public bool IsAlive=>Health.Current>0; readonly List<StatusEffect> _statuses=new List<StatusEffect>();
        public Combatant(string name,int hp,CharacterStats stats){Name=name;Health=new ResourcePool(hp);Stats=stats;}
        public void GainBlock(int amount)=>Block+=Math.Max(0,amount);
        public void ReceiveDamage(DamagePacket packet){ int incoming=Math.Max(0,packet.Amount); int blocked=Math.Min(Block,incoming); Block-=blocked; Health.Reduce(incoming-blocked); }
        public void AddStatus(StatusEffect effect){ _statuses.Add(effect); Stats.AddModifier(new StatModifier(effect.Stat,effect.StatDelta)); }
        public void BeginTurn(){ Block=0; }
    }
    public sealed class CombatState { public CombatPhase Phase; public Combatant Player; public List<Combatant> Enemies=new List<Combatant>(); public int Turn; }
    public sealed class CombatManager
    {
        public CombatState State { get; } = new CombatState();
        public void StartCombat(Combatant player,IEnumerable<Combatant> enemies){State.Player=player;State.Enemies=new List<Combatant>(enemies);State.Turn=1;State.Phase=CombatPhase.PlayerTurn;player.BeginTurn();}
        public bool PlayCard(CardDefinition card,Combatant target){ if(State.Phase!=CombatPhase.PlayerTurn||card?.Effect==null||target==null) return false; card.Effect.Resolve(State.Player,target,State); if(!target.IsAlive) State.Enemies.Remove(target); if(State.Enemies.Count==0) State.Phase=CombatPhase.Reward; return true; }
        public void EndPlayerTurn(){ if(State.Phase!=CombatPhase.PlayerTurn)return; State.Phase=CombatPhase.EnemyTurn; foreach(var enemy in State.Enemies.ToArray()){ enemy.BeginTurn(); State.Player.ReceiveDamage(new DamagePacket(enemy,5+enemy.Stats.Get(StatType.Strength),DamageType.Physical)); } State.Turn++; State.Phase=State.Player.IsAlive?CombatPhase.PlayerTurn:CombatPhase.Complete; State.Player.BeginTurn(); }
    }
}
