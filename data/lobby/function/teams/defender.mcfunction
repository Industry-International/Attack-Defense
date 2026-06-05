execute as @e[type=interaction,tag=join_defender] at @s on target run team join defender @s
execute as @e[type=interaction,tag=join_defender] at @s on target run function lobby:sounds/xp
execute as @e[type=interaction,tag=join_defender] at @s on target run tellraw @s {"text":"你已加入防守方！","color":"blue"}
execute as @e[type=interaction,tag=join_defender] if data entity @s interaction run data remove entity @s interaction