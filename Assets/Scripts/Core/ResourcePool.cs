using System;

namespace TheLastYodha.Core
{
    [Serializable]
    public sealed class ResourcePool
    {
        public int Current { get; private set; }
        public int Maximum { get; private set; }
        public event Action<int, int> Changed;
        public ResourcePool(int maximum) { Maximum = Math.Max(1, maximum); Current = Maximum; }
        public void SetMaximum(int maximum, bool fill) { Maximum = Math.Max(1, maximum); Current = fill ? Maximum : Math.Min(Current, Maximum); Changed?.Invoke(Current, Maximum); }
        public bool Spend(int amount) { if (amount < 0 || Current < amount) return false; Current -= amount; Changed?.Invoke(Current, Maximum); return true; }
        public void Restore(int amount) { Current = Math.Min(Maximum, Current + Math.Max(0, amount)); Changed?.Invoke(Current, Maximum); }
        public void Reduce(int amount) { Current = Math.Max(0, Current - Math.Max(0, amount)); Changed?.Invoke(Current, Maximum); }
    }
}
