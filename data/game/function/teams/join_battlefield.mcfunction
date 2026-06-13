tp @s[team=attacker] -1481.33 200.00 1874.86
tp @s[team=spectator] -229.47 106.00 -32.37
tp @s[team=defender] -1485.70 199.00 1911.36
title @s[team=unselected] title {"text":"你未选择队伍","color":"gold","bold":true}
spawnpoint @s[team=defender] -1485 200 1911
spawnpoint @s[team=attacker] -1481 200 1874
give @s[team=!spectator,team=!unselected] kubejs:profession_selector