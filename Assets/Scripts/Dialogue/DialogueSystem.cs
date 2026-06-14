using System;
using System.Collections.Generic;

namespace TheLastYodha.Dialogue
{
    [Serializable] public sealed class DialogueChoice { public string Text; public string NextNodeId; public string RequiredFlag; public string SetFlag; }
    [Serializable] public sealed class DialogueNode { public string Id; public string Speaker; public string Text; public List<DialogueChoice> Choices=new List<DialogueChoice>(); }
    public sealed class DialogueManager
    {
        readonly Dictionary<string,DialogueNode> _nodes=new Dictionary<string,DialogueNode>(); readonly HashSet<string> _flags=new HashSet<string>();
        public DialogueNode Current { get; private set; }
        public void Load(IEnumerable<DialogueNode> nodes){ foreach(var n in nodes) _nodes[n.Id]=n; }
        public bool Start(string id){ if(!_nodes.TryGetValue(id,out var node)) return false; Current=node; return true; }
        public bool Choose(int index){ if(Current==null||index<0||index>=Current.Choices.Count)return false; var c=Current.Choices[index]; if(!string.IsNullOrEmpty(c.RequiredFlag)&&!_flags.Contains(c.RequiredFlag))return false; if(!string.IsNullOrEmpty(c.SetFlag))_flags.Add(c.SetFlag); return Start(c.NextNodeId); }
    }
}
