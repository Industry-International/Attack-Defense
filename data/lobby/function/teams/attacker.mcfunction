execute as @e[type=interaction,tag=join_attacker] at @s on target run team join attacker @s
execute as @e[type=interaction,tag=join_attacker] at @s on target run function lobby:sounds/xp
execute as @e[type=interaction,tag=join_attacker] at @s on target run tellraw @s {"text":"你已加入进攻方！","color":"red"}
execute as @e[type=interaction,tag=join_attacker] if data entity @s interaction run data remove entity @s interaction