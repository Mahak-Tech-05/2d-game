using TheLastYodha.Core;
using TheLastYodha.Combat;

namespace TheLastYodha.Enemies
{
    public enum EnemyArchetype { FallenGuard, ShadeStalker, CrimsonWarden }
    public static class EnemyFactory
    {
        public static Combatant Create(EnemyArchetype type,int floor)
        {
            var stats=new CharacterStats(); stats.SetBase(StatType.Strength, type==EnemyArchetype.CrimsonWarden?7+floor:2+floor); stats.SetBase(StatType.Vitality,4+floor);
            int hp=type==EnemyArchetype.CrimsonWarden?120+floor*15:type==EnemyArchetype.ShadeStalker?38+floor*5:48+floor*6;
            return new Combatant(type.ToString(),hp,stats);
        }
    }
}
