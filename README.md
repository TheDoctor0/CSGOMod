# CSGOMod
Counter-Strike: Global Offensive mod for Counter-Strike 1.6 (AMXX 1.8.3 / 1.9 / 1.10).

[Release pack](https://github.com/TheDoctor0/CSGOMod/releases/latest) contains configuration and plugins with all needed resources: skins, maps, sounds, sprites etc.

## Compatibility
Mod was tested on AMXX builds:
- 1.8.3-dev+5142
- 1.9-dev+5235
- 1.10-dev+5392

In both cases with ReHLDS and ReGameDLL also installed.

## Configuration
Main configuration can be changed by cvars loaded from [csgo_mod.cfg](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_mod.cfg).

Plugins can be enabled / disabled in [plugins-csgo.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/plugins-csgo.ini).

Options for main menu are stored in [csgo_menu.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_menu.ini).

Missions configuration can be found in [csgo_operations.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_operations.ini).

Available skins can be changed in [csgo_skins.ini](https://github.com/TheDoctor0/CSGOMod/blob/master/cstrike/addons/amxmodx/configs/csgo_skins.ini).

All of available configuration files have proper descriptions.

## Optional
There are some optional plugins:
- [csgo_free_svip.sma](https://github.com/TheDoctor0/CSGOMod/blob/master/csgo_free_svip.sma) - Free SVIP for everyone (useful for server events)
- [csgo_assist_revenge_us.sma](https://github.com/TheDoctor0/CSGOMod/blob/master/csgo_assist_revenge_us.sma), [csgo_ranks_us.sma](https://github.com/TheDoctor0/CSGOMod/blob/master/csgo_ranks_us.sma) and [csgo_stattrak_us.sma](https://github.com/TheDoctor0/CSGOMod/blob/master/csgo_stattrak_us.sma) - Alternative versions compatible with [UltimateStats](https://github.com/TheDoctor0/UltimateStats)
- [sklepsms_usluga_euro.sma](https://github.com/TheDoctor0/CSGOMod/blob/master/sklepsms_usluga_euro.sma) - [SklepSMS](https://github.com/TheDoctor0/sklep-sms) service plugin

## Commands
There is one simple admin command that can be used to add money (Euro) to any player balance:
```
csgo_add_money <nick> <amount>
```
To use it you need **ADMIN_ADMIN** access, so better add yourself *"abcdefghijklmnopqrstuvxy"* flags.

## Servers
List of servers that are using this mod is available [HERE](https://www.gametracker.com/search/?search_by=server_variable&search_by2=csgo_version&query=&loc=_all&sort=&order=).
