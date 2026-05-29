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
        [link("anti", "anti"), link("gerald", "gerald"), link("dig", "dig"), link("random user", "randomroom", True)],
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
        [link("office", "liquor_store"), link("back to archive", "kensington_trash_yard")],
        location_screen="impound_lot",
    )

    pages["liquor_store"] = page(
        "liquor_store",
        "KENSINGTON LIQUORS",
        "neon / atm / coors",
        [],
        "where's ozzy?",
        [frag("DOOR", img("handprint.jpg"), "impound_lot")],
        [link("yard corner", "impound_lot"), link("archive", "dead")],
        location_screen="liquor_store",
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


def main() -> None:
    pages = pages_from_html()
    pages.update(authored_pages())  # authored wins

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
