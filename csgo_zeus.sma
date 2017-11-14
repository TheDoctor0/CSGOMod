#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <engine>
#include <cstrike>

#define PLUGIN "CS:GO Zeus"
#define AUTHOR "wopox1337 & O'Zone"
#define VERSION "1.0"

#define ZEUS_DISTANCE 230

new const zeusWeaponName[] = "weapon_p228";

new const gBeamSprite[] = "sprites/laserbeam.spr";

enum { ViewModel, PlayerModel, WorldModel }
new const Models[][] = {
	"models/csr_csgo/zeus/v_zeus.mdl",
	"models/csr_csgo/zeus/p_zeus.mdl",
	"models/csr_csgo/zeus/w_zeus.mdl"
}

stock const OLDWORLD_MODEL[] = "models/w_p228.mdl";

enum { Deploy, Hit, Shoot }
new const Sounds[][] = {
	"zeus/deploy.wav",
	"zeus/hit.wav",
	"zeus/hitwall.wav"
}

new g_pBoltSprite;

new Float:gameTime;

new bool:bRestarted
new bool:bReset;

new bool:bZeus[MAX_PLAYERS + 1];

new zeusEnabled;
new zeusPrice;

const XO_PLAYER	= 5;
const XO_WEAPON	= 4;

const m_pPlayer			= 41;
const m_flNextPrimaryAttack		= 46;
const m_flNextSecondaryAttack	= 47;
const m_flTimeWeaponIdle = 48;
const m_fKnown			= 44;
const m_iClip			= 51;
const m_iClientClip		= 52;

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
	
	register_forward(FM_SetModel, "fw_SetModel", false);

	register_event("DeathMsg", "event_deathmsg", "a", "2>0");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("TextMsg", "event_gamerestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");

	register_logevent("event_round_end", 2, "1=Round_End");
}

public plugin_precache()
{
	g_pBoltSprite = precache_model(gBeamSprite);

	new i, bWasFail;

	for(i = 0; i < sizeof Models; i++)
	{
		if(file_exists(Models[i])) precache_model(Models[i]);
		else
		{
			log_amx("[Zeus Precache] File '%s' not exist. Skipped!", Models[i]);
			
			bWasFail = true;
		}
	}
	
	new szFile[64];

	for(i = 0; i < sizeof Sounds; i++) 
	{
		formatex(szFile, charsmax(szFile), "sound\%s", Sounds[i]);

		if(file_exists(szFile)) precache_sound(Sounds[i]);
		else
		{
			log_amx("[Zeus Precache] File '%s' not exist. Skipped!", Sounds[i]);
			
			bWasFail = true;
		}
	}
	
	if(bWasFail) set_fail_state("[Zeus Precache] Not all files were precached. Check logs!");
}

public client_putinserver(id)
	bZeus[id] = false;

public client_disconnected(id)
	bZeus[id] = false;

