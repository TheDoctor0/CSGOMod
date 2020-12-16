#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <csgomod>

#define PLUGIN	"CS:GO Inspect"
#define AUTHOR	"O'Zone"

new const weaponsWithoutInspect = (1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE);

new bool:deagleDisable[MAX_PLAYERS + 1];

new inspectAnimation[] =
{
	0,	//null
	7,	//p228
	0,	//shield
	5,	//scout
	0,	//hegrenade
	7,	//xm1014
	0,	//c4
	6,	//mac10
	6,	//aug
	0,	//smoke grenade
	16,	//elites
	6,	//fiveseven
	6,	//ump45
	5,	//sg550
	6,	//galil
	6,	//famas
	16,	//usp
	13,	//glock
	6,	//awp
	6,	//mp5
	5,	//m249
	7,	//m3
	14,	//m4a1
	6,	//tmp
	5,	//g3sg1
	0,	//flashbang
	6,	//deagle
	6,	//sg552
	6,	//ak47
	8,	//knife
	6	//p90
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "deagle_reload");
	RegisterHam(Ham_Item_Deploy, "weapon_deagle", "deagle_override");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "deagle_override");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "knife_override");

	register_impulse(100, "inspect_weapon");
}

public deagle_reload(weapon)
{
	if (pev_valid(weapon) != VALID_PDATA) return HAM_IGNORED;

	new id = get_pdata_cbase(weapon, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	remove_task(id);

	if (!pev_valid(id) || !is_user_alive(id)) return HAM_IGNORED;

	deagleDisable[id] = true;

	set_task(2.5, "deagle_enable", id);

	return HAM_IGNORED;
}

public deagle_override(weapon)
{
	if (pev_valid(weapon) != VALID_PDATA) return HAM_IGNORED;

	new id = get_pdata_cbase(weapon, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	remove_task(id);

	if (!pev_valid(id) || !is_user_alive(id)) return HAM_IGNORED;

	deagleDisable[id] = true;

	set_task(0.8, "deagle_enable", id);

	return HAM_IGNORED;
}

public knife_override(weapon)
{
	if (pev_valid(weapon) != VALID_PDATA) return HAM_IGNORED;

	set_pdata_float(weapon, OFFSET_WEAPON_IDLE, 0.8, OFFSET_ITEM_LINUX);

	return HAM_IGNORED;
}

public deagle_enable(id)
	deagleDisable[id] = false;

public inspect_weapon(id)
{
	if (pev_valid(id) != VALID_PDATA || !is_user_alive(id) || cs_get_user_shield(id) || cs_get_user_zoom(id) > 1) return PLUGIN_HANDLED;

	new weaponId = get_user_weapon(id),
		weapon = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_PLAYER_LINUX);

	if (weaponsWithoutInspect & (1<<weaponId) || !pev_valid(weapon)) return PLUGIN_HANDLED;

	new animation = inspectAnimation[weaponId], currentAnimation = pev(get_pdata_cbase(weapon, OFFSET_PLAYER, OFFSET_ITEM_LINUX), pev_weaponanim);

	switch (weaponId) {
		case CSW_M4A1: {
			if (!cs_get_weapon_silen(weapon)) animation = 15;

			if (!currentAnimation || currentAnimation == 7 || currentAnimation == animation) play_inspect(id, weapon, animation);
		} case CSW_USP: {
			if (!cs_get_weapon_silen(weapon)) animation = 17;

			if (!currentAnimation || currentAnimation == 8 || currentAnimation == animation) play_inspect(id, weapon, animation);
		} case CSW_DEAGLE: {
			if (!deagleDisable[id]) play_inspect(id, weapon, animation);
		} case CSW_GLOCK18: {
			if (!currentAnimation || currentAnimation == 1 || currentAnimation == 2 || currentAnimation == 9 || currentAnimation == 10 || currentAnimation == animation) play_inspect(id, weapon, animation);
		} default: {
			if (!currentAnimation || currentAnimation == animation) play_inspect(id, weapon, animation);
		}
	}

	return PLUGIN_HANDLED;
}

stock play_inspect(id, weapon, animation)
{
	set_pdata_float(weapon, OFFSET_WEAPON_IDLE, 7.0, OFFSET_ITEM_LINUX);
	set_pev(id, pev_weaponanim, animation);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(animation);
	write_byte(pev(id, pev_body));
	message_end();
}
