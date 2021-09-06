#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <csgomod>

#define PLUGIN_NAME "[GRENADE] Molotov"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_AUTHOR "medusa"

new const MOLOTOV_FIRE_CLASSNAME[] = "molotov";
new const EFFECT_CLASSNAME_MUZZLEFLASH[] = "weapon_molotov_muzzleflash";
new const EFFECT_CLASSNAME_WICK[] = "weapon_molotov_wick";
new const CLASSNAME_SMOKE_TOUCHER[] = "molotov_touch_smoke";

const WeaponIdType:WEAPON_ID = WEAPON_SMOKEGRENADE;

const WeaponIdType:WEAPON_NEW_ID = WEAPON_GLOCK;

const WeaponIdType:WEAPON_FAKE_ID = WeaponIdType:76;
new const WEAPON_NAME[] = "weapon_smokegrenade";
new const AMMO_NAME[] = "Molotov";
new const WEAPON_NEW_NAME[] = "/grenaderad/weapon_molotov";
new const ITEM_CLASSNAME[] = "weapon_molotov";
new const GRENADE_CLASSNAME[] = "grenade_molotov";
const AMMO_ID = 17;
const NUM_SLOT = 5;

const Float:MOLOTOV_PLAYTHINK_TIME = 0.04;

new MsgIdWeaponList, MsgIdAmmoPickup;
#if WEAPON_NEW_ID != WEAPON_GLOCK
new FwdRegUserMsg, MsgHookWeaponList;
#endif

new SpriteFireColumn, SpriteFireExplode, SpriteFireBall, SpriteFireGround;
new bool:bCreate[MAX_PLAYERS + 1];
new sizes[] = { 51, 51, 51 }, count = 3;

new const WEAPON_MODEL_VIEW_MOLOTOV[] = "models/grenades/v_molotov.mdl";
new const WEAPON_MODEL_PLAYER_MOLOTOV[] = "models/grenades/p_molotov.mdl";
new const WEAPON_MODEL_WORLD_MOLOTOV[] = "models/grenades/w_molotov.mdl";

new const MOLOTOV_MODEL_FLOOR[] = "models/grenaderad/molotov_fire_floor.mdl";

new const MOLOTOV_SPRITE_FIRE_BALL[] = "sprites/grenaderad/molotov_fire_ball.spr";
new const MOLOTOV_SPRITE_FIRE_COLUMN[] = "sprites/grenaderad/molotov_fire_column.spr";
new const MOLOTOV_SPRITE_FIRE_EXPLODE[] = "sprites/grenaderad/molotov_fire_explode_c.spr";
new const MOLOTOV_SPRITE_FIRE_GROUND[] = "sprites/grenaderad/molotov_fire_ground.spr";
new const MOLOTOV_SPRITE_XPARK1[] = "sprites/grenaderad/molotov_fire_blend_c.spr";
new const MOLOTOV_SPRITE_WICK[] = "sprites/grenaderad/molotov_wick.spr";

new const MOLOTOV_SOUND_EXPLODE[] = "weapons/grenaderad/molotov_explode.wav";
new const MOLOTOV_SOUND_HIT[] = "weapons/grenaderad/molotov_hit.wav";
new const MOLOTOV_SOUND_IDLE[] = "weapons/grenaderad/molotov_idle_loop.wav";
new const MOLOTOV_SOUND_LOOP[] = "weapons/grenaderad/molotov_fire_ground.wav";
new const MOLOTOV_SOUND_FADEOUT[] = "weapons/grenaderad/molotov_fire_fadeout.wav";
new const MOLOTOV_SOUND_EXT[] = "weapons/grenaderad/molotov_extinguish.wav";
new const GUNPICKUP_SOUND[] = "items/gunpickup2.wav";
new const AMMOPICKUP_SOUND[] = "items/9mmclip1.wav";

enum CvarStruct {
	CVAR_BUY_ACCESS,
	CVAR_EQUIP_ACCESS,
	CVAR_CHECK_BUYZONE,
	CVAR_COST,
	CVAR_BUY_LIMIT,
	CVAR_LIMIT_ROUND,
	Float:CVAR_BUYTIME,
	CVAR_HIT_PLAYER,
	#if !defined ALLOW_CUSTOMNADE
	CVAR_NADE_DROPS,
	#endif
	CVAR_KILLFEED,
	Float:CVAR_RADIUS,
	Float:CVAR_THROWTIME,
	CVAR_DURATION,
	CVAR_DEMAGE_MODE,
	CVAR_DEMAGE_RADIUS_MODE,
	Float:CVAR_DEMAGE_TIME,
	Float:CVAR_DEMAGE_VALUE,
	CVAR_EFFECT_MODE,
	CVAR_EFFECT_NUM,
	CVAR_SMOKE_TOUCH
}

new g_pCvarBuyAccess;
new g_pCvarSmokeOwner;
new g_eCvar[CvarStruct];
new BuyLimit[MAX_PLAYERS + 1];

new HookChain:HookChain_CBasePlayer_TakeDamage; 
new HookChain:HookChain_deathNoticePostHook;

public plugin_precache() {
	precache_model(WEAPON_MODEL_VIEW_MOLOTOV);
	precache_model(WEAPON_MODEL_PLAYER_MOLOTOV);
	precache_model(WEAPON_MODEL_WORLD_MOLOTOV);

	if(get_cvar_num("sv_auto_precache_sounds_in_models") == 0) {
		UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW_MOLOTOV);
	}
	UTIL_PrecacheSpritesFromTxt(WEAPON_NEW_NAME);

#if WEAPON_NEW_ID != WEAPON_GLOCK
	MsgIdWeaponList = get_user_msgid("WeaponList");
	if (MsgIdWeaponList) {
		MsgHookWeaponList = register_message(MsgIdWeaponList, "HookWeaponList");
	} else {
		FwdRegUserMsg = register_forward(FM_RegUserMsg, "RegUserMsg_Post", true);
	}
