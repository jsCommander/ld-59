# Product Guide: Restoration Protocol

## Vision

An incremental roguelite about stubborn robots planting on a frozen planet. Not idle — every second costs energy. Session length is the scoreboard.

## Target Audience

The strategist-optimizer who wants their brain to boil but also wants to feel something. Factorio spreadsheet builders who secretly care about the lore. Cookie Clicker prestige grinders who stay for the story.

## Platform

- **Primary:** Web (itch.io)
- **Secondary:** Android (APK)

## Core Experience

A ticking bomb with flowers growing on it. The player manages a fragile biofuel economy under mounting pressure from a gradually escalating ice storm. Every run is active — dozens of resource allocation decisions, no "set and forget."

## Genre

Incremental roguelite. Side-scrolling view (terrarium cross-section). Resolution: 1920x1080 (16:9).

## Core Loop

1. Drill punches through ice from below, thaws 4 slots
2. Fill slots: plants (income), robots (logistics), labs (meta-progression)
3. Plants grow fruits → robots collect → drill converts to biofuel
4. Expand by deploying additional drills (exponential cost)
5. Storm ramps up, multiplying energy drain
6. Biofuel hits zero → collapse → prestige reset
7. Permanent plant upgrades (DNA) carry over → repeat stronger

## Economy — One Resource Rules All

**Biofuel** — produced by the drill from plant fruits. Everything consumes it:

| Drain | Purpose | Tension |
|-------|---------|---------|
| Generator upkeep | Keep drills running, slots thawed | If this wins, you die |
| Building upgrades | More power, but higher upkeep | Tightens economy |
| Lab research | DNA points for permanent upgrades | Starves current run |

## Buildings

| Building | Output | Role |
|----------|--------|------|
| Plant | Fruits | Only source of income |
| Robot Platform | Collector unit | Carries fruits to drills |
| Drill/Generator | Biofuel + heat + 4 new slots | Core economy |
| Laboratory | DNA points | Meta-progression (pure drain) |

## Session Shape

- Bad run: dies at minute 3
- Good run: reaches minute 10
- Masterful run: pushes past 15-20 minutes
- Theoretical ceiling rises with each DNA unlock

## Storm Escalation

| Phase | Time | Drain Multiplier | Feel |
|-------|------|-------------------|------|
| Calm | 0-3 min | x1.0 | Economy breathes easy |
| Rising | 3-7 min | up to x2.0 | Marginal builds bleed |
| Peak | 7-12 min | x4.0+ | Only optimized layouts survive |
| Brutal | 12+ min | No cap | Even perfect economies buckle |

## Meta-Progression

- **Within run (temporary):** Building upgrades — more power, more upkeep. Lost on death
- **Between runs (permanent):** DNA points → new plant species, plant perks (faster growth, frost resistance, richer yields)

## Art Style

Neon outlines on pure black. No fills. The line carries emotion:
- Trembling, broken lines → fragility
- Rough, jagged lines → worn-out robots
- Bold, pulsing lines → life, plants
- Chaotic slashes → storm

## Emotional Core

Not a story about hope. A story about stubbornness — mechanical, programmed, irrational stubbornness against an indifferent universe. The robots are us: grinding through cycles, building from ashes, unable to stop trying.

## Success Metrics

- Player feels "one more run" pull
- Economy decisions feel meaningful (no obviously correct path)
- Storm creates genuine tension, not just a timer
- Visual style is memorable and emotionally resonant
