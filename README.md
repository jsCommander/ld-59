# Restoration Protocol

## Elevator Pitch

Frozen planet. Dead world. A drill punches through the ice from below — robots wake up and start planting. They have an energy reserve that ticks down every second. When it hits zero — generators die, ice reclaims everything, robots burrow back underground. Then they drill up again and start over. Every time — a little smarter, a little tougher, with better seeds.

**Genre:** Incremental roguelite. Not idle — every second costs energy. No fixed timer — your economy decides how long you survive.

**The hook:** One resource — biofuel, refined from plant fruits. Generators eat it to stay alive. Labs eat it to earn DNA points for permanent plant upgrades. Building upgrades eat it to get stronger now but hungrier later. Every thawed slot is a choice: more plants to feed the machine, a robot to haul fruits faster, or a lab bleeding your economy dry for long-term gain. The storm ramps up gradually, multiplying energy drain until your economy buckles. A bad run lasts 3 minutes. A masterful one — 20.

**The feel:** Factorio's "one more optimization" loop meets the emotional weight of a robot with a half-broken arm reaching for a new seed. The world doesn't care about your plans. You plant anyway.

**Visual style:** Neon outlines on pure black. No fills. The line itself carries emotion — trembling for fragility, jagged for decay, bold and pulsing for life. The storm dissolves all structure into abstract chaos. After the storm: silence, and one thin arc of a new sprout.

## Concept

### What It's About

The world is falling apart, and you want to do something about it — but you don't know what. You want control back. You want to feel like your understanding of the world isn't complete garbage.

This game is that feeling, distilled into a loop that lasts as long as your energy holds. You don't fix the world. You don't beat the storm. You just keep planting — because the protocol says so, because the alternative is nothing, and because maybe, just maybe, this next cycle will be the one where the roots hold.

### How It Plays

Not an idle game. Nothing works while you sleep. Every session is an active run where the player makes dozens of resource allocation decisions under mounting pressure. There is no fixed timer — the session lasts exactly as long as the player's economy can produce biofuel faster than it drains. When biofuel hits zero, the drill dies, ice floods back, robots burrow underground. That's the forced prestige: total wipe, permanent plant upgrades carry over.

The ice storm is not a sudden kill switch. It's a gradual escalation — wind picks up, temperature drops, energy drain on generators climbs. The storm *squeezes* the economy until it collapses. A poorly managed run dies in 3 minutes. A well-oiled machine can hold out for 20. Session length is the scoreboard.

Early runs: desperately nursing one plant in four slots, watching the biofuel bar bleed out. Late runs: orchestrating a sprawling network of drills, specialized crops, robot fleets and labs — fighting to stay ahead of the storm's ever-growing appetite. The game you play on run 50 is qualitatively different from run 1.

Plants grow on their own. Robots collect fruits automatically. But the player is constantly making active decisions — where to expand, what to build, when to upgrade, whether to run a lab. There is no "set and forget." Every second costs biofuel.

### Who It's For

The strategist-optimizer who wants their brain to boil, but also wants to *feel* something. The player who builds spreadsheet-optimal layouts in Factorio and then stays up too late watching their factory hum. The one who optimizes prestige runs in Cookie Clicker but secretly cares about the lore.

Not a digital aquarium. A ticking bomb with flowers growing on it.

### Setting

A frozen planet. Abandoned robots reactivate under a restoration program. Their mission: grow plants, restore nature. They don't understand why. They just execute the protocol — over and over, session after session, storm after storm.

The ice is not a passive backdrop. It's an active, indifferent force that reclaims everything the moment the heat dies. The robots are not heroes. They're machines following instructions written by someone who is probably long dead. And the plants — the plants are the only real actors in this story. They grow because that's what life does.

### Metaphor

This isn't a story about hope. It's a story about stubbornness — mechanical, programmed, irrational stubbornness against the indifferent universe. Hope that doesn't die, not because it's brave, but because it's hard-coded into the restoration protocol.

The robots are us: grinding through cycles, building from the ashes of past failures, unable to stop trying even when the odds are cosmically unfair. The biofuel split mirrors a real tension: burn everything to survive today, or starve yourself feeding the lab so that future generations of plants are stronger. Sacrifice the present for a future you may never see.

