#include <amxmodx>
#include <fakemeta_util>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <csgomod>

#define PLUGIN	"CS:GO Molotov"
#define AUTHOR	"DynamicBits & O'Zone"

#define ENT_FIRE		pev_iuser3
#define THINK_COUNT		pev_iuser4

enum { ViewModel, PlayerModel, WorldModel, WorldModelBroken }
new const models[][] = {
	"models/csgo_ozone_v2/molotov/v_molotov.mdl",
	"models/csgo_ozone_v2/molotov/p_molotov.mdl",
	"models/csgo_ozone_v2/molotov/w_molotov.mdl",
	"models/csgo_ozone_v2/molotov/w_broken_molotov.mdl"
};

enum { Fire, Explode, Extinguish }
new const sounds[][] = {
	"weapons/molotov_fire.wav",
	"weapons/molotov_explode.wav",
	"weapons/molotov_extinguish.wav",
	"weapons/molotov_pinpull.wav",
	"weapons/molotov_throw.wav",
	"weapons/molotov_draw.wav",
};

new const molotovWeaponName[] = "weapon_hegrenade", molotovClassName[] = "molotov";

new const commandBuy[][] = { "say /molotov", "say_team /molotov", "say /m", "say_team /m", "molotov" };

new molotovEnabled, molotovPrice, molotov, mapBuyBlock, fireSprite, smokeSprite[2], bool:restarted, bool:reset,
	Float:molotovRadius, Float:molotovFireTime, Float:molotovFireDamage, Float:gameTime;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof commandBuy; i++) register_clcmd(commandBuy[i], "buy_molotov");

	bind_pcvar_num(create_cvar("csgo_molotov_enabled", "1"), molotovEnabled);
	bind_pcvar_num(create_cvar("csgo_molotov_price", "500"), molotovPrice);
	bind_pcvar_float(create_cvar("csgo_molotov_radius", "150.0"), molotovRadius);
	bind_pcvar_float(create_cvar("csgo_molotov_firetime", "7.0"), molotovFireTime);
	bind_pcvar_float(create_cvar("csgo_molotov_firedamage", "3.0"), molotovFireDamage);

	register_event("DeathMsg", "event_deathmsg", "a", "2>0");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");

	register_logevent("event_round_end", 2, "1=Round_End");

	register_think(molotovClassName, "think_molotov");

	RegisterHam(Ham_Item_Deploy, molotovWeaponName, "molotov_deploy_model", 1);
	RegisterHam(Ham_Spawn, "player", "player_spawned", 1);

	register_forward(FM_EmitSound, "sound_emit");
	register_forward(FM_KeyValue, "key_value", 1);
	register_forward(FM_SetModel, "set_model", 0);
}

public plugin_natives()
	register_native("csgo_get_user_molotov", "_csgo_get_user_molotov", 1);

