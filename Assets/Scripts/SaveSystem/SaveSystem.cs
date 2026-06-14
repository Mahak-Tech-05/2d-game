using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using TheLastYodha.Core;

namespace TheLastYodha.SaveSystem
{
    [Serializable] public sealed class SaveGame { public int Version=1; public DateTime SavedAtUtc=DateTime.UtcNow; public Dictionary<string, JsonElement> Systems=new Dictionary<string, JsonElement>(); }
    public sealed class SaveManager
    {
        readonly List<ISaveable> _saveables=new List<ISaveable>();
        public void Register(ISaveable saveable){ if(!_saveables.Contains(saveable)) _saveables.Add(saveable); }
        public void Save(string path){ var doc=new Dictionary<string,object>(); foreach(var s in _saveables) doc[s.SaveKey]=s.CaptureState(); File.WriteAllText(path,JsonSerializer.Serialize(doc,new JsonSerializerOptions{WriteIndented=true})); }
        public Dictionary<string,JsonElement> LoadRaw(string path){ if(!File.Exists(path)) return new Dictionary<string,JsonElement>(); return JsonSerializer.Deserialize<Dictionary<string,JsonElement>>(File.ReadAllText(path)); }
    }
}
