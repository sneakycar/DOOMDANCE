#!/usr/bin/env python3
"""Build data/maze_pages.json from deadbicycle HTML + authored game pages."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARCHIVE = ROOT / "archive" / "deadbicycle"
OUT = ROOT / "data" / "maze_pages.json"
IMG_PREFIX = "res://archive/deadbicycle/img/"

# New location/story page ids — builder randomly grafts these onto existing links.
WEAVE_TARGETS: list[str] = [
    "ozzy_basement",
    "meridian_incomplete_file",
    "meridian_pull",
    "tv_alley",
    "make_awesome_news",
    "tv_heaven",
    "movie_theater",
    "septa_allegheny",
    "el_bar",
    "mattress_lot",
    "panhandle",
    "pawn_shop",
    "underpass",
    "japan_doll_basement",
    "record_store",
]


def img(name: str) -> str:
    return IMG_PREFIX + name


def anti(name: str) -> str:
    return "res://archive/deadbicycle/anti/img/" + name


def page(
    pid: str,
    title: str,
    subtitle: str = "",
    images: list[str] | None = None,
    body: str = "",
    fragments: list[dict] | None = None,
    links: list[dict] | None = None,
    hidden: bool = False,
    unstable: bool = False,
    residue_key: str = "",
    location_screen: str = "",
    life_delta: float | None = None,
    life_min: float | None = None,
    life_max: float | None = None,
) -> dict:
    out = {
        "id": pid,
        "title": title,
        "subtitle": subtitle,
        "images": images or [],
        "body": body,
        "fragments": fragments or [],
        "links": links or [],
        "hidden": hidden,
        "unstable": unstable,
        "residue_key": residue_key or pid.upper(),
        "location_screen": location_screen,
    }
    if life_delta is not None:
        out["life_delta"] = life_delta
    if life_min is not None:
        out["life_min"] = life_min
    if life_max is not None:
        out["life_max"] = life_max
    return out


def frag(text: str, image: str, dest: str, rarity: int = 0) -> dict:
    return {"text": text, "image": image, "destination": dest, "rarity": rarity}


def link(label: str, dest: str, unstable: bool = False) -> dict:
    return {"label": label, "destination": dest, "unstable": unstable}


def simple(pid: str, title: str, subtitle: str, images: list[str], body: str, exits: list[str], unstable: bool = False) -> dict:
    frags = [
        frag(
            im.replace(".jpg", "").replace(".gif", "").upper(),
            img(im),
            exits[i % len(exits)],
        )
        for i, im in enumerate(images)
    ]
    lnks = [link(e.upper(), e, unstable) for e in exits]
    lnks.append(link("wrong door", "randomroom", True))
    return page(pid, title, subtitle, [img(i) for i in images], body, frags, lnks, unstable=unstable)


MILITARY_BODY = (
    "gerald have all gone away. please help me dispose of my bicycle. where has this gerald gone? "
    "we have never seen so many bicycles on fire. it is 5 a.m. and we are listening to a song. "
    "it is 24 minutes in length. everything has to be set in stone. the bicycle is still on fire. where is gerald?"
)
LARRY_BODY = (
    "Susan was born in 1931. She never left her home town of Farmington. Larry loved television. "
    "He left it on one night, and it started the house on fire. He died in that fire. "
    "The show he was watching was Rescue 911."
)
HIDDEN_BODY = " ".join(["THE HIDDEN PAGE!"] * 72)


def authored_pages() -> dict[str, dict]:
    pages: dict[str, dict] = {}

    pages["dead"] = page(
        "dead",
        "dead DEAD dead",
        "recovered index / no tabs / no clean way out",
        [img("deadbicyclelogo.gif"), img("deadbikelogo.jpg"), img("deadcontact.gif")],
        "The archive has been rebuilt as a broken hallway. Nothing is a category anymore. Everything is a door. "
        "Tap image fragments, wrong labels, repeated words, faces, product names, and things that look dead.",
        [
            frag("LOST DIRECTORY", img("lost.jpg"), "lost"),
            frag("GERALD", img("geraldstorybg.gif"), "gerald"),
            frag("SUPERMARKET", img("mildred2.jpg"), "supermarket"),
            frag("THE MACHINE", img("deadmachine.gif"), "machine"),
            frag("RANDOM WRONG ROOM", img("filenotfound3.gif"), "randomroom"),
            frag("DOTS AND TELEVISIONS", img("dotsandtelevisions.gif"), "dots"),
            frag("BICYCLE MACHINE", img("bikesandbikes.jpg"), "bicycles"),
            frag("KENSINGTON YARD", img("trash4b.gif"), "kensington_trash_yard", 4),
        ],
        [
            link("start from the broken directory", "lost"),
            link("dead feed", "feed"),
            link("salvage index", "salvage_sitemap", True),
            link("dig raw file", "dig"),
            link("dig site", "digsite"),
            link("dust meridian", "meridian_incomplete_file", True),
            link("unstable door", "unstable", True),
            link("panic crawl", "broadcastpanic", True),
        ],
        unstable=True,
    )

    pages["lost"] = page(
        "lost",
        "LOST",
        "KEY / APPAREL / ENTERTAINMENT / SPORTING GOODS / ELECTRONICS / SHOES / TOYS / HOBBY",
        [img("lost.jpg"), img("lost.gif")],
        "IF YOU WOULD LIKE TO RENT OUT A BUILDING, DON'T HESITATE TO EMAIL US OR GIVE US A CALL: 1-800-DIE-DEAD    gerald@deadbicycle.com",
        [
            frag("Green [25]", img("greendead.gif"), "green"),
            frag("Airplanes [50]", img("firebird_08.gif"), "airplanes"),
            frag("Urban [48a]", img("urban-loco.jpg"), "urban"),
            frag("Supermarket [43]", img("george.jpg"), "supermarket"),
            frag("Military [46]", img("policemanfellow.jpg"), "military"),
            frag("Larry [47]", img("larry_01.jpg"), "larry"),
            frag("Hidden [?]", img("filenotfound3.gif"), "hidden", 3),
        ],
        [
            link("trash", "trash"),
            link("tea", "tea"),
            link("failure", "failure"),
            link("bicycles", "bicycles"),
            link("money", "money"),
            link("wrong random aisle", "randomroom", True),
        ],
    )

    pages["feed"] = page(
        "feed",
        "DEAD FEED",
        "old forum / dead social network / anti residue",
        [img("newfeed.gif"), img("profilescreen.gif"), anti("phorum.gif")],
        "The feed is not chronological. It is whatever survived in the wrong order.",
        [
            frag("profile screen", img("profilescreen.gif"), "profiles"),
            frag("dead comments", img("deadcomments.gif"), "failure"),
            frag("AIM icon still signed in", anti("icon_aim.gif"), "anti"),
        ],
        [link("anti", "anti"), link("gerald", "gerald"), link("dig", "dig"), link("biography leak", "meridian_pull", True), link("random user", "randomroom", True)],
        unstable=True,
        residue_key="DEAD FEED",
    )

    pages["gerald"] = page(
        "gerald",
        "WHERE HAVE GERALD GO?",
        "dear friends / update / police contacted",
        [img("geraldstorybg.gif"), img("djgerald.gif"), img("candidgerald.gif")],
        "Dear Friends, our dear son Gerald has never returned from his fishing trip. UPDATE. GERALD HAS DIED. "
        "AND SO WILL YOU. the police have been contacted.",
        [
            frag("FISHING TRIP", img("goldfish.gif"), "pod"),
            frag("THE POLICE HAVE BEEN CONTACTED", img("policemanfellow.jpg"), "policeman"),
            frag("DJ GERALD", img("djgerald.gif"), "redrobotlove"),
        ],
        [
            link("where has this gerald gone?", "military"),
            link("larry knew somebody", "larry"),
            link("return to directory", "lost"),
            link("gerald is elsewhere", "randomroom", True),
        ],
        unstable=True,
        residue_key="GERALD",
    )

    pages["supermarket"] = page(
        "supermarket",
        "SUPERMARKET",
        "we have no milk for our cereal",
        [img("mildred2.jpg"), img("henry.jpg"), img("george.jpg")],
        "mildred went to buy groceries one day and she never returned. henry went to buy groceries one day and he never returned. "
        "george went to buy groceries one day and he never returned. maybe we will have pancakes.",
        [
            frag("MILDRED / hot green tea", img("mildred2.jpg"), "tea"),
            frag("HENRY / 1987 ford tempo", img("henry.jpg"), "military"),
            frag("GEORGE / laundry", img("george.jpg"), "gerald"),
        ],
        [link("bad aisle", "bad"), link("trash behind store", "trash"), link("return to lost", "lost"), link("random shelf", "randomroom", True)],
        unstable=True,
    )

    pages["hidden"] = page(
        "hidden",
        "THE HIDDEN PAGE",
        "hidden page hidden page hidden page",
        [img("filenotfound3.gif"), img("notfound1.gif"), img("notfound2.gif"), img("404bg.gif")],
        HIDDEN_BODY,
        [
            frag("FILE NOT FOUND FOUND", img("filenotfound3.gif"), "void", 4),
            frag("404 BG", img("404bg.gif"), "dead"),
            frag("LOCKED", img("locked.gif"), "residue"),
        ],
        [link("wrong exit", "randomroom", True), link("void", "void"), link("dead", "dead")],
        hidden=True,
        unstable=True,
        residue_key="HIDDEN PAGE",
    )

    pages["void"] = page(
        "void",
        "FILE NOT FOUND",
        "but it loaded",
        [img("notfound1.gif"), img("notfound2.gif"), img("filenotfound3.gif")],
        "The app opened a missing file. This counts as progress. No one should know why.",
        [
            frag("return image", img("deadcontact.gif"), "dead"),
            frag("missing image", img("file.gif"), "dig"),
        ],
        [link("back into site", "dead"), link("random broken redirect", "randomroom", True)],
        hidden=True,
        unstable=True,
    )

    pages["residue"] = page(
        "residue",
        "RESIDUE",
        "local memory / recovered stains",
        [img("deadstar.gif"), img("deadstar8.gif"), img("deadstar9.gif")],
        "Residue is the app remembering what you touched. It is not score. It is contamination.",
        [
            frag("DEAD STAR", img("deadstar.gif"), "randomroom"),
            frag("DEAD MOOD", img("deadmood.gif"), "feed"),
            frag("DEAD MACHINE", img("deadmachine.gif"), "machine"),
        ],
        [link("feed", "feed"), link("dead", "dead"), link("hidden", "hidden")],
        hidden=True,
    )

    pages["broadcastpanic"] = page(
        "broadcastpanic",
        "EMERGENCY BROADCAST",
        "this is not a test / this is not a conclusion",
        [img("warning.gif"), img("report.gif"), img("notfound2.gif"), img("deaddarkness.gif")],
        "If you are seeing this, the station has confused you with the local signal. Do not seek shelter. "
        "The shelter is one of the rooms. The crawl will now repeat until the app forgets what television was.",
        [
            frag("NOT A TEST", img("warning.gif"), "caseoffice", 5),
            frag("REPORT SIGNAL", img("report.gif"), "reports", 5),
            frag("BLACK SCREEN CONTINUES", img("deaddarkness.gif"), "void", 5),
        ],
        [
            link("stand by", "channelstatic", True),
            link("wrong shelter", "randomroom", True),
            link("turn it off", "dead", True),
        ],
        hidden=True,
        unstable=True,
        residue_key="EBS",
        life_min=-28.0,
        life_max=-6.0,
    )

    pages["channelstatic"] = page(
        "channelstatic",
        "CHANNEL STATIC",
        "not maze / not television / wrong layer",
        [img("dotsandtelevisions.gif"), img("dotsandtelevisions2.gif"), img("theglassofstereo.jpg")],
        "The archive stops being a website and becomes whatever was left on after midnight.",
        [
            frag("GLASS OF STEREO", img("theglassofstereo.jpg"), "stereo"),
            frag("PUBLIC ACCESS DOOR", img("hifi1x42.gif"), "commercialbreak"),
        ],
        [
            link("commercial break", "commercialbreak", True),
            link("panic crawl", "broadcastpanic", True),
        ],
        hidden=True,
        unstable=True,
        residue_key="CHANNEL STATIC",
    )

    pages["dig"] = page(
        "dig",
        "DIG",
        "raw file excavation",
        [img("dig1.gif"), img("dig2.gif"), img("file.gif"), img("file2.gif")],
        "You dug up a file the site forgot it had. The filename may not match the room.",
        [
            frag("OPEN FILE", img("file.gif"), "randomroom"),
            frag("SOURCE", img("file2.gif"), "sourceleak"),
        ],
        [link("dig site", "digsite"), link("lost", "lost"), link("dead", "dead")],
        unstable=True,
    )

    pages["digsite"] = page(
        "digsite",
        "DIG SITE",
        "dig1 / dig2 / dig3 / local excavation",
        [img("dig1.gif"), img("dig2.gif"), img("dig3.gif"), img("dig4.gif")],
        "The DIG button is now a place too. Excavation as navigation.",
        [
            frag("DIG ONE", img("digione.jpg"), "dig"),
            frag("DIG THREE", img("digithree.jpg"), "sourceleak"),
        ],
        [link("dig raw file", "dig"), link("source leak", "sourceleak"), link("lost", "lost")],
        unstable=True,
    )

    pages["machine"] = page(
        "machine",
        "DEAD MACHINE",
        "buttons / load / display diagram",
        [img("deadmachine.gif"), img("machines3.gif"), img("displaydiagram.gif")],
        "The machine is not a device. It is the part of the old site that still tries to operate.",
        [
            frag("DISPLAY DIAGRAM", img("displaydiagram.gif"), "blueprint"),
            frag("CONTROL", img("control.gif"), "puzzle"),
            frag("MACHINEX", img("machinex.jpg"), "reports"),
        ],
        [link("blueprint", "blueprint"), link("puzzle", "puzzle"), link("wrong machine output", "randomroom", True)],
        unstable=True,
    )

    pages["kensington_trash_yard"] = page(
        "kensington_trash_yard",
        "KENSINGTON TRASH YARD",
        "salvage / impound / rain again",
        [img("trash4b.gif"), img("circletrash4.gif"), img("biglegotrash.jpg")],
        "The yard is real now. You woke up outside again. The office door might still be open.",
        [
            frag("ENTER YARD", img("trash4b.gif"), "impound_lot"),
            frag("LIQUOR CORNER", img("circletrash4.gif"), "liquor_store"),
        ],
        [
            link("enter salvage yard", "impound_lot"),
            link("liquor store", "liquor_store"),
            link("vacant lot", "mattress_lot", True),
            link("el bar", "el_bar", True),
            link("back to maze", "lost"),
        ],
        unstable=True,
        residue_key="KENSINGTON YARD",
        location_screen="impound_lot",
    )

    pages["impound_lot"] = page(
        "impound_lot",
        "KENSINGTON SALVAGE YARD",
        "impound lot / day-night / rain",
        [],
        "you woke up drunk. it's raining again.",
        [frag("LOOK AROUND", img("handprint.jpg"), "impound_lot")],
        [
            link("office", "ozzy_basement"),
            link("vacant lot", "mattress_lot"),
            link("theater", "movie_theater", True),
            link("back to archive", "kensington_trash_yard"),
        ],
        location_screen="impound_lot",
    )

    pages["liquor_store"] = page(
        "liquor_store",
        "KENSINGTON LIQUORS",
        "neon / atm / coors",
        [],
        "where's ozzy?",
        [frag("DOOR", img("handprint.jpg"), "impound_lot")],
        [link("yard corner", "impound_lot"), link("archive", "dead"), link("incomplete biography", "meridian_incomplete_file", True)],
        location_screen="liquor_store",
    )

    pages["ozzy_basement"] = page(
        "ozzy_basement",
        "OZZY'S BASEMENT",
        "casino rumor / damp concrete / wrong radio",
        [],
        "The stairs go up to rain. The radio plays someone else's biography.",
        [frag("STAIRS UP", img("handprint.jpg"), "impound_lot"), frag("RADIO STATIC", img("theglassofstereo.jpg"), "meridian_incomplete_file", 3)],
        [
            link("back to yard", "impound_lot"),
            link("dust meridian file", "meridian_incomplete_file", True),
            link("pull a paragraph", "meridian_pull", True),
            link("wrong room", "randomroom", True),
        ],
        unstable=True,
        residue_key="OZZY BASEMENT",
        location_screen="ozzy_basement",
    )

    pages["tv_alley"] = page(
        "tv_alley",
        "TV ALLEY",
        "crt snow / syringes / wrong broadcast",
        [],
        "Here we were (all alone). The television was on again.",
        [frag("STATIC", img("dotsandtelevisions.gif"), "channelstatic"), frag("STREET", img("handprint.jpg"), "lost")],
        [
            link("channel static", "channelstatic", True),
            link("lost directory", "lost"),
            link("wrong signal", "broadcastpanic", True),
        ],
        unstable=True,
        residue_key="TV ALLEY",
        location_screen="tv_alley",
    )

    pages["make_awesome_news"] = page(
        "make_awesome_news",
        "MAKE AWESOME NEWS",
        "vol 13 issue 7 / march 14 / positive force",
        [img("blackline.gif")],
        "A POSITIVE FORCE IN A NEGATIVE WORLD. Beau Lou speaks. Kensington kills again. The footer still routes to the archive.",
        [frag("LEDGER", img("blackline.gif"), "dead")],
        [
            link("founding ledger", "dead", True),
            link("kensington kills", "murder"),
            link("back to yard", "kensington_trash_yard"),
        ],
        unstable=True,
        residue_key="MAKE AWESOME NEWS",
        location_screen="make_awesome_news",
    )

    pages["tv_heaven"] = page(
        "tv_heaven",
        "TV HEAVEN",
        "basement / crt graveyard / arrow down",
        [img("dotsandtelevisions.gif"), img("channelstatic.gif")],
        "TV HEAVEN. Dozens of sets. Most show snow. One is paused on a MAL night game.",
        [frag("SNOW", img("dotsandtelevisions.gif"), "channelstatic")],
        [
            link("channel static", "channelstatic", True),
            link("ozzy basement", "ozzy_basement"),
            link("wrong broadcast", "broadcastpanic", True),
        ],
        unstable=True,
        residue_key="TV HEAVEN",
        location_screen="tv_heaven",
    )

    pages["movie_theater"] = page(
        "movie_theater",
        "THE ABYSS THEATER",
        "now playing / ticket booth / star carpet",
        [img("handprint.jpg")],
        "NOW PLAYING THE ABYSS. Ground scores hide in the lobby trash and ticket dust.",
        [frag("LOBBY", img("handprint.jpg"), "movie_theater")],
        [
            link("enter lobby", "movie_theater"),
            link("tv heaven", "tv_heaven", True),
            link("allegheny", "septa_allegheny"),
        ],
        unstable=True,
        residue_key="THE ABYSS",
        location_screen="movie_theater",
    )

    pages["septa_allegheny"] = page(
        "septa_allegheny",
        "ALLEGHENY STATION",
        "septa eastbound / stair grit / fence line",
        [img("blackline.gif")],
        "Fluorescent hum. Trash can overflow. Something always glints on the steps.",
        [frag("STAIRS", img("blackline.gif"), "septa_allegheny")],
        [
            link("enter station", "septa_allegheny"),
            link("el bar", "el_bar"),
            link("vacant lot", "mattress_lot"),
            link("archive", "dead", True),
        ],
        unstable=True,
        residue_key="ALLEGHENY STATION",
        location_screen="septa_allegheny",
    )

    pages["el_bar"] = page(
        "el_bar",
        "EL BAR",
        "frankford av / neon / est 1963",
        [img("handprint.jpg")],
        "Cold beer good times. Ground scores under the bench and in the crosswalk gutter.",
        [frag("CORNER", img("handprint.jpg"), "el_bar")],
        [
            link("enter bar corner", "el_bar"),
            link("liquor store", "liquor_store"),
            link("allegheny station", "septa_allegheny"),
            link("vacant lot", "mattress_lot"),
        ],
        unstable=True,
        residue_key="EL BAR",
        location_screen="el_bar",
    )

    pages["mattress_lot"] = page(
        "mattress_lot",
        "VACANT LOT",
        "mattress / chain link / purple dusk",
        [img("trash4b.gif"), img("biglegotrash.jpg")],
        "Someone slept on the mattress. The lot keeps giving up ground scores.",
        [frag("LOT", img("trash4b.gif"), "mattress_lot")],
        [
            link("enter lot", "mattress_lot"),
            link("salvage yard", "impound_lot"),
            link("el bar", "el_bar"),
            link("theater", "movie_theater", True),
        ],
        unstable=True,
        residue_key="VACANT LOT",
        location_screen="mattress_lot",
    )

    pages["panhandle"] = page(
        "panhandle",
        "K & A CORNER",
        "kensington av / pawn shop / crosswalk",
        [img("handprint.jpg")],
        "K & A Food Market. Kensington Pawn. Sit on the crosswalk until they look away.",
        [frag("CURB", img("handprint.jpg"), "panhandle")],
        [
            link("enter curb", "panhandle"),
            link("salvage yard", "impound_lot"),
            link("liquor corner", "liquor_store"),
            link("kensington pawn", "pawn_shop"),
            link("allegheny station", "septa_allegheny"),
        ],
        unstable=True,
        residue_key="PANHANDLE CURB",
        location_screen="panhandle",
    )

    pages["pawn_shop"] = page(
        "pawn_shop",
        "KENSINGTON PAWN",
        "cash loans gold / glass case / loan drawer",
        [img("handprint.jpg"), img("circletrash4.gif")],
        "The window keeps lottery tickets like trophies. Griffey card under fluorescent guilt.",
        [frag("PAWN WINDOW", img("handprint.jpg"), "pawn_shop")],
        [
            link("enter pawn", "pawn_shop"),
            link("frankford curb", "panhandle"),
            link("liquor corner", "liquor_store"),
            link("allegheny station", "septa_allegheny"),
        ],
        unstable=True,
        residue_key="PAWN SHOP",
        location_screen="pawn_shop",
    )

    pages["underpass"] = page(
        "underpass",
        "KENSINGTON UNDERPASS",
        "kensington av 2800 / wet tunnel / crosswalk",
        [img("handprint.jpg"), img("trash4b.gif")],
        "Stay in lane. No pedestrians. Sit on the zebra stripes until someone looks away.",
        [frag("TUNNEL CROSSWALK", img("handprint.jpg"), "underpass")],
        [
            link("enter tunnel", "underpass"),
            link("frankford curb", "panhandle"),
            link("el bar", "el_bar"),
            link("allegheny station", "septa_allegheny"),
        ],
        unstable=True,
        residue_key="UNDERPASS",
        location_screen="underpass",
    )

    pages["record_store"] = page(
        "record_store",
        "SIGNAL STATIC",
        "frankford av / vinyl wall / buy retail",
        [img("handprint.jpg")],
        "Buy records at full price. Sell them back poorer.",
        [frag("VINYL WALL", img("handprint.jpg"), "record_store")],
        [
            link("enter shop", "record_store"),
            link("el bar", "el_bar"),
            link("allegheny station", "septa_allegheny"),
        ],
        unstable=True,
        residue_key="RECORD STORE",
        location_screen="record_store",
    )

    pages["japan_doll_basement"] = page(
        "japan_doll_basement",
        "JAPAN DOLL BASEMENT",
        "hardcore basement / pearl kit / wrong door",
        [img("handprint.jpg"), img("circletrash4.gif")],
        "Japan Doll banner drips red. Infest Integrity Unbroken on the walls. Almost nobody finds the stairs.",
        [frag("BASEMENT SHOW", img("handprint.jpg"), "japan_doll_basement", 2)],
        [
            link("enter basement", "japan_doll_basement"),
            link("ozzy basement", "ozzy_basement", True),
            link("signal static", "record_store"),
        ],
        hidden=True,
        unstable=True,
        residue_key="JAPAN DOLL",
        location_screen="japan_doll_basement",
    )

    pages["salvage_sitemap"] = page(
        "salvage_sitemap",
        "SALVAGE INDEX",
        "unopened folder / grenades residue",
        [img("filenotfound3.gif"), img("grenade1.jpg"), img("trash.gif")],
        "A folder that should not exist on the original site. It routes into Philadelphia debris and salvage logic.",
        [
            frag("TRASH YARD", img("trash4b.gif"), "kensington_trash_yard"),
            frag("GRENADES", img("grenade1.jpg"), "grenades"),
        ],
        [
            link("kensington yard", "kensington_trash_yard"),
            link("grenades", "grenades", True),
            link("lost", "lost"),
        ],
        hidden=True,
        unstable=True,
    )

    pages["caseoffice"] = page(
        "caseoffice",
        "CASE OFFICE",
        "municipal domestic incident board",
        [img("report.gif"), img("report1.jpg"), img("policebox.gif")],
        "Lesser-used archive pages filed as evidence. VACUUM. TOWN. INCISION. LOVE.",
        [
            frag("REPORT FORM", img("report.gif"), "reports"),
            frag("OPEN VACUUM", img("displaydiagram.gif"), "vacuum"),
            frag("OPEN TOWN", img("policebox.gif"), "town"),
        ],
        [link("vacuum bureau", "vacuum"), link("town list", "town"), link("broadcast test", "broadcastpanic", True)],
        hidden=True,
        unstable=True,
        residue_key="CASE OFFICE",
    )

    # simple rooms
    for pid, data in [
        ("military", ("MILITARY", "the 24 minute song / sheriff jake", ["policemanfellow.jpg", "camo2.gif", "grenade1.jpg"], MILITARY_BODY, ["gerald", "reports", "ashtray"])),
        ("larry", ("LARRY SUSAN JIM", "biographical fire / television", ["larry_01.jpg", "larryeye3.jpg", "larryface11.jpg"], LARRY_BODY, ["fire", "failure", "gerald"])),
        ("anti", ("ANTI", "fake community / image buttons", ["house2.jpg"], "The anti directory pretends to be infrastructure.", ["feed", "gerald", "profiles"])),
        ("profiles", ("PROFILES", "dead social layer", ["profilescreen.gif", "candidfeed.gif"], "These profiles are rooms wearing names.", ["feed", "anti", "gerald"])),
        ("reports", ("REPORTS", "police / paper", ["report.gif", "report1.jpg"], "A report exists. That does not mean anyone filed it.", ["policeman", "gerald", "military"])),
        ("dots", ("DOTS AND TELEVISIONS", "circles / loops / broadcast static", ["dotsandtelevisions.gif", "dotsandcircles.gif"], "The archive as a screensaver.", ["stereo", "circles", "void"])),
        ("bicycles", ("BICYCLES", "logo / green bike", ["bikesandbikes.jpg", "greenbike.gif"], "The bicycle is the original machine.", ["roads", "green", "fire"])),
        ("failure", ("FAILURE", "no clean resolution", ["everyonedie.gif", "deaddarkness.gif"], "Failure forgot to be funny.", ["hidden", "larry", "dead"])),
        ("trash", ("TRASH", "lego / circle / bins", ["trash.gif", "biglegotrash.jpg"], "The trash room is the archive admitting what it is.", ["anti", "supermarket", "redrobotlove"])),
        ("tea", ("TEA", "green tea / gun tea", ["teagun.jpg", "mildred.gif"], "Mildred was last seen drinking hot green tea.", ["supermarket", "green", "military"])),
        ("money", ("MONEY", "bill roll / dollar", ["billroll1.jpg", "dollar.jpg"], "Money exists here as a JPEG and nothing else.", ["lost", "supermarket", "anti"])),
        ("green", ("GREEN", "green dead / green road", ["greendead.gif", "greenbike.gif"], "Green is one of the archive's fake taxonomies.", ["tea", "roads", "lost"])),
        ("urban", ("URBAN", "loco / city / road", ["urban-loco.jpg", "city3bg.jpg"], "Urban tried to become a city and only found a background.", ["roads", "town", "lost"])),
        ("airplanes", ("AIRPLANES", "firebird / hovercraft", ["firebird_08.gif", "hovercraft.jpg"], "This room wants travel but only has image files.", ["roads", "racecar", "fire"])),
        ("fire", ("FIRE", "television / firebird", ["firebird_01.gif", "larryface.jpg"], "Larry left the TV on. The page still smells warm.", ["larry", "kerosene", "airplanes"])),
        ("policeman", ("POLICEMAN", "fellow / report", ["policemanfellow.jpg", "policebox.gif"], "The police have been contacted.", ["reports", "gerald", "military"])),
        ("town", ("TOWN", "municipal death list", ["city3bg.jpg", "traffic.jpg", "skullandcrossbones.gif"], "Charlie was murdered by Joe. Kevin died of bone cancer. This is the archive as a town ledger.", ["violent", "caseoffice", "pavement"])),
        ("vacuum", ("VACUUM", "new carpet / muddy boots", ["redman.jpg", "children1.jpg"], "henry walked on the new carpet with his muddy boots.", ["machine", "children", "caseoffice"])),
        ("children", ("CHILDREN", "four images / four wrong exits", ["children1.jpg", "children3.jpg"], "Faces without explanation, exits without comfort.", ["mugshot", "supermarket", "military"])),
        ("stereo", ("STEREO", "glass / hifi", ["theglassofstereo.jpg", "hifi1x42.gif"], "The stereo room is a promise that sound was withheld.", ["headphones", "computers", "feed"])),
        ("blueprint", ("BLUEPRINT", "diagram / impossible house", ["blueprint_01.jpg", "blueprint_05.jpg"], "Blueprints imply there was a plan.", ["machine", "room", "policeman"])),
        ("puzzle", ("PUZZLE", "pieces out of order", ["puzzle1.jpg", "puzzle5.jpg"], "Numbered pieces with no promised complete image.", ["machine", "reports", "hidden"])),
        ("happy", ("HAPPY", "hooray / forced grin", ["hooray.jpg", "happyeverafter.jpg"], "Happy is suspicious.", ["failure", "lost"])),
        ("pod", ("POD", "container with no contents", ["pod.jpg", "podbg.gif"], "Touching it feels like opening something that would rather stay shut.", ["gerald", "room", "machine"])),
        ("room", ("ROOM", "house / chair / temperature", ["chair.gif", "bg.jpg"], "He sat in a dark room all by himself.", ["military", "pod", "computers"])),
        ("roads", ("ROADS", "green / gray / orange", ["greenroad.jpg", "grayroad.jpg", "orangeroad.jpg"], "All roads are image files.", ["green", "urban", "fire"])),
        ("sourceleak", ("SOURCE LEAK", "php / sql guts", ["file.gif", "loading.gif"], "The site accidentally opened its own stomach.", ["anti", "gerald", "computers"])),
        ("grenades", ("GRENADES", "dropdown / sitemap residue", ["grenade1.jpg", "grenade3.jpg"], "A menu that should not resolve.", ["military", "reports", "salvage_sitemap"])),
    ]:
        title, subtitle, images, body, exits = data
        pages[pid] = simple(pid, title, subtitle, images, body, exits, unstable=True)

    return pages


def normalize_href(href: str, from_dir: Path) -> str | None:
    href = href.strip()
    if not href or href.startswith("#") or href.startswith("mailto:") or href.startswith("javascript:"):
        return None
    if href.startswith("http"):
        return None
    target = (from_dir / href).resolve()
    try:
        rel = target.relative_to(ARCHIVE.resolve())
    except ValueError:
        return None
    parts = rel.parts
    if rel.suffix.lower() in {".jpg", ".jpeg", ".gif", ".png", ".swf"}:
        return None
    if rel.name == "index.html" and len(parts) >= 2:
        return parts[-2].lower()
    if rel.suffix.lower() in {".html", ".shtml", ".htm"}:
        stem = rel.stem.lower()
        if stem == "index" and len(parts) >= 2:
            return parts[-2].lower()
        return stem
    return None


def parse_html_page(html_path: Path) -> dict | None:
    text = html_path.read_text(encoding="utf-8", errors="ignore")
    folder = html_path.parent
    if folder == ARCHIVE:
        page_id = "dead_index"
    else:
        page_id = folder.name.lower()

    title_match = re.search(r"<title>([^<]+)</title>", text, re.I)
    title = title_match.group(1).strip() if title_match else page_id.upper()

    images: list[str] = []
    for m in re.finditer(r'<img[^>]+src="([^"]+)"', text, re.I):
        src = m.group(1)
        if src.startswith("http"):
            continue
        resolved = (folder / src).resolve()
        try:
            rel = resolved.relative_to(ARCHIVE.resolve())
            images.append("res://archive/deadbicycle/" + str(rel).replace("\\", "/"))
        except ValueError:
            pass

    body_bits = re.sub(r"<[^>]+>", " ", text)
    body_bits = re.sub(r"\s+", " ", body_bits).strip()
    if len(body_bits) > 600:
        body_bits = body_bits[:600] + "..."

    links: list[dict] = []
    fragments: list[dict] = []
    seen: set[str] = set()
    for m in re.finditer(r'<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', text, re.I | re.S):
        href = m.group(1)
        dest = normalize_href(href, folder)
        if not dest or dest in seen:
            continue
        seen.add(dest)
        label = re.sub(r"<[^>]+>", "", m.group(2)).strip() or dest
        links.append(link(label[:48], dest))

    for i, path in enumerate(images[:8]):
        label = Path(path).stem.upper().replace("_", " ")
        dest = links[i % len(links)]["destination"] if links else "randomroom"
        fragments.append(frag(label, path, dest))

    if folder == ARCHIVE:
        # Original index handprint hotspots
        fragments = [
            frag("TOWN", img("handprint.jpg"), "town"),
            frag("URBAN", img("handprint.jpg"), "urban"),
            frag("SKULL", img("handprint.jpg"), "skull"),
            frag("SUPERMARKET", img("handprint.jpg"), "supermarket"),
        ]
        page_id = "dead"
        title = "dead DEAD dead"

    return page(
        page_id,
        title,
        f"original /{folder.name}" if folder != ARCHIVE else "original index",
        images[:6],
        body_bits,
        fragments,
        links[:12],
        unstable=True,
    )


def pages_from_html() -> dict[str, dict]:
    out: dict[str, dict] = {}
    for html_path in sorted(ARCHIVE.rglob("index.html")):
        parsed = parse_html_page(html_path)
        if parsed:
            out[parsed["id"]] = parsed
    return out


def weave_targets(pages: dict[str, dict], targets: list[str], replacements_per_target: int = 14) -> None:
    import random

    slots: list[tuple[str, int, str]] = []
    skip_dest = {"randomroom", "unstable", "dig", "void"}
    for pid, pdata in pages.items():
        for i, entry in enumerate(pdata.get("links", [])):
            dest = str(entry.get("destination", ""))
            if dest in skip_dest or pid == dest:
                continue
            slots.append((pid, i, "links"))
        for i, entry in enumerate(pdata.get("fragments", [])):
            dest = str(entry.get("destination", ""))
            if dest in skip_dest or pid == dest:
                continue
            slots.append((pid, i, "fragments"))

    if not slots:
        return

    random.shuffle(slots)
    slot_idx = 0
    for target in targets:
        if target not in pages:
            continue
        for _ in range(replacements_per_target):
            if slot_idx >= len(slots):
                slot_idx = 0
                random.shuffle(slots)
            pid, idx, kind = slots[slot_idx]
            slot_idx += 1
            if kind == "links":
                pages[pid]["links"][idx]["destination"] = target
                pages[pid]["links"][idx]["label"] = f"wrong door / {target.replace('_', ' ')}"
                pages[pid]["links"][idx]["unstable"] = True
            else:
                pages[pid]["fragments"][idx]["destination"] = target


def ensure_inbound_links(pages: dict[str, dict]) -> None:
    import random

    inbound: dict[str, int] = {pid: 0 for pid in pages}
    skip = {"randomroom", "unstable", "dig", "void"}
    for pdata in pages.values():
        for entry in pdata.get("links", []):
            dest = str(entry.get("destination", ""))
            if dest in inbound and dest not in skip:
                inbound[dest] += 1
        for entry in pdata.get("fragments", []):
            dest = str(entry.get("destination", ""))
            if dest in inbound and dest not in skip:
                inbound[dest] += 1

    hubs = ["dead", "lost", "feed", "gerald", "larry", "failure"]
    for pid, count in inbound.items():
        if count > 0 or pid == "dead":
            continue
        hub = random.choice(hubs)
        pages[hub]["links"].append(link(f"misfiled / {pid.replace('_', ' ')}", pid, True))


def main() -> None:
    from meridian_pages import meridian_pages

    pages = pages_from_html()
    pages.update(authored_pages())  # authored wins
    pages.update(meridian_pages(page, link, frag, img))
    weave_targets(pages, WEAVE_TARGETS)
    weave_targets(pages, ["japan_doll_basement"], replacements_per_target=32)
    ensure_inbound_links(pages)

    payload = {
        "generated": "DOOM DANCE maze builder",
        "start_room": "dead",
        "page_count": len(pages),
        "pages": pages,
    }
    OUT.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"Wrote {OUT} ({len(pages)} pages)")


if __name__ == "__main__":
    main()
