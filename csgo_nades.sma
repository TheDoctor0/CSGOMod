#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <xs>

#define PLUGIN "CS:GO Nades"
#define VERSION "2.0"
#define AUTHOR "O'Zone"

new const grenadeModels[][][] = {
	{ "models/csgo_ozone/nades/w_hegrenade.mdl", "models/csgo_ozone/nades/v_hegrenade.mdl", "models/csgo_ozone/nades/p_hegrenade.mdl" },
	{ "models/csgo_ozone/nades/w_flashbang.mdl", "models/csgo_ozone/nades/v_flashbang.mdl", "models/csgo_ozone/nades/p_flashbang.mdl" },
	{ "models/csgo_ozone/nades/w_smokegrenade.mdl", "models/csgo_ozone/nades/v_smokegrenade.mdl", "models/csgo_ozone/nades/p_smokegrenade.mdl" }
};

new const grenadeNames[][] = { "weapon_flashbang", "weapon_hegrenade", "weapon_smokegrenade" };

new const Float:velocityMultiplier[] = { 1.0, 0.7, 0.45 };

enum { HEGRENADE, FLASHBANG, SMOKEGRENADE };
enum { W_MODEL, V_MODEL, P_MODEL };
enum { NORMAL, MEDIUM, SHORT };

new grenadeThrow[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i = 0; i < sizeof grenadeNames; i++) {
		RegisterHam(Ham_Item_Deploy, grenadeNames[i], "grenade_deploy_model", true);
		RegisterHam(Ham_Weapon_SecondaryAttack, grenadeNames[i], "grenade_secondary_attack", false);
	}

	register_forward(FM_SetModel, "grenade_world_model", false);
}

public plugin_precache()
{
	for (new i = 0; i < sizeof(grenadeModels); i++) {
		for (new j = 0; j < sizeof(grenadeModels); j++) {
			precache_model(grenadeModels[i][j]);
		}
	}
}

public grenade_deploy_model(weapon)
{
	static id; id = get_pdata_cbase(weapon, 41, 4);

	if (!is_user_alive(id)) return HAM_IGNORED;

	switch (cs_get_weapon_id(weapon)) {
		case CSW_HEGRENADE: {
			set_pev(id, pev_weaponmodel2, grenadeModels[HEGRENADE][P_MODEL]);
			set_pev(id, pev_viewmodel2, grenadeModels[HEGRENADE][V_MODEL]);
		}
		case CSW_FLASHBANG: {
			set_pev(id, pev_weaponmodel2, grenadeModels[FLASHBANG][P_MODEL]);
			set_pev(id, pev_viewmodel2, grenadeModels[FLASHBANG][V_MODEL]);
		}
		case CSW_SMOKEGRENADE: {
			set_pev(id, pev_weaponmodel2, grenadeModels[SMOKEGRENADE][P_MODEL]);
			set_pev(id, pev_viewmodel2, grenadeModels[SMOKEGRENADE][V_MODEL]);
		}
	}

	return HAM_IGNORED;
}

public grenade_world_model(ent, model[])
{
	static id; id = pev(ent, pev_owner);

	if (!is_user_connected(id)) return FMRES_IGNORED;

	if (model[0] == 'm' && model[7] == 'w' && model[8] == '_') {
		if (contain(model[9], "hegrenade") != -1) {
			engfunc(EngFunc_SetModel, ent, grenadeModels[HEGRENADE][W_MODEL]);

			return FMRES_SUPERCEDE;
		} else if (contain(model[9], "flashbang") != -1) {
			engfunc(EngFunc_SetModel, ent, grenadeModels[FLASHBANG][W_MODEL]);

			return FMRES_SUPERCEDE;
		} else if (contain(model[9], "smokegrenade") != -1) {
			engfunc(EngFunc_SetModel, ent, grenadeModels[SMOKEGRENADE][W_MODEL]);

			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
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