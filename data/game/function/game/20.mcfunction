scoreboard players set state game_state 1
execute as @a[team=attacker] at @s run tp @s -1481.33 200.00 1874.86
spawnpoint @a[team=attacker] -1481 200 1874
execute as @a[team=defender] at @s run tp @s -1485.70 199.00 1911.36
spawnpoint @a[team=defender] -1485 200 1911
execute as @a[team=spectator] at @s run tp @s -229.47 106.00 -32.37
execute as @a[team=!unselected] at @s run function game:sounds/levelup
title @a[team=!unselected] title {"translate":"game.choose_profession.title","color":"gold","bold":true}
title @a[team=!unselected] subtitle {"translate":"game.choose_profession.subtitle","color":"yellow","italic":true,"bold":true}
clear @a[team=!spectator,team=!unselected]
kubejsadmin profession @a
module team on
module team_revive on
sbw_vehicle stop
sbw_vehicle clear
sbw_vehicle start
spawn_selector visible attacker attacker
spawn_selector visible defender defender
spawn_selector visible A1 defender
spawn_selector visible B1 defender
spawn_selector visible B2 defender
spawn_selector visible B3 defender
spawn_selector visible C1 defender
spawn_selector visible C2 defender
give @a[team=!spectator,team=!unselected] kubejs:profession_selector
scoreboard players reset CTD game_start_ctd