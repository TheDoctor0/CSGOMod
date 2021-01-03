#!/usr/bin/env python3
import sys
import os
import glob
import math
import shutil
import fileinput
from os import path

weapons = {
    "random": {"random": 50.0},
    "knife": {"random": 500.0, "skin": 2500},
    "knife_bayonet": {"random": 500.0, "skin": 2500},
    "knife_bowie": {"random": 500.0, "skin": 2500},
    "knife_butterfly": {"random": 500.0, "skin": 2500},
    "knife_daggers": {"random": 500.0, "skin": 2500},
    "knife_falchion": {"random": 500.0, "skin": 2500},
    "knife_flip": {"random": 500.0, "skin": 2500},
    "knife_gut": {"random": 500.0, "skin": 2500},
    "knife_huntsman": {"random": 500.0, "skin": 2500},
    "knife_karambit": {"random": 500.0, "skin": 2500},
    "knife_m9_bayonet": {"random": 500.0, "skin": 2500},
    "knife_navaja": {"random": 500.0, "skin": 2500},
    "knife_nomad": {"random": 500.0, "skin": 2500},
    "knife_paracord": {"random": 500.0, "skin": 2500},
    "knife_skeleton": {"random": 500.0, "skin": 2500},
    "knife_stiletto": {"random": 500.0, "skin": 2500},
    "knife_survival": {"random": 500.0, "skin": 2500},
    "knife_talon": {"random": 500.0, "skin": 2500},
    "knife_ursus": {"random": 500.0, "skin": 2500},
    "ak47": {"random": 50.0, "skin": 250},
    "m4a1": {"random": 50.0, "skin": 250},
    "m4a4": {"random": 50.0, "skin": 250},
    "awp": {"random": 50.0, "skin": 250},
    "deagle": {"random": 30.0, "skin": 150},
    "usp": {"random": 25.0, "skin": 125},
    "glock18": {"random": 25.0, "skin": 125},
    "galil": {"random": 20.0, "skin": 100},
    "famas": {"random": 20.0, "skin": 100},
    "p90": {"random": 15.0, "skin": 75},
    "mp5navy": {"random": 15.0, "skin": 75},
    "ump45": {"random": 15.0, "skin": 75},
    "mac10": {"random": 10.0, "skin": 50},
    "tmp": {"random": 10.0, "skin": 50},
    "scout": {"random": 15.0, "skin": 75},
    "aug": {"random": 20.0, "skin": 100},
    "sg552": {"random": 20.0, "skin": 100},
    "p228": {"random": 10.0, "skin": 50},
    "fiveseven": {"random": 10.0, "skin": 50},
    "elite": {"random": 10.0, "skin": 50},
    "m3": {"random": 10.0, "skin": 50},
    "xm1014": {"random": 10.0, "skin": 50},
    "m249": {"random": 10.0, "skin": 50},
    "sg550": {"random": 10.0, "skin": 50},
    "g3sg1": {"random": 10.0, "skin": 50},
    "flashbang": False,
    "hegrenade": False,
    "smokegrenade": False,
    "molotov": False,
    "zeus": False,
    "c4": False,
    "thighpack": False,
}

default_models_directory = 'csgo_v2_models'
custom_skins_directory = sys.argv[1] if len(sys.argv) > 1 and len(sys.argv[1]) else 'csgo_v2_skins'
compiler = "studiomdl.exe"
compiled_directory = "_compiled"
compiled_models_directory = f"{compiled_directory}/{default_models_directory}"
compiled_skins_directory = f"{compiled_directory}/{custom_skins_directory}"
skins_directory = "skins"
models_directory = "models"
smd_directory = "smd"
skins_ini = "csgo_skins.ini"
smd_template = "template.smd"
qc_template = "template.qc"
default_skin = "default.bmp"
default_model = "default.mdl"
max_per_file = 40

print('Compiling models...')

if path.exists(compiled_directory):
    shutil.rmtree(compiled_directory)

os.mkdir(compiled_directory)
os.mkdir(compiled_models_directory)
os.mkdir(compiled_skins_directory)

