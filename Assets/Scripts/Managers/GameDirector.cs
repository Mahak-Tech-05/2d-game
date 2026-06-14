using System;
using TheLastYodha.Core;
using TheLastYodha.Player;
using TheLastYodha.Combat;
using TheLastYodha.Map;
using TheLastYodha.Rewards;
using TheLastYodha.SaveSystem;
using TheLastYodha.Dialogue;
using TheLastYodha.Events;

namespace TheLastYodha.Managers
{
    public sealed class GameDirector
    {
        public GameContext Context { get; } = new GameContext();
        public PlayerProfile Player { get; } = new PlayerProfile();
        public CombatManager Combat { get; } = new CombatManager();
        public RewardSystem Rewards { get; } = new RewardSystem();
        public SaveManager Saves { get; } = new SaveManager();
        public DialogueManager Dialogue { get; } = new DialogueManager();
        public EventBus Events { get; } = new EventBus();
        public int CurrentFloor { get; private set; } = 1;
        public void Boot(int seed)
        {
            Context.Register(Player); Context.Register(Combat); Context.Register(Rewards); Context.Register(Saves); Context.Register(Dialogue); Context.Register(Events);
            Saves.Register(Player);
            new TowerMapGenerator(seed).Generate();
        }
        public void AdvanceFloor(){ CurrentFloor++; Events.Publish(new FloorChangedEvent(CurrentFloor)); }
    }
}
