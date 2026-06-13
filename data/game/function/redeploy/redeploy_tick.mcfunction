scoreboard players remove @a[scores={redeploy_ctd=1..}] redeploy_ctd 1
execute as @a[scores={redeploy_ctd=80}] at @s run title @s title {"text":"4","color":"gold","bold":true}
execute as @a[scores={redeploy_ctd=60}] at @s run title @s title {"text":"3","color":"gold","bold":true}
execute as @a[scores={redeploy_ctd=40}] at @s run title @s title {"text":"2","color":"gold","bold":true}
execute as @a[scores={redeploy_ctd=20}] at @s run title @s title {"text":"1","color":"gold","bold":true}
execute as @a[scores={redeploy_ctd=0},team=attacker] at @s run tp @s -265.43 109.00 -30.04
execute as @a[scores={redeploy_ctd=0},team=defender] at @s run tp @s -633.99 114.00 -24.56
execute as @a[scores={redeploy_ctd=0}] at @s run tag @s add yes_start_1
execute as @a[scores={redeploy_ctd=0},tag=assault] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute as @a[scores={redeploy_ctd=0},tag=assault] run title @s subtitle {"translate":"profession.assault","color":"red"}
execute as @a[scores={redeploy_ctd=0},tag=scout] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute as @a[scores={redeploy_ctd=0},tag=scout] run title @s subtitle {"translate":"profession.scout","color":"aqua"}
execute as @a[scores={redeploy_ctd=0},tag=medic] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute as @a[scores={redeploy_ctd=0},tag=medic] run title @s subtitle {"translate":"profession.medic","color":"green"}
execute as @a[scores={redeploy_ctd=0},tag=support] run title @s title {"translate":"game.profession.title","with":[{"selector":"@s"}]}
execute as @a[scores={redeploy_ctd=0},tag=support] run title @s subtitle {"translate":"profession.support","color":"gold"}
execute as @a[scores={redeploy_ctd=0}] run scoreboard players set @s redeploy_ctd -1
