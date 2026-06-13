# 锁 team_selector 到 hotbar.0
clear @a kubejs:team_selector
execute if score state game_state matches 0 as @a run item replace entity @s hotbar.0 with kubejs:team_selector
execute if score state game_state matches 1 as @a[team=unselected] run item replace entity @s hotbar.0 with kubejs:team_selector
kill @e[type=item,nbt={Item:{id:"kubejs:team_selector"}}]

# 锁 profession_selector 到 hotbar.0
clear @a kubejs:profession_selector
execute if score state game_state matches 1 as @a[team=!unselected,team=!spectator,tag=!yes_start_1] run item replace entity @s hotbar.0 with kubejs:profession_selector
kill @e[type=item,nbt={Item:{id:"kubejs:profession_selector"}}]