"""Dust Meridian biography rooms — ported from DEADDEADDEADApp."""

from __future__ import annotations

import random
from typing import Callable


def meridian_pages(page_fn: Callable[..., dict], link_fn: Callable[..., dict], frag_fn: Callable[..., dict], img_fn: Callable[[str], str]) -> dict[str, dict]:
    shards = _meridian_shards()
    pages: dict[str, dict] = {}

    pages["meridian_incomplete_file"] = page_fn(
        "meridian_incomplete_file",
        "INCOMPLETE BIOGRAPHY",
        "Daniel Mercer / Dust Meridian / wrong filenames",
        [img_fn("file2.gif"), img_fn("profile.gif"), img_fn("eye.gif"), img_fn("handprint.jpg")],
        "THE LIFE OF DUST MERIDIAN — recovered biography file. Status: incomplete. Contradictions preserved on purpose. "
        "Daniel Mercer. Dust Meridian. Kyle Mercer died 2019. Some rooms invert the twin. Some pretend he was alone.",
        [frag_fn(s["id"].upper().replace("_", " "), img_fn(s["image"]), s["shard_room"], 4) for s in random.sample(shards, min(8, len(shards)))]
        + [frag_fn("RANDOM SHARD", img_fn("filenotfound3.gif"), "meridian_pull", 6)],
        [
            link_fn("pull random paragraph", "meridian_pull", True),
            link_fn("1982", "meridian_1982", True),
            link_fn("class of 92", "meridian_class", True),
            link_fn("wrong ending", "meridian_afterword", True),
            link_fn("ozy's basement", "ozzy_basement", True),
            link_fn("dead index", "dead"),
        ],
        hidden=True,
        unstable=True,
        residue_key="MERIDIAN FILE",
    )

    for shard in shards:
        others = [s for s in shards if s["id"] != shard["id"]]
        bleed = random.sample(others, min(3, len(others)))
        bleed_text = "\n\n".join(f"【{s['graft_label'].upper()}】 {s['text']}" for s in bleed)
        host = random.choice(shard["host_rooms"]) if shard["host_rooms"] else "dead"
        pages[shard["shard_room"]] = page_fn(
            shard["shard_room"],
            f"SHARD / {shard['id'].replace('_', ' ').upper()}",
            shard["graft_label"],
            [img_fn(shard["image"]), img_fn("file2.gif"), img_fn("handprint.jpg")],
            shard["text"] + "\n\n—\n\nOTHER PARAGRAPHS ATTACHED WITHOUT PERMISSION:\n\n" + bleed_text,
            [frag_fn("NEXT SHARD", img_fn("filenotfound3.gif"), "meridian_pull", 5), frag_fn("BIOGRAPHY INDEX", img_fn("profile.gif"), "meridian_incomplete_file", 4)]
            + [frag_fn(s["id"].upper(), img_fn(s["image"]), s["shard_room"], 5) for s in bleed],
            [
                link_fn("pull another", "meridian_pull", True),
                link_fn("index", "meridian_incomplete_file", True),
                link_fn("graft host", host, True),
                link_fn("wrong person", random.choice(["larry", "gerald", "failure", "feed"]), True),
            ],
            hidden=True,
            unstable=True,
            residue_key=f"MERIDIAN / {shard['id'].upper()}",
        )

    pages["meridian_pull"] = page_fn(
        "meridian_pull",
        "PARAGRAPH PULLED FROM ELSEWHERE",
        "non-linear / misfiled / still about him",
        [img_fn("gap2.jpg"), img_fn("lost.jpg")],
        _pull_body(shards),
        [frag_fn("ANOTHER", img_fn("handprint.jpg"), "meridian_pull", 6)],
        [link_fn("index", "meridian_incomplete_file", True), link_fn("random room", "randomroom", True)],
        hidden=True,
        unstable=True,
        residue_key="MERIDIAN PULL",
    )

    return pages


def _pull_body(shards: list[dict]) -> str:
    shard = random.choice(shards)
    return f"【{shard['graft_label']}】\n\n{shard['text']}"