#endif

	precache_model(MOLOTOV_MODEL_FLOOR);
	precache_model(MOLOTOV_SPRITE_XPARK1);
	precache_model(MOLOTOV_SPRITE_WICK);

	precache_sound(MOLOTOV_SOUND_EXPLODE);
	precache_sound(MOLOTOV_SOUND_HIT);
	precache_sound(MOLOTOV_SOUND_IDLE);
	precache_sound(MOLOTOV_SOUND_LOOP);
	precache_sound(MOLOTOV_SOUND_FADEOUT);
	precache_sound(MOLOTOV_SOUND_EXT);
	precache_sound(GUNPICKUP_SOUND);
	precache_sound(AMMOPICKUP_SOUND);

	SpriteFireGround = precache_model(MOLOTOV_SPRITE_FIRE_GROUND);
	SpriteFireBall = precache_model(MOLOTOV_SPRITE_FIRE_BALL);
	SpriteFireColumn = precache_model(MOLOTOV_SPRITE_FIRE_COLUMN);
	SpriteFireExplode = precache_model(MOLOTOV_SPRITE_FIRE_EXPLODE);
}

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	g_pCvarBuyAccess = create_cvar(
		"molotov_buy_access", "", FCVAR_SERVER,
		.description = "Флаги доступа для покупки или выдачи коктейля молотова (требует наличия вписанных; ^"^" - покупка доступна всем)."
		);

	bind_pcvar_num(
		create_cvar(
			"molotov_equip_access", "0", FCVAR_SERVER,
			.description = "Автоматически выдавать коктейль молотова в начале раунда.",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 1.0
			),
		g_eCvar[CVAR_EQUIP_ACCESS]
		);

	bind_pcvar_num(
		create_cvar(
			"molotov_check_buyzone", "1", FCVAR_SERVER,
			.description = "Проверка нахождения в зоне покупки.",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 1.0
			),
		g_eCvar[CVAR_CHECK_BUYZONE]
		);

	bind_pcvar_num(
		create_cvar(
			"molotov_cost", "800", FCVAR_SERVER,
			.description = "Цена коктейля молотова.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_COST]
		);	
		
	bind_pcvar_num(
		create_cvar(
			"molotov_buy_limit", "1", FCVAR_SERVER,
			.description = "Сколько коктейлей молотова можно купить за одн раунд (значение: -1 убирает лимит).",
			.has_min = true, .min_val = -1.0
			),
		g_eCvar[CVAR_BUY_LIMIT]
		);	
		
	bind_pcvar_num(
		create_cvar(
			"molotov_limit_round", "3", FCVAR_SERVER,
			.description = "С какого раунда после начала игры будет доступен молотов.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_LIMIT_ROUND]
		);

	bind_pcvar_num(
		create_cvar(
			"molotov_check_hit_player", "2", FCVAR_SERVER,
			.description = "Сколько урона наносить при попадании коктейля молотова в тело игрока.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_HIT_PLAYER]
		);	
		
	bind_pcvar_num(
		create_cvar(
			"molotov_killfeed", "1", FCVAR_SERVER,
			.description = "Показывать ли в киллфиде рядом с именем приставку [ᴍᴏʟᴏᴛᴏᴠ].",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 1.0
			),
		g_eCvar[CVAR_KILLFEED]
		);

	bind_pcvar_float(
		create_cvar(
			"molotov_radius", "128.0", FCVAR_SERVER,
			.description = "Радиус горения коктейля молотова.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_RADIUS]
		);

	bind_pcvar_float(
		create_cvar(
			"molotov_throwtime", "2.0", FCVAR_SERVER,
			.description = "Сколько секунд коктейль молотова может находиться в полете перед взрывом.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_THROWTIME]
		);

	bind_pcvar_num(
		create_cvar(
			"molotov_duration", "12", FCVAR_SERVER,
			.description = "Сколько секунд будет гореть коктейль молотова.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_DURATION]
		);

	bind_pcvar_num(
		create_cvar(
			"molotov_demage_mode", "1", FCVAR_SERVER,
			.description = "Кто получает урон от коктейля молотова (0 - только противники, 1 - противники и игрок бросивший коктейль молотова, 2 - все игроки).",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 2.0
			),
		g_eCvar[CVAR_DEMAGE_MODE]
		);	

	bind_pcvar_num(
		create_cvar(
			"molotov_demage_radius_mode", "2", FCVAR_SERVER,
			.description = "Как будет наноситься урон от огня (1 - через Ham_TakeDamage [урон фиксированный в любой точке радиуса горения], 2 - через rg_dmg_radius [урон зависит от дальности к эпицентру горения и наличия брони]). ",
			.has_min = true, .min_val = 1.0,
			.has_max = true, .max_val = 2.0
			),
		g_eCvar[CVAR_DEMAGE_RADIUS_MODE]
		);

	bind_pcvar_float(
		create_cvar(
			"molotov_demage_time", "0.25", FCVAR_SERVER,
			.description = "Переодичность нанесения урона.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_DEMAGE_TIME]
		);

	bind_pcvar_float(
		create_cvar(
			"molotov_demage_value", "20.0", FCVAR_SERVER,
			.description = "Количество нанесенного урона за период (molotov_demage_time).",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_DEMAGE_VALUE]
		);
		
	bind_pcvar_num(
		create_cvar(
			"molotov_effect_mode", "2", FCVAR_SERVER,
			.description = "Режим отрисовки спрайтов (1 - через Entities [env_sprite], 2 - через Temporary Entities [TE_SPRITE]).",
			.has_min = true, .min_val = 1.0,
			.has_max = true, .max_val = 2.0
			),
		g_eCvar[CVAR_EFFECT_MODE]
		);
		
	bind_pcvar_num(
		create_cvar(
			"molotov_effect_num", "40", FCVAR_SERVER,
			.description = "Количество отрисовываемых спрайтов огня.",
			.has_min = true, .min_val = 0.0
			),
		g_eCvar[CVAR_EFFECT_NUM]
		);
		
	bind_pcvar_num(
		create_cvar(
			"molotov_smoke_touch", "1", FCVAR_SERVER,
			.description = "Тушить ли коктейль молотова дымовой гранатой.",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 1.0
			),
		g_eCvar[CVAR_SMOKE_TOUCH]
		);
		
	g_pCvarSmokeOwner = create_cvar(
		"molotov_smoke_owner", "models/w_smokegrenade.mdl", FCVAR_SERVER,
		.description = "Путь до модели дымовой гранаты. (Стандартная: models/w_smokegrenade.mdl)."
		);

	AutoExecConfig();

	register_clcmd(WEAPON_NEW_NAME, "CmdSelect");

	register_clcmd("molotov", "BuyMolotov_Cmd");

	#if WEAPON_NEW_ID != WEAPON_GLOCK
		RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_RestrictItem_Pre", false)
	#endif

	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "CSGameRules_CleanUpMap_Post", true);
	RegisterHookChain(RG_CBasePlayer_GiveAmmo, "CBasePlayer_GiveAmmo_Pre", false);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy_Pre", false);

	RegisterHam(Ham_Item_Deploy, WEAPON_NAME, "Item_Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, WEAPON_NAME, "Item_Holster_Post", true);
	RegisterHam(Ham_Item_Holster, WEAPON_NAME, "Item_Holster_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_NAME, "Item_PrimaryAttack_Pre", false);

	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "CBasePlayer_ThrowGrenade_Pre", false);

	DisableHookChain((HookChain_CBasePlayer_TakeDamage = RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage_Pre", false)));
	
	RegisterHookChain(RG_CSGameRules_DeathNotice, "CSGameRules_DeathNotice_Pre", false);
	DisableHookChain((HookChain_deathNoticePostHook = RegisterHookChain(RG_CSGameRules_DeathNotice, "CSGameRules_DeathNotice_Post", true)));
	
	RegisterHookChain(RG_CGrenade_ExplodeSmokeGrenade, "CSGrenade_ExplodeSmokeGrenade_Pre", false);
	RegisterHam(Ham_Think, "env_sprite", "FireMolotov_Think_Post", true);
	
	new szAccess[24];
	get_pcvar_string(g_pCvarBuyAccess, szAccess, charsmax(szAccess));
	g_eCvar[CVAR_BUY_ACCESS] = read_flags(szAccess);
	
	MsgIdAmmoPickup = get_user_msgid("AmmoPickup");

#if WEAPON_NEW_ID == WEAPON_GLOCK
	MsgIdWeaponList = get_user_msgid("WeaponList");
	UTIL_WeapoList(
		MSG_INIT, 0,
		WEAPON_NEW_NAME,
		AMMO_ID, 1,
		-1, -1, GRENADE_SLOT, NUM_SLOT, WEAPON_NEW_ID,
		ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE
		);
#else
	if (FwdRegUserMsg) {
		unregister_forward(FM_RegUserMsg, FwdRegUserMsg, true);
	}
	unregister_message(MsgIdWeaponList, MsgHookWeaponList);
#endif
}


public OnConfigsExecuted() {
	g_eCvar[CVAR_BUYTIME] = get_cvar_float("mp_buytime");
	#if !defined ALLOW_CUSTOMNADE
	g_eCvar[CVAR_NADE_DROPS] = get_cvar_num("mp_nadedrops");
	#endif
}

public plugin_natives()
{
    register_native("IsUserHasMolotov", "NativeIsUserHasMolotov", false);
    register_native("GiveUserMolotov", "NativeGiveUserMolotov", false);
    register_native("csgo_get_user_molotov", "_csgo_get_user_molotov", true);
}

public _csgo_get_user_molotov(id)
	return bool:(get_member(id, m_rgAmmo, AMMO_ID))
	
public NativeGiveUserMolotov(plugin, params)
{
    enum { arg_player = 1 };

    new id = get_param(arg_player);

    if(!is_user_connected(id))
    {
        return false;
    }

    giveNade(id);

    return true;
}

public NativeIsUserHasMolotov(plugin, params)
{
    enum { arg_player = 1 };

    new id = get_param(arg_player);

    if(!is_user_connected(id))
    {
        return false;
    }

    return bool:(get_member(id, m_rgAmmo, AMMO_ID));
}

public BuyMolotov_Cmd(id) 
{
	if (!is_user_alive(id)) {
		return;
	}

	new bitAccess = g_eCvar[CVAR_BUY_ACCESS];
	
	if (g_eCvar[CVAR_CHECK_BUYZONE] && !rg_get_user_buyzone(id)) {
		return;
	}
	
	if (get_member(id, m_bIsVIP)) {
		client_print(id, print_center, "#Cstrike_TitlesTXT_VIP_cant_buy");

		return;
	}

	if (bitAccess && ~get_user_flags(id) & bitAccess){
		client_print(id, print_center, "#Cstrike_TitlesTXT_Weapon_Not_Available");

		return;
	}
	
	if(get_member_game(m_iTotalRoundsPlayed) + 1 < g_eCvar[CVAR_LIMIT_ROUND])
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Cant_buy");
		return;
	}

	if(BuyLimit[id] == 0 && BuyLimit[id] != -1){
		client_print(id, print_center, "#Cstrike_TitlesTXT_Already_Have_One");
		
		return;
	}

	if(g_eCvar[CVAR_COST] && get_member(id, m_iAccount) < g_eCvar[CVAR_COST]) {
		client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money");

		return;
	}

	if(get_member(id, m_rgAmmo, AMMO_ID)) {
		client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
		
		return;
	}
	
	rg_add_account(id, -g_eCvar[CVAR_COST]);
	rh_emit_sound2(id, 0, CHAN_ITEM, AMMOPICKUP_SOUND);
	giveNade(id);
	BuyLimit[id]--;
}

#if WEAPON_NEW_ID != WEAPON_GLOCK
public CBasePlayer_RestrictItem_Pre(id, ItemID:item, ItemRestType:iRestType) {
	if(iRestType != ITEM_TYPE_BUYING) {
		return HC_CONTINUE
	}

	if(item == ITEM_TMP) { 
		SetHookChainReturn(ATYPE_BOOL, true)
		return HC_SUPERCEDE
	}

	return HC_CONTINUE
}
#endif

public CBasePlayer_OnSpawnEquip_Post(const id){
	if(!is_user_connected(id))
		return;
	
	BuyLimit[id] = g_eCvar[CVAR_BUY_LIMIT];
	new bitAccess = g_eCvar[CVAR_BUY_ACCESS];

	if(g_eCvar[CVAR_EQUIP_ACCESS] < 1)
		return;

	if (bitAccess && ~get_user_flags(id) & bitAccess)
		return;
	
	if(get_member_game(m_iTotalRoundsPlayed) + 1 < g_eCvar[CVAR_LIMIT_ROUND])
        return;
	

	giveNade(id);
}

public CBasePlayer_Killed_Post(victim, attacker, inflictor){
	if(!is_user_connected(victim)) return;
	
	new activeItem = get_member(victim, m_pActiveItem);
	if (!is_nullent(activeItem) && FClassnameIs(activeItem, ITEM_CLASSNAME) && get_entvar(victim, var_button) & IN_ATTACK && get_member(victim, m_rgAmmo, get_member(activeItem, m_Weapon_iPrimaryAmmoType)) > 0) {
		new Float:origin[3], Float:view_ofs[3], Float:vecSrc[3], Float:vecThrow[3];
		get_entvar(victim, var_origin, origin);
		get_entvar(victim, var_view_ofs, view_ofs);
		vecSrc[0] = origin[0] + view_ofs[0];
		vecSrc[1] = origin[1] + view_ofs[1];
		vecSrc[2] = origin[2] + view_ofs[2];
		get_entvar(victim, var_angles, vecThrow);

		throwNade(victim, activeItem, vecSrc, vecThrow, g_eCvar[CVAR_THROWTIME]);

		new ammoIndex = get_member(activeItem, m_Weapon_iPrimaryAmmoType);
		set_member(victim, m_rgAmmo, get_member(victim, m_rgAmmo, ammoIndex) - 1, ammoIndex);
		set_member(activeItem, m_flStartThrow, 0.0);
		
		Molotov_DeleteMuzzleFlash(activeItem);
	}
	
	#if !defined ALLOW_CUSTOMNADE
	if(!get_member(victim, m_rgAmmo, AMMO_ID)) return;
	
	switch(g_eCvar[CVAR_NADE_DROPS]){
		case 1:
		{
			if(rg_get_player_item(victim, "weapon_hegrenade", GRENADE_SLOT) | rg_get_player_item(victim, "weapon_flashbang", GRENADE_SLOT) | rg_get_player_item(victim, "weapon_smokegrenade", GRENADE_SLOT))
			return;
			
			dropNade(victim);
		}
		case 2: dropNade(victim);
	}
	#endif
}

#if !defined ALLOW_CUSTOMNADE
dropNade(const other){
	if(!is_user_connected(other)) return;

	new dropnade = rg_create_entity("info_target", true);

	if(is_nullent(dropnade))
		return;

	new Float: origin[3];
	new Float: velocity[3];

	ExecuteHam(Ham_Player_GetGunPosition, other, origin);

	//get_entvar(other, var_origin, origin);

	velocity[0] = random_float(-45.0, 45.0);
	velocity[1] = random_float(-45.0, 45.0);

	set_entvar(dropnade, var_classname, GRENADE_CLASSNAME);
	engfunc(EngFunc_SetModel, dropnade, WEAPON_MODEL_WORLD_MOLOTOV);
	set_entvar(dropnade, var_sequence, 0);
	set_entvar(dropnade, var_movetype, MOVETYPE_TOSS);
	set_entvar(dropnade, var_solid, SOLID_TRIGGER);
	set_entvar(dropnade, var_velocity, velocity);
	engfunc(EngFunc_SetOrigin, dropnade, origin);
	
	SetTouch(dropnade, "Drop_ItemMolotov_Touch");
}
#endif

public CSGameRules_DeathNotice_Pre(victim, attacker, inflictor)
{
	if(g_eCvar[CVAR_KILLFEED] == 0){
		return;
	}
	
	if (!is_user_connected(attacker)){
		return;
	}

	if(victim != attacker && inflictor != attacker && get_member(victim, m_bKilledByGrenade) && FClassnameIs(inflictor, MOLOTOV_FIRE_CLASSNAME)) {
	new nameattacker[32], name[32];
	get_entvar(attacker, var_netname, nameattacker, charsmax(nameattacker));

	if(strlen(nameattacker) > 16) {
	formatex(name, charsmax(name), "%.16s [ᴍᴏʟᴏᴛᴏᴠ]", nameattacker);
	}else{
	formatex(name, charsmax(name), "%s [ᴍᴏʟᴏᴛᴏᴠ]", nameattacker);}  
	message_begin(MSG_ALL, SVC_UPDATEUSERINFO);
	write_byte(attacker - 1);
	write_long(get_user_userid(attacker));
	write_char('\');
	write_char('n');
	write_char('a');
	write_char('m');
	write_char('e');
	write_char('\');
	write_string(name);
	for(new i = 0; i < 16; i++)
		write_byte(0);
	message_end();
		
	EnableHookChain(HookChain_deathNoticePostHook);
	}
}

public CSGameRules_DeathNotice_Post(victimEntIndex, killerEntIndex, inflictorEntIndex)
{
	rh_update_user_info(killerEntIndex);
	DisableHookChain(HookChain_deathNoticePostHook);
}



#if WEAPON_NEW_ID != WEAPON_GLOCK
public RegUserMsg_Post(const name[]) {
	if (strcmp(name, "WeaponList") == 0) {
		MsgIdWeaponList = get_orig_retval();
		MsgHookWeaponList = register_message(MsgIdWeaponList, "HookWeaponList");
	}
}

public HookWeaponList(const msg_id, const msg_dest, const msg_entity) {
	enum {
		arg_name = 1,
		arg_ammo1,
		arg_ammo1_max,
		arg_ammo2,
		arg_ammo2_max,
		arg_slot,
		arg_position,
		arg_id,
		arg_flags,
	};

	if (msg_dest != MSG_INIT || WeaponIdType:get_msg_arg_int(arg_id) != WEAPON_NEW_ID) {
		return PLUGIN_CONTINUE;
	}

	set_msg_arg_string(arg_name, WEAPON_NEW_NAME);
	set_msg_arg_int(arg_ammo1, ARG_BYTE, AMMO_ID);
	set_msg_arg_int(arg_ammo1_max, ARG_BYTE, 1);
	set_msg_arg_int(arg_ammo2, ARG_BYTE, -1);
	set_msg_arg_int(arg_ammo2_max, ARG_BYTE, -1);
	set_msg_arg_int(arg_slot, ARG_BYTE, _:GRENADE_SLOT - 1);
	set_msg_arg_int(arg_position, ARG_BYTE, NUM_SLOT);
	set_msg_arg_int(arg_flags, ARG_BYTE, ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
	
	return PLUGIN_CONTINUE;
}
#endif

public CmdSelect(const id) {
	if (!is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}
	
	new item = rg_get_player_item(id, ITEM_CLASSNAME, GRENADE_SLOT);
	if (item != 0 && get_member(id, m_pActiveItem) != item) {
		rg_switch_weapon(id, item);
	}
	return PLUGIN_HANDLED;
}

public CSGameRules_CleanUpMap_Post() {
	new ent = rg_find_ent_by_class(NULLENT, GRENADE_CLASSNAME, false);
	while (ent > 0) {
		destroyNade(ent);
		ent = rg_find_ent_by_class(ent, GRENADE_CLASSNAME, false);
	}

	new MolotovFire = rg_find_ent_by_class(NULLENT, MOLOTOV_FIRE_CLASSNAME, false);
	while (MolotovFire > 0) {
		rh_emit_sound2(MolotovFire, 0, CHAN_STATIC, MOLOTOV_SOUND_LOOP, 0.0, ATTN_NONE, SND_STOP);
		destroyNade(MolotovFire);
		MolotovFire = rg_find_ent_by_class(MolotovFire, MOLOTOV_FIRE_CLASSNAME, false);
	}
	
	new SmokeTouch = rg_find_ent_by_class(NULLENT, CLASSNAME_SMOKE_TOUCHER, false);
	while (SmokeTouch > 0) {
		SetTouch(SmokeTouch, "");
		SmokeTouch = rg_find_ent_by_class(SmokeTouch, CLASSNAME_SMOKE_TOUCHER, false);
	}
}

public CBasePlayer_GiveAmmo_Pre(const id, const amount, const name[]) {
	if (strcmp(name, AMMO_NAME) != 0) {
		return HC_CONTINUE;
	}

	giveAmmo(id, amount, AMMO_ID, 1);
	SetHookChainReturn(ATYPE_INTEGER, AMMO_ID);
	return HC_SUPERCEDE;
}


public CBasePlayerWeapon_DefaultDeploy_Pre(const item, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[], const skiplocal) 
{
	if (FClassnameIs(item, ITEM_CLASSNAME)) 
	{
		SetHookChainArg(2, ATYPE_STRING, WEAPON_MODEL_VIEW_MOLOTOV);
		SetHookChainArg(3, ATYPE_STRING, WEAPON_MODEL_PLAYER_MOLOTOV);
	}

	new WeaponIdType:wid = WeaponIdType:rg_get_iteminfo(item, ItemInfo_iId);
	if (wid != WEAPON_ID && wid != WEAPON_FAKE_ID) {
		return HC_CONTINUE;
	}

	new lastItem = get_member(get_member(item, m_pPlayer), m_pLastItem);
	if (is_nullent(lastItem) || item == lastItem) {
		return HC_CONTINUE;
	}

	if (WeaponIdType:rg_get_iteminfo(lastItem, ItemInfo_iId) == WEAPON_ID) {
		SetHookChainArg(6, ATYPE_INTEGER, 0);
	}

	return HC_CONTINUE;
}

public Item_Deploy_Post(const item) {
	if (WeaponIdType:rg_get_iteminfo(item, ItemInfo_iId) == WEAPON_FAKE_ID) {
		rg_set_iteminfo(item, ItemInfo_iId, WEAPON_ID);
	}

	new other = get_member(get_member(item, m_pPlayer), m_rgpPlayerItems, GRENADE_SLOT);
	while (!is_nullent(other)) {
		if (item != other && WeaponIdType:rg_get_iteminfo(other, ItemInfo_iId) == WEAPON_ID) {
			rg_set_iteminfo(other, ItemInfo_iId, WEAPON_FAKE_ID);
		}
		other = get_member(other, m_pNext);
	}
}

public Item_Holster_Pre(const item) {
	new other = get_member(item, m_pPlayer);
	
	rh_emit_sound2(other, 0, CHAN_WEAPON, MOLOTOV_SOUND_IDLE, 0.0, ATTN_NONE, SND_STOP);
}

public Item_Holster_Post(const item) {
	new other = get_member(get_member(item, m_pPlayer), m_rgpPlayerItems, GRENADE_SLOT);
	
	while(!is_nullent(other)) {
		Molotov_DeleteMuzzleFlash(item);
		
		if (item != other && WeaponIdType:rg_get_iteminfo(other, ItemInfo_iId) == WEAPON_FAKE_ID) {
			rg_set_iteminfo(other, ItemInfo_iId, WEAPON_ID);
		}
		other = get_member(other, m_pNext);
	}
}

public Item_PrimaryAttack_Pre(item) {
	if (is_nullent(item)) return;

	new other = get_member(item, m_pPlayer);

	if (FClassnameIs(item, ITEM_CLASSNAME) && Float: get_member(item, m_flStartThrow) + 0.5 < get_gametime() && get_member(item, m_flStartThrow)) {

		if (bCreate[other]) {
			return;
		}

		if (!bCreate[other]) {
			Molotov_CreateMuzzleFlash(item, other, MOLOTOV_SPRITE_FIRE_COLUMN, 200.0, 25.0, 0.028, 3);
			Molotov_CreateMuzzleFlash(item, other, MOLOTOV_SPRITE_FIRE_BALL, 180.0, 30.0, 0.035, 3);
			Molotov_CreateMuzzleFlash(item, other, MOLOTOV_SPRITE_FIRE_BALL, 250.0, 25.0, 0.026, 4);
			Molotov_CreateMuzzleFlash(item, other, MOLOTOV_SPRITE_XPARK1, 100.0, 1.0, 0.032, 4);
			
			rh_emit_sound2(other, 0, CHAN_WEAPON, MOLOTOV_SOUND_IDLE, 0.5, 4.0);
			
			bCreate[other] = true;
		}
	}

	if (FClassnameIs(item, ITEM_CLASSNAME) && !Float: get_member(item, m_flStartThrow)) {
		bCreate[other] = false;
	}

}

public CBasePlayer_ThrowGrenade_Pre(const id, const item, const Float:vecSrc[3], const Float:vecThrow[3], const Float:time, const const usEvent) {
	if (!FClassnameIs(item, ITEM_CLASSNAME)) {
		return HC_CONTINUE;
	}
	
	rh_emit_sound2(id, 0, CHAN_WEAPON, MOLOTOV_SOUND_IDLE, 0.0, ATTN_NONE, SND_STOP);

	new grenade = throwNade(id, item, vecSrc, vecThrow, g_eCvar[CVAR_THROWTIME]);
	SetHookChainReturn(ATYPE_INTEGER, grenade);

	Molotov_DeleteMuzzleFlash(item);

	return HC_SUPERCEDE;
}


public FireMolotov_Think_Post(iEntity)
{
	if (is_nullent(iEntity)) return;

	set_entvar(iEntity, var_nextthink, get_gametime() + 0.025);
}

giveNade(const id) {
	new item = rg_get_player_item(id, ITEM_CLASSNAME, GRENADE_SLOT);
	if (item != 0) {
		giveAmmo(id, 1, AMMO_ID, 1);
		return item;
	}

	item = rg_create_entity(WEAPON_NAME, false);
	if (is_nullent(item)) {
		return NULLENT;
	}

	new Float:origin[3];
	get_entvar(id, var_origin, origin);
	set_entvar(item, var_origin, origin);
	set_entvar(item, var_spawnflags, get_entvar(item, var_spawnflags) | SF_NORESPAWN);

	set_member(item, m_Weapon_iPrimaryAmmoType, AMMO_ID);
	set_member(item, m_Weapon_iSecondaryAmmoType, -1);

	set_entvar(item, var_classname, ITEM_CLASSNAME);

	dllfunc(DLLFunc_Spawn, item);

	set_member(item, m_iId, WEAPON_NEW_ID);

	rg_set_iteminfo(item, ItemInfo_pszName, WEAPON_NEW_NAME);
	rg_set_iteminfo(item, ItemInfo_pszAmmo1, AMMO_NAME);
	rg_set_iteminfo(item, ItemInfo_iMaxAmmo1, 1);
	rg_set_iteminfo(item, ItemInfo_iId, WEAPON_FAKE_ID);
	rg_set_iteminfo(item, ItemInfo_iPosition, NUM_SLOT);
	rg_set_iteminfo(item, ItemInfo_iWeight, 1);
	
	dllfunc(DLLFunc_Touch, item, id);

	if (get_entvar(item, var_owner) != id) {
		set_entvar(item, var_flags, FL_KILLME);
		return NULLENT;
	}

	return item;
}

giveAmmo(const id, const amount, const ammo, const max) {
	if (get_entvar(id, var_flags) & FL_SPECTATOR) {
		return;
	}

	new count = get_member(id, m_rgAmmo, ammo);
	new add = min(amount, max - count);
	if (add < 1) {
		return;
	}

	set_member(id, m_rgAmmo, count + add, ammo);

	emessage_begin(MSG_ONE, MsgIdAmmoPickup, .player = id);
	ewrite_byte(ammo);
	ewrite_byte(add);
	emessage_end();
}

throwNade(const id, const item, const Float:vecSrc[3], const Float:vecThrow[3], const Float:time) {
	new grenade = rg_create_entity("grenade");
	if (is_nullent(grenade) || is_nullent(item)) {
		return 0;
	}

	set_entvar(grenade, var_classname, GRENADE_CLASSNAME);

	set_entvar(grenade, var_movetype, MOVETYPE_BOUNCE);
	set_entvar(grenade, var_solid, SOLID_BBOX);

	engfunc(EngFunc_SetOrigin, grenade, vecSrc);

	new Float:angles[3];
	get_entvar(id, var_angles, angles);
	set_entvar(grenade, var_angles, angles);

	set_entvar(grenade, var_owner, id);

	if (time < 0.1) {
		set_entvar(grenade, var_nextthink, get_gametime());
		set_entvar(grenade, var_velocity, Float:{ 0.0, 0.0, 0.0 });
	} else {
		set_entvar(grenade, var_nextthink, get_gametime() + time);
		set_entvar(grenade, var_velocity, vecThrow);
	}

	set_entvar(grenade, var_animtime, get_gametime());
	set_entvar(grenade, var_sequence, random_num(2, 7));
	set_entvar(grenade, var_framerate, 1.0);
	set_entvar(grenade, var_gravity, 0.55);
	set_entvar(grenade, var_friction, 0.8);
	engfunc(EngFunc_SetModel, grenade, WEAPON_MODEL_WORLD_MOLOTOV);
	set_entvar(grenade, var_dmgtime, get_gametime() + time);
	set_entvar(grenade, var_nextthink, get_gametime() + 0.1);
	set_member(grenade, m_Grenade_bIsC4, false);

	Molotov_CreateWickFollow(grenade, MOLOTOV_SPRITE_WICK, 250.0, 25.0, 0.125);

	SetTouch(grenade, "GrenadeTouch");
	SetThink(grenade, "GrenadeThink");

	return grenade;
}


public GrenadeTouch(const grenade, const other) {

	if (is_nullent(grenade)) return;

	if (FClassnameIs(other, "func_breakable") && get_entvar(other, var_spawnflags) != SF_BREAK_TRIGGER_ONLY)
		dllfunc(DLLFunc_Use, other, grenade);

	new owner = get_entvar(grenade, var_owner);

	if (!is_nullent(other) && ExecuteHam(Ham_IsPlayer, other))
	{
		if (g_eCvar[CVAR_HIT_PLAYER]) {
			ExecuteHamB(Ham_TakeDamage, other, grenade, owner, g_eCvar[CVAR_HIT_PLAYER], DMG_GRENADE);
		}

		set_entvar(grenade, var_dmgtime, 0.0);
		set_entvar(grenade, var_nextthink, get_gametime() + 0.01);

		return;
	}

	new Float: flFraction;

	new Float: vecOffset[6][3] =
	{
		{ 0.0, 0.0, -1.0 }, { 0.0, 0.0, 1.0 }, { -1.0, 0.0, 0.0 },
		{ 1.0, 0.0, 0.0 }, { 0.0, -1.0, 0.0 }, { 0.0, 1.0, 0.0 }
	};

	new Float: vecEnd[3];
	new Float: origin[3];
	new Float: vecPlaneNormal[3];

	get_entvar(grenade, var_origin, origin);

	for (new i = 0; i < 6; i++)
	{
		vecEnd[0] = origin[0] + vecOffset[i][0];
		vecEnd[1] = origin[1] + vecOffset[i][1];
		vecEnd[2] = origin[2] + vecOffset[i][2];

		engfunc(EngFunc_TraceLine, origin, vecEnd, IGNORE_MONSTERS, grenade, 0);

		get_tr2(0, TR_flFraction, flFraction);

		if (flFraction >= 1.0)
			continue;

		get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);

		if (vecPlaneNormal[2] >= 0.5)
		{
			set_entvar(grenade, var_dmgtime, 0.0);
			set_entvar(grenade, var_nextthink, get_gametime() + 0.01);
		}
		else
			rh_emit_sound2(grenade, 0, CHAN_VOICE, MOLOTOV_SOUND_HIT);

		break;
	}
}

public GrenadeThink(const grenade) {
	if (is_nullent(grenade)) return;

	new Float: origin[3];
	get_entvar(grenade, var_origin, origin);

	if (engfunc(EngFunc_PointContents, origin) == CONTENTS_SKY)
	{
		set_entvar(grenade, var_flags, FL_KILLME);
		destroyWick(grenade);
		return;
	}

	set_entvar(grenade, var_nextthink, get_gametime() + 0.1);

	if (Float: get_entvar(grenade, var_dmgtime) > get_gametime())
		return;

	explodeNade(grenade);
}



explodeNade(const grenade) {
	if (is_nullent(grenade)) return;

	new Float: flFraction;

	new Float: vecEnd[3];
	new Float: origin[3];
	new Float: angles[3];

	get_entvar(grenade, var_origin, origin);
	get_entvar(grenade, var_angles, angles);

	vecEnd = origin;
	vecEnd[2] -= 64.0;

	engfunc(EngFunc_TraceLine, origin, vecEnd, IGNORE_MONSTERS, grenade, 0);
	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction >= 1.0)
	{
		UTIL_CreateExplosion(origin, Float: { 0.0, 0.0, 20.0 }, SpriteFireExplode, 16, 20, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
		rh_emit_sound2(grenade, 0, CHAN_STATIC, MOLOTOV_SOUND_EXPLODE);
		destroyNade(grenade);
		return;
	}

	if (engfunc(EngFunc_PointContents, origin) == CONTENTS_WATER)
	{
		new dropnade = rg_create_entity("info_target");

		if (is_nullent(dropnade)) return;
		
		set_entvar(dropnade, var_classname, GRENADE_CLASSNAME);
		engfunc(EngFunc_SetModel, dropnade, WEAPON_MODEL_WORLD_MOLOTOV);
		set_entvar(dropnade, var_sequence, 0);
		set_entvar(dropnade, var_movetype, MOVETYPE_TOSS);
		set_entvar(dropnade, var_solid, SOLID_TRIGGER);
		set_entvar(dropnade, var_velocity, Float:{ 0.0, 0.0, 0.0 });
		engfunc(EngFunc_SetOrigin, dropnade, origin);
		set_entvar(dropnade, var_angles, angles);

		SetTouch(dropnade, "Drop_ItemMolotov_Touch");

		destroyNade(grenade);

		return;
	}

	new owner = get_entvar(grenade, var_owner);

	new Float: vecEndPos[3];
	new Float: vecPlaneNormal[3];

	get_tr2(0, TR_vecEndPos, vecEndPos);
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);

	UTIL_CreateExplosion(origin, Float: { 0.0, 0.0, 0.0 }, SpriteFireExplode, 10, 20, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
	rh_emit_sound2(grenade, 0, CHAN_STATIC, MOLOTOV_SOUND_EXPLODE);
	
	engfunc(EngFunc_VecToAngles, vecPlaneNormal, angles);

	for (new i = 0; i < 3; i++)
		origin[i] = vecEndPos[i] + vecPlaneNormal[i];

	new EntMolotovRadius = rg_create_entity("info_target");

	if (is_nullent(EntMolotovRadius))
		return;

	set_entvar(EntMolotovRadius, var_origin, origin);
	set_entvar(EntMolotovRadius, var_angles, angles);
	set_entvar(EntMolotovRadius, var_classname, MOLOTOV_FIRE_CLASSNAME);
	set_entvar(EntMolotovRadius, var_solid, SOLID_TRIGGER);
	set_entvar(EntMolotovRadius, var_movetype, MOVETYPE_TOSS);
	set_entvar(EntMolotovRadius, var_iuser2, get_gametime() + g_eCvar[CVAR_DURATION]);
	set_entvar(EntMolotovRadius, var_fuser1, get_gametime() + 0.3);
	set_entvar(EntMolotovRadius, var_owner, owner);
	engfunc(EngFunc_SetOrigin, EntMolotovRadius, origin);
	engfunc(EngFunc_SetSize, EntMolotovRadius, Float:{-100.0, -100.0, -30.0}, Float:{100.0, 100.0, 30.0});

	set_entvar(EntMolotovRadius, var_nextthink, get_gametime() + MOLOTOV_PLAYTHINK_TIME);

	Molotov_CreateModelFloor(EntMolotovRadius, origin, angles, { 1, 15, 30 }, 1, g_eCvar[CVAR_DURATION]);
	
	rh_emit_sound2(EntMolotovRadius, 0, CHAN_STATIC, MOLOTOV_SOUND_LOOP, 0.5);

	SetThink(EntMolotovRadius, "ThinkFire");
	
	if(g_eCvar[CVAR_SMOKE_TOUCH]){
		SetTouch(EntMolotovRadius, "Molotov_TouchSmoke");
	}

	destroyNade(grenade);
}

public ThinkFire(EntMolotovRadius)
{
	if (is_nullent(EntMolotovRadius))
		return;

	new Float: flCurTime = get_gametime();

	static Float: origin[3];
	get_entvar(EntMolotovRadius, var_origin, origin);

	new owner = get_entvar(EntMolotovRadius, var_owner);

	new Float: vecEnd[3];
	vecEnd = origin;
	vecEnd[2] += 32.0;

	if (Float: get_entvar(EntMolotovRadius, var_dmgtime) <= flCurTime)
	{
		set_entvar(EntMolotovRadius, var_dmgtime, flCurTime + g_eCvar[CVAR_DEMAGE_TIME]);
		EnableHookChain(HookChain_CBasePlayer_TakeDamage);
		
		switch(g_eCvar[CVAR_DEMAGE_RADIUS_MODE]){
			case 1:{
				static iVictim = -1;
				while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, origin,  g_eCvar[CVAR_RADIUS])))
				{
					if(!is_user_alive(iVictim))continue;

					ExecuteHamB(Ham_TakeDamage, iVictim, EntMolotovRadius, owner, g_eCvar[CVAR_DEMAGE_VALUE], DMG_GRENADE);
				}
			}
			case 2: rg_dmg_radius(origin, EntMolotovRadius, owner, g_eCvar[CVAR_DEMAGE_VALUE], g_eCvar[CVAR_RADIUS], 0, DMG_GRENADE);
		}

		DisableHookChain(HookChain_CBasePlayer_TakeDamage);
	}

	if (get_entvar(EntMolotovRadius, var_fuser1) <= flCurTime)
	{
		UTIL_CreateExplosion(origin, Float: { 3.0, 3.0, 0.0 }, SpriteFireBall, 3, 20, TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
		UTIL_CreateExplosion(origin, Float: { 6.0, 6.0, 0.0 }, SpriteFireColumn, 3, 20, TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);
		UTIL_CreateExplosion(origin, Float: { 0.0, 0.0, 0.0 }, SpriteFireBall, 5, 23, TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES);

		set_entvar(EntMolotovRadius, var_fuser1, get_gametime() + random_float(0.35, 0.45));
	}

	new iFireNum = get_entvar(EntMolotovRadius, var_iuser3);

	if(iFireNum < g_eCvar[CVAR_EFFECT_NUM] / 10)
	{
		new Float: flFraction;

		new Float: vecStart[3];
		new Float: vecEnd[3];
		new Float: vecAngles[3];
		new Float: vecViewForward[3];
		new Float: vecPlaneNormal[3];

		get_entvar(EntMolotovRadius, var_vuser2, vecPlaneNormal);

		vecAngles[0] = random_float(-(g_eCvar[CVAR_RADIUS] / 4), -g_eCvar[CVAR_RADIUS]);
		vecAngles[1] = random_float(0.0, 360.0);
		engfunc(EngFunc_MakeVectors, vecAngles);
		global_get(glb_v_forward, vecViewForward);

		for (new i = 0; i < 3; i++)
		{
			vecStart[i] = origin[i] + vecPlaneNormal[i] * (g_eCvar[CVAR_RADIUS] / 4); 
			vecEnd[i] = vecStart[i] + vecViewForward[i] * g_eCvar[CVAR_RADIUS];
		}

		engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, EntMolotovRadius, 0);

		get_tr2(0, TR_flFraction, flFraction);
		get_tr2(0, TR_vecEndPos, vecEnd);
		get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);
		
	
		if (flFraction >= 1.0 || vecPlaneNormal[2] == -1.0)
		{
			Molotov_CreateModelFloor(EntMolotovRadius, vecEnd, vecAngles, { 15, 30, 45 }, random_num(1, 25), random_num(g_eCvar[CVAR_DURATION] / 3, g_eCvar[CVAR_DURATION] - (g_eCvar[CVAR_DURATION] / 4)))
			set_entvar(EntMolotovRadius, var_iuser3, iFireNum + 1);

			UTIL_WorldDecal(vecEnd);
		}
	}
	
	new iDebrisNum
	
	if (g_eCvar[CVAR_EFFECT_MODE] == 1)
		iDebrisNum = get_entvar(EntMolotovRadius, var_iuser4);

	if (iDebrisNum < g_eCvar[CVAR_EFFECT_NUM])
	{
		new Float: flFraction;

		new Float: vecStart[3];
		new Float: vecEnd[3];
		new Float: vecAngles[3];
		new Float: vecViewForward[3];
		new Float: vecPlaneNormal[3];

		get_entvar(EntMolotovRadius, var_vuser1, vecPlaneNormal);

		vecAngles[0] = random_float(-(g_eCvar[CVAR_RADIUS] / 4), -g_eCvar[CVAR_RADIUS]);
		vecAngles[1] = random_float(0.0, 360.0);

		engfunc(EngFunc_MakeVectors, vecAngles);
		global_get(glb_v_forward, vecViewForward);

		for (new i = 0; i < 3; i++)
		{
			vecStart[i] = origin[i] + vecPlaneNormal[i] * g_eCvar[CVAR_RADIUS] / 4;
			vecEnd[i] = vecStart[i] + vecViewForward[i] * g_eCvar[CVAR_RADIUS];
		}
		engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, EntMolotovRadius, 0);

		get_tr2(0, TR_flFraction, flFraction);
		get_tr2(0, TR_vecEndPos, vecEnd);
		get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);
		
		if (flFraction >= 1.0 || vecPlaneNormal[2] == -1.0)
		{
			switch(g_eCvar[CVAR_EFFECT_MODE]){
				case 1: set_entvar(EntMolotovRadius, var_iuser4, iDebrisNum + 1);
				case 2: iDebrisNum++;
			}

			Molotov_CreateDebris(EntMolotovRadius, vecEnd);
		}
	}
	else{ 
		if(g_eCvar[CVAR_EFFECT_MODE] == 2)	iDebrisNum = 0;
	}

	new MolotovFire = MaxClients + 1;

	new Float:flDuration = get_entvar(EntMolotovRadius, var_iuser2);

	if (flDuration <= get_gametime())
	{
		set_entvar(EntMolotovRadius, var_nextthink, get_gametime() + MOLOTOV_PLAYTHINK_TIME);
		SetThink(EntMolotovRadius, "FireRemove");
		
		rh_emit_sound2(EntMolotovRadius, 0, CHAN_STATIC, MOLOTOV_SOUND_LOOP, 0.0, ATTN_NONE, SND_STOP);
		rh_emit_sound2(EntMolotovRadius, 0, CHAN_STATIC, MOLOTOV_SOUND_FADEOUT, 0.5);

		return;
	}

	while ((MolotovFire = rg_find_ent_by_class(MolotovFire, MOLOTOV_FIRE_CLASSNAME)))
	{
		if (get_entvar(MolotovFire, var_owner) != EntMolotovRadius)
			continue;

		new Float:flDuration = get_entvar(get_entvar(MolotovFire, var_iuser1), var_iuser2);

		new parts[3]; get_entvar(MolotovFire, var_vuser1, parts);

		if (flDuration >= get_gametime())
		{
			for (new i = 0; i < count; i++)
			{
				parts[i]++;

				if (parts[i] > 50)
					parts[i] = 1;
			}
		}
		else
		{
			for (new i = 0; i < count; i++)
			{
				if (parts[i] > 0)
					parts[i]++;

				if (parts[i] > 50)
					parts[i] = 0;
			}
		}
		
		set_entvar(MolotovFire, var_vuser1, parts);
		set_entvar(MolotovFire, var_body, CalculateModelBodyArr(parts, sizes, count));
	}
	
	set_entvar(EntMolotovRadius, var_nextthink, get_gametime() +  MOLOTOV_PLAYTHINK_TIME);
}


public FireRemove(EntMolotovRadius)
{
	if (is_nullent(EntMolotovRadius))
		return;

	new MolotovFire = MaxClients + 1, bool:bRemove;

	while ((MolotovFire = rg_find_ent_by_class(MolotovFire, MOLOTOV_FIRE_CLASSNAME)))
	{
		if (get_entvar(MolotovFire, var_owner) != EntMolotovRadius)
			continue;

		new parts[3]; get_entvar(MolotovFire, var_vuser1, parts);

		for (new i = 0; i < count; i++)
		{
			if (parts[i] > 0)
				parts[i]++;

			if (parts[i] > 50)
				parts[i] = 0;
		}

		set_entvar(MolotovFire, var_vuser1, parts);
		set_entvar(MolotovFire, var_body, CalculateModelBodyArr(parts, sizes, count));
		
		new Float:render = get_entvar(MolotovFire, var_renderamt);
		
		if (render - 10.0 <= 0)
		{
			bRemove = true;
			SetTouch(EntMolotovRadius, "");
			set_entvar(MolotovFire, var_flags, FL_KILLME);
		}
		else
		{
			set_entvar(MolotovFire, var_renderamt, render - 10.0);
		}
		
		if (bRemove)
		{
			if((parts[0] | parts[1] | parts[2]) == 0)
			{
				set_entvar(MolotovFire, var_flags, FL_KILLME);
			}
		}
	}

	set_entvar(EntMolotovRadius, var_nextthink, get_gametime() + MOLOTOV_PLAYTHINK_TIME);
}

public CBasePlayer_TakeDamage_Pre(victim, inflictor, attacker, Float:flDamage, bitsDamageType)
{
	if (!is_user_connected(victim)) {
		return HC_SUPERCEDE;
	}

	if (FClassnameIs(inflictor, MOLOTOV_FIRE_CLASSNAME)) {
		switch (g_eCvar[CVAR_DEMAGE_MODE]){
			case 0: {
				if (attacker == victim || get_member(attacker, m_iTeam) == get_member(victim, m_iTeam)){
					SetHookChainReturn(ATYPE_INTEGER, true);
					return HC_SUPERCEDE;
				}
				else return HC_CONTINUE;
				
			}
			case 1: {
				if (attacker != victim && get_member(attacker, m_iTeam) == get_member(victim, m_iTeam)){
					SetHookChainReturn(ATYPE_INTEGER, true);
					return HC_SUPERCEDE;
				}
				else return HC_CONTINUE;
			}
			case 2: {
				return HC_CONTINUE;
			}
		}
	}
	
	return HC_CONTINUE;
}

public Molotov_TouchSmoke(item, other)
{
	if (is_nullent(item) || is_nullent(other)) return;
	
	new ModelSmoke[64], SmokeOwner[64];
	get_entvar(other, var_model, ModelSmoke, charsmax(ModelSmoke));
	get_pcvar_string(g_pCvarSmokeOwner, SmokeOwner, charsmax(SmokeOwner));

	if(equali(ModelSmoke, SmokeOwner))
	{
		set_entvar(other, var_flags, get_entvar(other, var_flags) | FL_ONGROUND);
		set_entvar(other, var_dmgtime,0.0);
		dllfunc(DLLFunc_Think,other);
		
		new Float:origin[3];
		get_entvar(other, var_origin, origin);		

		new MolotovFire = MaxClients + 1;
		
		while((MolotovFire = engfunc(EngFunc_FindEntityInSphere, MolotovFire, origin, g_eCvar[CVAR_RADIUS])))
		{
			if(!FClassnameIs(MolotovFire, MOLOTOV_FIRE_CLASSNAME))
				continue;

			destroyEffect(MolotovFire)
			set_entvar(MolotovFire, var_flags, FL_KILLME);
		}
		
		rh_emit_sound2(item, 0, CHAN_STATIC, MOLOTOV_SOUND_EXT);
		
		destroyNade(item);

		new SmokeRadius = rg_create_entity("info_target");

		if (is_nullent(SmokeRadius))
			return;

		set_entvar(SmokeRadius, var_origin, origin);
		set_entvar(SmokeRadius, var_classname, CLASSNAME_SMOKE_TOUCHER);
		set_entvar(SmokeRadius, var_solid, SOLID_TRIGGER);
		set_entvar(SmokeRadius, var_movetype, MOVETYPE_TOSS);
		set_entvar(SmokeRadius, var_iuser2, get_gametime() + 20.0);
		engfunc(EngFunc_SetOrigin, SmokeRadius, origin);
		engfunc(EngFunc_SetSize, SmokeRadius, Float:{-100.0, -100.0, -30.0}, Float:{100.0, 100.0, 30.0});

		SetTouch(SmokeRadius, "Molotov_TouchSmokeFire");
	}
}

public Molotov_TouchSmokeFire(item, other)
{
	if(is_nullent(item) || is_nullent(other)) return;

	if(FClassnameIs(other, GRENADE_CLASSNAME))
	{
		set_entvar(other, var_flags, FL_KILLME);
			
		rh_emit_sound2(other, 0, CHAN_STATIC, MOLOTOV_SOUND_EXT);
		rh_emit_sound2(other, 0, CHAN_STATIC, MOLOTOV_SOUND_LOOP, 0.0, ATTN_NONE, SND_STOP);
		
		destroyWick(other);
	}
	
	new Float:flDuration = get_entvar(item, var_iuser2);

	if (flDuration <= get_gametime())
	{
		SetTouch(item, "");
		return;
	}
}

public CSGrenade_ExplodeSmokeGrenade_Pre(const this)
{
	if (is_nullent(this)) return;
	
	if(g_eCvar[CVAR_SMOKE_TOUCH]){
	
		new SmokeRadius = rg_create_entity("info_target");

		if (is_nullent(SmokeRadius))
			return;
		
		new Float:origin[3];
		get_entvar(this, var_origin, origin);
		
		set_entvar(SmokeRadius, var_origin, origin);
		set_entvar(SmokeRadius, var_classname, CLASSNAME_SMOKE_TOUCHER);
		set_entvar(SmokeRadius, var_solid, SOLID_TRIGGER);
		set_entvar(SmokeRadius, var_movetype, MOVETYPE_TOSS);
		set_entvar(SmokeRadius, var_iuser2, get_gametime() + 20.0);
		engfunc(EngFunc_SetOrigin, SmokeRadius, origin);
		engfunc(EngFunc_SetSize, SmokeRadius, Float:{-100.0, -100.0, -30.0}, Float:{100.0, 100.0, 30.0});
		
		SetTouch(SmokeRadius, "Molotov_TouchSmokeFire");
	}
}

public Drop_ItemMolotov_Touch(item, other)
{
	if (is_nullent(item) || is_nullent(other)) return;

	if (!ExecuteHam(Ham_IsPlayer, other)) return;
	
	new bitAccess = g_eCvar[CVAR_BUY_ACCESS];
	
	if (bitAccess && ~get_user_flags(other) & bitAccess)
		return;

	new ammo = rg_get_player_item(other, ITEM_CLASSNAME, GRENADE_SLOT);
	if (ammo != 0) return;

	giveNade(other);
	rh_emit_sound2(other, 0, CHAN_ITEM, GUNPICKUP_SOUND);

	set_entvar(item, var_flags, FL_KILLME);
}

destroyNade(const grenade) {
	SetTouch(grenade, "");
	SetThink(grenade, "");
	
	set_entvar(grenade, var_flags, FL_KILLME);

	destroyWick(grenade);
}

destroyWick(const grenade){
	new item =  MaxClients + 1;

	while ((item = rg_find_ent_by_class(item, EFFECT_CLASSNAME_WICK)))
	{
		if (get_entvar(item, var_owner) != grenade)
			continue;
			
		if (!is_nullent(item))
			set_entvar(item, var_flags, FL_KILLME);
	}
}

destroyEffect(const grenade) {
	new item =  MaxClients + 1;

	while ((item = rg_find_ent_by_class(item, MOLOTOV_FIRE_CLASSNAME)))
	{
		if (get_entvar(item, var_owner) != grenade)
			continue;

		if (!is_nullent(item))
			set_entvar(item, var_flags, FL_KILLME);
	}
	
	rh_emit_sound2(grenade, 0, CHAN_STATIC, MOLOTOV_SOUND_LOOP, 0.0, ATTN_NONE, SND_STOP);
}


stock rg_get_player_item(const id, const classname[], const InventorySlotType:slot = NONE_SLOT) {
	new item = get_member(id, m_rgpPlayerItems, slot);
	while (!is_nullent(item)) {
		if (FClassnameIs(item, classname)) {
			return item;
		}
		item = get_member(item, m_pNext);
	}

	return 0;
}

stock UTIL_WeapoList(
	const type,
	const player,
	const name[],
	const ammo1,
	const maxAmmo1,
	const ammo2,
	const maxammo2,
	const InventorySlotType:slot,
	const position,
	const WeaponIdType:id,
	const flags
	) {
	message_begin(type, MsgIdWeaponList, .player = player);
	write_string(name);
	write_byte(ammo1);
	write_byte(maxAmmo1);
	write_byte(ammo2);
	write_byte(maxammo2);
	write_byte(_:slot - 1);
	write_byte(position);
	write_byte(_:id);
	write_byte(flags);
	message_end();
}

stock UTIL_CreateExplosion(const Float: origin[3], const Float: vecOriginOffset[3] = { 0.0, 0.0, 0.0 }, const isModelIndex, const iScale, const iFrameRate, const iFlags)
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_EXPLOSION);
	write_coord_f(origin[0] + vecOriginOffset[0]);
	write_coord_f(origin[1] + vecOriginOffset[1]);
	write_coord_f(origin[2] + vecOriginOffset[2]);
	write_short(isModelIndex);
	write_byte(iScale);
	write_byte(iFrameRate);
	write_byte(iFlags);
	message_end();
}

stock UTIL_CreateSprite(const Float: origin[3], const isModelIndex, const iScale, const iAlpha)
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_SPRITE);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_short(isModelIndex);
	write_byte(iScale);
	write_byte(iAlpha);
	message_end();
}

