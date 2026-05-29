#!/usr/bin/env python3
"""Build data/collectibles.json — large category catalog with variants."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "collectibles.json"

# Hand-authored entries (maze gates, story items) — preserved across rebuilds.
SPECIAL: list[dict] = [
    {"id": "photo", "name": "Photo", "category": "items", "base_value": 12, "reveal": "blurry hallway. half a face.", "maze_page": "meridian_photos"},
    {"id": "griffey_card", "name": "Griffey Card", "category": "cards", "base_value": 45, "reveal": "1989 upper deck. rookie.", "maze_page": "racecar"},
    {"id": "bus_pass", "name": "Bus Pass", "category": "items", "base_value": 18, "reveal": "panhandle legendary.", "sellable": False},
    {"id": "pawn_stub", "name": "Pawn Stub", "category": "items", "base_value": 1, "reveal": "cash loans gold.", "sellable": False},
    {"id": "transit_map", "name": "Transit Map", "category": "items", "base_value": 4, "reveal": "septa departures.", "sellable": False},
    {"id": "lottery_ticket", "name": "Lottery Ticket", "category": "items", "base_value": 2, "reveal": "pawn shop glass."},
    {"id": "rusty_key", "name": "Rusty Key", "category": "items", "base_value": 8, "reveal": "pawn drawer. no lock fits."},
    {"id": "matchbook", "name": "Matchbook", "category": "items", "base_value": 1, "reveal": "el bar. est. 1963."},
    {"id": "neon_flyer", "name": "Neon Flyer", "category": "items", "base_value": 1, "reveal": "cold beer good times."},
    {"id": "newspaper", "name": "Newspaper", "category": "items", "base_value": 1, "reveal": "make awesome news. march 14."},
    {"id": "old_receipt", "name": "Old Receipt", "category": "items", "base_value": 1, "reveal": "panhandle uncommon."},
    {"id": "crushed_beer_can", "name": "Crushed Beer Can", "category": "liquor", "base_value": 1, "reveal": "panhandle uncommon."},
    {"id": "infest_flyer", "name": "Infest Flyer", "category": "items", "base_value": 3, "reveal": "basement wall. spread fear."},
    {"id": "integrity_sticker", "name": "Integrity Sticker", "category": "items", "base_value": 4, "reveal": "peeling off the pillar."},
]

CATEGORIES = {
    "liquor": {"label": "LIQUOR", "cap": 99},
    "drugs": {"label": "DRUGS", "cap": 99},
    "vinyl": {"label": "VINYL", "cap": 99},
    "jackets": {"label": "JACKETS", "cap": 99},
    "cards": {"label": "CARDS", "cap": 99},
    "guns": {"label": "GUNS", "cap": 99},
    "items": {"label": "ITEMS", "cap": 99},
}

LIQUOR = [
    ("beer", "Beer", 3),
    ("beer_can", "Beer Can", 1),
    ("whiskey", "Whiskey", 8),
    ("old_crow", "Old Crow", 5),
    ("steel_reserve", "Steel Reserve", 4),
    ("evan_williams", "Evan Williams", 6),
    ("forty_oz", "Forty Ounce", 5),
    ("liquor_bottle", "Liquor Bottle", 7),
    ("mad_dog", "Mad Dog 20/20", 3),
    ("burnettes", "Burnett's Vodka", 4),
    ("natty_ice", "Natty Ice 30-Pack", 6),
    ("fireball", "Fireball Mini", 2),
    ("jameson", "Jameson Half-Pint", 7),
    ("malt_liquor", "Country Club Malt", 3),
    ("rotgut", "Rotgut Pint", 2),
]

DRUGS = [
    ("cocaine", "Cocaine", 25, "ground score. cocaine."),
    ("ketamine", "Ketamine", 18, "ground score. ketamine."),
    ("meth", "Meth", 15, "ground score. meth."),
    ("heroin_bag", "Heroin Bag", 30, "foil corner."),
    ("xanax_strip", "Xanax Strip", 12, "pharmacy trash."),
    ("perc_10", "Perc 10", 14, "bathroom tile."),
    ("crack_vial", "Crack Vial", 20, "cap in the gutter."),
    ("fent_strip", "Fent Strip", 22, "test line pink."),
    ("adderall", "Adderall 30", 10, "library floor."),
    ("lsd_tab", "LSD Tab", 16, "stamp on tongue."),
    ("mdma_cap", "MDMA Cap", 18, "club parking lot."),
    ("oxy_15", "Oxy 15", 24, "pill in the dust."),
    ("speed_bag", "Speed Bag", 11, "trucker stop."),
    ("k_pin", "K Pin", 17, "vial in the seam."),
    ("bup_strip", "Sub Strip", 9, "clinic line."),
]

VINYL = [
    ("vinyl_punk_7", "Punk 7-Inch", 8),
    ("vinyl_hardcore_lp", "Hardcore LP", 14),
    ("vinyl_jazz", "Jazz Reissue", 12),
    ("vinyl_soul", "Philly Soul LP", 10),
    ("vinyl_metal", "Thrash Demo", 18),
    ("vinyl_ambient", "Ambient 2LP", 15),
    ("vinyl_country", "Country Gold", 6),
    ("vinyl_disco", "Disco 12-Inch", 9),
    ("vinyl_comp", "Comp Tape Dub", 4),
    ("vinyl_infest", "Infest LP", 35),
    ("vinyl_integrity", "Integrity LP", 28),
    ("vinyl_japan_doll", "Japan Doll Demo", 40),
    ("vinyl_misfits", "Misfits Boot", 22),
    ("vinyl_minor_threat", "Minor Threat 7", 30),
    ("vinyl_bad_brains", "Bad Brains LP", 26),
]

JACKETS = [
    ("starter_eagles", "Eagles Starter", 35),
    ("starter_sixers", "Sixers Starter", 32),
    ("starter_phillies", "Phillies Starter", 30),
    ("starter_flyers", "Flyers Starter", 28),
    ("starter_bulls", "Bulls Starter", 25),
    ("starter_raiders", "Raiders Starter", 38),
    ("starter_lions", "Detroit Starter", 22),
    ("varsity_leather", "Varsity Leather", 45),
    ("denim_jacket", "Denim Jacket", 15),
    ("carhartt_coat", "Carhartt Coat", 40),
    ("northface_old", "North Face Old", 35),
    ("puffy_90s", "90s Puffy", 28),
    ("letterman", "Letterman Jacket", 50),
    ("work_chore", "Chore Coat", 18),
    ("rain_poncho", "SEPTA Poncho", 3),
]

CARDS = [
    ("baseball_card", "Baseball Card", 5),
    ("card_griffey", "Griffey Rookie", 45),
    ("card_jordan", "Jordan Insert", 55),
    ("card_ripken", "Ripken Cal", 12),
    ("card_bonds", "Bonds RC", 20),
    ("card_mantle", "Mantle Reprint", 8),
    ("card_hockey", "Hockey Goalie", 6),
    ("card_football", "Football QB", 7),
    ("card_pokemon", "Holo Pokemon", 15),
    ("card_garbage", "Garbage Pail", 4),
    ("card_wrestling", "Wrestling Card", 3),
    ("card_nascar", "NASCAR Card", 2),
    ("card_bicycle", "Bicycle Deck", 5),
    ("card_topps", "Topps Foil", 9),
    ("card_error", "Misprint Card", 25),
]

GUNS = [
    ("revolver_rust", "Rusty Revolver", 80),
    ("bb_pistol", "BB Pistol", 12),
    ("cap_gun", "Cap Gun", 2),
    ("pellet_rifle", "Pellet Rifle", 35),
    ("shotgun_saw", "Sawed Shotgun", 120),
    ("pistol_22", ".22 Pistol", 65),
    ("flare_gun", "Flare Gun", 18),
    ("starter_pistol", "Starter Pistol", 8),
    ("taser_old", "Old Taser", 40),
    ("brass_knuckles", "Brass Knuckles", 15),
    ("switchblade", "Switchblade", 22),
    ("machete", "Machete", 28),
    ("crowbar", "Crowbar", 10),
    ("bat_aluminum", "Aluminum Bat", 14),
    ("knife_kitchen", "Kitchen Knife", 6),
]

ITEMS = [
    ("zippo", "Zippo Lighter", 8),
    ("chain_gold", "Gold Chain", 55),
    ("watch_casio", "Casio Watch", 12),
    ("phone_flip", "Flip Phone", 6),
    ("charger_burn", "Burned Charger", 2),
    ("earbuds", "Earbuds", 5),
    ("sunglasses", "Sunglasses", 7),
    ("backpack", "Backpack", 10),
    ("wallet_empty", "Empty Wallet", 1),
    ("id_fake", "Fake ID", 20),
    ("tool_mult", "Multi-Tool", 14),
    ("flashlight", "Flashlight", 4),
    ("umbrella_broke", "Broken Umbrella", 1),
    ("scarf_knit", "Knit Scarf", 3),
    ("band_shirt", "Band Shirt", 8),
]


def entry(cid: str, name: str, category: str, base_value: int, **extra) -> dict:
    row = {
        "id": cid,
        "name": name,
        "category": category,
        "base_value": base_value,
        "pawn_rate": extra.pop("pawn_rate", 0.42),
        "sellable": extra.pop("sellable", True),
    }
    row.update(extra)
    return row


def expand(base: list, category: str) -> list[dict]:
    out: list[dict] = []
    for row in base:
        if len(row) == 3:
            cid, name, val = row
            out.append(entry(cid, name, category, val))
        else:
            cid, name, val, reveal = row
            out.append(entry(cid, name, category, val, reveal=reveal))
    return out


def main() -> None:
    special_ids = {s["id"] for s in SPECIAL}
    collectibles: list[dict] = list(SPECIAL)
    collectibles.extend(expand(LIQUOR, "liquor"))
    collectibles.extend(expand(DRUGS, "drugs"))
    collectibles.extend(expand(VINYL, "vinyl"))
    collectibles.extend(expand(JACKETS, "jackets"))
    collectibles.extend(expand(CARDS, "cards"))
    collectibles.extend(expand(GUNS, "guns"))
    collectibles.extend(expand(ITEMS, "items"))
    # Dedupe by id (special wins)
    by_id: dict[str, dict] = {}
    for row in collectibles:
        cid = row["id"]
        if cid in by_id and cid in special_ids:
            continue
        by_id[cid] = row
    payload = {
        "categories": CATEGORIES,
        "collectibles": sorted(by_id.values(), key=lambda r: (r["category"], r["id"])),
    }
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(payload['collectibles'])} collectibles)")


if __name__ == "__main__":
    main()
