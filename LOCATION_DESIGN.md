# DOOM DANCE — Location Design System (LOCKED)

**Do not build a giant open world.**  
**Do not build a scrolling map.**  
**Do not build procedural cities.**  
**Do not build hundreds of interconnected systems.**

DOOM DANCE grows **one location at a time**. Each new location is a handcrafted illustrated screen. The city is built like a scrapbook.

---

## Core location philosophy

One illustration = one experience.

A location is not a physical space the player walks through. A location is a **scene the player visits**.

Examples: Alley · Liquor Store · Pawn Shop · Dive Bar · SEPTA Platform · Movie Theater · Western Union · Abandoned Rowhouse · Underpass · Vacant Lot

Every location should feel memorable.

---

## Every location must contain

### 1. Visual anchor

One thing that immediately defines the scene.

Examples: pawn counter · movie marquee · burning barrel · subway stairs · liquor shelf · chain-link fence · bar jukebox · Western Union window

### 2. Pseudo-animation

At least **one** subtle animation so static scenes feel alive.

Examples: light flicker · neon flicker · rain overlay · steam · smoke · TV glow · passing headlights · puddle shimmer · drifting trash · train light sweep · ceiling fan

Implementation: `overlays` in `data/screens.json` — see existing overlay names in `scripts/game/screen_overlays.gd`.

### 3. Interaction

At least **one** meaningful interaction.

Examples: talk · buy · sell · search · inspect · enter · wait · panhandle · use item

Implementation: `hotspots` in `data/screens.json` — actions: `goto`, `buy`, `collect`, `message`, `panhandle`, etc.

### 4. Observation

At least **one** memorable observation.

Examples: *"The sign hasn't worked in years."* · *"Something moved behind the fence."* · *"Most of the bottles are empty."* · *"Showing since 1997."*

Observations should be short. Prefer fragments. Prefer implication over explanation.

Implementation: `message` hotspot or copy in `data/copy.json` under `observations/<screen_id>/`.

---

## Production rule

New content is added as **new locations** — not giant systems.

| Night | Build |
|-------|--------|
| One night | Pawn Shop |
| Another | Dive Bar |
| Another | Theater Lobby |
| Another | Abandoned Basement |
| Another | SEPTA Platform |

The city grows one place at a time.

### Checklist for a new location

1. Illustration (background PNG path in `data/screens.json`)
2. Visual anchor (named in this doc + `DOOM_DANCE.md`)
3. ≥1 overlay (pseudo-animation)
4. ≥1 hotspot (interaction)
5. ≥1 observation (copy fragment)
6. Update `DOOM_DANCE.md` living index

---

## Design goal

A player should remember locations **because of atmosphere**, not mechanics.

- *"The bar with the flickering jukebox."*
- *"The pawn shop with the fan."*
- *"The theater that never changes movies."*
- *"The underpass with the train lights."*

Every location should feel like a place that existed before the player arrived and will still exist after they leave.

---

## DOOM DANCE principle (summary)

Every new location is a handcrafted illustrated screen containing:

- One visual anchor
- One pseudo-animation
- One interaction
- One memorable detail

Follow this rule consistently for all future locations.

---

## Chapter 1 — current screens

| Screen | Anchor | Animation | Interaction | Observation |
|--------|--------|-----------|-------------|-------------|
| Impound Lot | Gate / office light | rain, light flicker, puddle | Enter alley | *Light on inside. Locked.* |
| Alley | Chain-link / storefront row | rain, light flicker | Travel hub, panhandle | Fence man · chained basement |
| Liquor Store | Fluorescent shelf | fluorescent flicker, neon buzz | Buy liquor | *(expand)* |
| Pawn Shop | Counter display | light flicker, fluorescent | Collect Griffey, key | *(expand)* |
| Vacant Lot | Empty lot / trash | wind trash, distant light | Collect can, matchbook | *(expand)* |
| SEPTA Entrance | Turnstile stairs | fluorescent, train flash | Pay turnstile, map | *Not implemented.* (stub) |
| Movie Theater | Marquee | light flicker, distant light | Ticket, boarded door | *Boarded. Marquee still on.* |
| Western Union | Wire window | fluorescent, light flicker | Receipt, photo | *(expand)* |
| Rowhouse | Chained basement | rain, light flicker | Newspaper | *Padlock. Chain rusted through.* |
| Underpass | Tunnel / tracks | rain, light sweep, puddle | Flyer, bottle | *(expand)* |

Rows marked *(expand)* need a dedicated observation hotspot or copy pass — future nightly work.
