#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <fun>
#include <csgomod>

#define PLUGIN		"CS:GO Asysta i Zemsta"
#define VERSION		"1.2"
#define AUTHOR		"O'Zone"

new playerTeam[MAX_PLAYERS + 1], playerRevenge[MAX_PLAYERS + 1], playerDamage[MAX_PLAYERS + 1][MAX_PLAYERS + 1];

new bool:playerAlive[MAX_PLAYERS] = {false, ...}, bool:playerOnline[MAX_PLAYERS] = {false, ...};

new assistEnabled, revengeEnabled, assistDamage, Float:assistReward, Float:revengeReward;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	bind_pcvar_num(create_cvar("csgo_assist_enabled", "1"), assistEnabled);
	bind_pcvar_num(create_cvar("csgo_revenge_enabled", "1"), revengeEnabled);
	bind_pcvar_num(create_cvar("csgo_assist_min_damage", "60"), assistDamage);
	bind_pcvar_float(create_cvar("csgo_assist_reward", "0.15"), assistReward);
	bind_pcvar_float(create_cvar("csgo_revenge_reward", "0.15"), revengeReward);
	
	register_event("Damage", "player_damage", "be", "2!0", "3=0", "4!0");
	register_event("DeathMsg", "player_die", "ae");
	register_event("TeamInfo", "player_joinTeam", "a");
	
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
}

public client_putinserver(id)
{
	playerOnline[id] = true;
	
	playerRevenge[id] = 0;
	
	for (new i = 1; i <= MAX_PLAYERS; i++) playerDamage[id][i] = 0;
}

public client_disconnected(id)
{
	playerTeam[id] = 0;
	playerAlive[id] = false;
	playerOnline[id] = false;
}

public player_joinTeam()
{
	new id, teamName[2];

	id = read_data(1);

	read_data(2, teamName, charsmax(teamName));

	switch(teamName[0]) {
		case 'T': playerTeam[id] = 1;
		case 'C': playerTeam[id] = 2;
		default: playerTeam[id] = 3;
	}

	return PLUGIN_CONTINUE;
}

public player_spawn(id)
{
	if (!is_user_alive(id)) return HAM_IGNORED;

	playerAlive[id] = true;

	for (new i = 1; i <= MAX_PLAYERS; i++) playerDamage[id][i] = 0;

	return HAM_IGNORED;
}

public player_damage(victim)
{
	if (!assistEnabled || !is_user_connected(victim)) return PLUGIN_CONTINUE;

	new attacker = get_user_attacker(victim);

	if (!is_user_connected(attacker)) return PLUGIN_CONTINUE;

	playerDamage[attacker][victim] += read_data(2);

	return PLUGIN_CONTINUE;
}

public player_die()
{
	if (!assistEnabled) return PLUGIN_CONTINUE;

	static msgMoney;

	if (!msgMoney) msgMoney = get_user_msgid("Money");
	
	new victim = read_data(2), killer = read_data(1);
	
	playerAlive[victim] = false;
	playerRevenge[victim] = killer;
	
	if (killer != victim && playerTeam[victim] != playerTeam[killer]) {
		if (playerRevenge[killer] == victim && revengeEnabled) {
			set_user_frags(killer, get_user_frags(killer) + 1);

			cs_set_user_deaths(killer, cs_get_user_deaths(killer));

			new money = min(cs_get_user_money(killer) + 300, 16000);

			cs_set_user_money(killer, money);

			if (playerAlive[killer]) {
				message_begin(MSG_ONE_UNRELIABLE, msgMoney, _, killer);
				write_long(money);
				write_byte(1);
				message_end();
			}
			
			new victimName[32];

			get_user_name(victim, victimName, charsmax(victimName));
			
			client_print_color(killer, victim, "^x04[CS:GO]^x01 Zemsciles sie na^x03 %s^x01. Dostajesz fraga!", victimName);

			csgo_add_kill(killer);

			csgo_add_money(killer, revengeReward);
		}

		new assistant = 0, damage = 0;

		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (i != killer && playerOnline[i] && playerTeam[killer] == playerTeam[i] && playerDamage[i][victim] >= assistDamage && playerDamage[i][victim] > damage) {
				assistant = i;
				damage = playerDamage[i][victim];
			}

			playerDamage[i][victim] = 0;
		}

		if(assistant > 0 && damage > assistDamage) {
			set_user_frags(assistant, get_user_frags(assistant) + 1);

			cs_set_user_deaths(assistant, cs_get_user_deaths(assistant));

			new money = min(cs_get_user_money(assistant) + 300, 16000);

			cs_set_user_money(assistant, money);

			if(playerAlive[assistant]) {
				message_begin(MSG_ONE_UNRELIABLE, msgMoney, _, assistant);
				write_long(money);
				write_byte(1);
				message_end();
			}
			
			new killerName[32], assistantName[32], victimName[32];

			get_user_name(killer, killerName, charsmax(killerName));
			get_user_name(assistant, assistantName, charsmax(assistantName));
			get_user_name(victim, victimName, charsmax(victimName));

			set_hudmessage(255, 155, 0, 0.6, 0.2, 0, 0.0, 1.0, 0.3, 1.0, -1);
			show_hudmessage(0, "%s pomogl %s w  zabiciu %s", assistantName, killerName, victimName);
			
			client_print_color(assistant, victim, "^x04[CS:GO]^x01 Asystowales^x03 %s^x01 w zabiciu^x03 %s^x01. Dostajesz fraga!", killerName, victimName);
			
			csgo_add_kill(assistant);

			csgo_add_money(assistant, assistReward);
		}
	}

	return PLUGIN_CONTINUE;
}