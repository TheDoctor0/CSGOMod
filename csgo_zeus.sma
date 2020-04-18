#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <engine>
#include <cstrike>
#include <csgomod>

#define PLUGIN "CS:GO Zeus"
#define AUTHOR "wopox1337 & O'Zone"
#define VERSION "2.0"

#define ZEUS_DISTANCE 230

enum { ViewModel, PlayerModel, WorldModel }
new const models[][] = {
	"models/csgo_ozone/zeus/v_zeus.mdl",
	"models/csgo_ozone/zeus/p_zeus.mdl",
	"models/csgo_ozone/zeus/w_zeus.mdl"
}

enum { Deploy, Hit, Shoot }
new const sounds[][] = {
	"weapons/zeus_deploy.wav",
	"weapons/zeus_hit.wav",
	"weapons/zeus_hitwall.wav"
}

new const zeusWeaponName[] = "weapon_p228";
new const beamSprite[] = "sprites/laserbeam.spr";
new const worldModel[] = "models/w_p228.mdl";

new Float:gameTime, bool:restarted, zeus, zeusEnabled, zeusPrice, mapBuyBlock, boltSprite;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("zeus", "buy_zeus");
	register_clcmd("say /z", "buy_zeus");
	register_clcmd("say_team /z", "buy_zeus");
	register_clcmd("say /zeus", "buy_zeus");
	register_clcmd("say_team /zeus", "buy_zeus");

	bind_pcvar_num(create_cvar("csgo_zeus_enabled", "1"), zeusEnabled);
	bind_pcvar_num(create_cvar("csgo_zeus_price", "300"), zeusPrice);

	RegisterHam(Ham_Item_AttachToPlayer, zeusWeaponName, "weapon_attach_to_player", true);
	RegisterHam(Ham_Item_Deploy, zeusWeaponName, "weapon_item_deploy", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, zeusWeaponName, "weapon_primary_attack", false);
	RegisterHam(Ham_CS_Item_CanDrop, zeusWeaponName, "weapon_item_can_drop", false);
	RegisterHam(Ham_Spawn, "player", "player_spawned", true);

	register_forward(FM_SetModel, "set_model", false);
	register_forward(FM_KeyValue, "key_value", true);

	register_event("DeathMsg", "event_deathmsg", "a", "2>0");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_logevent("event_round_start", 2, "1=Round_Start");
	register_event("TextMsg", "event_gamerestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");

	register_logevent("event_round_end", 2, "1=Round_End");
}

public plugin_natives()
	register_native("csgo_get_zeus", "_csgo_get_zeus", 1);

public plugin_precache()
{
	boltSprite = precache_model(beamSprite);

	precache_sound("items/9mmclip1.wav");

	new i, bWasFail;

	for (i = 0; i < sizeof models; i++) {
		if (file_exists(models[i])) precache_model(models[i]);
		else {
			log_amx("[CS:GO] Zeus file '%s' not exist. Skipped!", models[i]);

			bWasFail = true;
		}
	}

	new szFile[64];

	for (i = 0; i < sizeof sounds; i++) {
		formatex(szFile, charsmax(szFile), "sound\%s", sounds[i]);

		if (file_exists(szFile)) precache_sound(sounds[i]);
		else {
			log_amx("[CS:GO] Zeus file '%s' not exist. Skipped!", sounds[i]);

			bWasFail = true;
		}
	}

	if (bWasFail) set_fail_state("[CS:GO] Not all zeus files were precached. Check logs!");
}

public key_value(ent, keyValueId)
{
	if (pev_valid(ent)) {
		new className[32], keyName[32], keyValue[32];

		get_kvd(keyValueId, KV_ClassName, className, charsmax(className));
		get_kvd(keyValueId, KV_KeyName, keyName, charsmax(keyName));
		get_kvd(keyValueId, KV_Value, keyValue, charsmax(keyValue));

		if (equali(className, "info_map_parameters") && equali(keyName, "buying")) {
			if (str_to_num(keyValue) != 0) mapBuyBlock = str_to_num(keyValue);
		}
	}
}

public client_putinserver(id)
	rem_bit(id, zeus);

