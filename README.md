# CSGOMod
Counter-Strike: Global Offensive mod for CS 1.6 (AMXX 1.8.3 / 1.9 / 1.10).

[Release pack](https://github.com/TheDoctor0/CSGOMod/releases/latest) contains all plugins and configuration with needed resources: skins, maps, sounds, sprites etc.

Feel free to suggest new functionality, changes and of course please report any found bugs.

## Compatibility
Mod was tested on AMXX builds:
- 1.8.3-dev+5142
- 1.9-dev+5235
- 1.10-dev+5407

In both cases with ReHLDS and ReGameDLL also installed.

## Installation
1. Download `csgo_mod.zip` from the lastest [release pack](https://github.com/TheDoctor0/CSGOMod/releases/latest).
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

## Commands
There is one simple admin command that can be used to add money (Euro) to any player balance:
```
csgo_add_money <nick> <amount>
```
To use it you need **ADMIN_ADMIN** access, so better add yourself *"abcdefghijklmnopqrstuvxy"* flags.

## Documentation
Online documentation is available on [csgomod-docs.5v.pl](http://csgomod-docs.5v.pl/). You can also find it in [csgomod.inc](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/scripting/include/csgomod.inc).

## Known issues
1. Server may crash on map `csgo_dust2_new` with message `FATAL ERROR (shutting down): Cache_TryAlloc: x is greater then free hunk`.

Solution: Add `-heapsize 65536` to server starting options.

2. After few mapchanges client may crash with error `Texture overflow: GL_MAXTEXTURES`.

Solution: This is a bug in GoldSource itself that is being tracked [here](https://github.com/ValveSoftware/halflife/issues/2234) and will be fixed in next release.

## Servers
List of servers that are using this mod is available [HERE](https://www.gametracker.com/search/?search_by=server_variable&search_by2=csgo_version&query=&loc=_all&sort=&order=).

## Credits

- [CS:GO Ports](https://gamebanana.com/studios/34724) for CS:GO maps, pack of weapon textures, original models and more
- [Hanna](https://forums.alliedmods.net/member.php?u=273346) and [1xAero](https://forums.alliedmods.net/member.php?u=284061) for ability to change viewmodel bodygroup that is required for submodels
- [In-line](https://github.com/In-line) for unprecacher module
- [wopox1337](https://dev-cs.ru/members/4/) for base zeus plugin
- [DynamicBits](https://forums.alliedmods.net/member.php?u=30983) for base molotov plugin
- [MPNumB](https://forums.alliedmods.net/member.php?u=25348) for base smoke plugin
