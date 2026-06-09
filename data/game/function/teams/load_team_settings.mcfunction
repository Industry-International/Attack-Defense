# 进攻方和防守方

team add attacker {"translate":"team.attacker.name"}
team add defender {"translate":"team.defender.name"}
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
team modify attacker prefix {"translate":"team.attacker.prefix"}
team modify defender prefix {"translate":"team.defender.prefix"}

# 未选择队伍

team add unselected {"translate":"team.unselected.name"}
team modify unselected color white
team modify unselected collisionRule pushOwnTeam
team modify unselected prefix {"translate":"team.unselected.prefix"}

# 观战队伍

team add spectator {"translate":"team.spectator.name"}
team modify spectator color gray
team modify spectator collisionRule never
team modify spectator prefix {"translate":"team.spectator.prefix"}