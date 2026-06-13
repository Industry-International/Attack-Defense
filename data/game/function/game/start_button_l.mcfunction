execute if score state game_state matches 0 if score CTD game_start_ctd matches 140 as @a at @s run function game:sounds/exp_orb_pickup
execute if score state game_state matches 0 if score CTD game_start_ctd matches 140 run title @a title {"translate":"game.start.title","color":"red","bold":true}
execute if score state game_state matches 0 if score CTD game_start_ctd matches 140 run title @a subtitle {"translate":"game.start.subtitle","color":"gray","italic":true,"bold":true}
execute if score CTD game_start_ctd matches 120 as @a at @s run function game:sounds/click_button
execute if score CTD game_start_ctd matches 120 run title @a title {"text":"5","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 100 as @a at @s run function game:sounds/click_button
execute if score CTD game_start_ctd matches 100 run title @a title {"text":"4","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 80 as @a at @s run function game:sounds/click_button
execute if score CTD game_start_ctd matches 80 run title @a title {"text":"3","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 60 as @a at @s run function game:sounds/click_button
execute if score CTD game_start_ctd matches 60 run title @a title {"text":"2","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 40 as @a at @s run function game:sounds/click_button
execute if score CTD game_start_ctd matches 40 run title @a title {"text":"1","color":"gold","bold":true}
execute if score CTD game_start_ctd matches 20 run function game:game/20