execute as @e[type=interaction,tag=attacker_redeploy] at @s on target if score state game_state matches 1 if entity @s[tag=!no_job] run function game:redeploy/redeploy_click
execute as @e[type=interaction,tag=attacker_redeploy] at @s on target if score state game_state matches 1 if entity @s[tag=no_job] run function game:redeploy/no_job
execute as @e[type=interaction,tag=attacker_redeploy] if data entity @s interaction run data remove entity @s interaction
execute as @e[type=interaction,tag=defender_redeploy] at @s on target if score state game_state matches 1 if entity @s[tag=!no_job] run function game:redeploy/redeploy_click
execute as @e[type=interaction,tag=defender_redeploy] at @s on target if score state game_state matches 1 if entity @s[tag=no_job] run function game:redeploy/no_job
execute as @e[type=interaction,tag=defender_redeploy] if data entity @s interaction run data remove entity @s interaction
