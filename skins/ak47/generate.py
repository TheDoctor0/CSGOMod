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

if not os.path.isfile("{}.smd".format(weapon)):
    print("Template file {}.smd does not exists!".format(weapon))
    exit(0)

if not os.path.isfile("v_{}.qc".format(weapon)):
    print("Template file v_{}.qc does not exists!".format(weapon))
    exit(0)

if not os.path.isfile("v_{}.qc".format(weapon)):
    print("Default weapon skin {}_default.bmp does not exists!".format(weapon))
    exit(0)

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