public buy_zeus(id) 
{
	if(!is_user_alive(id) || !zeusEnabled) return PLUGIN_HANDLED;

	if(!cs_get_user_buyzone(id))
	{
		client_print(id, print_center, "Nie mozesz kupic zeusa poza buyzone.");

		return PLUGIN_HANDLED;
	}

	new Float:buytime = get_cvar_float("mp_buytime") * 60.0, Float:timepassed = get_gametime() - gameTime;

	if(floatcmp(timepassed, buytime) == 1)
	{
		client_print(id, print_center, "Czas na zakup juz minal!");

		return PLUGIN_HANDLED;
	}

	new money = cs_get_user_money(id);

	if(money < zeusPrice)
	{
		client_print(id, print_center, "Nie masz wystarczajaco duzo $, zeby kupic zeusa (%i$).", zeusPrice);

		return PLUGIN_HANDLED;
	}

	if(bZeus[id])
	{
		client_print(id, print_center, "Juz posiadasz zeusa!");

		return PLUGIN_HANDLED;
	}

	bZeus[id] = true;

	cs_set_user_money(id, money - zeusPrice);

	ham_strip_weapon(id, zeusWeaponName);

	give_item(id, zeusWeaponName);

	engclient_cmd(id, zeusWeaponName);

	emit_sound(id, CHAN_AUTO, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return PLUGIN_HANDLED;
}

public event_deathmsg()
	bZeus[read_data(2)] = false;

public event_gamerestart() 
	bRestarted = true;

public event_round_end()
	if(!bReset) bReset = true;

public event_new_round()
{
	bReset = false;

	gameTime = get_gametime();

	if(bRestarted)
	{
		for(new i; i <= MAX_PLAYERS; i++) bZeus[i] = false;

		bRestarted = false;
	}

	return PLUGIN_CONTINUE;
}

public weapon_attach_to_player(weapon, id)
{
	if(get_pdata_float(weapon, m_fKnown, XO_WEAPON) || !bZeus[id] || !zeusEnabled) return;

	set_pdata_int(weapon, m_iClip, 1, XO_WEAPON);
	set_pdata_int(id, m_iClientClip, 0, XO_PLAYER);
}

public weapon_item_deploy(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, m_pPlayer, XO_WEAPON);

	if(!is_user_alive(id) || !zeusEnabled || !bZeus[id]) return HAM_IGNORED;

	set_pev(id, pev_viewmodel2, Models[ViewModel]);
	set_pev(id, pev_weaponmodel2, Models[PlayerModel]);

	UTIL_PlayWeaponAnimation(id, 3);
	emit_sound(weapon, CHAN_WEAPON, Sounds[Deploy], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return HAM_IGNORED;
}

public weapon_primary_attack(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, m_pPlayer, XO_WEAPON);

	if(!is_user_alive(id) || !zeusEnabled || !bZeus[id]) return HAM_IGNORED;

	bZeus[id] = false;
	
	static target, iBody, Float: fDistance;
	fDistance = get_user_aiming(id, target, iBody);
	
	static iOrigin[3];
	
	static any: targetOrigin[3];
	
	static Float: fOrigin[3], Float: fVelocity[3];
	entity_get_vector(id, EV_VEC_origin, fOrigin);
	VelocityByAim(id, ZEUS_DISTANCE, fVelocity);
	
	static Float: fTemp[3];
	xs_vec_add(fOrigin, fVelocity, fTemp);
	FVecIVec(fOrigin, iOrigin);
	FVecIVec(fTemp, targetOrigin);
	
	if(is_user_connected(target) && fDistance <= ZEUS_DISTANCE)
	{
		get_user_origin(target, targetOrigin, 0);
		
		if(get_user_team(id) != get_user_team(target)) ExecuteHam(Ham_TakeDamage, target, 0, id, 999.0, DMG_SHOCK);
		
		emit_sound(id, CHAN_WEAPON, Sounds[Hit], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	} 
	else emit_sound(id, CHAN_WEAPON, Sounds[Shoot], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	UTIL_CreateThunder2(id, targetOrigin);
	UTIL_CreateLight(iOrigin);
	UTIL_PlayWeaponAnimation(id, 2);

	ham_strip_weapon(id, zeusWeaponName);

	return HAM_SUPERCEDE;
}

public weapon_item_can_drop(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, m_pPlayer, XO_WEAPON);

	if(!is_user_alive(id) || !zeusEnabled || !bZeus[id]) return HAM_IGNORED;

	SetHamReturnInteger(false);

	return HAM_SUPERCEDE;
}

public player_spawned(id)
	if(bZeus[id]) set_task(0.1, "player_spawned_post", id);

public player_spawned_post(id)
{
	new weapons[32], weaponsNum, bool:zeus;

	get_user_weapons(id, weapons, weaponsNum);

	for(new i; i < weaponsNum; i++) if(weapons[i] == get_weaponid(zeusWeaponName)) zeus = true;
	
	bZeus[id] = zeus;
}

public fw_SetModel(weapon, szModel[])
{
	if(!pev_valid(weapon)) return FMRES_IGNORED;

	if(equali(szModel, OLDWORLD_MODEL))
	{
		static szClassName[8];
		pev(weapon, pev_classname, szClassName, charsmax(szClassName));
		
		if(szClassName[0] == 'w' && szClassName[6] == 'b')
		{
			engfunc(EngFunc_SetModel, weapon, Models[WorldModel]);
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED
}


stock UTIL_PlayWeaponAnimation(const id, const Sequence)
{
	set_pev(id, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id);
	write_byte(Sequence);
	write_byte(pev(id, pev_body));
	message_end();
}

stock UTIL_CreateThunder(iStart[3], iEnd[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY); 
	write_byte(TE_BEAMPOINTS); 
	write_coord(iStart[0]); 
	write_coord(iStart[1]); 
	write_coord(iStart[2]); 
	write_coord(iEnd[0]); 
	write_coord(iEnd[1]); 
	write_coord(iEnd[2]); 
	write_short(g_pBoltSprite); 
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

stock UTIL_CreateThunder2(iStartId, iEnd[3])
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(iStartId | 0x1000);	// Начальное энтити
	write_coord(iEnd[0]);	// Конец луча
	write_coord(iEnd[1]);	// Y
	write_coord(iEnd[2]);	// Z
	write_short(g_pBoltSprite);	// Индекс спрайта
	write_byte(1);		// FrameStart
	write_byte(30);		// FrameRate
	write_byte(5);		// Life
	write_byte(2);		// Width
	write_byte(20);		// Noise
	write_byte(135); 	// Color R
	write_byte(206);	// G
	write_byte(250);	// B
	write_byte(200);	// Brightness
	write_byte(200);	// Scroll
	message_end()
}

stock UTIL_CreateLight(origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_DLIGHT);
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_byte(50); // radius
	write_byte(135);	// r
	write_byte(206);	// g
	write_byte(250);	// b
	write_byte(3); // life
	write_byte(120); // decay rate
	message_end();
}

stock ham_strip_weapon(id, const weapon[])
{
	if(!equal(weapon, "weapon_", 7)) return 0;

	new wId = get_weaponid(weapon);

	if(!wId) return 0;

	new wEnt;

	while((wEnt = engfunc(EngFunc_FindEntityByString, wEnt, "classname", weapon)) && pev(wEnt, pev_owner) != id) {}

	if(!wEnt) return 0;
	
	if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem, id, wEnt)) return 0;
	ExecuteHamB(Ham_Item_Kill, wEnt);
	
	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId));

	return 1;
}