using System;
using System.Collections.Generic;
using TheLastYodha.Core;
using TheLastYodha.Inventory;
using TheLastYodha.Cards;
using TheLastYodha.Relics;

namespace TheLastYodha.Player
{
    [Serializable]
    public sealed class PlayerProfile : ISaveable
    {
        public string SaveKey => "player";
        public ResourcePool Health { get; } = new ResourcePool(80);
        public ResourcePool Energy { get; } = new ResourcePool(3);
        public ResourcePool Mana { get; } = new ResourcePool(2);
        public CharacterStats Stats { get; } = new CharacterStats();
        public InventoryModel Inventory { get; } = new InventoryModel(40);
        public Deck Deck { get; } = StarterDeckFactory.CreateYodhaDeck();
        public List<Relic> Relics { get; } = new List<Relic>();
        public int Gold { get; private set; } = 99;
        public int Level { get; private set; } = 1;
        public int Experience { get; private set; }
        public PlayerProfile(){ Stats.SetBase(StatType.Strength,4); Stats.SetBase(StatType.Dexterity,3); Stats.SetBase(StatType.Intelligence,3); Stats.SetBase(StatType.Vitality,8); }
        public void AddGold(int amount)=>Gold=Math.Max(0,Gold+amount);
        public void AddExperience(int amount){ Experience+=Math.Max(0,amount); while(Experience>=Level*100){ Experience-=Level*100; Level++; Health.SetMaximum(Health.Maximum+8,true); } }
        public object CaptureState()=>new PlayerSaveData{Gold=Gold,Level=Level,Experience=Experience,Health=Health.Current,DeckCardIds=Deck.CardIds};
        public void RestoreState(object state){ if(state is PlayerSaveData d){ Gold=d.Gold; Level=d.Level; Experience=d.Experience; Health.Reduce(Health.Maximum); Health.Restore(d.Health); } }
    }
    [Serializable] public sealed class PlayerSaveData { public int Gold; public int Level; public int Experience; public int Health; public List<string> DeckCardIds=new List<string>(); }
}
