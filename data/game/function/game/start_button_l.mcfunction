execute if score CTD game_start_ctd = 20 game_start_ctd run function game:sounds/exp_orb_pickup
execute if score CTD game_start_ctd = 20 game_start_ctd run title @a title {"translate":"game.start.title","color":"red","bold":true}
execute if score CTD game_start_ctd = 20 game_start_ctd run title @a subtitle {"translate":"game.start.subtitle","color":"gray","italic":true,"bold":true}
execute if score CTD game_start_ctd = 40 game_start_ctd run function game:sounds/click_button
execute if score CTD game_start_ctd = 40 game_start_ctd run title @a title {"text":"5","color":"gold","bold":true}
execute if score CTD game_start_ctd = 60 game_start_ctd run title @a title {"text":"4","color":"gold","bold":true}
execute if score CTD game_start_ctd = 80 game_start_ctd run title @a title {"text":"3","color":"gold","bold":true}
execute if score CTD game_start_ctd = 100 game_start_ctd run title @a title {"text":"2","color":"gold","bold":true}
execute if score CTD game_start_ctd = 120 game_start_ctd run title @a title {"text":"1","color":"gold","bold":true}
execute if score CTD game_start_ctd = 140 game_start_ctd run scoreboard players set state game_state 1
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[team=attacker] at @s run tp @s 0 0 0
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[team=defender] at @s run tp @s 0 0 0
execute if score CTD game_start_ctd = 140 game_start_ctd at @a run function game:sounds/levelup
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=assault] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=assault] run title @s subtitle {"translate":"profession.assault","color":"red"}
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=scout] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=scout] run title @s subtitle {"translate":"profession.scout","color":"aqua"}
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=medic] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=medic] run title @s subtitle {"translate":"profession.medic","color":"green"}
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=support] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute if score CTD game_start_ctd = 140 game_start_ctd run execute as @a[tag=support] run title @s subtitle {"translate":"profession.support","color":"gold"}
