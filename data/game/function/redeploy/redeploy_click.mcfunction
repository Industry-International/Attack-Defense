execute unless score @s redeploy_ctd matches 1.. run scoreboard players set @s redeploy_ctd 100
execute if score @s redeploy_ctd matches 100 run title @s title {"text":"5","color":"gold","bold":true}
