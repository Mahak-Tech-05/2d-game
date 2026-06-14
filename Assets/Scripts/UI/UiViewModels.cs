using System;
using TheLastYodha.Player;
using TheLastYodha.Combat;

namespace TheLastYodha.UI
{
    public sealed class HudViewModel
    {
        readonly PlayerProfile _player; public HudViewModel(PlayerProfile player){_player=player;}
        public string HealthText=>$"{_player.Health.Current}/{_player.Health.Maximum}"; public string EnergyText=>$"{_player.Energy.Current}/{_player.Energy.Maximum}"; public string ManaText=>$"{_player.Mana.Current}/{_player.Mana.Maximum}"; public string GoldText=>_player.Gold.ToString();
    }
    public sealed class CombatViewModel { readonly CombatManager _combat; public CombatViewModel(CombatManager combat){_combat=combat;} public bool IsPlayerTurn=>_combat.State.Phase==CombatPhase.PlayerTurn; public int EnemyCount=>_combat.State.Enemies.Count; }
}
