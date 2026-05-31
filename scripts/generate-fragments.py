#!/usr/bin/env python3
"""Generate atmospheric fragment JSON for EVOL / Return But Different."""

from __future__ import annotations

import json
import random
from pathlib import Path

random.seed(404)

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "public" / "data"

BANNED = {
    "WELCOME", "NEW GAME", "BEGIN YOUR JOURNEY", "CREATE YOUR CHARACTER",
    "SELECT YOUR HERO", "CHOOSE YOUR DESTINY", "LEVEL UP", "QUEST",
    "ADVENTURE", "ACHIEVEMENT", "SUCCESS", "MAGICAL", "LEGENDARY", "EPIC", "RARE",
}

OPENING_CURATED = [
    "THE LOT REMAINED VACANT.",
    "THE WATER KEPT MOVING.",
    "THE BUILDING CHANGED OWNERS.",
    "THE LIGHTS REMAINED ON.",
    "THE TRACKS WERE STILL IN USE.",
    "THE PARKING LOT WAS EMPTY.",
    "THE HOUSE WAS DEMOLISHED.",
    "THE STORM MOVED NORTH.",
    "THE DITCH FILLED WITH WATER.",
    "THE NAME WAS FORGOTTEN.",
    "THE RIVER IGNORED IT.",
    "THE FIELD WAS STILL THERE.",
    "THE LAST PHOTO WAS BLURRY.",
    "THE WINDOWS WERE PAINTED OVER.",
    "THE TELEVISION WAS STILL ON.",
    "SOMETHING WAS LEFT BEHIND.",
    "THE ROAD CONTINUED WEST.",
    "THE SNOW LASTED LONGER THAN EXPECTED.",
    "NOBODY REMEMBERED WHY.",
    "THE RAILROAD SURVIVED.",
    "THE SIGN FELL OVER.",
    "THE FENCE WAS UNLOCKED.",
    "THE BASEMENT STAYED DRY.",
    "THE MACHINES WERE STILL RUNNING.",
    "THE ADDRESS CHANGED.",
    "THE MAIL STOPPED.",
    "THE KEY NO LONGER FIT.",
    "THE STAIRS CREAKED ONCE.",
    "THE PAINT DRIED WRONG.",
    "THE CLOCK WAS WRONG.",
]

BIRTH_CURATED = [
    "{NAME} IS BORN.",
    "SOMEBODY ARRIVES.",
    "A LIFE BEGINS.",
    "THE RECORD STARTS HERE.",
    "ANOTHER NAME ENTERS THE ARCHIVE.",
    "THE FIRST MEMORY HAS NOT HAPPENED YET.",
    "A NEW OBSERVER APPEARS.",
    "{NAME} ENTERS THE RECORD.",
    "A NAME IS ADDED.",
    "THE ARCHIVE RECEIVES ANOTHER ENTRY.",
]

DEATH_CURATED = [
    "THE RECORD ENDS HERE.",
    "THE ARCHIVE REMAINS.",
    "NOTHING FURTHER WAS RECORDED.",
    "THE MEMORY STOPS.",
    "THE LIFE IS CLOSED.",
    "THAT NAME ENTERS THE ARCHIVE.",
    "THE LAST OBSERVATION HAS BEEN MADE.",
    "THE FILE IS CLOSED.",
    "NO MORE ENTRIES FOLLOW.",
    "THE OBSERVATIONS CEASE.",
]

TRANSITION_CURATED = [
    "SOMEBODY ELSE ARRIVES.",
    "THE NEXT LIFE WAITS.",
    "ANOTHER RECORD BEGINS.",
    "THE ARCHIVE CONTINUES.",
    "THE WORLD REMAINS OPEN.",
    "THE NEXT NAME APPROACHES.",
    "THE OBSERVATIONS CONTINUE.",
    "ANOTHER NAME IS POSSIBLE.",
    "THE INDEX SHIFTS.",
    "SOMETHING ELSE REMAINS.",
]

