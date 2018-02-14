#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <csx>

#define MOLOTOV_TASKID_RESET 1000
#define MOLOTOV_TASKID_OFFSET 10
#define MOLOTOV_TASKID_BASE1 2000
#define MOLOTOV_TASKID_BASE2 MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * MAX_PLAYERS)
#define MOLOTOV_TASKID_BASE3 MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * MAX_PLAYERS)

#define PLUGIN "CS:GO Molotov"
#define AUTHOR "DynamicBits & O'Zone"
#define VERSION "3.5"

new molotovEnabled, molotovPrice;
new Float:molotovRadius, Float:molotovFireTime, Float:molotovFireDamage;

new bool:bMolotov[MAX_PLAYERS + 1], molotovOffset[MAX_PLAYERS + 1];
new msgScoreInfo, msgDeathMsg, maxPlayers;
new bool:bRestarted, bool:bReset;
new fireSprite, smokeSprite[2];
new Float:gameTime;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("molotov", "buy_molotov");
	register_clcmd("say /m", "buy_molotov");
	register_clcmd("say_team /m", "buy_molotov");
	register_clcmd("say /molotov", "buy_molotov");
	register_clcmd("say_team /molotov", "buy_molotov");

	bind_pcvar_num(create_cvar("csgo_molotov_enabled", "1"), molotovEnabled);
	bind_pcvar_num(create_cvar("csgo_molotov_price", "500"), molotovPrice);
	bind_pcvar_float(create_cvar("csgo_molotov_radius", "150.0"), molotovRadius);
	bind_pcvar_float(create_cvar("csgo_molotov_firetime", "7.0"), molotovFireTime);
	bind_pcvar_float(create_cvar("csgo_molotov_firedamage", "3.0"), molotovFireDamage);

	register_event("DeathMsg", "event_deathmsg", "a", "2>0");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("TextMsg", "event_gamerestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");

	register_logevent("event_round_end", 2, "1=Round_End");

	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "molotov_deploy_model", true);
	RegisterHam(Ham_Spawn, "player", "player_spawned", true);

	register_forward(FM_EmitSound, "fw_emitsound");

	maxPlayers = get_maxplayers();

	msgScoreInfo = get_user_msgid("ScoreInfo");
	msgDeathMsg = get_user_msgid("DeathMsg");
}

public plugin_precache()
{
	fireSprite = precache_model("sprites/flame.spr");
	smokeSprite[0] = precache_model("sprites/black_smoke3.spr");
	smokeSprite[1] = precache_model("sprites/steam1.spr");

	precache_model("models/csr_csgo/nades/p_molotov.mdl");
	precache_model("models/csr_csgo/nades/v_molotov.mdl");
	precache_model("models/csr_csgo/nades/w_molotov.mdl");
	precache_model("models/csr_csgo/nades/w_broken_molotov.mdl");

	precache_sound("molotov/fire.wav");
	precache_sound("molotov/explode.wav");
	precache_sound("molotov/extinguish.wav");

	precache_sound("items/9mmclip1.wav");
}

public client_putinserver(id)
	bMolotov[id] = false;

public client_disconnected(id)
{
	bMolotov[id] = false;

	remove_molotovs(id);
}

public buy_molotov(id) 
{
	if(!molotovEnabled || !is_user_alive(id)) return PLUGIN_HANDLED;

	if(!cs_get_user_buyzone(id))
	{
		client_print(id, print_center, "Nie mozesz kupic molotova poza buyzone.");

		return PLUGIN_HANDLED;
	}

	new Float:buytime = get_cvar_float("mp_buytime") * 60.0, Float:timepassed = get_gametime() - gameTime;

	if(floatcmp(timepassed, buytime) == 1)
	{
		client_print(id, print_center, "Czas na zakup juz minal!");

		return PLUGIN_HANDLED;
	}

	new money = cs_get_user_money(id);

	if(money < molotovPrice)
	{
		client_print(id, print_center, "Nie masz wystarczajaco duzo $, zeby kupic molotova (%i$).", molotovPrice);

		return PLUGIN_HANDLED;
	}

	if(bMolotov[id])
	{
		client_print(id, print_center, "Juz posiadasz molotova!");

		return PLUGIN_HANDLED;
	}

	bMolotov[id] = true;

	cs_set_user_money(id, money - molotovPrice);

	fm_give_item(id, "weapon_hegrenade");

	engclient_cmd(id, "weapon_hegrenade");

	emit_sound(id, CHAN_AUTO, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return PLUGIN_HANDLED;
}

public event_deathmsg()
	bMolotov[read_data(2)] = false;

public event_gamerestart() 
	bRestarted = true;

public event_round_end()
{
	if(!bReset)
	{
		reset_tasks();

		bReset = true;
	}
}

public event_new_round()
{
	bReset = false;

	gameTime = get_gametime();

	if(!molotovEnabled) return PLUGIN_CONTINUE;

	reset_tasks();

	remove_molotovs();

	if(bRestarted)
	{
		for(new i; i <= MAX_PLAYERS; i++) bMolotov[i] = false;

		bRestarted = false;
	}

	return PLUGIN_CONTINUE;
}

public molotov_deploy_model(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, 41, 4);

	if(!is_user_alive(id) || !molotovEnabled || !bMolotov[id]) return HAM_IGNORED;

	set_pev(id, pev_viewmodel2, "models/csr_csgo/nades/v_molotov.mdl");
	set_pev(id, pev_weaponmodel2, "models/csr_csgo/nades/p_molotov.mdl");

	return HAM_IGNORED;
}

