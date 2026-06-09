execute if score CTD game_start_ctd < 140 game_start_ctd run scoreboard players add CTD game_start_ctd 1
execute if score CTD game_start_ctd < 140 game_start_ctd run function game:scoreboard/game_start_ctd
execute if score CTD game_start_ctd >= 140 game_start_ctd run scoreboard players reset CTD game_start_ctd