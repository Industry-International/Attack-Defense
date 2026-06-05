execute as @e[type=interaction,tag=join_spectator] at @s on target run team join spectator @s
execute as @e[type=interaction,tag=join_spectator] at @s on target run function lobby:sounds/xp
execute as @e[type=interaction,tag=join_spectator] at @s on target run tellraw @s {"text":"你已加入观战方！","color":"gray"}
execute as @e[type=interaction,tag=join_spectator] if data entity @s interaction run data remove entity @s interaction