stock Molotov_CreateModelFloor(owner, Float: origin[3], Float: angles[3], parts[3], sequence, time)
{
	if (is_nullent(owner)) return;

	new Float: flFraction;

	new Float: vecEndPos[3];
	new Float: vecPlaneNormal[3];
	new Float: vecAngles[3];

	vecEndPos = origin;
	vecEndPos[2] -= 256.0;

	engfunc(EngFunc_TraceLine, origin, vecEndPos, IGNORE_MONSTERS, owner, 0);
	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction >= 1.0)
		return;

	get_tr2(0, TR_vecEndPos, vecEndPos);
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);
	engfunc(EngFunc_VecToAngles, vecPlaneNormal, vecAngles);

	for (new i = 0; i < 3; i++)
		origin[i] = vecEndPos[i] + vecPlaneNormal[i];

	FloorOriginAngles(origin, angles);

	new MolotovFire = rg_create_entity("info_target", false);

	if (is_nullent(MolotovFire)) return;

	set_entvar(MolotovFire, var_classname, MOLOTOV_FIRE_CLASSNAME);
	set_entvar(MolotovFire, var_owner, owner);
	engfunc(EngFunc_SetOrigin, MolotovFire, origin);
	engfunc(EngFunc_SetModel, MolotovFire, MOLOTOV_MODEL_FLOOR);
	set_entvar(MolotovFire, var_angles, angles);
	set_entvar(MolotovFire, var_sequence, sequence);
	set_entvar(MolotovFire, var_rendermode, kRenderTransAdd);
	set_entvar(MolotovFire, var_renderamt, 255.0);
	set_entvar(MolotovFire, var_vuser1, parts);
	set_entvar(MolotovFire, var_iuser1, MolotovFire);
	set_entvar(MolotovFire, var_iuser2, get_gametime() + time);

	dllfunc(DLLFunc_Spawn, MolotovFire);
}