The ice storm is not the villain. It's the universe doing what it does. The question the game asks is not "can you win?" but "what do you build from the wreckage, knowing the wreckage is coming again?"

## View & Screen Layout

Side-scrolling view. The camera looks at the world from the side — like a terrarium cross-section. The surface is a horizontal strip; plants grow upward, roots go down, ice presses in from the edges.

**Resolution:** 1920×1080 (16:9).

**Screen split:**
- **Top ~60%** — the game world. Scrollable horizontally. Shows the frozen surface, thawed slots with plants and buildings, robots moving between them, the drill below. The storm visual effects play here
- **Bottom ~40%** — persistent UI panel. Building cards (showing stats, upgrade costs, production), resource bar (biofuel amount, drain rate), DNA counter, storm intensity indicator. Does not scroll with the world

The player sees everything from the side: drill punches up through ice at the bottom of the game area, slots open left and right along the surface, plants grow upward, robots walk along the ground carrying fruits.

## Art Style

Neon outlines on pure black. No fills. The line itself carries all emotion and information.

**Line as expression:**
- **Trembling, broken lines** — fragility, the world barely holding together. Ice cracks rendered as interrupted strokes with gaps that scream emptiness
- **Rough, jagged lines with scratches and dents** — the worn-out robots. A bolt drawn as an incomplete circle. A body contour that breaks and resumes with an offset
- **Bold, confident, pulsing lines** — life. Plant stems that reach upward. Leaves that unfurl like open palms. Flower contours with tiny serrations — life beating from within. These lines are thicker and brighter than everything else on screen
- **Chaotic, overlapping slashes** — the storm. Ghost-lines (pale shifted echoes) appear as the storm approaches. Plant contours gain counter-directional hatching as wind tears at them. At peak storm: no contours at all, just short directionless dashes flying across the screen

**Storm escalation changes line behavior:**
1. **Calm** — clean, distinct outlines. Warm neon colors pulse gently. Energy drain is low
2. **Storm rising** — lines start doubling, trembling. Colors desaturate at screen edges. Energy drain accelerates
3. **Storm peak** — all structure dissolves into abstract monochrome chaos. Energy drain is brutal — only the strongest economies survive here
4. **Collapse** — energy hits zero. Generators flicker and die. Neon fades out, line by line. The screen goes dark. Then: silence, a drill sound from below, and a new run begins

## Core Loop

1. **Drill up** — The drill bores through the frozen surface from below. It's your first generator: it thaws 4 adjacent slots and starts processing fruits into biofuel. Biofuel reserve starts ticking down
2. **Plant and build** — Fill thawed slots with plants, robot platforms, or a lab. Plants grow fruits; robots collect them and carry to the drill; the drill converts fruits into biofuel to keep itself running
3. **Expand** — Spend biofuel to deploy additional drills. Each new drill thaws 4 more slots but demands exponentially more biofuel to operate. New slots need plants and robots before they produce anything
4. **Upgrade** — Spend biofuel to upgrade buildings in-place. More power, but higher upkeep. Every upgrade tightens the economy
5. **Survive** — The storm ramps up gradually, multiplying generator drain. The player fights to keep biofuel income above biofuel drain. Optionally, run a lab to bleed biofuel into DNA points for permanent plant upgrades
6. **Collapse** — Biofuel hits zero. Drill dies. Ice floods back. Robots burrow underground. Everything on the surface is lost
7. **Restart** — Restoration protocol re-engages. Drill punches through again. Plants are now stronger thanks to DNA research from previous cycles

The tension: expanding territory costs exponential biofuel, and the storm keeps raising the bill. A second drill needs 2+ plants and a robot just to break even — but those plants need time to grow, and the storm's drain is already climbing. Do you overextend and risk early collapse, run a lab and starve your generators, or play it safe and miss out on DNA progress?

## Buildings & Economy

### Production Chain

One resource runs the colony: **biofuel** — refined from plant fruits by the drill. Everything consumes it, nothing replaces it except more plants.

