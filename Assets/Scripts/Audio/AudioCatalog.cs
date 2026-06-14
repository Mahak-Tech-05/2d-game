using System.Collections.Generic;

namespace TheLastYodha.Audio
{
    public enum AudioCue { MenuTheme, TowerAmbience, CombatTheme, BossTheme, CardPlay, SwordHit, Reward }
    public sealed class AudioCatalog { readonly Dictionary<AudioCue,string> _paths=new Dictionary<AudioCue,string>(); public void Register(AudioCue cue,string resourcePath)=>_paths[cue]=resourcePath; public bool TryGet(AudioCue cue,out string path)=>_paths.TryGetValue(cue,out path); }
}