stock Molotov_CreateDebris(owner, Float: origin[3])
{
	if (is_nullent(owner)) return;
	
	new Float: flFraction;

	new Float: vecEndPos[3];
	new Float: vecPlaneNormal[3];
	new Float: vecAngles[3];

	vecEndPos = origin;
	vecEndPos[2] -= 256.0;

	engfunc(EngFunc_TraceLine, origin, vecEndPos, IGNORE_MONSTERS, owner, 0);
	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction >= 1.0)
		return;

	get_tr2(0, TR_vecEndPos, vecEndPos);
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);
	engfunc(EngFunc_VecToAngles, vecPlaneNormal, vecAngles);

	for (new i = 0; i < 3; i++)
		origin[i] = vecEndPos[i] + vecPlaneNormal[i];

	vecAngles[0] = -vecAngles[0] + 180.0;
	vecAngles[2] = -vecAngles[2] + 180.0;
	
	switch(g_eCvar[CVAR_EFFECT_MODE]){
		case 1:
		{
			new iFire = rg_create_entity("env_sprite", true);

			if (is_nullent(iFire))
				return;

			set_entvar(iFire, var_classname, MOLOTOV_FIRE_CLASSNAME);
			set_entvar(iFire, var_origin, origin);
			set_entvar(iFire, var_angles, vecAngles);
			set_entvar(iFire, var_model, MOLOTOV_SPRITE_FIRE_GROUND);
			set_entvar(iFire, var_spawnflags, SF_SPRITE_STARTON);
			set_entvar(iFire, var_owner, owner);
			set_entvar(iFire, var_rendermode, kRenderTransAdd);
			set_entvar(iFire, var_renderamt, 255.0);
			set_entvar(iFire, var_framerate, 12.0);
			set_entvar(iFire, var_scale, 0.5);
			dllfunc(DLLFunc_Spawn, iFire);
		}
		case 2: UTIL_CreateSprite(origin, SpriteFireGround, random_num(5,7), 255);
	}
}