REROLL_CURATED = [
    "THE LIVES DISAPPEAR.",
    "THOSE NAMES ARE GONE.",
    "THEY WERE NEVER CHOSEN.",
    "THREE OTHER LIVES APPEAR.",
    "THE OFFERING CHANGES.",
    "THE NAMES FADE.",
    "SOMETHING ELSE IS POSSIBLE.",
    "THE NAMES DISAPPEAR.",
    "THE CANDIDATES ARE DISCARDED.",
    "OTHER LIVES REMAIN.",
]

SUBJECTS = [
    "THE LOT", "THE FIELD", "THE RIVER", "THE PARKING LOT", "THE DITCH",
    "THE TRACKS", "THE BUILDING", "THE HOUSE", "THE TELEVISION", "THE LIGHT",
    "THE STORM", "THE ROAD", "THE WAREHOUSE", "THE FENCE", "THE WINDOW",
    "THE BASEMENT", "THE ATTIC", "THE BRIDGE", "THE HARBOR", "THE ELEVATOR",
    "THE GRAIN BIN", "THE WATER TOWER", "THE SIGN", "THE ALLEY", "THE PLATFORM",
    "THE BOILER", "THE CONVEYOR", "THE TUNNEL", "THE YARD", "THE SHED",
    "THE MOTEL", "THE OFFICE", "THE CHURCH", "THE SCHOOL", "THE FACTORY",
    "THE CANAL", "THE PIER", "THE TOWER", "THE MILL", "THE DEPOT",
]

VERBS = [
    "REMAINED", "CHANGED", "SURVIVED", "MOVED", "DISAPPEARED", "RETURNED",
    "STOPPED", "CONTINUED", "STAYED", "FAILED", "HELD", "LASTED", "SHIFTED",
    "SETTLED", "WAITED", "STOOD", "SAT", "LEANED", "RUSTED", "CRACKED",
]

OPENING_ENDINGS = [
    "VACANT", "EMPTY", "UNUSED", "UNTOUCHED", "FORGOTTEN", "IN SERVICE",
    "PAINTED OVER", "FULL OF WATER", "STILL THERE", "UNOCCUPIED", "DARK",
    "LOCKED", "OPEN", "WET", "COLD", "QUIET", "LOUD", "BENT", "BROKEN",
    "OUT OF ORDER", "UNDER REPAIR", "WITHOUT POWER", "WITHOUT HEAT",
]

REROLL_PATTERNS = [
    "THE NAMES {V}.",
    "THOSE LIVES {V}.",
    "THE OFFERING {V}.",
    "THE CANDIDATES {V}.",
    "THREE NAMES {V}.",
    "THE OPTIONS {V}.",
    "OTHER NAMES {V}.",
    "THE CHOICES {V}.",
    "THE RECORDS {V}.",
    "THE ENTRIES {V}.",
    "THESE LIVES {V}.",
    "THE LIST {V}.",
    "THOSE OPTIONS {V}.",
    "THE SELECTION {V}.",
    "OTHER LIVES {V}.",
    "THE THREE NAMES {V}.",
    "THE CURRENT NAMES {V}.",
    "THE PRESENTED LIVES {V}.",
    "THE SHOWN NAMES {V}.",
    "THE OFFERED LIVES {V}.",
]

REROLL_VERBS = [
    "DISAPPEAR", "FADE", "ARE DISCARDED", "ARE REMOVED", "ARE WITHDRAWN",
    "ARE REPLACED", "CHANGE", "SHIFT", "ARE GONE", "ARE UNSELECTED",
    "ARE FORGOTTEN", "ARE SET ASIDE", "ARE LEFT BEHIND", "ARE CLEARED",
    "DO NOT REMAIN", "ARE NO LONGER OFFERED", "PASS", "VANISH",
    "ARE STRUCK FROM THE LIST", "ARE UNCHOSEN", "ARE ABANDONED",
    "ARE DISMISSED", "ARE ERASED", "ARE OVERRIDDEN", "ARE SWAPPED OUT",
    "ARE REJECTED", "ARE UNRECORDED", "ARE UNPICKED", "ARE UNCLAIMED",
    "ARE RETURNED", "ARE RECALLED", "ARE WITHHELD", "ARE UNSEEN",
    "ARE UNMADE", "ARE UNNAMED", "ARE UNKEPT", "ARE UNHELD",
    "ARE RELEASED", "ARE REPLACED", "ARE REVOKED", "ARE RETRACTED",
]