public client_disconnected(id)
	rem_bit(id, zeus);

public buy_zeus(id)
{
	if (!is_user_alive(id) || !cs_get_user_buyzone(id) || !zeusEnabled) return PLUGIN_HANDLED;

	new Float:cvarBuyTime = get_cvar_float("mp_buytime"), Float:buyTime;

	if (cvarBuyTime != -1.0 && !(get_gametime() < gameTime + (buyTime = cvarBuyTime * 60.0))) {
		new buyTimeText[8];

		num_to_str(floatround(buyTime), buyTimeText, charsmax(buyTimeText));

		message_begin(MSG_ONE, get_user_msgid("TextMsg"), .player = id);
		write_byte(print_center);
		write_string("#Cant_buy");
		write_string(buyTimeText);
		message_end();

		return PLUGIN_HANDLED;
	}

	if ((mapBuyBlock == 1 && cs_get_user_team(id) == CS_TEAM_CT) || (mapBuyBlock == 2 && cs_get_user_team(id) == CS_TEAM_T) || mapBuyBlock == 3) {
		message_begin(MSG_ONE, get_user_msgid("TextMsg"), .player = id);
		write_byte(print_center);

		if (cs_get_user_team(id) == CS_TEAM_T) write_string("#Cstrike_TitlesTXT_Terrorist_cant_buy");
		else if (cs_get_user_team(id) == CS_TEAM_CT) write_string("#Cstrike_TitlesTXT_CT_cant_buy");

		message_end();

		return PLUGIN_HANDLED;
	}

	new money = cs_get_user_money(id);

	if (money < zeusPrice) {
		message_begin(MSG_ONE, get_user_msgid("TextMsg"), .player = id);
		write_byte(print_center);
		write_string("#Not_Enough_Money");
		message_end();

		return PLUGIN_HANDLED;
	}

	if (get_bit(id, zeus)) {
		message_begin(MSG_ONE, get_user_msgid("TextMsg"), .player = id);
		write_byte(print_center);
		write_string("#Already_Have_One");
		message_end();

		return PLUGIN_HANDLED;
	}

	set_bit(id, zeus);

	cs_set_user_money(id, money - zeusPrice);

	if (get_user_weapon(id) == CSW_P228) {
		new weapon = get_pdata_cbase(id, 373);

		ExecuteHamB(Ham_Item_Deploy, weapon);
	} else {
		fm_give_item(id, zeusWeaponName);
	}

	emit_sound(id, CHAN_AUTO, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return PLUGIN_HANDLED;
}

public event_deathmsg()
	rem_bit(read_data(2), zeus);

public event_gamerestart()
	restarted = true;

public event_round_start()
	gameTime = get_gametime();

public event_new_round()
{
	if (restarted) {
		for (new i; i <= MAX_PLAYERS; i++) {
			rem_bit(i, zeus);
		}

		restarted = false;
	}

	return PLUGIN_CONTINUE;
}

public weapon_attach_to_player(weapon, id)
{
	if (get_pdata_float(weapon, 44, 4) || !get_bit(id, zeus) || !zeusEnabled) return;

	set_pdata_int(weapon, 51, 1, 4);
	set_pdata_int(id, 52, 0, 5);
}

public weapon_item_deploy(weapon)
{
	static id; id = get_pdata_cbase(weapon, 41, 4);

	if (!is_user_alive(id) || !zeusEnabled || !get_bit(id, zeus)) return HAM_IGNORED;

	set_pev(id, pev_viewmodel2, models[ViewModel]);
	set_pev(id, pev_weaponmodel2, models[PlayerModel]);

	send_weapon_animation(id, 3);
	emit_sound(weapon, CHAN_WEAPON, sounds[Deploy], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return HAM_IGNORED;
}

public weapon_primary_attack(weapon)
{
	static id; id = get_pdata_cbase(weapon, 41, 4);

	if (!is_user_alive(id) || !zeusEnabled || !get_bit(id, zeus)) return HAM_IGNORED;

	rem_bit(id, zeus);

	static any:targetOrigin[3], Float:origin[3], Float:velocity[3], Float:vector[3], end[3], target, body, Float:distance;

	distance = get_user_aiming(id, target, body);
	entity_get_vector(id, EV_VEC_origin, origin);
	VelocityByAim(id, ZEUS_DISTANCE, velocity);

	xs_vec_add(origin, velocity, vector);
	FVecIVec(origin, end);
	FVecIVec(vector, targetOrigin);

	if (is_user_connected(target) && distance <= ZEUS_DISTANCE) {
		get_user_origin(target, targetOrigin, 0);

		if (get_user_team(id) != get_user_team(target)) {
			ExecuteHam(Ham_TakeDamage, target, 0, id, 999.0, DMG_SHOCK);
		}

		emit_sound(id, CHAN_WEAPON, sounds[Hit], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	} else {
		emit_sound(id, CHAN_WEAPON, sounds[Shoot], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	create_thunder2(id, targetOrigin);
	create_light(end);
	send_weapon_animation(id, 2);

	ham_strip_weapon(id, zeusWeaponName);

	return HAM_SUPERCEDE;
}

public weapon_item_can_drop(weapon)
{
	static id; id = get_pdata_cbase(weapon, 41, 4);

	if (!is_user_alive(id) || !zeusEnabled || !get_bit(id, zeus)) return HAM_IGNORED;

	SetHamReturnInteger(false);

	return HAM_SUPERCEDE;
}

public player_spawned(id)
	if (get_bit(id, zeus)) set_task(0.1, "player_spawned_post", id);

public player_spawned_post(id)
	fm_give_item(id, zeusWeaponName);

public set_model(ent, model[])
{
	if (!pev_valid(ent) || !zeusEnabled) return FMRES_IGNORED;

	new id = entity_get_edict(ent, EV_ENT_owner);

	if (!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || !get_bit(id, zeus)) return HAM_IGNORED;

	if (equali(model, worldModel)) {
		static className[8];

		pev(ent, pev_classname, className, charsmax(className));

		if (className[0] == 'w' && className[6] == 'b') {
			engfunc(EngFunc_SetModel, ent, models[WorldModel]);

			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public _csgo_get_zeus(id)
	return get_bit(id, zeus);

stock send_weapon_animation(const id, const animation)
{
	set_pev(id, pev_weaponanim, animation);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id);
	write_byte(animation);
	write_byte(pev(id, pev_body));
	message_end();
}

stock create_thunder(start[3], end[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	write_coord(start[0]);
	write_coord(start[1]);
	write_coord(start[2]);
	write_coord(end[0]);
	write_coord(end[1]);
	write_coord(end[2]);
	write_short(boltSprite);
	write_byte(1);
	write_byte(5);
	write_byte(7);
	write_byte(20);
	write_byte(30);
	write_byte(135);
	write_byte(206);
	write_byte(250);
	write_byte(255);
	write_byte(145);
	message_end();
}

stock create_thunder2(start, end[3])
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(start | 0x1000);
	write_coord(end[0]);
	write_coord(end[1]);
	write_coord(end[2]);
	write_short(boltSprite);
	write_byte(1);
	write_byte(30);
	write_byte(5);
	write_byte(2);
	write_byte(20);
	write_byte(135);
	write_byte(206);
	write_byte(250);
	write_byte(200);
	write_byte(200);
	message_end()
}

stock create_light(origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_DLIGHT);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_byte(50);
	write_byte(135);
	write_byte(206);
	write_byte(250);
	write_byte(3);
	write_byte(120);
	message_end();
}

stock ham_strip_weapon(id, const weapon[])
{
	if (!equal(weapon, "weapon_", 7)) return 0;

	new weaponId = get_weaponid(weapon);

	if (!weaponId) return 0;

	new ent;

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", weapon)) && pev(ent, pev_owner) != id) {}

	if (!ent) return 0;

	if (get_user_weapon(id) == weaponId) ExecuteHamB(Ham_Weapon_RetireWeapon, ent);

	if (!ExecuteHamB(Ham_RemovePlayerItem, id, ent)) return 0;

	ExecuteHamB(Ham_Item_Kill, ent);

	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1 << weaponId));

	return 1;
}