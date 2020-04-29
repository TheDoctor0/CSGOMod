#include <amxmodx>
#include <csgomod>
#include <ultimate_stats>

#define PLUGIN		"CS:GO Assist and Revenge (Ultimate Stats)"
#define VERSION		"1.4"
#define AUTHOR		"O'Zone"

new assistEnabled, revengeEnabled, assistDamage, Float:assistReward, Float:revengeReward;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("csgo_assist_enabled", "1"), assistEnabled);
	bind_pcvar_num(create_cvar("csgo_revenge_enabled", "1"), revengeEnabled);
	bind_pcvar_num(create_cvar("csgo_assist_min_damage", "60"), assistDamage);
	bind_pcvar_float(create_cvar("csgo_assist_reward", "0.15"), assistReward);
	bind_pcvar_float(create_cvar("csgo_revenge_reward", "0.15"), revengeReward);
}

public client_assist(killer, victim, assistant)
{
	new killerName[32], assistantName[32], victimName[32];

	get_user_name(killer, killerName, charsmax(killerName));
	get_user_name(assistant, assistantName, charsmax(assistantName));
	get_user_name(victim, victimName, charsmax(victimName));

	client_print_color(assistant, victim, "^x04[CS:GO]^x01 Asystowales^x03 %s^x01 w zabiciu^x03 %s^x01. Dostajesz fraga!", killerName, victimName);

	csgo_add_money(assistant, assistReward);
}

public client_revenge(killer, victim)
{
	new victimName[32];

	get_user_name(victim, victimName, charsmax(victimName));

	client_print_color(killer, victim, "^x04[CS:GO]^x01 Zemsciles sie na^x03 %s^x01. Dostajesz fraga!", victimName);

	csgo_add_money(killer, revengeReward);
}