```
Plant → fruits (lie on ground, useless alone)
  ↓
Robot (collects fruits → carries to nearest drill)
  ↓
Drill/Generator → processes fruits into biofuel → generates heat + thaws 4 slots
  ↓
Laboratory (consumes biofuel → DNA points for meta-progression)
```

### Buildings

Four building types compete for thawed slots:

| Building | Input | Output | Role |
|---|---|---|---|
| **Plant** | — | Fruits | Raw production. The only source of income |
| **Robot Platform** | — | Collector unit | Logistics. Robots carry fruits to the nearest drill |
| **Drill/Generator** | Fruits (via robots) | Biofuel → heat + 4 new slots | Core economy. First one is free (start of run) |
| **Laboratory** | Biofuel | DNA points | Meta-progression. Pure drain on current-run economy |

The first drill bores up from underground for free — it's the starting point of every run. It thaws 4 slots, processes fruits into biofuel, and generates heat. Additional drills cost biofuel to build and demand exponentially more to operate.

### Three Drains on Biofuel

Every drop of biofuel produced gets fought over by three sinks:

1. **Generator upkeep** — constant drain to keep drills running and slots thawed. More generators + storm escalation = exponentially growing appetite. If this drain wins, you die.
2. **Building upgrades** — one-time biofuel cost to upgrade any building in-place. Upgraded buildings are more powerful BUT consume more biofuel going forward. A level 2 robot collects faster but costs more to maintain. A level 3 drill processes more fruits but eats more fuel. Every upgrade tightens the economy.
3. **Lab research** — constant drain converting biofuel into DNA points. The only path to permanent progress, and the most painful one — every unit of biofuel the lab eats is a unit not keeping your generators alive.

### Progression

**Within a run (temporary):** Upgrade buildings by spending biofuel. More power, more upkeep. All lost on death. The question: is a level 2 drill worth the extra fuel drain, or does it push you past the tipping point?

**Between runs (permanent):** DNA points earned from labs unlock new plant species and plant perks — faster growth, frost resistance, richer yields. This is the ONLY thing that persists. Better plants → more fruits → more biofuel → longer runs → more lab time → more DNA. The spiral tightens.

## Balance

### Two Curves

The entire game is a race between two curves:

- **Production curve** — biofuel income. Grows with more plants, more robots to collect, more drills to process. Roughly linear growth with diminishing returns (logistics bottlenecks, robot travel time).
- **Cost curve** — biofuel drain. Generator upkeep + building maintenance + storm escalation. Grows exponentially. Each new generator costs more than the last. The storm multiplier climbs every minute.

The session ends when cost overtakes production and biofuel reserves hit zero. The player's job is to push that intersection point as far into the future as possible.

### Slot Allocation Puzzle

Each drill thaws 4 slots. But the drill itself needs fruits to run. So out of those 4 slots:
- At minimum: 2 plants + 1 robot just to feed the drill that opened them
- That leaves 1 slot for a lab, another plant, or another robot
- A second drill from those 4 slots? It opens 4 MORE slots but now you need even more plants and robots to feed two drills

Expansion is never free. Every new ring of territory demands infrastructure before it produces anything. The early game is about bootstrapping; the late game is about not drowning in upkeep.

### Storm as Pressure Multiplier

The storm doesn't kill directly — it multiplies generator energy drain:
- **Minutes 0-3:** Calm. Drain coefficient ×1.0. Economy breathes easy
- **Minutes 3-7:** Rising. Coefficient climbs to ×2.0. Marginal builds start bleeding
- **Minutes 7-12:** Peak. Coefficient hits ×4.0+. Only optimized layouts survive
- **Beyond 12:** Brutal. Coefficient grows without cap. Even perfect economies eventually buckle

Session length IS the scoreboard. A bad run dies at minute 3. A good run reaches 10. A masterful one pushes past 15. The theoretical ceiling rises with each DNA unlock.

### Upgrade Tension

Building upgrades create a within-run dilemma:
- **Upgrade early** = stronger economy sooner, but the higher upkeep compounds over time
- **Upgrade late** = cheaper total cost, but you might not survive long enough to benefit
- **Don't upgrade** = weakest economy, but lowest drain. Sometimes the right call on a "lab rush" run where you're dumping everything into DNA points before dying fast
