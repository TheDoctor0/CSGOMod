#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <xs>

#define PLUGIN "CS:GO Nades"
#define VERSION "2.0"
#define AUTHOR "O'Zone"

new const grenadeNames[][] = { "weapon_flashbang", "weapon_hegrenade", "weapon_smokegrenade" };

new const Float:velocityMultiplier[] = { 1.0, 0.7, 0.45 };

enum { NORMAL, MEDIUM, SHORT };

new grenadeThrow[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i = 0; i < sizeof grenadeNames; i++) {
		RegisterHam(Ham_Weapon_SecondaryAttack, grenadeNames[i], "grenade_secondary_attack", false);
	}
}

public grenade_secondary_attack(const ent)
{
	if (pev_valid(ent)) {
		new id = get_pdata_cbase(ent, 41, 4), buttons = pev(id, pev_button);

		grenadeThrow[id] = (buttons & IN_ATTACK) ? MEDIUM : SHORT;

		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent);
	}
}

public grenade_throw(id, ent, weapon)
{
	if (pev_valid(ent)) {
		new Float:grenadeVelocity[3];

		pev(ent, pev_velocity, grenadeVelocity);

		new Float:multiplier = velocityMultiplier[grenadeThrow[id]];

		xs_vec_mul_scalar(grenadeVelocity, multiplier, grenadeVelocity);

		set_pev(ent, pev_velocity, grenadeVelocity);

		grenadeThrow[id] = NORMAL;
	}
}