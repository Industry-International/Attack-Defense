scoreboard players set state game_state 0
clear @a
team leave @a
team remove attacker
team remove defender
team remove spectator
team remove unselected
function game:teams/load_team_settings