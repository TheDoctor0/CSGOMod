#!/usr/bin/env python3
import sys
import glob
import math
import shutil
import os.path
import fileinput

max_per_file = 40
compiler = "studiomdl.exe"

weapon = os.path.basename(os.path.normpath(os.getcwd()))
fresh = len(sys.argv) > 1

if not os.path.isfile("template.smd"):
    print("Template SMD file (template.smd) does not exists!")
    exit(0)

if not os.path.isfile("template.qc"):
    print("Template QC file (template.qc) does not exists!")
    exit(0)

if not os.path.isfile("default.bmp"):
    print("Default weapon texture file (default.bmp) does not exists!")
    exit(0)

if not os.path.isfile("default.qc"):
    print("Default weapon QC file (default.qc) does not exists!")
    exit(0)

if not os.path.isdir("bmp"):
    print("Directory (bmp) that contains skin textures does not exists!")
    exit(0)

skins = glob.glob("bmp/*.bmp".format(weapon))

if fresh:
    files = glob.glob("v_{}_*.qc".format(weapon))

    for file in files:
        os.remove(file)

for index, skin in enumerate(skins, start=0):
    original = skin
    skin = skin.lower().replace(' ', '_').replace('\'', '_')

    if original != skin:
        os.rename(original, skin)

    smd = skin.replace("bmp", "smd")

    if not os.path.isdir("smd"):
        os.mkdir("smd")

    if fresh or not os.path.isfile(smd):
        shutil.copyfile("template.smd", smd)

        with fileinput.FileInput(smd, inplace=True) as file:
            for line in file:
                print(line.replace("{}.bmp".format(weapon), skin), end='')

    order = math.floor(index / max_per_file)
    filename = "v_{}_{}.qc".format(weapon, order)

    if not os.path.isfile(filename):
        shutil.copyfile("template.qc", filename)

        with fileinput.FileInput(filename, inplace=True) as file:
            for line in file:
                print(line.replace("v_{}.mdl".format(weapon), "v_{}_{}.mdl".format(weapon, order)), end='')

    with fileinput.FileInput(filename.format(weapon), inplace=True) as file:
        found = False

        for line in file:
            entry = "studio \"{}\"".format(smd.replace(".smd", ""))

            if entry in line:
                found = True

            if "// end" in line and not found:
                print(line.replace(line, entry + "\n" + line), end='')
            else:
                print(line, end='')

files = glob.glob("v_{}_*.qc".format(weapon))
files = ["default.qc"] + files

for file in files:
    os.system("{} {}".format(compiler, file))
