using System;
using System.Collections.Generic;

namespace TheLastYodha.Events
{
    public sealed class EventBus
    {
        private readonly Dictionary<Type, List<Delegate>> _handlers = new Dictionary<Type, List<Delegate>>();
        public void Subscribe<T>(Action<T> handler) { var t=typeof(T); if(!_handlers.ContainsKey(t)) _handlers[t]=new List<Delegate>(); _handlers[t].Add(handler); }
        public void Unsubscribe<T>(Action<T> handler) { if(_handlers.TryGetValue(typeof(T), out var list)) list.Remove(handler); }
        public void Publish<T>(T message) { if(!_handlers.TryGetValue(typeof(T), out var list)) return; foreach(var h in list.ToArray()) ((Action<T>)h)(message); }
    }
    public readonly struct CombatLogEvent { public readonly string Message; public CombatLogEvent(string message){Message=message;} }
    public readonly struct GoldChangedEvent { public readonly int Gold; public GoldChangedEvent(int gold){Gold=gold;} }
    public readonly struct FloorChangedEvent { public readonly int Floor; public FloorChangedEvent(int floor){Floor=floor;} }
}
