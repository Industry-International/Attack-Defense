execute at @s run tp @s[team=attacker] -1481.33 200.00 1874.86
execute at @s run tp @s[team=spectator] -229.47 106.00 -32.37
execute at @s run tp @s[team=defender] -1485.70 199.00 1911.36
execute at @s run title @s title {"text":"你未选择队伍","color":"gold","bold":true}
execute at @s run clear @s[team=!unselected]
execute at @s run spawnpoint @s[team=defender] -1485 200 1911
execute at @s run spawnpoint @s[team=attacker] -1481 200 1874