public player_spawned(id)
	if(bMolotov[id]) set_task(0.1, "player_spawned_post", id);

public player_spawned_post(id)
{
	new weapons[32], weaponsNum, bool:molotov;

	get_user_weapons(id, weapons, weaponsNum);

	for(new i; i < weaponsNum; i++) if(weapons[i] == CSW_HEGRENADE) molotov = true;
	
	bMolotov[id] = molotov;
}

public grenade_throw(id, ent, wid)
{
	if(!molotovEnabled || !is_user_connected(id) || wid != CSW_HEGRENADE || !bMolotov[id]) return PLUGIN_CONTINUE;

	bMolotov[id] = false;

	engfunc(EngFunc_SetModel, ent, "models/csr_csgo/nades/w_molotov.mdl");
	set_pev(ent, pev_nextthink, 99999.0);

	set_pev(ent, pev_team, get_user_team(id));

	return PLUGIN_HANDLED;
}

public fw_emitsound(ent, channel, sample[])
{
	if(equal(sample[8], "he_bounce", 9))
	{
		new sModel[64];
		pev(ent, pev_model, sModel, charsmax(sModel));

		if(contain(sModel, "w_molotov.mdl") != -1)
		{
			emit_sound(ent, CHAN_AUTO, "debris/glass2.wav", VOL_NORM, ATTN_STATIC, 0, PITCH_LOW);

			new Float:fFriction, Float:fVelocity[3];

			pev(ent, pev_friction, fFriction);
			fFriction *= 1.15;
			set_pev(ent, pev_friction, fFriction);

			pev(ent, pev_velocity, fVelocity);
			fVelocity[0] *= 0.3;
			fVelocity[1] *= 0.3;
			fVelocity[2] *= 0.3;
			set_pev(ent, pev_velocity, fVelocity);

			molotov_explode(ent);

			return FMRES_SUPERCEDE;
		}
		else if(contain(sModel, "w_broken_molotov.mdl") != -1) return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

stock molotov_explode(ent) 
{
	new Float:fOrigin[3], iOrigin[3], param[7], iOwner = pev(ent, pev_owner);
	new ent2 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	set_pev(ent, pev_classname, "molotov");
	set_pev(ent2, pev_classname, "molotov");

	pev(ent, pev_origin, fOrigin);

	param[0] = ent;
	param[1] = ent2;
	param[2] = iOwner;
	param[3] = pev(ent, pev_team);
	param[4] = iOrigin[0] = floatround(fOrigin[0]);
	param[5] = iOrigin[1] = floatround(fOrigin[1]);
	param[6] = iOrigin[2] = floatround(fOrigin[2]);

	engfunc(EngFunc_SetModel, ent, "models/csr_csgo/nades/w_broken_molotov.mdl");

	if(bReset)
	{
		set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);

		return PLUGIN_HANDLED;
	}

	if(extinguish_molotov(param)) return PLUGIN_CONTINUE;

	random_fire(iOrigin, ent2);

	if(++molotovOffset[iOwner] == 10) molotovOffset[iOwner] = 0;

	emit_sound(param[1], CHAN_AUTO, "molotov/explode.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_task(0.1, "fire_damage", MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * (iOwner - 1)) + molotovOffset[iOwner], param, 7, "a", floatround(molotovFireTime / 0.1, floatround_floor));
	set_task(1.0, "fire_sound", MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * (iOwner - 1)) + molotovOffset[iOwner], param, 7, "a", floatround(molotovFireTime) - 1);

	set_task(molotovFireTime, "fire_stop", MOLOTOV_TASKID_BASE3 + (MOLOTOV_TASKID_OFFSET * (iOwner - 1)) + molotovOffset[iOwner], param, 7);

	return PLUGIN_CONTINUE;
}

public fire_sound(param[])
	if(pev_valid(param[1])) emit_sound(param[1], CHAN_AUTO, "molotov/fire.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

public fire_stop(param[]) 
{
	if(pev_valid(param[0])) set_pev(param[0], pev_flags, pev(param[0], pev_flags) | FL_KILLME);
	if(pev_valid(param[1])) set_pev(param[1], pev_flags, pev(param[1], pev_flags) | FL_KILLME);
}

public fire_damage(param[]) 
{
	if(extinguish_molotov(param)) return;

	new Float:fOrigin[3], iOrigin[3];

	iOrigin[0] = param[4];
	iOrigin[1] = param[5];
	iOrigin[2] = param[6];

	random_fire(iOrigin, param[1]);

	IVecFVec(iOrigin, fOrigin);

	radius_damage2(param[2], param[3], fOrigin, molotovFireDamage, molotovRadius, DMG_BURN, false);
}

stock radius_damage2(iAttacker, iAttackerTeam, Float:fOrigin[3], Float:fDamage, Float:fRange, iDmgType, bool:bCalc = true)
{
	new Float:pOrigin[3], Float:fDist, Float:fTmpDmg, i;

	while(i++ < maxPlayers)
	{
		if(!is_user_alive(i) || (iAttacker != i && iAttackerTeam == get_user_team(i))) continue;

		pev(i, pev_origin, pOrigin);
		fDist = get_distance_f(fOrigin, pOrigin);

		if(fDist > fRange) continue;

		if (bCalc) fTmpDmg = fDamage - (fDamage / fRange) * fDist;
		else fTmpDmg = fDamage;

		if(pev(i, pev_health) <= fTmpDmg) kill(iAttacker, i, iAttackerTeam);
		else fm_fakedamage(i, "molotov", fTmpDmg, iDmgType);
	}
}

stock extinguish_molotov(param[])
{
	if(!is_valid_ent(param[1])) return false;

	new entList[64], foundGrenades = find_sphere_class(param[1], "grenade", molotovRadius * 0.75, entList, charsmax(entList));

	for(new i = 0; i < foundGrenades; i++)
	{
		if(grenade_is_smoke(entList[i]))
		{
			new Float:entVelocity[3];
			entVelocity[0] = 0.0;
			entVelocity[1] = 0.0;
			entVelocity[2] = 0.0;
			entity_set_vector(entList[i], EV_VEC_velocity, entVelocity);

			static Float:dmgTime;
			pev(entList[i], pev_dmgtime, dmgTime);
			set_pev(entList[i], pev_dmgtime, dmgTime - 3.0);

			if(pev_valid(param[0])) set_pev(param[0], pev_flags, pev(param[0], pev_flags) | FL_KILLME);

			if(pev_valid(param[1]))
			{
				emit_sound(param[1], CHAN_AUTO, "molotov/extinguish.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				set_pev(param[1], pev_flags, pev(param[1], pev_flags) | FL_KILLME);
			}

			return true;
		}
	}

	return false;
}

stock random_fire(Origin[3], ent)
{
	static iRange, iOrigin[3], g_g, i;

	iRange = floatround(molotovRadius);

	for(i = 1; i <= 5; i++)
	{
		g_g = 1;

		iOrigin[0] = Origin[0] + random_num(-iRange, iRange);
		iOrigin[1] = Origin[1] + random_num(-iRange, iRange);
		iOrigin[2] = Origin[2];
		iOrigin[2] = ground_z(iOrigin, ent);

		while (get_distance(iOrigin, Origin) > iRange)
		{
			iOrigin[0] = Origin[0] + random_num(-iRange, iRange);
			iOrigin[1] = Origin[1] + random_num(-iRange, iRange);
			iOrigin[2] = Origin[2];

			if (++g_g >= 10) iOrigin[2] = ground_z(iOrigin, ent, 1);
			else iOrigin[2] = ground_z(iOrigin, ent);
		}

		new rand = random_num(5, 15);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_SPRITE);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2] + rand * 5);
		write_short(fireSprite);
		write_byte(rand);
		write_byte(100);
		message_end();
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2] + 120);
	write_short(smokeSprite[random_num(0, 1)]);
	write_byte(random_num(10, 30));
	write_byte(random_num(10, 20));
	message_end();
}

