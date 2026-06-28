tellraw @a[team=!unselected] {"translate":"capture.C.Occupied","color":"red"}
team_revive add 100
function game:capture/c/c1
function game:capture/c/c2
scoreboard players set Cyes temp 1
function game:game/attacker_victory