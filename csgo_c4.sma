#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <csgomod>

#define PLUGIN  "CS:GO C4"
#define VERSION "2.0"
#define AUTHOR  "O'Zone"

new const modelsC4[][] = { "models/csgo_ozone/c4/p_c4.mdl", "models/csgo_ozone/c4/v_c4.mdl", "models/csgo_ozone/c4/w_c4.mdl" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("HLTV", "remove_c4", "a", "1=0", "2=0");
	register_logevent("remove_c4", 2, "1=Round_Start")

	RegisterHam(Ham_Item_Deploy, "weapon_c4", "weapon_deploy", 1);

	register_forward(FM_SetModel, "set_model");
}

public plugin_precache()
{
	for (new i = 0; i < sizeof(modelsC4); i++) {
		precache_model(modelsC4[i]);
	}
}

public remove_c4()
{
	new entC4 = -1;

	while ((entC4 = engfunc(EngFunc_FindEntityByString, entC4, "classname", "grenade"))) {
		if (pev_valid(entC4) && get_pdata_bool(entC4, OFFSET_C4)) {
			engfunc(EngFunc_RemoveEntity, entC4);
		}
	}
}

public weapon_deploy(ent)
{
	static id; id = get_pdata_cbase(ent, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!is_user_alive(id)) return HAM_IGNORED;

	set_pev(id, pev_weaponmodel2, modelsC4[0]);
	set_pev(id, pev_viewmodel2, modelsC4[1]);

	return HAM_IGNORED;
}

public set_model(ent, model[])
{
	if (equali(model,"models/w_c4.mdl")) {
		engfunc(EngFunc_SetModel, ent, modelsC4[2]);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}