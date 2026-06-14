using System;
using System.Collections.Generic;

namespace TheLastYodha.Core
{
    public enum StatType { Strength, Dexterity, Intelligence, Vitality, Armor, Resistance }
    public enum DamageType { Physical, Magical, Pure }
    public enum RoomType { Combat, Elite, Boss, Treasure, Story, Merchant, Rest, Secret }
    public enum Rarity { Common, Uncommon, Rare, Epic, Legendary }

    [Serializable]
    public readonly struct StatModifier
    {
        public readonly StatType Stat;
        public readonly int FlatValue;
        public readonly float Multiplier;
        public StatModifier(StatType stat, int flatValue, float multiplier = 0f)
        { Stat = stat; FlatValue = flatValue; Multiplier = multiplier; }
    }

    [Serializable]
    public sealed class CharacterStats
    {
        private readonly Dictionary<StatType, int> _baseStats = new Dictionary<StatType, int>();
        private readonly List<StatModifier> _modifiers = new List<StatModifier>();
        public CharacterStats()
        {
            foreach (StatType type in Enum.GetValues(typeof(StatType))) _baseStats[type] = 0;
        }
        public void SetBase(StatType stat, int value) => _baseStats[stat] = Math.Max(0, value);
        public void AddModifier(StatModifier modifier) => _modifiers.Add(modifier);
        public void RemoveModifier(StatModifier modifier) => _modifiers.Remove(modifier);
        public int Get(StatType stat)
        {
            int value = _baseStats.TryGetValue(stat, out int baseValue) ? baseValue : 0;
            float multiplier = 0f;
            foreach (var modifier in _modifiers)
            {
                if (modifier.Stat != stat) continue;
                value += modifier.FlatValue;
                multiplier += modifier.Multiplier;
            }
            return Math.Max(0, (int)Math.Round(value * (1f + multiplier)));
        }
    }

    public interface IIdentifiable { string Id { get; } }
    public interface IGameService { void Initialize(GameContext context); }
    public interface ITickable { void Tick(float deltaTime); }
    public interface ISaveable { string SaveKey { get; } object CaptureState(); void RestoreState(object state); }

    public sealed class GameContext
    {
        private readonly Dictionary<Type, object> _services = new Dictionary<Type, object>();
        public void Register<T>(T service) where T : class => _services[typeof(T)] = service;
        public T Resolve<T>() where T : class
        {
            if (_services.TryGetValue(typeof(T), out var service)) return (T)service;
            throw new InvalidOperationException($"Service {typeof(T).Name} was not registered.");
        }
        public bool TryResolve<T>(out T service) where T : class
        {
            if (_services.TryGetValue(typeof(T), out var raw)) { service = (T)raw; return true; }
            service = null; return false;
        }
    }
}
