using System;
using System.Collections.Generic;
using TheLastYodha.Core;

namespace TheLastYodha.Map
{
    [Serializable] public sealed class TowerRoom { public int Floor; public int Column; public RoomType Type; public List<TowerRoom> Next=new List<TowerRoom>(); }
    public sealed class TowerMapGenerator
    {
        readonly Random _rng; public TowerMapGenerator(int seed){_rng=new Random(seed);}
        public List<TowerRoom> Generate(int floors=16,int width=5)
        {
            var rooms=new List<TowerRoom>();
            for(int f=1;f<=floors;f++) for(int c=0;c<width;c++) rooms.Add(new TowerRoom{Floor=f,Column=c,Type=PickType(f,floors)});
            foreach(var r in rooms){ if(r.Floor==floors) continue; foreach(var n in rooms.FindAll(x=>x.Floor==r.Floor+1 && Math.Abs(x.Column-r.Column)<=1)) if(_rng.NextDouble()<0.45) r.Next.Add(n); if(r.Next.Count==0) r.Next.Add(rooms.Find(x=>x.Floor==r.Floor+1&&x.Column==r.Column)); }
            return rooms;
        }
        RoomType PickType(int floor,int max){ if(floor==max) return RoomType.Boss; double v=_rng.NextDouble(); if(floor%5==0)return RoomType.Elite; if(v<.55)return RoomType.Combat; if(v<.68)return RoomType.Treasure; if(v<.78)return RoomType.Story; if(v<.88)return RoomType.Merchant; if(v<.96)return RoomType.Rest; return RoomType.Secret; }
    }
}