with open(path.join(compiled_directory, skins_ini), 'w+') as generated_ini:
    generated_ini.write(f""";---INSTRUCTIONS---
; [WEAPON NAME - Price of Drawing (set to 0.0 to disable for this weapon)]
; "Skin Name" "Model Path" "Submodel Index" "Price" "Rarity"
;
; Skin rarity can be:
; 1 - Common
; 2 - Uncommon
; 3 - Rare
; 4 - Mythical
; 5 - Legendary
; 6 - Ancient
; 7 - Exceedingly Rare (only knives)
; 8 - Immortal (cannot be bought or aquired by draw)

; Default skins path
SKINS_PATHS={custom_skins_directory}

; Optional possibility to draw random skin (set to 0.0 to disable)
[RANDOM - {weapons.get('random').get('random')}]
""")

    for weapon in weapons.keys():
        if weapon == 'random':
            continue

        weapon_data = weapons.get(weapon)

        if not 'knife_' in weapon and weapon != 'm4a4':
            weapon_compiled_directory = path.join(compiled_models_directory, weapon)

            if path.exists(weapon_compiled_directory):
                shutil.rmtree(weapon_compiled_directory)

            os.mkdir(weapon_compiled_directory)

            model_files = glob.glob(path.join(weapon, "*.mdl"))

            for model_file in model_files:
                shutil.copyfile(model_file, path.join(compiled_models_directory, model_file))

        if weapon_data:
            generated_ini.write(f"\n[{weapon.upper()} - {weapon_data.get('random')}]\n")
        else:
            continue

        weapon_compiled_directory = path.join(compiled_skins_directory, weapon)

        if path.exists(weapon_compiled_directory):
            shutil.rmtree(weapon_compiled_directory)

        os.mkdir(weapon_compiled_directory)

        existing_skins = glob.glob(path.join(weapon, models_directory, "*.mdl"))
        default_skin_found = False

        rarity = "7" if "knife" in weapon else "1"

        for skin in existing_skins:
            skin_file = path.basename(skin)

            if skin_file == default_model:
                shutil.copyfile(skin, path.join(compiled_skins_directory, f"{weapon}/v_{weapon}_0.mdl"))

                default_skin_found = True

                continue

            if weapon in ["m4a4", "knife"]:
                prefix = f'{weapon.title()} | '
            elif "knife_" in weapon:
                prefix = f'{weapon.replace("knife_", "").replace("_", " ").title()} | '
            else:
                prefix = ""

            skin_name = skin_file.replace(path.join(weapon, skins_directory, ""), "")\
                .replace(f"{weapon}_", "")\
                .replace(".mdl", "")\
                .replace("_", " ")\
                .title()

            generated_ini.write(f'"{skin_name}"'
                                f'\t\t"{f"models/{custom_skins_directory}/{weapon}/v_{weapon}_{skin_file}"}"'
                                f'\t\t"0"'
                                f'\t\t"{weapons.get(weapon).get("skin")}"'
                                f'\t\t"{rarity}\n')

            shutil.copyfile(skin, path.join(compiled_skins_directory, f"{weapon}/v_{weapon}_{skin_file}"))

            continue

        if not default_skin_found:
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

        if 'knife_' in weapon:
            generated_ini.write(f'"{weapon.replace("knife_", "").replace("_", "").title()} | Vanilla"'
                                f'\t\t"{f"models/{custom_skins_directory}/{weapon}/v_{weapon}_0.mdl"}"'
                                f'\t\t"0"'
                                f'\t\t"{weapon_data.get("skin")}"'
                                f'\t\t"{rarity}"\n')

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
                prefix = f'{weapon.replace("knife_", "").replace("_", " ").title()} | '
            else:
                prefix = ""

            skin_name = skin.replace(path.join(weapon, skins_directory, ""), "")\
                .replace(f"{weapon}_", "")\
                .replace(".bmp", "")\
                .replace("_", " ")\
                .title()

            generated_ini.write(f'"{prefix}{skin_name}"'
                                f'\t\t"{f"models/{custom_skins_directory}/{weapon}/v_{weapon}_{order}.mdl"}"'
                                f'\t\t"{index - order * max_per_file}"'
                                f'\t\t"{weapon_data.get("skin")}"'
                                f'\t\t"{rarity}"\n')

        shutil.copyfile(compiler, path.join(weapon, compiler))

        qc_files = glob.glob(path.join(weapon, f"v_{weapon}_*.qc"))

        for qc_file in qc_files:
            os.system(f'cd {weapon} && {compiler} {qc_file.replace(path.join(weapon, ""), "")}')
            os.remove(qc_file)

        os.remove(path.join(weapon, compiler))
        shutil.rmtree(weapon_smd_directory)

        model_files = glob.glob(path.join(weapon, f"v_{weapon}_*.mdl"))

        for model_file in model_files:
            shutil.move(model_file, path.join(compiled_skins_directory, model_file))

print('Finished compiling models and generating `csgo_skins.ini`.')