stock Molotov_CreateMuzzleFlash(item, other, const models[], Float:renderamt, Float:frame, Float:scale, body)
{
	if (is_nullent(item)) return;

	new iMuzzleFlash = rg_create_entity("env_sprite", true);

	if (is_nullent(iMuzzleFlash)) return;

	set_entvar(iMuzzleFlash, var_model, models);
	set_entvar(iMuzzleFlash, var_classname, EFFECT_CLASSNAME_MUZZLEFLASH);
	set_entvar(iMuzzleFlash, var_spawnflags, SF_SPRITE_STARTON);
	set_entvar(iMuzzleFlash, var_rendermode, kRenderTransAdd);
	set_entvar(iMuzzleFlash, var_renderamt, renderamt);
	set_entvar(iMuzzleFlash, var_framerate, frame);
	set_entvar(iMuzzleFlash, var_scale, scale);
	set_entvar(iMuzzleFlash, var_owner, other);
	set_entvar(iMuzzleFlash, var_aiment, other);
	set_entvar(iMuzzleFlash, var_body, body);
	dllfunc(DLLFunc_Spawn, iMuzzleFlash);
}

stock Molotov_CreateWickFollow(other, const models[], Float:renderamt, Float:frame, Float:scale)
{
	new iWickFollow = rg_create_entity("env_sprite", true);

	if (is_nullent(iWickFollow)) return;

	set_entvar(iWickFollow, var_model, models);
	set_entvar(iWickFollow, var_classname, EFFECT_CLASSNAME_WICK);
	set_entvar(iWickFollow, var_spawnflags, SF_SPRITE_STARTON);
	set_entvar(iWickFollow, var_rendermode, kRenderTransAdd);
	set_entvar(iWickFollow, var_renderamt, renderamt);
	set_entvar(iWickFollow, var_framerate, frame);
	set_entvar(iWickFollow, var_scale, scale);
	set_entvar(iWickFollow, var_owner, other);
	set_entvar(iWickFollow, var_aiment, other);
	dllfunc(DLLFunc_Spawn, iWickFollow);
}