public plugin_precache()
{
	fireSprite = precache_model("sprites/flame.spr");
	smokeSprite[0] = precache_model("sprites/black_smoke3.spr");
	smokeSprite[1] = precache_model("sprites/steam1.spr");

	precache_sound("items/9mmclip1.wav");

	new i, failed;

	for (i = 0; i < sizeof models; i++) {
		if (file_exists(models[i])) precache_model(models[i]);
		else
		{
			log_amx("[CS:GO] Molotov file '%s' not exist. Skipped!", models[i]);

			failed = true;
		}
	}

	new filePath[64];

	for (i = 0; i < sizeof sounds; i++) {
		formatex(filePath, charsmax(filePath), "sound\%s", sounds[i]);

		if (file_exists(filePath)) precache_sound(sounds[i]);
		else {
			log_amx("[CS:GO] Molotov file '%s' not exist. Skipped!", sounds[i]);

			failed = true;
		}
	}

	if (failed) set_fail_state("[CS:GO] Not all molotov files were precached. Check logs!");
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
	rem_bit(id, molotov);

public client_disconnected(id)
{
	rem_bit(id, molotov);

	remove_molotovs(id);
}

public buy_molotov(id)
{
	if (!molotovEnabled || !pev_valid(id) || !cs_get_user_buyzone(id) || !is_user_alive(id)) return PLUGIN_HANDLED;

	new Float:cvarBuyTime = get_cvar_float("mp_buytime"), Float:buyTime;

	static msgText;

	if (!msgText) msgText = get_user_msgid("TextMsg");

	if (cvarBuyTime != -1.0 && !(get_gametime() < gameTime + (buyTime = cvarBuyTime * 60.0))) {
		new buyTimeText[8];

		num_to_str(floatround(buyTime), buyTimeText, charsmax(buyTimeText));

		message_begin(MSG_ONE, msgText, _, id);
		write_byte(print_center);
		write_string("#Cant_buy");
		write_string(buyTimeText);
		message_end();

		return PLUGIN_HANDLED;
	}

	if ((mapBuyBlock == 1 && cs_get_user_team(id) == CS_TEAM_CT) || (mapBuyBlock == 2 && cs_get_user_team(id) == CS_TEAM_T) || mapBuyBlock == 3) {
		message_begin(MSG_ONE, msgText, _, id);
		write_byte(print_center);

		if (cs_get_user_team(id) == CS_TEAM_T) write_string("#Cstrike_TitlesTXT_Terrorist_cant_buy");
		else if (cs_get_user_team(id) == CS_TEAM_CT) write_string("#Cstrike_TitlesTXT_CT_cant_buy");

		message_end();

		return PLUGIN_HANDLED;
	}

	new money = cs_get_user_money(id);

	if (money < molotovPrice) {
		message_begin(MSG_ONE, msgText, _, id);
		write_byte(print_center);
		write_string("#Not_Enough_Money");
		message_end();

		return PLUGIN_HANDLED;
	}

	if (get_bit(id, molotov)) {
		message_begin(MSG_ONE, msgText, _, id);
		write_byte(print_center);
		write_string("#Cannot_Carry_Anymore");
		message_end();

		return PLUGIN_HANDLED;
	}

	cs_set_user_money(id, cs_get_user_money(id) - molotovPrice);

	set_bit(id, molotov);

	give_item(id, molotovWeaponName);

	emit_sound(id, CHAN_AUTO, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return PLUGIN_HANDLED;
}

public event_deathmsg()
{
	new victim = read_data(2);

	if (is_user_connected(victim)) {
		rem_bit(victim, molotov);
	}
}

public event_game_restart()
	restarted = true;

public event_round_end()
	reset = true;

public event_new_round()
{
	reset = false;

	gameTime = get_gametime();

	if (!molotovEnabled) return PLUGIN_CONTINUE;

	if (restarted) {
		for (new i; i <= MAX_PLAYERS; i++) rem_bit(i, molotov);

		restarted = false;
	}

	remove_molotovs();

	return PLUGIN_CONTINUE;
}

public molotov_deploy_model(weapon)
{
	if (pev_valid(weapon) != VALID_PDATA) return HAM_IGNORED;

	new id = get_pdata_cbase(weapon, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!molotovEnabled || !pev_valid(id) || !is_user_alive(id) || !get_bit(id, molotov)) return HAM_IGNORED;

	set_pev(id, pev_viewmodel2, models[ViewModel]);
	set_pev(id, pev_weaponmodel2, models[PlayerModel]);

	return HAM_IGNORED;
}

public player_spawned(id)
{
	if (!get_bit(id, molotov)) return;

	set_task(0.1, "player_spawned_post", id);
}

public player_spawned_post(id)
{
	if (!is_user_alive(id)) return;

	give_item(id, molotovWeaponName);
}

public set_model(ent, model[])
{
	if (!pev_valid(ent) || !molotovEnabled) return FMRES_IGNORED;

	static className[9];

	pev(ent, pev_classname, className, charsmax(className));

	if (!equal(className, "grenade") || containi(model, "hegrenade") == -1) return FMRES_IGNORED;

	new id = pev(ent, pev_owner);

	if (!is_user_connected(id) || !pev_valid(id) || !get_bit(id, molotov)) return FMRES_IGNORED;

	set_pev(ent, pev_dmgtime, 9999.0);
	set_pev(ent, pev_team, get_user_team(id));

	engfunc(EngFunc_SetModel, ent, models[WorldModel]);

	return FMRES_SUPERCEDE;
}

public sound_emit(ent, channel, sample[])
{
	if (!equal(sample[8], "he_bounce", 9) || !pev_valid(ent)) return FMRES_IGNORED;

	static modelName[64];

	pev(ent, pev_model, modelName, charsmax(modelName));

	if (contain(modelName, models[WorldModel]) != -1) {
		emit_sound(ent, CHAN_AUTO, "debris/glass2.wav", VOL_NORM, ATTN_STATIC, 0, PITCH_LOW);

		set_pev(ent, pev_velocity, {0.0, 0.0, 0.0});

		molotov_explode(ent);

		return FMRES_SUPERCEDE;
	}

	if (contain(modelName, models[WorldModelBroken]) != -1) {
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

stock molotov_explode(entMolotov)
{
	new owner = pev(entMolotov, pev_owner);

	if (!pev_valid(owner)) return;

	rem_bit(owner, molotov);

	if (reset) {
		engfunc(EngFunc_RemoveEntity, entMolotov);

		return;
	}

	new Float:origin[3];

	pev(entMolotov, pev_origin, origin);

	new entFire = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	set_pev(entFire, pev_classname, "molotov_fire");
	set_pev(entFire, pev_owner, owner);
	set_pev(entFire, pev_origin, origin);
	set_pev(entFire, pev_nextthink, get_gametime() + 0.1);

	engfunc(EngFunc_SetModel, entMolotov, models[WorldModelBroken]);
	entity_set_int(entMolotov, EV_INT_solid, SOLID_NOT);

	set_pev(entMolotov, pev_classname, molotovClassName);
	set_pev(entMolotov, pev_nextthink, get_gametime() + 0.1);
	set_pev(entMolotov, ENT_FIRE, entFire);
	set_pev(entMolotov, THINK_COUNT, floatround(molotovFireTime / 0.1, floatround_floor) - 1);

	if (extinguish_molotov(entMolotov)) return;

	emit_sound(entMolotov, CHAN_AUTO, sounds[Explode], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public think_molotov(entMolotov)
{
	new entFire = pev(entMolotov, ENT_FIRE), owner = pev(entMolotov, pev_owner);

	if (!pev_valid(entMolotov) || !pev_valid(entFire) || !pev_valid(owner) || !is_user_connected(owner) || extinguish_molotov(entMolotov)) {
		fire_stop(entMolotov);

		return;
	}

	set_pev(entMolotov, THINK_COUNT, pev(entMolotov, THINK_COUNT) - 1);
	set_pev(entMolotov, pev_nextthink, get_gametime() + 0.1);
	set_pev(entFire, pev_nextthink, get_gametime() + 0.1);

	if (!pev(entMolotov, THINK_COUNT)) {
		fire_stop(entMolotov);

		return;
	}

	if (pev(entMolotov, THINK_COUNT) % 10 == 0) {
		emit_sound(entMolotov, CHAN_AUTO, sounds[Fire], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	new Float:origin[3];

	pev(entMolotov, pev_origin, origin);

	random_fire(origin, entFire);

	radius_damage2(pev(entMolotov, pev_owner), pev(entMolotov, pev_team), origin, molotovFireDamage, molotovRadius);
}

public fire_stop(entMolotov)
{
	if (pev_valid(entMolotov)) {
		new entFire = pev(entMolotov, ENT_FIRE);

		if (pev_valid(entFire)) {
			set_pev(entFire, pev_flags, pev(entFire, pev_flags) | FL_KILLME);
		}

		set_pev(entMolotov, pev_flags, pev(entMolotov, pev_flags) | FL_KILLME);
	}
}

stock radius_damage2(attacker, team, Float:origin[3], Float:damage, Float:range)
{
	new Float:tempOrigin[3], Float:distance, Float:tempDamange;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_alive(i) || (attacker != i && team == get_user_team(i))) continue;

		pev(i, pev_origin, tempOrigin);

		distance = get_distance_f(origin, tempOrigin);

		if (distance > range) continue;

		tempDamange = damage;

		if (pev(i, pev_health) <= tempDamange) kill(attacker, i, team);
		else fm_fakedamage(i, molotovClassName, tempDamange, DMG_BURN);
	}
}

stock extinguish_molotov(entMolotov)
{
	new entFire = pev(entMolotov, ENT_FIRE), owner = pev(entMolotov, pev_owner);

	if (!pev_valid(entMolotov) || !pev_valid(entFire) || !pev_valid(owner) || !is_user_connected(owner)) {
		fire_stop(entMolotov);

		return true;
	}

	static entList[16];

	new foundGrenades = find_sphere_class(entMolotov, "grenade", molotovRadius * 0.75, entList, charsmax(entList));

	for (new i = 0; i < foundGrenades; i++) {
		if (grenade_is_smoke(entList[i])) {
			new Float:velocity[3], Float:origin[3], Float:dmgTime;

			velocity[0] = 0.0;
			velocity[1] = 0.0;
			velocity[2] = 0.0;

			entity_set_vector(entList[i], EV_VEC_velocity, velocity);
			entity_get_vector(entList[i], EV_VEC_origin, origin);

			origin[2] -= distance_to_floor(origin);

			entity_set_origin(entList[i], origin);

			pev(entList[i], pev_dmgtime, dmgTime);

			set_pev(entList[i], pev_dmgtime, floatmax(0.0, dmgTime - 3.0));
			set_pev(entList[i], pev_velocity, {0.0, 0.0, 0.0});

			emit_sound(entList[i], CHAN_AUTO, sounds[Extinguish], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			fire_stop(entMolotov);

			return true;
		}
	}

	return false;
}

stock random_fire(Float:temp[3], ent)
{
	new range, origin[3], source[3], counter, i;

	FVecIVec(temp, source);

	range = floatround(molotovRadius);

	for (i = 1; i <= 5; i++) {
		counter = 1;

		origin[0] = source[0] + random_num(-range, range);
		origin[1] = source[1] + random_num(-range, range);
		origin[2] = source[2];
		origin[2] = ground_z(origin, ent);

		while (get_distance(origin, source) > range) {
			origin[0] = source[0] + random_num(-range, range);
			origin[1] = source[1] + random_num(-range, range);
			origin[2] = source[2];

			if (++counter >= 10) origin[2] = ground_z(origin, ent, 1);
			else origin[2] = ground_z(origin, ent);
		}

		new random = random_num(5, 15);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2] + random * 5);
		write_short(fireSprite);
		write_byte(random);
		write_byte(100);
		message_end();
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 120);
	write_short(smokeSprite[random_num(0, 1)]);
	write_byte(random_num(10, 30));
	write_byte(random_num(10, 20));
	message_end();
}

stock kill(killer, victim, team)
{
	if (!pev_valid(killer) || !pev_valid(victim) || !is_user_connected(killer) || !is_user_alive(victim)) return;

	static msgDeathMsg;

	if (!msgDeathMsg) msgDeathMsg = get_user_msgid("DeathMsg");

	message_begin(MSG_ALL, msgDeathMsg, {0,0,0}, 0);
	write_byte(killer);
	write_byte(victim);
	write_byte(0);
	write_string(molotovClassName);
	message_end();

	new msgBlock = get_msg_block(msgDeathMsg);

	set_msg_block(msgDeathMsg, BLOCK_ONCE);

	new killerFrags = get_user_frags(killer),
		victimFrags = get_user_frags(victim);

	if (killer != victim) fm_set_user_frags(victim, victimFrags + 1);

	if (team != get_user_team(victim)) killerFrags++;
	else killerFrags--;

	fm_set_user_frags(killer, killerFrags);

	user_kill(victim, 0);
	set_msg_block(msgDeathMsg, msgBlock);

	new victimName[32], victimAuth[35], victimTeam[32];

	get_user_name(victim, victimName, charsmax(victimName));
	get_user_authid(victim, victimAuth, charsmax(victimAuth));
	get_user_team(victim, victimTeam, charsmax(victimTeam));

	if (killer == victim) {
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"molotov^"", victimName, get_user_userid(victim), victimAuth, victimTeam);
	} else if (is_user_connected(killer)) {
		new killerName[32], killerAuth[35], killerTeam[32];

		get_user_name(killer, killerName, charsmax(killerName));
		get_user_authid(killer, killerAuth, charsmax(killerAuth));
		get_user_team(killer, killerTeam, charsmax(killerTeam));

		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"molotov^"", killerName, get_user_userid(killer), killerAuth, killerTeam, victimName, get_user_userid(victim), victimAuth, victimTeam);
	}

	if (killer != victim) {
		new money = cs_get_user_money(killer) + 300;

		cs_set_user_money(killer, money > 16000 ? 16000 : money);
	}

	static msgScoreInfo;

	if (!msgScoreInfo) msgScoreInfo = get_user_msgid("ScoreInfo");

	message_begin(MSG_ALL, msgScoreInfo);
	write_byte(killer);
	write_short(killerFrags);
	write_short(get_user_deaths(killer));
	write_short(0);
	write_short(team);
	message_end();
}

stock ground_z(origin[3], ent, skip = 0, recursion = 0)
{
	origin[2] += random_num(5, 80);

	if (!pev_valid(ent)) return origin[2];

	new Float:tempOrigin[3];

	IVecFVec(origin, tempOrigin);
	set_pev(ent, pev_origin, tempOrigin);
	engfunc(EngFunc_DropToFloor, ent);

	if (!skip && !engfunc(EngFunc_EntIsOnFloor, ent)) {
		if (recursion >= 10) skip = 1;

		return ground_z(origin, ent, skip, ++recursion);
	}

	pev(ent, pev_origin, tempOrigin);

	return floatround(tempOrigin[2]);
}

stock grenade_is_smoke(ent)
{
	if (!pev_valid(ent)) return false;

	new entModel[64];

	pev(ent, pev_model, entModel, charsmax(entModel));

	if (contain(entModel, "smokegrenade") != -1) return true;

	return false;
}

stock remove_molotovs(id = 0)
{
	new ent = find_ent_by_class(0, molotovClassName);

	while (ent > 0) {
		if (!id || (id && pev(ent, pev_owner) == id)) {
			fire_stop(ent);
		}

		ent = find_ent_by_class(ent, molotovClassName);
	}
}

stock Float:distance_to_floor(Float:start[3], ignoremonsters = 1)
{
	new Float:dest[3], Float:end[3];

	dest[0] = start[0];
	dest[1] = start[1];
	dest[2] = -8191.0;

	engfunc(EngFunc_TraceLine, start, dest, ignoremonsters, 0, 0);
	get_tr2(0, TR_vecEndPos, end);

	new Float:ret = start[2] - end[2];

	return ret > 0 ? ret : 0.0;
}


public _csgo_get_user_molotov(id)
	return get_bit(id, molotov);