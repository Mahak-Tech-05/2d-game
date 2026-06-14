using System;
using System.Collections.Generic;
using TheLastYodha.Core;

namespace TheLastYodha.Inventory
{
    public enum ItemType { Consumable, Weapon, Armor, Trinket, Quest }
    [Serializable] public sealed class ItemDefinition : IIdentifiable { public string Id{get;set;} public string Name{get;set;} public ItemType Type; public Rarity Rarity; public int GoldValue; public List<StatModifier> Modifiers=new List<StatModifier>(); }
    [Serializable] public sealed class ItemStack { public ItemDefinition Item; public int Quantity; public ItemStack(ItemDefinition item,int quantity){Item=item;Quantity=quantity;} }
    [Serializable]
    public sealed class InventoryModel
    {
        public int Capacity { get; }
        public IReadOnlyList<ItemStack> Items => _items;
        private readonly List<ItemStack> _items = new List<ItemStack>();
        public InventoryModel(int capacity){Capacity=Math.Max(1,capacity);}
        public bool Add(ItemDefinition item,int quantity=1){ if(item==null||quantity<=0||_items.Count>=Capacity) return false; var stack=_items.Find(s=>s.Item.Id==item.Id); if(stack!=null) stack.Quantity+=quantity; else _items.Add(new ItemStack(item,quantity)); return true; }
        public bool Remove(string itemId,int quantity=1){ var s=_items.Find(x=>x.Item.Id==itemId); if(s==null||s.Quantity<quantity) return false; s.Quantity-=quantity; if(s.Quantity==0)_items.Remove(s); return true; }
    }
}
