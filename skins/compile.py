#!/usr/bin/env python3
import sys
import os
import glob
import math
import shutil
import fileinput
from os import path

weapons = {
    "random": {"random": 125.0},
    "knife": {"random": 250.0, "skin": 1000},
    "knife_bayonet": {"random": 250.0, "skin": 1000},
    "knife_bowie": {"random": 250.0, "skin": 1000},
    "knife_butterfly": {"random": 250.0, "skin": 1000},
    "knife_daggers": {"random": 250.0, "skin": 1000},
    "knife_falchion": {"random": 250.0, "skin": 1000},
    "knife_flip": {"random": 250.0, "skin": 1000},
    "knife_gut": {"random": 250.0, "skin": 1000},
    "knife_huntsman": {"random": 250.0, "skin": 1000},
    "knife_karambit": {"random": 250.0, "skin": 1000},
    "knife_m9_bayonet": {"random": 250.0, "skin": 1000},
    "knife_navaja": {"random": 250.0, "skin": 1000},
    "knife_nomad": {"random": 250.0, "skin": 1000},
    "knife_paracord": {"random": 250.0, "skin": 1000},
    "knife_skeleton": {"random": 250.0, "skin": 1000},
    "knife_stiletto": {"random": 250.0, "skin": 1000},
    "knife_survival": {"random": 250.0, "skin": 1000},
    "knife_talon": {"random": 250.0, "skin": 1000},
    "knife_ursus": {"random": 250.0, "skin": 1000},
    "ak47": {"random": 50.0, "skin": 200},
    "m4a1": {"random": 50.0, "skin": 200},
    "m4a4": {"random": 50.0, "skin": 200},
    "awp": {"random": 50.0, "skin": 200},
    "deagle": {"random": 30.0, "skin": 120},
    "usp": {"random": 25.0, "skin": 100},
    "glock18": {"random": 25.0, "skin": 100},
    "galil": {"random": 20.0, "skin": 80},
    "famas": {"random": 20.0, "skin": 80},
    "p90": {"random": 15.0, "skin": 60},
    "mp5navy": {"random": 15.0, "skin": 60},
    "ump45": {"random": 15.0, "skin": 60},
    "mac10": {"random": 10.0, "skin": 40},
    "tmp": {"random": 10.0, "skin": 40},
    "scout": {"random": 15.0, "skin": 60},
    "aug": {"random": 20.0, "skin": 80},
    "sg552": {"random": 20.0, "skin": 80, "skins": ["", "Aerial", "Cyrex", "Phantom", "Pulse", "Tiger Moth", "Triarch"]},
    "p228": {"random": 10.0, "skin": 40},
    "fiveseven": {"random": 10.0, "skin": 40},
    "elite": {"random": 10.0, "skin": 40, "skins": ["", "Cobalt Quartz", "Dualing Dragons", "Royal Consorts", "Urban Shock"]},
    "m3": {"random": 10.0, "skin": 40, "skins": ["", "Antique", "Hyperbeast", "Koi", "Rising Skull"]},
    "xm1014": {"random": 10.0, "skin": 40},
    "m249": {"random": 10.0, "skin": 40, "skins": ["", "Gator Mesh", "Nebula Crusader", "Sprectre", "System Lock"]},
    "sg550": {"random": 10.0, "skin": 40},
    "g3sg1": {"random": 10.0, "skin": 40},
    "flashbang": False,
    "hegrenade": False,
    "smokegrenade": False,
    "molotov": False,
    "zeus": False,
    "c4": False,
    "thighpack": False,
}

models_directory = f"models/{sys.argv[1] if len(sys.argv) > 1 and len(sys.argv[1]) else 'csgo_ozone'}"
compiler = "studiomdl.exe"
compiled_directory = "_compiled"
skins_directory = "skins"
smd_directory = "smd"
skins_ini = "csgo_skins.ini"
smd_template = "template.smd"
qc_template = "template.qc"
default_skin = "default.bmp"
max_per_file = 40

if not path.exists(compiled_directory):
    os.mkdir(compiled_directory)