stock reset_tasks()
{
	for(new i; i < maxPlayers; i++)
	{
		for(new o; o < MOLOTOV_TASKID_OFFSET; o++)
		{
			if(task_exists(MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * i) + o)) remove_task(MOLOTOV_TASKID_BASE1 + (MOLOTOV_TASKID_OFFSET * i) + o);

			if(task_exists(MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * i) + o)) remove_task(MOLOTOV_TASKID_BASE2 + (MOLOTOV_TASKID_OFFSET * i) + o);
		}
	}
}

stock kill(iKiller, iVictim, iKillerTeam)
{
	message_begin(MSG_ALL, msgDeathMsg, {0,0,0}, 0);
	write_byte(iKiller);
	write_byte(iVictim);
	write_byte(0);
	write_string("molotov");
	message_end();

	new iVictimTeam = get_user_team(iVictim);
	new iMsgBlock = get_msg_block(msgDeathMsg);

	set_msg_block(msgDeathMsg, BLOCK_ONCE);

	new iKillerFrags = get_user_frags(iKiller);
	new iVictimFrags = get_user_frags(iVictim);

	if(iKiller != iVictim) fm_set_user_frags(iVictim, iVictimFrags + 1);

	if(iKillerTeam != iVictimTeam) iKillerFrags++;
	else iKillerFrags--;

	fm_set_user_frags(iKiller, iKillerFrags);

	user_kill(iVictim, 0);
	set_msg_block(msgDeathMsg, iMsgBlock);

	new sVictim[32], sVictimAuth[35], sVictimTeam[32];

	get_user_name(iVictim, sVictim, charsmax(sVictim));
	get_user_authid(iVictim, sVictimAuth, charsmax(sVictimAuth));
	get_user_team(iVictim, sVictimTeam, charsmax(sVictimTeam));

	if(iKiller == iVictim) log_message("^"%s<%d><%s><%s>^" committed suicide with ^"molotov^"", sVictim, get_user_userid(iVictim), sVictimAuth, sVictimTeam);
	else if (is_user_connected(iKiller))
	{
		new sKiller[32], sKillerAuth[35], sKillerTeam[32];

		get_user_name(iKiller, sKiller, charsmax(sKiller));
		get_user_authid(iKiller, sKillerAuth, charsmax(sKillerAuth));
		get_user_team(iKiller, sKillerTeam, charsmax(sKillerTeam));

		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"molotov^"", sKiller, get_user_userid(iKiller), sKillerAuth, sKillerTeam, sVictim, get_user_userid(iVictim), sVictimAuth, sVictimTeam);
	}

	if (iKiller != iVictim)
	{
		new iMoney = cs_get_user_money(iKiller) + 300;

		cs_set_user_money(iKiller, iMoney > 16000 ? 16000 : iMoney);
	}

	message_begin(MSG_ALL, msgScoreInfo);
	write_byte(iKiller);
	write_short(iKillerFrags);
	write_short(get_user_deaths(iKiller));
	write_short(0);
	write_short(iKillerTeam);
	message_end();
}

