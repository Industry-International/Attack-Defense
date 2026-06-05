# 进攻方和防守方

team add attacker "进攻方"
team add defender "防守方"
team modify attacker color red
team modify defender color blue
team modify attacker friendlyFire false
team modify defender friendlyFire false
team modify attacker seeFriendlyInvisibles true
team modify defender seeFriendlyInvisibles true
team modify attacker nametagVisibility hideForOtherTeams
team modify defender nametagVisibility hideForOtherTeams
team modify attacker collisionRule pushOwnTeam
team modify defender collisionRule pushOwnTeam
team modify attacker prefix "§c[进攻方] "
team modify defender prefix "§9[防守方] "

# 未选择队伍

team add unselected "未选择队伍"
team modify unselected color white
team modify unselected collisionRule pushOwnTeam
team modify unselected prefix "§7[未选择队伍] "

# 观战队伍

team add spectator "观战"
team modify spectator color gray
team modify spectator collisionRule never
team modify spectator prefix "§8[观战] "