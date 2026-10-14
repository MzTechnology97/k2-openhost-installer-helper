#!/usr/bin/env python3
"""K2-OpenHost: set crowsnest up for the K2 Pro chamber camera (Creality CAM).

The camera (USB 1d6c:0103, Fullhan firmware) needs two things from crowsnest:
  * max_fps 25: at 30 fps its auto exposure, once set, settles on a black
    image; at 25 fps (the stock T113 rate) it settles bright;
  * its controls in v4l2ctl: crowsnest sends them before the stream starts,
    as the stock firmware did. Sent while streaming, the first change after
    power-on blanks the image.

    crowsnest_creality_cam.py CONF DEVICE [DEVICE...] [--dry-run]

DEVICE is a video node of the camera (a /dev/v4l/by-id link or /dev/videoN).
Every [cam ...] section whose device resolves to one of them gets max_fps 25
and, unless it already has one, the v4l2ctl line below. A crowsnest default
resolution (640x480) becomes 1920x1080, the tested mode. Other sections and
lines are left as they are. Exit status: 0 changed or nothing to change,
3 no section uses the camera, 2 error.
"""
import os
import re
import shutil
import sys
import time

FPS = "25"
RESOLUTION = "1920x1080"
DEFAULT_RESOLUTION = "640x480"
CONTROLS = ("brightness=128,contrast=128,sharpness=128,saturation=128,"
            "power_line_frequency=1,auto_exposure=3")
FPS_NOTE = "# Creality CAM: at 30 fps its auto exposure goes black"
CTRL_NOTE = "# Creality CAM: set before the stream; needs max_fps 25"
# auto_exposure 1 (manual) and 2 (shutter priority) freeze this camera black.
BAD_EXPOSURE = re.compile(r"(?:^|[,\s])(?:auto_exposure|exposure_auto)=([12])\b")
SECTION = re.compile(r"^\s*\[([^\]]+)\]")
OPTION = re.compile(r"^(\s*)([A-Za-z0-9_]+)\s*:\s*([^#]*?)\s*(#.*)?$")


def option_line(name, value, note):
    return "%-39s %s\n" %("%s: %s" % (name, value), note)


def sections(lines):
    """(name, first, end) of each section; first is the header line."""
    found = []
    for i, line in enumerate(lines):
        match = SECTION.match(line)
        if match:
            if found:
                found[-1][2] = i
            found.append([match.group(1).strip(), i, len(lines)])
    return found


def options(lines, first, end):
    found = {}
    for i in range(first + 1, end):
        match = OPTION.match(lines[i])
        if match:
            found[match.group(2)] = (i, match.group(3).strip())
    return found


def same_device(path, cameras):
    try:
        return os.path.realpath(path) in cameras
    except (OSError, ValueError):
        return False


def update(lines, cameras):
    """The edited lines, the cam sections changed or checked, warnings."""
    lines = list(lines)
    touched, warnings = [], []
    for name, first, end in reversed(sections(lines)):
        if not name.startswith("cam "):
            continue
        opts = options(lines, first, end)
        if "device" not in opts or not same_device(opts["device"][1], cameras):
            continue
        touched.append(name)
        insert_at = max(i for i, _ in opts.values()) + 1 if opts else first + 1
        if "v4l2ctl" in opts:
            value = opts["v4l2ctl"][1]
            if BAD_EXPOSURE.search(value):
                warnings.append("[%s] v4l2ctl sets manual exposure (auto_exposure 1/2): "
                                "it freezes this camera black, use 3" % name)
        else:
            lines.insert(insert_at, option_line("v4l2ctl", CONTROLS, CTRL_NOTE))
        if "max_fps" in opts:
            i, value = opts["max_fps"]
            if value != FPS:
                lines[i] = option_line("max_fps", FPS, FPS_NOTE)
        else:
            lines.insert(insert_at, option_line("max_fps", FPS, FPS_NOTE))
        if "resolution" in opts and opts["resolution"][1] == DEFAULT_RESOLUTION:
            lines[opts["resolution"][0]] = option_line(
                "resolution", RESOLUTION, "# Creality CAM: tested mode")
    return lines, list(reversed(touched)), warnings


def main(argv):
    dry_run = "--dry-run" in argv
    args = [a for a in argv if a != "--dry-run"]
    if len(args) < 2:
        print("usage: crowsnest_creality_cam.py CONF DEVICE [DEVICE...] [--dry-run]",
              file=sys.stderr)
        return 2
    conf, devices = args[0], args[1:]
    cameras = {os.path.realpath(d) for d in devices}
    try:
        with open(conf, encoding="utf-8") as handle:
            before = handle.readlines()
    except OSError as exc:
        print("cannot read %s: %s" % (conf, exc), file=sys.stderr)
        return 2
    if before and not before[-1].endswith("\n"):
        before[-1] += "\n"
    after, touched, warnings = update(before, cameras)
    for warning in warnings:
        print("WARNING: " + warning)
    if not touched:
        print("no [cam] section in %s uses the Creality CAM" % conf)
        return 3
    if after == before:
        print("%s already set for the Creality CAM (%s)" % (conf, ", ".join(touched)))
        return 0
    if dry_run:
        sys.stdout.writelines(after)
        return 0
    backup = "%s.k2oh-%s.bak" % (conf, time.strftime("%Y%m%d-%H%M%S"))
    shutil.copy2(conf, backup)
    with open(conf, "w", encoding="utf-8") as handle:
        handle.writelines(after)
    print("updated %s for the Creality CAM (%s); backup %s"
          % (conf, ", ".join(touched), backup))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
