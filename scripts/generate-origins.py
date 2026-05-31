#!/usr/bin/env python3
"""Generate curated atmosphere-first origins for EVOL / Return But Different."""

from __future__ import annotations

import json
import random
import sys
from pathlib import Path

random.seed(77)

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

TARGETS = {
    "town": 400,
    "neighborhood": 200,
    "region": 200,
    "non_city": 150,
    "rare": 50,
}

# Always present — atmosphere anchors from the design brief.
MUST_INCLUDE = {
    "Kensington",
    "Fishtown",
    "Port Richmond",
    "West Philadelphia",
    "Rock Springs, Wyoming",
    "Butte, Montana",
    "Valentine, Nebraska",
    "Outside Valentine, Nebraska",
    "Near Devils Tower",
    "Near a shuttered grain elevator",
    "Beside the Missouri River",
    "Along the Schuylkill River",
    "The Upper Peninsula",
    "The Badlands",
    "The Salton Sea",
    "Slab City",
    "Marfa",
    "Deadwood",
    "Thunder Bay",
    "Akureyri",
    "Outside Carmel, Iowa",
    "The Faroe Islands",
    "Svalbard",
    "Lofoten",
    "The Shetland Islands",
    "Youngstown, Ohio",
    "Erie, Pennsylvania",
    "Flint, Michigan",
    "Scranton, Pennsylvania",
    "Duluth, Minnesota",
    "Inverness, Scotland",
}

VALID_TAGS = {
    "industrial", "rustbelt", "railroad", "river", "cornfield", "farmland", "mining",
    "desert", "arctic", "nordic", "coastal", "warehouse", "urban", "rural", "isolation",
    "plains", "weather", "forest", "mountain", "working_class", "abandoned", "cold",
    "highway", "small_town", "salvage", "waterfront", "fog", "grain_elevator", "oil",
    "paper_mill", "borderland", "volcanic", "rowhouse", "fluorescent", "vacant_lot",
    "drainage_ditch", "church_basement", "county_road", "tractor", "storm",
}


def entry(name: str, category: str, tags: list[str]) -> dict:
    tags = [t for t in tags if t in VALID_TAGS]
    if not tags:
        tags = ["rural"]
    return {"name": name.strip(), "category": category, "tags": tags}


def load_towns() -> list[dict]:
    from origins_data.towns import TOWNS  # noqa: PLC0415

    return [entry(n, "town", t) for n, t in TOWNS]


def load_neighborhoods() -> list[dict]:
    from origins_data.neighborhoods import NEIGHBORHOODS  # noqa: PLC0415

    return [entry(n, "neighborhood", t) for n, t in NEIGHBORHOODS]


def load_regions() -> list[dict]:
    from origins_data.regions import REGIONS  # noqa: PLC0415

    return [entry(n, "region", t) for n, t in REGIONS]


def load_rare() -> list[dict]:
    from origins_data.rare import RARE  # noqa: PLC0415

    return [entry(n, "rare", t) for n, t in RARE]


def load_non_city() -> list[dict]:
    from origins_data.non_city import NON_CITY  # noqa: PLC0415

    return [entry(n, "non_city", t) for n, t in NON_CITY]


def dedupe(items: list[dict]) -> list[dict]:
    seen: set[str] = set()
    out: list[dict] = []
    for item in items:
        key = item["name"].lower()
        if key in seen:
            continue
        seen.add(key)
        out.append(item)
    return out


def sample_to_target(items: list[dict], target: int) -> list[dict]:
    items = dedupe(items)
    must = [i for i in items if i["name"] in MUST_INCLUDE]
    rest = [i for i in items if i["name"] not in MUST_INCLUDE]
    if len(must) > target:
        return must[:target]
    need = target - len(must)
    if len(rest) < need:
        raise SystemExit(f"Not enough entries after must-include: need {need}, have {len(rest)}")
    return must + random.sample(rest, need)


def assign_ids(items: list[dict]) -> list[dict]:
    random.shuffle(items)
    for i, item in enumerate(items, start=1):
        item["id"] = f"origin_{i:04d}"
    return items


def main() -> None:
    pool = {
        "town": load_towns(),
        "neighborhood": load_neighborhoods(),
        "region": load_regions(),
        "non_city": load_non_city(),
        "rare": load_rare(),
    }

    selected: list[dict] = []
    stats: dict[str, int] = {}
    for cat, target in TARGETS.items():
        picked = sample_to_target(pool[cat], target)
        if len(picked) < target:
            raise SystemExit(f"Not enough {cat} entries: have {len(picked)}, need {target}")
        stats[cat] = len(picked)
        selected.extend(picked)

    selected = assign_ids(selected)

    root = Path(__file__).resolve().parent.parent
    outputs = [
        root / "public" / "data" / "origins.json",
        Path("/Users/dustyaltena/Documents/dev/EVOL/ReturnButDifferent/ReturnButDifferent/Data/origins.json"),
    ]

    for path in outputs:
        if path.parent.exists():
            path.write_text(json.dumps(selected, indent=2, ensure_ascii=False) + "\n")
            print(f"Wrote {len(selected)} origins → {path}")

    print("Category counts:", stats)


if __name__ == "__main__":
    main()