with open(path.join(compiled_directory, skins_ini), 'w+') as generated_ini:
    generated_ini.write(""";---INSTRUCTIONS---
; [WEAPON NAME - Price of Drawing (set to 0.0 to disable for this weapon)]
; "Skin Name" "Model Path" "Submodel Index" "Price" "Odds" "Buyable"
;
; NOTES:
; 1. Skin names must be unique.
;
; 2. Submodels are always numbered from 0.
;
; 3. The odds must be greater than 1 - if the undefined odds will be set to 1.
; The greater the odds, the greater the probability of a particular skin being drawn
; and the smaller the chance of others being drawn.
;
; 4. Non-buyable skins are not available for purchase or in draw.

; Optional possibility to draw any skin (set to 0.0 to disable)""")

    for weapon in weapons.keys():
        if weapon != "random":
            weapon_compiled_directory = path.join(compiled_directory, weapon)

            if path.exists(weapon_compiled_directory):
                shutil.rmtree(weapon_compiled_directory)

            os.mkdir(weapon_compiled_directory)

        weapon_data = weapons.get(weapon)

        if weapon_data is False:
            model_files = glob.glob(path.join(weapon, f"*_{weapon}.mdl"))

            for model_file in model_files:
                shutil.copyfile(model_file, path.join(compiled_directory, model_file))

            continue

        if 'knife_' not in weapon and weapon != 'm4a4':
            generated_ini.write(f"\n[{weapon.upper()} - {weapon_data.get('random')}]\n")

            if weapon == "random":
                continue

        existing_skins = weapon_data.get('skins')

        if existing_skins is not None:
            for index, skin_name in enumerate(existing_skins, start=0):
                if index > 0:
                    generated_ini.write(f'"{skin_name}"'
                                        f'\t\t"{f"{models_directory}/v_{weapon}_{index}.mdl"}"'
                                        f'\t\t"0"'
                                        f'\t\t"{weapons.get(weapon).get("skin")}"'
                                        f'\t\t"1"'
                                        f'\t\t"1"\n')

                model_file = f"{weapon}/v_{weapon}_{index}.mdl"

                shutil.copyfile(model_file, path.join(compiled_directory, model_file))

            continue

        if not path.isfile(path.join(weapon, smd_template)):
            print(f"File `{smd_template}` for weapon {weapon} does not exists!")
            exit(0)

        if not path.isfile(path.join(weapon, qc_template)):
            print(f"File `{qc_template}` for weapon {weapon} does not exists!")
            exit(0)

        if not path.isfile(path.join(weapon, default_skin)):
            print(f"File `{default_skin}` for weapon {weapon} does not exists!")
            exit(0)

        if not path.isdir(path.join(weapon, skins_directory)):
            print(f"Directory `{skins_directory}` for weapon {weapon} does not exists!")
            exit(0)

        weapon_smd_directory = path.join(weapon, smd_directory)

        if path.exists(weapon_smd_directory):
            shutil.rmtree(weapon_smd_directory)

        os.mkdir(weapon_smd_directory)

        skins = glob.glob(path.join(weapon, skins_directory, "*.bmp"))

        for index, skin in enumerate(skins, start=1):
            smd = skin.replace(skins_directory, smd_directory).replace(".bmp", ".smd")

            shutil.copyfile(path.join(weapon, smd_template), smd)

            with fileinput.FileInput(smd, inplace=True) as file:
                for line in file:
                    print(line.replace(default_skin, skin.replace(path.join(weapon, ""), "")), end='')

            order = math.floor(index / max_per_file)
            filename = path.join(weapon, f"v_{weapon}_{order}.qc")

            if not path.isfile(filename):
                shutil.copyfile(path.join(weapon, qc_template), filename)

                with fileinput.FileInput(filename, inplace=True) as file:
                    for line in file:
                        print(line.replace(f"v_{weapon}.mdl", f"v_{weapon}_{order}.mdl"), end='')

            with fileinput.FileInput(filename.format(weapon), inplace=True) as file:
                found = False

                for line in file:
                    entry = f'studio \"{smd.replace(path.join(weapon, ""), "").replace(".smd", "")}\"'

                    if index == 1:
                        entry = f'studio "{smd_template.replace(".smd", "")}"\n{entry}'

                    if entry in line:
                        found = True

                    if "// end" in line and not found:
                        print(line.replace(line, f'{entry}\n{line}'), end='')
                    else:
                        print(line, end='')

            if weapon in ["m4a4", "knife"]:
                prefix = f'{weapon.title()} | '
            elif "knife_" in weapon:
                prefix = f'{weapon.replace("knife_", "").title()} | '
            else:
                prefix = ""

            skin_name = skin.replace(path.join(weapon, skins_directory, ""), "")\
                .replace(f"{weapon}_", "")\
                .replace(".bmp", "")\
                .replace("_", " ")\
                .title()

            generated_ini.write(f'"{prefix}{skin_name}"'
                                f'\t\t"{f"{models_directory}/v_{weapon}_{order}.mdl"}"'
                                f'\t\t"{index - order * max_per_file}"'
                                f'\t\t"{weapon_data.get("skin")}"'
                                f'\t\t"1"'
                                f'\t\t"1"\n')

        shutil.copyfile(compiler, path.join(weapon, compiler))

        qc_files = glob.glob(path.join(weapon, f"v_{weapon}_*.qc"))

        for qc_file in qc_files:
            os.system(f'cd {weapon} && {compiler} {qc_file.replace(path.join(weapon, ""), "")}')
            os.remove(qc_file)

        os.remove(path.join(weapon, compiler))
        shutil.rmtree(weapon_smd_directory)

        model_files = glob.glob(path.join(weapon, f"v_{weapon}_*.mdl"))

        for model_file in model_files:
            shutil.move(model_file, path.join(compiled_directory, model_file))

print('Finished compiling skins and generating `csgo_skins.ini`.')
