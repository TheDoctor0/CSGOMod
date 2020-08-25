#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <xs>
#include <csgomod>

#define PLUGIN	"CS:GO Nades"
#define AUTHOR	"O'Zone"

new const grenadeNames[][] = { "weapon_flashbang", "weapon_hegrenade", "weapon_smokegrenade" };

new const Float:velocityMultiplier[] = { 1.0, 0.7, 0.45 };

enum { NORMAL, MEDIUM, SHORT };

new grenadeThrow[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i = 0; i < sizeof grenadeNames; i++) {
		RegisterHam(Ham_Item_Deploy, grenadeNames[i], "grenade_deploy", true);
		RegisterHam(Ham_Weapon_SecondaryAttack, grenadeNames[i], "grenade_secondary_attack", false);
	}
}

public grenade_deploy(weapon)
{
	if (!pev_valid(weapon)) return HAM_IGNORED;

	static id; id = get_pdata_cbase(weapon, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!pev_valid(id) || !is_user_alive(id)) return HAM_IGNORED;

	grenadeThrow[id] = NORMAL;

	return HAM_IGNORED;
}

public grenade_secondary_attack(ent)
{
	if (!pev_valid(ent)) return HAM_IGNORED;

	new id = get_pdata_cbase(ent, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!pev_valid(id) || !is_user_alive(id)) return HAM_IGNORED;

	new buttons = pev(id, pev_button);

	grenadeThrow[id] = (buttons & IN_ATTACK) ? MEDIUM : SHORT;

	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent);

	return HAM_IGNORED;
}

public grenade_throw(id, ent, weapon)
{
	if (!pev_valid(ent) || !pev_valid(id)) return;

	new Float:grenadeVelocity[3];

	pev(ent, pev_velocity, grenadeVelocity);

	new Float:multiplier = velocityMultiplier[grenadeThrow[id]];

	xs_vec_mul_scalar(grenadeVelocity, multiplier, grenadeVelocity);

	set_pev(ent, pev_velocity, grenadeVelocity);

	grenadeThrow[id] = NORMAL;
}