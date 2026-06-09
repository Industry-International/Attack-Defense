execute if score state game_state = 0 game_state run title @a[team=attacker] actionbar {"translate":"team.attacker.name","color":"red","bold":true}
execute if score state game_state = 0 game_state run title @a[team=defender] actionbar {"translate":"team.defender.name","color":"blue","bold":true}
execute if score state game_state = 0 game_state run title @a[team=unselected] actionbar {"translate":"team.unselected.name","color":"white"}
execute if score state game_state = 0 game_state run title @a[team=spectator] actionbar {"translate":"team.spectator.name","color":"gray"}