stock Molotov_DeleteMuzzleFlash(other)
{
	new item =  MaxClients + 1;

	while ((item = rg_find_ent_by_class(item, EFFECT_CLASSNAME_MUZZLEFLASH)))
	{
		if (get_entvar(item, var_owner) != get_entvar(other, var_owner))
			continue;

		if (!is_nullent(item))
			set_entvar(item, var_flags, FL_KILLME);
	}
}

stock UTIL_WorldDecal(Float:origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_byte(engfunc(EngFunc_DecalIndex, "{ding10"));
	message_end();
}

stock bool:rg_get_user_buyzone(const other) {
	new bitSignals[UnifiedSignals];
	get_member(other, m_signals, bitSignals);

	return bool:(SignalState:bitSignals[US_State] & SIGNAL_BUY);
}

public CalculateModelBodyArr(const parts[], const sizes[], const count) {
	static bodyInt32 = 0, temp = 0, it = 0, tempCount; bodyInt32 = 0; tempCount = count;
	while (tempCount--) {
		if (sizes[tempCount] == 1) continue;
		temp = parts[tempCount]; for (it = 0; it < tempCount; it++) temp *= sizes[it];
		bodyInt32 += temp;
	}
	return bodyInt32;
}

new const Float:SubFloat[3] = { 0.0, 0.0, 9999.0 };
stock FloorOriginAngles(Float:flOrigin[3], Float:fAngles[3]) {
	static Float:traceto[3], Float:fraction, Float:original_forward[3], Float:angles2[3], Float:right[3], Float:up[3], Float:fwd[3];
	new iTrace = create_tr2(); if (!iTrace) return;
	xs_vec_sub(flOrigin, SubFloat, traceto);
	engfunc(EngFunc_TraceLine, flOrigin, traceto, IGNORE_MONSTERS | IGNORE_MISSILE, 0, iTrace);
	get_tr2(iTrace, TR_flFraction, fraction);
	if (fraction == 1.0) { free_tr2(iTrace); return; }
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, original_forward);
	get_tr2(iTrace, TR_vecPlaneNormal, up); free_tr2(iTrace);
	xs_vec_cross(original_forward, up, right);
	xs_vec_cross(up, right, fwd);
	vector_to_angle(fwd, fAngles);
	vector_to_angle(right, angles2);
	fAngles[2] = -1.0 * angles2[0];
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;

	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];

		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;

		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);

		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);

				if (iEvent != 5004)
					continue;

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);

				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}

	fclose(iFile);
}

stock UTIL_PrecacheSpritesFromTxt(const szWeaponList[])
{
	new szTxtDir[64], szSprDir[64];
	new szFileData[128], szSprName[48], temp[1];

	format(szTxtDir, charsmax(szTxtDir), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szTxtDir);

	new iFile = fopen(szTxtDir, "rb");
	while (iFile && !feof(iFile))
	{
		fgets(iFile, szFileData, charsmax(szFileData));
		trim(szFileData);

		if (!strlen(szFileData))
			continue;

		new pos = containi(szFileData, "640");

		if (pos == -1)
			continue;

		format(szFileData, charsmax(szFileData), "%s", szFileData[pos + 3]);
		trim(szFileData);

		strtok(szFileData, szSprName, charsmax(szSprName), temp, charsmax(temp), ' ', 1);
		trim(szSprName);

		format(szSprDir, charsmax(szSprDir), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szSprDir);
	}

	if (iFile) fclose(iFile);
}