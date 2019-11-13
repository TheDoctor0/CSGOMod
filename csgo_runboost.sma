#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN "CS:GO Run Boost"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

new bool:runBoost[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Player_Jump, "player", "player_jump", 0);

	register_touch("player", "player", "player_touch");
}

public player_touch(id, player)
{
	if (!is_user_alive(id) || !is_user_alive(player)) return FMRES_IGNORED;

	static Float:origin[2][3];

	pev(id, pev_origin, origin[0]);
	pev(player, pev_origin, origin[1]);

	new Float:distance = origin[1][2] - origin[0][2];

	if (distance > 51.0 && get_user_button(player) & IN_FORWARD) {
		new Float:velocity[3];

		entity_get_vector(player, EV_VEC_velocity, velocity);

		new speed = floatround(vector_length(velocity));

		if(speed >= 150) runBoost[player] = true;
	} else runBoost[player] = false;

	return FMRES_IGNORED;
}

public player_jump(id)
{
	static buttonPressed; buttonPressed = get_pdata_int(id, 246);

	if (runBoost[id] && buttonPressed & IN_JUMP) {
		new Float:velocity[3];

		pev(id, pev_velocity, velocity);

		velocity[0] *= 1.3;
		velocity[1] *= 1.3;
		velocity[2] *= 1.2;

		set_pev(id, pev_velocity, velocity);

		set_pdata_int(id, 246, buttonPressed & ~IN_JUMP);

		runBoost[id] = false;

		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}