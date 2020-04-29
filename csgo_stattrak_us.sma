#include <amxmodx>
#include <ultimate_stats>

#define PLUGIN "CS:GO StatTrak (Ultimate Stats)"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

#define CSW_SHIELD	2

new const excludedWeapons = (1<<CSW_SHIELD) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_HEGRENADE) | (1<<CSW_C4);

new statTrakEnabled;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("csgo_stattrak_enabled", "1"), statTrakEnabled);
}

public plugin_natives()
{
	register_native("csgo_get_weapon_stattrak", "_csgo_get_weapon_stattrak", 1);
}

public _csgo_get_weapon_stattrak(id, weapon)
{
	if (!statTrakEnabled || (1<<weapon) & excludedWeapons) {
		return -1;
	}

	new stats[8], hits[8];

	get_user_wstats(id, weapon, stats, hits);

	return stats[0];
}
