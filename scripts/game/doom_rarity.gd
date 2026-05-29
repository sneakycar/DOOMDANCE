extends Node
## Weighted realism — 85% ordinary, 14% uncommon, 1% legendary.

enum Tier { ORDINARY, UNCOMMON, LEGENDARY }

const P_ORDINARY := 0.85
const P_UNCOMMON := 0.14
const P_LEGENDARY := 0.01

func roll_tier() -> Tier:
	var r := randf()
	if r < P_ORDINARY:
		return Tier.ORDINARY
	if r < P_ORDINARY + P_UNCOMMON:
		return Tier.UNCOMMON
	return Tier.LEGENDARY

func tier_name(tier: Tier) -> String:
	match tier:
		Tier.ORDINARY:
			return "ordinary"
		Tier.UNCOMMON:
			return "uncommon"
		Tier.LEGENDARY:
			return "legendary"
		_:
			return "ordinary"
