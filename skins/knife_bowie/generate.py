#!/usr/bin/env python3
import sys
import glob
import math
import shutil
import os.path
import fileinput

if len(sys.argv) < 2:
    print('Missing weapon name argument!')
    exit(0)

weapon = sys.argv[1]
fresh = len(sys.argv) > 2

max_per_file = 40
compiler = 'studiomdl.exe'

skins = glob.glob("{}_[!default]*.bmp".format(weapon))
skins = ["{}_default.bmp".format(weapon)] + skins

if fresh:
    files = glob.glob("v_{}_*.qc".format(weapon))

    for file in files:
        os.remove(file)

for index, skin in enumerate(skins, start=0):
    smd = skin.replace(".bmp", ".smd")

    if fresh or not os.path.isfile(smd):
        shutil.copyfile("{}.smd".format(weapon), smd)

        with fileinput.FileInput(smd, inplace=True) as file:
            for line in file:
                print(line.replace("{}.bmp".format(weapon), skin), end='')

    order = math.floor(index / max_per_file)
    filename = "v_{}_{}.qc".format(weapon, order)

    if not os.path.isfile(filename):
        shutil.copyfile("v_{}.qc".format(weapon), filename)

        with fileinput.FileInput(filename, inplace=True) as file:
            for line in file:
                print(line.replace("v_{}.mdl".format(weapon), "v_{}_{}.mdl".format(weapon, order)), end='')

    with fileinput.FileInput(filename.format(weapon), inplace=True) as file:
        found = False

        for line in file:
            entry = "studio \"{}\"".format(skin.replace(".bmp", ""))

            if entry in line:
                found = True

            if "// end" in line and not found:
                print(line.replace(line, entry + "\n" + line), end='')
            else:
                print(line, end='')

files = glob.glob("v_{}_*.qc".format(weapon))

for file in files:
    os.system("{} {}".format(compiler, file))
