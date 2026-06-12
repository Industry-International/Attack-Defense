execute if score CTD game_start_ctd matches 1.. run scoreboard players remove CTD game_start_ctd 1
execute if score CTD game_start_ctd = 140 game_start_ctd run function game:sounds/exp_orb_pickup
execute if score CTD game_start_ctd = 140 game_start_ctd run title @a title {"translate":"game.start.title","color":"red","bold":true}
execute if score CTD game_start_ctd = 140 game_start_ctd run title @a subtitle {"translate":"game.start.subtitle","color":"gray","italic":true,"bold":true}
execute if score CTD game_start_ctd = 120 game_start_ctd run function game:sounds/click_button
execute if score CTD game_start_ctd = 120 game_start_ctd run title @a title {"text":"5","color":"gold","bold":true}
execute if score CTD game_start_ctd = 100 game_start_ctd run title @a title {"text":"4","color":"gold","bold":true}
execute if score CTD game_start_ctd = 80 game_start_ctd run title @a title {"text":"3","color":"gold","bold":true}
execute if score CTD game_start_ctd = 60 game_start_ctd run title @a title {"text":"2","color":"gold","bold":true}
execute if score CTD game_start_ctd = 40 game_start_ctd run title @a title {"text":"1","color":"gold","bold":true}
execute if score CTD game_start_ctd = 20 game_start_ctd run scoreboard players set state game_state 1
execute if score CTD game_start_ctd = 20 game_start_ctd run execute as @a[team=attacker] at @s run tp @s -1481.33 200.00 1874.86
spawnpoint @a[team=attacker] -1481 200 1874
execute if score CTD game_start_ctd = 20 game_start_ctd run execute as @a[team=defender] at @s run tp @s -1485.70 199.00 1911.36
spawnpoint @a[team=defender] -1485 200 1911
execute if score CTD game_start_ctd = 20 game_start_ctd run execute as @a[team=spectator] at @s run tp @s -229.47 106.00 -32.37
execute if score CTD game_start_ctd = 20 game_start_ctd at @a run function game:sounds/levelup
execute if score CTD game_start_ctd = 20 game_start_ctd run title @a title {"translate":"game.choose_profession.title","color":"gold","bold":true}
execute if score CTD game_start_ctd = 20 game_start_ctd run title @a subtitle {"translate":"game.choose_profession.subtitle","color":"yellow","italic":true,"bold":true}
execute if score CTD game_start_ctd = 20 game_start_ctd run give @a[team=!spectator,team=!unselected] kubejs:profession_selector
execute if score CTD game_start_ctd >= 20 game_start_ctd run scoreboard players reset CTD game_start_ctd