stock ground_z(iOrigin[3], ent, skip = 0, iRecursion = 0)
{
	iOrigin[2] += random_num(5, 80);

	if(!pev_valid(ent)) return iOrigin[2];

	new Float:fOrigin[3];

	IVecFVec(iOrigin, fOrigin);
	set_pev(ent, pev_origin, fOrigin);
	engfunc(EngFunc_DropToFloor, ent);

	if(!skip && !engfunc(EngFunc_EntIsOnFloor, ent))
	{
		if(iRecursion >= 10) skip = 1;

		return ground_z(iOrigin, ent, skip, ++iRecursion);
	}

	pev(ent, pev_origin, fOrigin);

	return floatround(fOrigin[2]);
}

stock grenade_is_smoke(ent)
{
	if(!is_valid_ent(ent)) return false;
	
	new entModel[32];

	pev(ent, pev_model, entModel, charsmax(entModel));
	
	if(equal(entModel, "models/w_smokegrenade.mdl")) return true;
	
	return false;
}

stock remove_molotovs(id = 0)
{
	new className[10], ents = engfunc(EngFunc_NumberOfEntities);

	for(new i = get_maxplayers(); i <= ents; i++)
	{
		if(!pev_valid(i) || (id && pev(i, pev_owner) != id)) continue;

		pev(i, pev_classname, className, charsmax(className));

		if(equal(className, "molotov")) engfunc(EngFunc_RemoveEntity, i);
	}
}