
# CSGOMod
Counter-Strike: Global Offensive mod for CS 1.6 (AMXX 1.8.3 / 1.9 / 1.10).

[Release pack](https://github.com/TheDoctor0/CSGOMod/releases/latest) contains all plugins and configuration with needed resources: skins, maps, sounds, sprites etc.

Feel free to suggest new functionality, changes and of course please report any found bugs.

## Compatibility
Mod was tested on AMXX builds:
- 1.8.3-dev+5142
- 1.9-dev+5235
- 1.10-dev+5407 (recommended)

## Installation
1. Download `csgo_mod.7z` from the lastest [release pack](https://github.com/TheDoctor0/CSGOMod/releases/latest).
2. Extract downloaded archive and upload `cstrike` directory to your server.
3. Add `linux addons/unprecacher/unprecacher_mm_i386.so` to `/cstrike/addons/metamod/plugins.ini`.
4. Configure database cvars in [csgo_mod.cfg](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_mod.cfg).
5. Enjoy!

## Configuration
Main configuration can be changed by cvars loaded from [csgo_mod.cfg](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_mod.cfg).

Options for main menu are stored in [csgo_menu.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_menu.ini).

Missions configuration can be found in [csgo_operations.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_operations.ini).

Available skins can be changed in [csgo_skins.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_skins.ini).

Plugins can be enabled / disabled in [plugins-csgo.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/plugins-csgo.ini).

All of available configuration files have proper description.

## Skins
Skins customization is easy and can be done by anyone in a matter of minutes, so if you want to make your server special, make sure to customize them.

Before starting you need to:
1. Download and install [Python 3](https://www.python.org/downloads/). This is required to use skins auto-compilation script.
2. Download `csgo_skins.7z` from the [latest release](https://github.com/TheDoctor0/CSGOMod/releases/latest) and extract it anywhere on your computer.
    Inside you will find source files for all skins that you can select for compilation. You may also extend it by adding some of your own - more about it in section below.

### Management
1. Inside every weapon directory you will find `_textures` folder with all available skins.
    Select any textures that you want to use and copy them into `skins` folder.

    Textures that are already in `skins` are those for skins included in `csgo_mod.7z`, so of course you can remove or replace them.

    You can make your own textures and add them here. All textures need to be `512x512px` and match weapon structure.

2. You can add regular skins that don't use submodels. Place them inside `models` folder that you will find for every weapon.

3. When you think that all skins are ready to compile, run `compile.bat`, input new models directory name (optional) and press `Enter`.
    It will take some time to compile all skins so be patient.

4. When the process is finished go into `_compiled` directory where you will find folder with all your skins.
    Script will also generated `csgo_skins.ini` that you can use, so you don't have to update it manually.

### Gloves
If you want to have skins with different gloves you can check `_gloves` directory, select any gloves texture that you want and
replace `gloves.bmp` (or `t_glove.bmp`) in any weapon directory. This will change them in all skins for this weapon.

If you want to use different gloves only for single skin you will need to use model without submodels.
There are two possible ways:
1. Change existing model:
- Download a model from [GameBanana](https://gamebanana.com/skins/games/4254) or any other source.
- Download and install [Jed's Model Viewer](https://gamebanana.com/tools/4779).
- Open model file in Jed's Model Viewer and go to `Textures` tab.
- Select `gloves.bmp` (or `t_glove.bmp`) texture - it is required to be `512x512px`.
- Click `Import Texture` and select any file from `_gloves` directory.
- Click `File` > `Save Model As...` to save model file with changed gloves.

2. Compile it yourself:
- Copy all files from weapon directory to separate folder.
- Copy `debug.bat` and `studiomdl.exe` to the same folder.
- Replace `default.bmp` with any file from `_textures`.
- Replace `gloves.bmp` (or `t_glove.bmp`) with any file from `_gloves`.
- Run `debug.bat` and drag & drop `template.qc` file to script window to compile it.

Remember to copy your new skin without submodels into `models` folder inside directory with weapon skins sources so compiler script can detect it.

### Submodels
By default core plugin provides support for submodels.
If want to only use regular models with single skin you can disable it in `csgo_core.sma`:
```
// Uncomment to disable support for skins based on submodels
//#define DISABLE_SUBMODELS
```
Be sure to also uncomment lines for `v_` models replacement in Unprecacher `list.ini` config.

Disabling submodels support should improve server performance, but will drastically reduce number of skins that you can use.

## Commands
If you want to add money (Euro) to any player balance, you can use this command::
```
csgo_add_money <nick> <amount>
```

If you want to give any skin to any player from menu, you can use this command::
```
csgo_add_skin
```

If you want to make a full data reset without manually cleaning up database, you can use this command:
```
csgo_reset_data
```

To use those commands you need **ADMIN_ADMIN** access, so better add yourself *"abcdefghijklmnopqrstuvxy"* flags.

## Documentation
Online documentation is available on [csgomod-docs.5v.pl](http://csgomod-docs.5v.pl/). You can also find it in [csgomod.inc](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/scripting/include/csgomod.inc).

## Known issues
1. Server may crash on map `csgo_dust2_new` with message `FATAL ERROR (shutting down): Cache_TryAlloc: x is greater then free hunk`.

	**Solution:** Add `-heapsize 65536` to server starting options.

2. After few mapchanges client may crash with error `Texture overflow: GL_MAXTEXTURES`.

	**Solution:** This is a bug in GoldSource itself that is being tracked [here](https://github.com/ValveSoftware/halflife/issues/2234) and will probably be fixed in next release.

## Servers
List of servers that are using this mod is available [HERE](https://www.gametracker.com/search/?search_by=server_variable&search_by2=csgo_version&query=&loc=_all&sort=&order=).

## Credits

- [CS:GO Ports](https://gamebanana.com/studios/34724) for CS:GO maps, pack of weapon textures, original models and more
- [Hanna](https://forums.alliedmods.net/member.php?u=273346) and [1xAero](https://forums.alliedmods.net/member.php?u=284061) for ability to change viewmodel bodygroup that is required for submodels
- [In-line](https://github.com/In-line) for unprecacher module
- [wopox1337](https://dev-cs.ru/members/4/) for base zeus plugin
- [DynamicBits](https://forums.alliedmods.net/member.php?u=30983) for base molotov plugin
- [MPNumB](https://forums.alliedmods.net/member.php?u=25348) for base smoke plugin
- [Nomexous](https://forums.alliedmods.net/member.php?u=31824) for base weapon physics plugin
