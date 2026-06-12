execute if score state game_state matches 0 if score CTD game_start_ctd matches 140 run function game:sounds/exp_orb_pickup
execute if score state game_state matches 0 if score CTD game_start_ctd matches 140 run title @a title {"translate":"game.start.title","color":"red","bold":true}
execute if score state game_state matches 0 if score CTD game_start_ctd matches 140 run title @a subtitle {"translate":"game.start.subtitle","color":"gray","italic":true,"bold":true}
execute if score CTD game_start_ctd matches 120 run function game:sounds/click_button
execute if score CTD game_start_ctd matches 120 run title @a title {"text":"5","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 100 run function game:sounds/click_button
execute if score CTD game_start_ctd matches 100 run title @a title {"text":"4","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 80 run function game:sounds/click_button
execute if score CTD game_start_ctd matches 80 run title @a title {"text":"3","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 60 run function game:sounds/click_button
execute if score CTD game_start_ctd matches 60 run title @a title {"text":"2","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 40 run function game:sounds/click_button
execute if score CTD game_start_ctd matches 40 run title @a title {"text":"1","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 20 run scoreboard players set state game_state 1
execute if score CTD game_start_ctd matches 20 run execute as @a[team=attacker] at @s run tp @s -1481.33 200.00 1874.86
execute if score CTD game_start_ctd matches 20 run spawnpoint @a[team=attacker] -1481 200 1874
execute if score CTD game_start_ctd matches 20 run execute as @a[team=defender] at @s run tp @s -1485.70 199.00 1911.36
execute if score CTD game_start_ctd matches 20 run spawnpoint @a[team=defender] -1485 200 1911
execute if score CTD game_start_ctd matches 20 run execute as @a[team=spectator] at @s run tp @s -229.47 106.00 -32.37
execute if score CTD game_start_ctd matches 20 run function game:sounds/levelup
execute if score CTD game_start_ctd matches 20 run title @a title {"translate":"game.choose_profession.title","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 20 run title @a subtitle {"translate":"game.choose_profession.subtitle","color":"yellow","italic":true,"bold":true}
execute if score CTD game_start_ctd matches 20 run clear @a[team=!spectator,team=!unselected]
execute if score CTD game_start_ctd matches 20 run give @a[team=!spectator,team=!unselected] kubejs:profession_selector
execute if score CTD game_start_ctd matches 0..20 run scoreboard players reset CTD game_start_ctd