def unique(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        key = item.upper().strip()
        if not key or key in seen:
            continue
        if any(b in key for b in BANNED):
            continue
        seen.add(key)
        out.append(key if key.endswith(".") else f"{key}.")
    return out


def gen_pool(count: int, seed_items: list[str], maker) -> list[str]:
    items = list(seed_items)
    guard = 0
    while len(unique(items)) < count and guard < count * 40:
        items.append(maker())
        guard += 1
    return unique(items)[:count]


def gen_opening(count: int) -> list[str]:
    def make() -> str:
        subj = random.choice(SUBJECTS)
        verb = random.choice(VERBS)
        end = random.choice(OPENING_ENDINGS)
        roll = random.random()
        if roll < 0.35:
            return f"{subj} {verb}."
        if roll < 0.7:
            return f"{subj} WAS {end}."
        return f"{subj} {verb} {end}."

    return gen_pool(count, OPENING_CURATED, make)


def gen_birth(count: int) -> list[str]:
    extras = [
        "{NAME} IS ADDED TO THE RECORD.",
        "{NAME} APPEARS IN THE INDEX.",
        "ANOTHER LIFE IS POSSIBLE.",
        "THE NEXT RECORD OPENS.",
        "A BIRTH IS NOTED.",
        "THE ARCHIVE EXPANDS.",
        "ONE MORE NAME EXISTS.",
        "THE FILE BEGINS EMPTY.",
        "NO MEMORIES YET.",
        "THE FIRST ENTRY WAITS.",
        "{NAME} IS LISTED.",
        "{NAME} IS REGISTERED.",
        "THE RECORD ACCEPTS A NAME.",
        "AN OBSERVER ENTERS.",
        "THE INDEX GROWS.",
    ]
    prefixes = ["A", "ANOTHER", "ONE", "THE NEXT", "A NEW", "THE LATEST", "A FRESH"]
    nouns = ["LIFE", "NAME", "RECORD", "ENTRY", "OBSERVER", "FILE", "SUBJECT", "LINE", "PAGE"]
    verbs = ["BEGINS", "STARTS", "OPENS", "ENTERS", "ARRIVES", "APPEARS", "IS ADDED", "IS WRITTEN"]

    def make() -> str:
        roll = random.random()
        if roll < 0.4:
            return random.choice(extras)
        if roll < 0.7 and "{NAME}" not in random.choice(extras):
            return f"{random.choice(prefixes)} {random.choice(nouns)} {random.choice(verbs)}."
        return f"{random.choice(prefixes)} {random.choice(nouns)} BEGINS."

    return gen_pool(count, BIRTH_CURATED, make)


def gen_death(count: int) -> list[str]:
    extras = [
        "THE OBSERVATIONS END.",
        "THE NAME IS ARCHIVED.",
        "THE FILE IS SEALED.",
        "NOTHING MORE IS WRITTEN.",
        "THE RECORD IS COMPLETE.",
        "THE LAST LINE IS DRAWN.",
        "THE ENTRY CLOSES.",
        "THE LIFE IS ARCHIVED.",
        "THE INDEX MARKS AN END.",
        "THE FINAL NOTE IS MADE.",
        "THE ACCOUNT IS CLOSED.",
        "NO FURTHER ENTRIES EXIST.",
        "THE LOG ENDS.",
        "THE CHAPTER CLOSES.",
        "THE NAME IS FILED AWAY.",
    ]
    subjects = [
        "THE RECORD", "THE FILE", "THE ENTRY", "THE LOG", "THE INDEX", "THE LIFE", "THE NAME",
        "THE ARCHIVE", "THE ACCOUNT", "THE PAGE", "THE LINE", "THE CHAPTER", "THE NOTE",
        "THE OBSERVATION", "THE MEMORY", "THE LISTING", "THE DOCUMENT",
    ]
    endings = [
        "ENDS HERE", "IS CLOSED", "IS SEALED", "IS COMPLETE", "STOPS",
        "IS ARCHIVED", "IS FINISHED", "IS DONE", "IS FINAL", "IS OVER",
        "IS FILED", "IS STORED", "IS LOCKED", "IS SET ASIDE", "IS MARKED CLOSED",
        "NO LONGER UPDATES", "REMAINS UNCHANGED", "IS LEFT AS IS",
    ]
    tails = [
        "NOTHING FOLLOWS.", "NO MORE LINES APPEAR.", "THE REST IS SILENT.",
        "THE FILE STAYS SHUT.", "THE DRAWER CLOSES.", "THE LIGHT GOES OUT.",
    ]

    def make() -> str:
        roll = random.random()
        if roll < 0.35:
            return random.choice(extras)
        if roll < 0.55:
            return f"{random.choice(subjects)} {random.choice(endings)}."
        return f"{random.choice(subjects)} {random.choice(endings)}. {random.choice(tails)}"

    return gen_pool(count, DEATH_CURATED, make)


def gen_transition(count: int) -> list[str]:
    extras = [
        "ANOTHER NAME WAITS.",
        "THE NEXT FILE OPENS.",
        "SOMETHING ELSE CONTINUES.",
        "THE WORLD KEEPS GOING.",
        "OTHER LIVES REMAIN.",
        "THE ARCHIVE IS NOT FULL.",
        "THE NEXT RECORD WAITS.",
        "ANOTHER ENTRY IS POSSIBLE.",
        "THE OBSERVATIONS RESUME.",
        "THE INDEX TURNS.",
        "THE LIST CONTINUES.",
        "MORE NAMES EXIST.",
        "THE FILE DRAWER STAYS OPEN.",
        "ANOTHER LINE IS POSSIBLE.",
        "THE NEXT PAGE WAITS.",
    ]
    subjects = ["ANOTHER", "THE NEXT", "SOMEBODY ELSE", "ONE MORE", "A DIFFERENT", "A FURTHER"]
    nouns = ["NAME", "LIFE", "RECORD", "ENTRY", "FILE", "OBSERVER", "LINE", "PAGE", "SUBJECT"]
    verbs = ["WAITS", "REMAINS", "APPROACHES", "EXISTS", "CONTINUES", "PERSISTS", "IS POSSIBLE"]

    def make() -> str:
        roll = random.random()
        if roll < 0.45:
            return random.choice(extras)
        if roll < 0.75:
            return f"{random.choice(subjects)} {random.choice(nouns)} {random.choice(verbs)}."
        return f"{random.choice(subjects)} {random.choice(nouns)} WAITS."

    return gen_pool(count, TRANSITION_CURATED, make)


def gen_reroll(count: int) -> list[str]:
    def make() -> str:
        pattern = random.choice(REROLL_PATTERNS)
        verb = random.choice(REROLL_VERBS)
        return pattern.replace("{V}", verb)

    return gen_pool(count, REROLL_CURATED, make)


def main() -> None:
    fragments = {
        "opening_fragments": gen_opening(500),
        "birth_fragments": gen_birth(100),
        "reroll_fragments": gen_reroll(100),
        "death_fragments": gen_death(200),
        "transition_fragments": gen_transition(100),
    }

    (DATA / "atmospheric_fragments.json").write_text(
        json.dumps(fragments, indent=2, ensure_ascii=False) + "\n"
    )

    (DATA / "fragment_subjects.json").write_text(
        json.dumps(SUBJECTS, indent=2) + "\n"
    )
    (DATA / "fragment_verbs.json").write_text(
        json.dumps(VERBS, indent=2) + "\n"
    )
    (DATA / "fragment_endings.json").write_text(
        json.dumps(OPENING_ENDINGS, indent=2) + "\n"
    )

    for key, arr in fragments.items():
        print(f"{key}: {len(arr)}")


if __name__ == "__main__":
    main()
