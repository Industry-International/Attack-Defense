data merge entity @e[type=interaction,tag=start_button,limit=1] {response:1b}
execute as @e[type=interaction,tag=start_button] at @s on target run function game:game/start_button_l
execute as @e[type=interaction,tag=start_button] if data entity @s interaction run data remove entity @s interaction