def _meridian_shards() -> list[dict]:
    return [
        {"id": "born_1982", "text": "Born 1982, Long Beach. Legal name Daniel Mercer. After middle school almost nobody used it.", "graft_label": "wrong footer on /dead index", "host_rooms": ["dead", "lost", "moved"], "shard_room": "meridian_1982", "image": "gap1.jpg"},
        {"id": "alley_box", "text": "The apartment backed onto an alley. He kept bottle caps and rain-warped receipts in a box under the bed labeled CHRISTMAS LIGHTS.", "graft_label": "Larry's widow misfiled this paragraph", "host_rooms": ["larry", "room", "gap"], "shard_room": "meridian_alley", "image": "gap1.jpg"},
        {"id": "report_card", "text": "Fourth-grade report card: Daniel appears to be somewhere else entirely. He drew maps of dead malls and harbors that froze.", "graft_label": "Mrs. Van Ravensway duplicate", "host_rooms": ["town", "hidden"], "shard_room": "meridian_maps", "image": "file2.gif"},
        {"id": "class_cursed", "text": "1992 classroom. Expo markers and dust. Classmates died young in unrelated ways. He called it the last bright room before the tunnel.", "graft_label": "town list appendix", "host_rooms": ["town", "children"], "shard_room": "meridian_class", "image": "children1.jpg"},
        {"id": "hoodie_leather", "text": "High school: oversized hoodies under black leather jackets regardless of weather. Gaylord and Jeffrey 2. Sonic Youth on Maxell tapes.", "graft_label": "Gerald's mother insists this is about fishing", "host_rooms": ["gerald", "roads", "urban"], "shard_room": "meridian_hoodies", "image": "blackroad.jpg"},
        {"id": "loading_dock", "text": "They preferred loading docks at 2 a.m. Beaches were too exposed. Industrial Long Beach: yards, refineries, parking structures.", "graft_label": "Mikey Vekker interview (unverified)", "host_rooms": ["roads", "urban"], "shard_room": "meridian_docks", "image": "city3bg.jpg"},
        {"id": "pharmacy_trash", "text": "He stole discarded one-hour photo prints from pharmacy trash. Blurry hallways. Half-cutoff faces.", "graft_label": "anti profile scrape", "host_rooms": ["anti", "profiles", "feed"], "shard_room": "meridian_photos", "image": "profilescreen.gif"},
        {"id": "shackleton", "text": "Never north of Oregon but talked about Iceland, Greenland, Finland. Shackleton photocopies folded in notebooks.", "graft_label": "Nordic drift misroute", "host_rooms": ["machine", "stereo"], "shard_room": "meridian_north_talk", "image": "icecubesfortimscat.jpg"},
        {"id": "warehouse_pills", "text": "1998. Behind a carpet warehouse off Anaheim Street. Pills in a Taco Bell napkin. He stared at concrete cracks forty minutes while freight screamed.", "graft_label": "policeman report names the wrong boy", "host_rooms": ["violent", "grenades"], "shard_room": "meridian_warehouse", "image": "handprint.jpg"},
        {"id": "pill_neighborhoods", "text": "Ketamine with motel bathrooms. Cocaine with garages. Whiskey with winter bus stops. He called blocks pill neighborhoods.", "graft_label": "Mildred never returned (filed here by mistake)", "host_rooms": ["supermarket", "tea", "military"], "shard_room": "meridian_geography_drugs", "image": "cancerman.jpg"},
        {"id": "od_scare_2001", "text": "2001 overdose scare. Nobody died. They photographed cemeteries anyway. He started lists of everyone who vanished.", "graft_label": "Larry television file overlap", "host_rooms": ["larry", "failure", "fire"], "shard_room": "meridian_lists", "image": "larry_01.jpg"},
        {"id": "signal_static", "text": "Longest job: used record shop Signal Static downtown. Shelved by mood: Night Driving. Hospital Music. Fired after eleven days gone.", "graft_label": "machine room footnote", "host_rooms": ["machine", "stereo", "headphones"], "shard_room": "meridian_signal_static", "image": "machines3.gif"},
        {"id": "iceland_bag", "text": "Returned with a grocery bag of Icelandic dock photos. Would not explain the eleven days.", "graft_label": "Gerald fishing trip (incorrect merge)", "host_rooms": ["gerald"], "shard_room": "meridian_iceland_bag", "image": "gap2.jpg"},
        {"id": "philly_cough", "text": "Winter in Philadelphia clearing mold apartments. Cough that stayed. TB raised once; paperwork never matched.", "graft_label": "Kensington wall writing", "host_rooms": ["kensington_trash_yard", "liquor_store", "ozzy_basement"], "shard_room": "meridian_philly_sick", "image": "trash4b.gif"},
        {"id": "postcards", "text": "Postcards from Milwaukee, Duluth, Reykjavik, Helsinki, Nuuk, Tacoma, Philadelphia. No return address—or one that lied.", "graft_label": "soldier transmission fragment", "host_rooms": ["roads", "money"], "shard_room": "meridian_postcards", "image": "us.gif"},
        {"id": "felt_temporary", "text": "Whenever he left, it felt temporary. Even after he did not come back, someone expected a postcard.", "graft_label": "universal detail (disputed)", "host_rooms": ["dead", "feed", "void"], "shard_room": "meridian_afterword", "image": "lost.jpg"},
        {"id": "kind_cruel", "text": "Some call him kind. Some cruel. Some credit overdoses reversed. Others blame first pills on him.", "graft_label": "everyone eventually becomes weather (misheard)", "host_rooms": ["failure", "mind"], "shard_room": "meridian_memory_split", "image": "deadmood.gif"},
        {"id": "posts_after_death", "text": "Forum posts and database rows under his name after the last sighting. Hoax, mistake, or something else—unsettled.", "graft_label": "anti_no_php stderr", "host_rooms": ["anti", "feed", "void"], "shard_room": "meridian_online", "image": "notfound1.gif"},
    ]
