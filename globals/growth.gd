class_name Growth

# --- Public ---

## Linear growth: base + step * (n - 1)
## When to use: early prototype, when you don't want to bother balancing.
## Feel: predictable, boring. The further you go, the less it's felt
## (100 -> 200 hurts, 1000 -> 1100 nobody cares).
## Players stop feeling progression by mid-game.
static func linear(n: int, base: float, step: float) -> float:
	var clamped: int = maxi(n, 1)
	return base + step * (clamped - 1)


## Power growth: base * n^exponent
## When to use: main curve for idle/clickers, mob HP, upgrade costs.
## Feel: each next level is noticeably harder than the previous one,
## but without shock. Player sees they need to grind, but doesn't hit a wall.
## Picking exponent:
##   1.3 — soft, almost-linear with light acceleration
##   1.5 — sweet spot for HP/damage (Cookie Clicker, Diablo)
##   2.0 — quadratic, already harsh (for late-game scaling)
##   2.5+ — close to exponential, breaks balance without a cap
static func power(n: int, base: float, exponent: float) -> float:
	var clamped: int = maxi(n, 1)
	return base * pow(float(clamped), exponent)


## Exponential: base * multiplier^(n - 1)
## When to use: prestige costs, late levels, anywhere you need a wall.
## Feel: first levels are almost free, then suddenly into orbit.
## Picking multiplier:
##   1.07 — soft (Cookie Clicker building costs)
##   1.15 — standard for idle upgrades
##   1.5+ — hard wall, used for prestige/reroll
## Dangerous without a cap — by level 50 numbers fly to the moon.
static func exponential(n: int, base: float, multiplier: float) -> float:
	var clamped: int = maxi(n, 1)
	return base * pow(multiplier, clamped - 1)


## Logarithmic: base + scale * log(n)
## When to use: diminishing returns, stack bonuses, XP for repeated actions.
## Feel: first levels give a lot, then almost nothing.
## Player feels they "squeezed out the maximum", further grinding is pointless.
static func logarithmic(n: int, base: float, scale: float) -> float:
	var clamped: int = maxi(n, 1)
	return base + scale * log(float(clamped))


## Sigmoid: smooth S-shaped transition from base to base + range
## When to use: chances (crit, drop), efficiency that needs a cap.
## Feel: slow start, sharp rise in the middle, plateau at the end.
## Player sees a clear threshold "this is where it kicks in" and a clear ceiling.
## midpoint — level at which half of range is reached.
## steepness — sharpness of the transition (0.5 = smooth, 2.0 = sharp).
static func sigmoid(n: int, base: float, range_value: float, midpoint: float, steepness: float = 1.0) -> float:
	var x: float = steepness * (float(n) - midpoint)
	return base + range_value / (1.0 + exp(-x))
