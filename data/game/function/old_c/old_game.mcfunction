scoreboard players set state game_state 0
clear @a
team leave @a
team remove attacker
team remove defender
team remove spectator
team remove unselected
function game:teams/load_team_settings
setworldspawn -1462 197 1835 0.0
spawnpoint @a -1462 197 1835