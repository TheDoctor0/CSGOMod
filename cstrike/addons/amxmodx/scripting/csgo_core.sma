#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <engine>
#include <sqlx>
#include <xs>
#include <csgomod>

#define PLUGIN	"CS:GO Mod Core"
#define AUTHOR	"O'Zone"

#pragma dynamic 65536
#pragma semicolon 1

#define ADMIN_FLAG	ADMIN_ADMIN

#define TASK_SKINS	1045
#define TASK_DATA	2592
#define TASK_AIM	3309
#define TASK_AD		4234
#define TASK_SHELL	5892
#define TASK_SPEC   6012
#define TASK_DEPLOY 7321
#define TASK_FORCE  8568

// Uncomment to disable support for skins based on submodels
//#define DISABLE_SUBMODELS

#if !defined DISABLE_SUBMODELS
#define WPNSTATE_USP_SILENCED		(1<<0)
#define WPNSTATE_GLOCK18_BURST_MODE	(1<<1)
#define WPNSTATE_M4A1_SILENCED		(1<<2)
#define WPNSTATE_ELITE_LEFT			(1<<3)
#define WPNSTATE_FAMAS_BURST_MODE	(1<<4)

#define WEAPONTYPE_ELITE	1
#define WEAPONTYPE_GLOCK18	2
#define WEAPONTYPE_FAMAS	3
#define WEAPONTYPE_OTHER	4
#define WEAPONTYPE_M4A1		5
#define WEAPONTYPE_USP		6

#define OBSERVER	4
#endif

#define WEAPON_ALL	31

#define UNSILENCED 	0
#define SILENCED 	1

#define CHANCE      1
#define NONE		-1

#define M4A1		"M4A1"
#define M4A4		"M4A4"
#define KNIFE		"KNIFE"

new const commandSkins[][] = { "skiny", "say /skins", "say_team /skins", "say /skin", "say_team /skin", "say /skiny",
	"say_team /skiny", "say /modele", "say_team /modele", "say /model", "say_team /model", "say /jackpot", "say_team /jackpot" };
new const commandHelp[][] = { "pomoc", "say /pomoc", "say_team /pomoc", "say /help", "say_team /help" };
new const commandSet[][] = { "ustaw", "say /ustaw", "say_team /ustaw", "say /set", "say_team /set" };
new const commandBuy[][] = { "kup", "say /kup", "say_team /kup", "say /buy", "say_team /buy", "say /sklep", "say_team /sklep", "say /shop", "say_team /shop" };
new const commandRandom[][] = { "losuj", "say /los", "say_team /los", "say /losuj", "say_team /losuj", "say /draw", "say_team /draw", "say /drawing", "say_team /drawing" };
new const commandExchange[][] = { "wymien", "say /exchange", "say_team /exchange", "say /zamien", "say_team /zamien", "say /wymien", "say_team /wymien", "say /wymiana", "say_team /wymiana" };
new const commandGive[][] = { "daj", "say /give", "say_team /give", "say /oddaj", "say_team /oddaj", "say /daj", "say_team /daj" };
new const commandMarket[][] = { "rynek", "say /market", "say_team /market", "say /rynek", "say_team /rynek" };
new const commandSell[][] = { "wystaw", "say /wystaw", "say_team /wystaw", "say /sprzedaj", "say_team /sprzedaj", "say /sell", "say_team /sell" };
new const commandPurchase[][] = { "wykup", "say /wykup", "say_team /wykup", "say /purchase", "say_team /purchase" };
new const commandWithdraw[][] = { "wycofaj", "say /wycofaj", "say_team /wycofaj", "say /withdraw", "say_team /withdraw" };

new const ammoType[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp", "556nato", "556nato", "556nato",
						"45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot", "556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" };

new const weaponSlots[] = { -1, 2, -1, 1, 4, 1, 5, 1, 1, 4, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 4, 2, 1, 1, 3, 1 };
new const maxBPAmmo[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 };

#if !defined DISABLE_SUBMODELS
new const defaultShell[] = "models/pshell.mdl",
		  shotgunShell[] = "models/shotgunshell.mdl";
#endif

new const availableWeapons[][] = { "weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
		"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
		"weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
		"weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" };

enum _:tempInfo { WEAPON, WEAPONS, WEAPON_ENT, EXCHANGE_PLAYER, EXCHANGE, EXCHANGE_FOR_SKIN, GIVE_PLAYER, SALE_SKIN, BUY_SKIN,
	BUY_WEAPON, BUY_SUBMODEL, ADD_SKIN, Float:COUNTDOWN };
enum _:playerInfo { ACTIVE[CSW_P90 + 1], Float:MONEY, SKIN, SUBMODEL, bool:SKINS_LOADED, bool:DATA_LOADED, bool:EXCHANGE_BLOCKED,
	bool:MENU_BLOCKED, bool:SKINS_BLOCKED, bool:HUD_BLOCKED, TEMP[tempInfo], NAME[32], SAFE_NAME[64], STEAM_ID[35] };
enum _:playerSkinsInfo { SKIN_ID, SKIN_COUNT };
enum _:skinsInfo { SKIN_NAME[64], SKIN_WEAPON[32], SKIN_WEAPON_SHORT[32], SKIN_MODEL[128], SKIN_SUBMODEL, SKIN_PRICE, SKIN_RARITY };
enum _:marketInfo { MARKET_ID, MARKET_SKIN, MARKET_OWNER, Float:MARKET_PRICE };
enum _:typeInfo { TYPE_NAME, TYPE_STEAM_ID };
enum _:skinRarity { RARITY_COMMON = 1, RARITY_UNCOMMON, RARITY_RATE, RARITY_MYTHICAL, RARIRTY_LEGENDARY, RARITY_ANCIENT, RARITY_EXCEEDINGLY_RARE, RARITY_IMMORTAL };
enum _:menuTypes { MENU_SET, MENU_BUY, MENU_RANDOM, MENU_ADD };

new playerData[MAX_PLAYERS + 1][playerInfo], Array:playerSkins[MAX_PLAYERS + 1], Float:randomSkinPrice[WEAPON_ALL + 1], overallSkinChance[WEAPON_ALL + 1],
	bool:canPickup[MAX_PLAYERS + 1], Array:skins, Array:weapons, Array:market, Handle:sql, Handle:connection, saveType, marketSkins, multipleSkins, defaultSkins,
	skinChance, skinChanceSVIP, silencerAttached, Float:skinChancePerMember, maxMarketSkins, Float:marketCommision, Float:killReward, Float:killHSReward,
	Float:bombReward, Float:defuseReward, Float:hostageReward, Float:winReward, Float:botMultiplier, Float:vipMultiplier, Float:svipMultiplier, minPlayers,
	minPlayerFilter, bool:end, bool:sqlConnected, sqlHost[64], sqlUser[64], sqlPassword[64], sqlDatabase[64], skinsPath[64], force, resetHandle, weaponHud;

native csgo_get_zeus(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("csgo_version", VERSION, FCVAR_SERVER);

	register_dictionary("csgomod.txt");

	bind_pcvar_string(create_cvar("csgo_sql_host", "localhost", FCVAR_SPONLY | FCVAR_PROTECTED), sqlHost, charsmax(sqlHost));
	bind_pcvar_string(create_cvar("csgo_sql_user", "user", FCVAR_SPONLY | FCVAR_PROTECTED), sqlUser, charsmax(sqlUser));
	bind_pcvar_string(create_cvar("csgo_sql_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED), sqlPassword, charsmax(sqlPassword));
	bind_pcvar_string(create_cvar("csgo_sql_db", "database", FCVAR_SPONLY | FCVAR_PROTECTED), sqlDatabase, charsmax(sqlDatabase));

	bind_pcvar_num(create_cvar("csgo_save_type", "0"), saveType);
	bind_pcvar_num(create_cvar("csgo_multiple_skins", "1"), multipleSkins);
	bind_pcvar_num(create_cvar("csgo_default_skins", "1"), defaultSkins);
	bind_pcvar_num(create_cvar("csgo_min_players", "4"), minPlayers);
	bind_pcvar_num(create_cvar("csgo_min_player_filter", "0"), minPlayerFilter);
	bind_pcvar_num(create_cvar("csgo_max_market_skins", "5"), maxMarketSkins);
	bind_pcvar_num(create_cvar("csgo_skin_chance", "20"), skinChance);
	bind_pcvar_num(create_cvar("csgo_svip_skin_chance", "25"), skinChanceSVIP);
	bind_pcvar_num(create_cvar("csgo_silencer_attached", "1"), silencerAttached);
	bind_pcvar_float(create_cvar("csgo_market_commision", "5"), marketCommision);
	bind_pcvar_float(create_cvar("csgo_clan_skin_chance_per_member", "1"), skinChancePerMember);
	bind_pcvar_float(create_cvar("csgo_kill_reward", "0.35"), killReward);
	bind_pcvar_float(create_cvar("csgo_kill_hs_reward", "0.15"), killHSReward);
	bind_pcvar_float(create_cvar("csgo_bomb_reward", "2.0"), bombReward);
	bind_pcvar_float(create_cvar("csgo_defuse_reward", "2.0"), defuseReward);
	bind_pcvar_float(create_cvar("csgo_hostages_reward", "2.0"), hostageReward);
	bind_pcvar_float(create_cvar("csgo_round_reward", "0.5"), winReward);
	bind_pcvar_float(create_cvar("csgo_multiplier_vip", "1.25"), vipMultiplier);
	bind_pcvar_float(create_cvar("csgo_multiplier_svip", "1.5"), svipMultiplier);
	bind_pcvar_float(create_cvar("csgo_multiplier_bot", "0.5"), botMultiplier);

	for (new i; i < sizeof commandSkins; i++) register_clcmd(commandSkins[i], "skins_menu");
	for (new i; i < sizeof commandHelp; i++) register_clcmd(commandHelp[i], "skins_help");
	for (new i; i < sizeof commandSet; i++) register_clcmd(commandSet[i], "set_skin_menu");
	for (new i; i < sizeof commandBuy; i++) register_clcmd(commandBuy[i], "buy_skin_menu");
	for (new i; i < sizeof commandRandom; i++) register_clcmd(commandRandom[i], "random_skin_menu");
	for (new i; i < sizeof commandExchange; i++) register_clcmd(commandExchange[i], "exchange_skin_menu");
	for (new i; i < sizeof commandGive; i++) register_clcmd(commandGive[i], "give_skin_menu");
	for (new i; i < sizeof commandMarket; i++) register_clcmd(commandMarket[i], "market_menu");
	for (new i; i < sizeof commandSell; i++) register_clcmd(commandSell[i], "market_sell_skin");
	for (new i; i < sizeof commandPurchase; i++) register_clcmd(commandPurchase[i], "market_buy_skin");
	for (new i; i < sizeof commandWithdraw; i++) register_clcmd(commandWithdraw[i], "market_withdraw_skin");

	register_menucmd(register_menuid("Exchange"), (MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0), "exchange_question_handle");

	register_clcmd("SKIN_PRICE", "set_skin_price");

	register_concmd("csgo_add_skin", "add_skin_menu");
	register_concmd("csgo_reset_data", "cmd_reset_data", ADMIN_FLAG);
	register_concmd("csgo_add_money", "cmd_add_money", ADMIN_FLAG, "<player> <money>");

	register_logevent("log_event_operation", 3, "1=triggered");

	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("SendAudio", "t_win_round" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "ct_win_round", "a", "2=%!MRAD_ctwin");
	register_event("SetFOV", "set_fov" , "be");
	register_event("Money", "event_money", "be");

	register_message(SVC_INTERMISSION, "message_intermission");

	register_forward(FM_SetModel, "set_model", 0);

	#if !defined DISABLE_SUBMODELS
	register_forward(FM_UpdateClientData, "update_client_data_post", 1);
	register_forward(FM_PlaybackEvent, "client_playback_event");
	register_forward(FM_ClientUserInfoChanged, "client_user_info_changed");
	#endif

	RegisterHam(Ham_AddPlayerItem, "player", "add_player_item", 1);
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);

	for (new i = 0; i < sizeof availableWeapons; i++) {
		RegisterHam(Ham_Item_Deploy, availableWeapons[i], "weapon_deploy_post", 1);

		#if !defined DISABLE_SUBMODELS
		RegisterHam(Ham_CS_Weapon_SendWeaponAnim, availableWeapons[i], "weapon_send_weapon_anim_post", 1);
		RegisterHam(Ham_Weapon_PrimaryAttack, availableWeapons[i], "weapon_primary_attack");
		#endif
	}

	#if !defined DISABLE_SUBMODELS
	new const traceBullets[][] = { "func_breakable", "func_wall", "func_door", "func_plat", "func_rotating", "worldspawn", "func_door_rotating" };

	for (new i = 0; i < sizeof traceBullets; i++) {
		RegisterHam(Ham_TraceAttack, traceBullets[i], "trace_attack_post", 1);
	}
	#endif

	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "m4a1_secondary_attack", 0);

	resetHandle = CreateMultiForward("csgo_reset_data", ET_IGNORE);

	weaponHud = CreateHudSyncObj();
}

public plugin_precache()
{
	skins = ArrayCreate(skinsInfo);
	market = ArrayCreate(marketInfo);
	weapons = ArrayCreate(32, 32);

	#if !defined DISABLE_SUBMODELS
	precache_model(defaultShell);
	precache_model(shotgunShell);
	#endif

	new file[128];

	get_localinfo("amxx_configsdir", file, charsmax(file));
	format(file, charsmax(file), "%s/csgo_skins.ini", file);

	if (!file_exists(file)) set_fail_state("[CS:GO] No skins configuration file csgo_skins.ini!");

	new skin[skinsInfo], lineData[256], tempValue[5][128], bool:error, skinsCount = 0, fileCount = 0, fileOpen = fopen(file, "r"), Array:files = ArrayCreate(64, 128);

	while (!feof(fileOpen)) {
		fgets(fileOpen, lineData, charsmax(lineData)); trim(lineData);

		if (lineData[0] == ';' || lineData[0] == '^0' || lineData[0] == '/') continue;

		if (contain(lineData, "SKINS_PATH") != -1) {
			strtok2(lineData, tempValue[0], charsmax(tempValue[]), skinsPath, charsmax(skinsPath), '=', 1);

			continue;
		}

		if (lineData[0] == '[') {
			replace_all(lineData, charsmax(lineData), "[", "");
			replace_all(lineData, charsmax(lineData), "]", "");

			split(lineData, skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), tempValue[0], charsmax(tempValue[]), " - ");

			replace_all(skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), "_", " ");

			ArrayPushString(weapons, skin[SKIN_WEAPON]);

			if (is_skin_knife(skin[SKIN_WEAPON])) {
				formatex(skin[SKIN_WEAPON_SHORT], charsmax(skin[SKIN_WEAPON_SHORT]), KNIFE);
			} else if (is_skin_m4a4(skin[SKIN_WEAPON])) {
				copy(skin[SKIN_WEAPON_SHORT], charsmax(skin[SKIN_WEAPON_SHORT]), M4A1);
			} else {
				copy(skin[SKIN_WEAPON_SHORT], charsmax(skin[SKIN_WEAPON_SHORT]), skin[SKIN_WEAPON]);
			}

			continue;
		} else {
			parse(lineData, tempValue[0], charsmax(tempValue[]), tempValue[1], charsmax(tempValue[]), tempValue[2], charsmax(tempValue[]), tempValue[3], charsmax(tempValue[]), tempValue[4], charsmax(tempValue[]));

			formatex(skin[SKIN_NAME], charsmax(skin[SKIN_NAME]), tempValue[0]);
			formatex(skin[SKIN_MODEL], charsmax(skin[SKIN_MODEL]), tempValue[1]);

			skin[SKIN_SUBMODEL] = str_to_num(tempValue[2]);
			skin[SKIN_PRICE] = str_to_num(tempValue[3]);
			skin[SKIN_RARITY] = str_to_num(tempValue[4]);

			if (is_skin_knife(skin[SKIN_WEAPON_SHORT])) {
				if (skin[SKIN_RARITY] < RARITY_EXCEEDINGLY_RARE) {
					skin[SKIN_RARITY] = RARITY_EXCEEDINGLY_RARE;
				}
			} else if (skin[SKIN_RARITY] == RARITY_EXCEEDINGLY_RARE) {
				skin[SKIN_RARITY] = RARITY_ANCIENT;
			}

			if (!file_exists(skin[SKIN_MODEL])) {
				log_to_file("csgo-error.log", "[CS:GO] The file %s containing the skin %s does not exist!", skin[SKIN_MODEL], skin[SKIN_NAME]);

				error = true;
			} else {
				precache_model(skin[SKIN_MODEL]);

				new bool:found;

				for (new i = 0; i < ArraySize(files); i++) {
					ArrayGetString(files, i, file, charsmax(file));

					if (equal(file, skin[SKIN_MODEL])) found = true;
				}

				if (!found) ArrayPushString(files, skin[SKIN_MODEL]);

				skinsCount++;
			}

			ArrayPushArray(skins, skin);
		}
	}

	fclose(fileOpen);

	#if !defined DISABLE_SUBMODELS
	for (new i = 0; i < sizeof availableWeapons; i++) {
		static weapon[32], weaponModel[128];

		copy(weapon, charsmax(weapon), availableWeapons[i]);

		if (equal(weapon, "weapon_c4") || equal(weapon, "weapon_hegrenade") || equal(weapon, "weapon_flashbang") || equal(weapon, "weapon_smokegrenade")) continue;

		formatex(weaponModel, charsmax(weaponModel), "models/%s/%s/v_%s_0.mdl", skinsPath, weapon[7], weapon[7]);

		if (!file_exists(weaponModel)) {
			log_to_file("csgo-error.log", "[CS:GO] The file %s containing one of the default skins does not exist!", weaponModel);

			error = true;
		} else {
			new bool:precached;

			for (new i = 0; i < ArraySize(skins); i++) {
				ArrayGetArray(skins, i, skin);

				if (equal(weaponModel, skin[SKIN_MODEL])) {
					precached = true;
				}
			}

			if (!precached) {
				fileCount++;

				precache_model(weaponModel);
			}

			skinsCount++;
		}
	}
	#endif

	if (error) set_fail_state("[CS:GO] Not all the skins were loaded. Check the error logs!");

	if (!ArraySize(skins)) set_fail_state("[CS:GO] No skin has been loaded. Check the configuration file csgo_skins.ini!");

	for (new i = 1; i <= MAX_PLAYERS; i++) playerSkins[i] = ArrayCreate(playerSkinsInfo);

	log_amx("CS:GO Mod by O'Zone (v%s).", VERSION);
	log_amx("Loaded %i skins from %i files.", skinsCount, ArraySize(files) + fileCount);

	set_task(0.1, "load_skins_details");
}

public load_skins_details()
{
	new file[128];

	get_localinfo("amxx_configsdir", file, charsmax(file));
	format(file, charsmax(file), "%s/csgo_skins.ini", file);

	if (!file_exists(file)) set_fail_state("[CS:GO] No skins configuration file csgo_skins.ini!");

	new skin[skinsInfo], lineData[256], tempValue[4][64], tempPrice[16], fileOpen = fopen(file, "r");

	while (!feof(fileOpen)) {
		fgets(fileOpen, lineData, charsmax(lineData)); trim(lineData);

		if (lineData[0] == ';' || lineData[0] == '^0' || lineData[0] == '/') continue;

		if (lineData[0] == '[') {
			replace_all(lineData, charsmax(lineData), "[", "");
			replace_all(lineData, charsmax(lineData), "]", "");

			split(lineData, skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), tempPrice, charsmax(tempPrice), " - ");

			randomSkinPrice[equal(skin[SKIN_WEAPON], "RANDOM") ? WEAPON_ALL : get_weapon_id(skin[SKIN_WEAPON])] = str_to_float(tempPrice);

			continue;
		} else {
			parse(lineData, tempValue[0], charsmax(tempValue[]), tempValue[1], charsmax(tempValue[]), tempValue[2], charsmax(tempValue[]), tempValue[3], charsmax(tempValue[]));

			overallSkinChance[get_weapon_id(skin[SKIN_WEAPON])] += (str_to_num(tempValue[3]) > 1 ? str_to_num(tempValue[3]) : 1);
		}
	}
}


public plugin_cfg()
{
	new configPath[64], host[64], user[64], pass[64], db[64], error[256], errorNum;

	get_localinfo("amxx_configsdir", configPath, charsmax(configPath));

	server_cmd("exec %s/csgo_mod.cfg", configPath);
	server_exec();

	get_cvar_string("csgo_sql_host", host, charsmax(host));
	get_cvar_string("csgo_sql_user", user, charsmax(user));
	get_cvar_string("csgo_sql_pass", pass, charsmax(pass));
	get_cvar_string("csgo_sql_db", db, charsmax(db));

	sql = SQL_MakeDbTuple(host, user, pass, db);

	connection = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file("csgo-error.log", "[CS:GO Mod] Init SQL Error: %s (%i)", error, errorNum);

		return;
	}

	new queryData[256], bool:hasError;

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_skins` (name VARCHAR(64), steamid VARCHAR(35), weapon VARCHAR(35), skin VARCHAR(64), count INT NOT NULL DEFAULT 1, PRIMARY KEY(name, steamid, weapon, skin));");

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	if (!SQL_Execute(query)) {
		SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "[CS:GO Mod] Init SQL Error: %s", error);

		hasError = true;
	}

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_data` (name VARCHAR(64), steamid VARCHAR(35), money FLOAT NOT NULL DEFAULT 0, exchange INT NOT NULL DEFAULT 0, menu INT NOT NULL DEFAULT 0, online INT NOT NULL DEFAULT 0, PRIMARY KEY(steamid, name));");

	query = SQL_PrepareQuery(connection, queryData);

	if (!SQL_Execute(query)) {
		SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "[CS:GO Mod] Init SQL Error: %s", error);

		hasError = true;
	}

	formatex(queryData, charsmax(queryData), "ALTER TABLE `csgo_data` ADD COLUMN hud INT NOT NULL DEFAULT 0, ADD COLUMN skins INT NOT NULL DEFAULT 0;");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);

	if (!hasError) sqlConnected = true;
}

public plugin_natives()
{
	register_native("csgo_get_money", "_csgo_get_money", 1);
	register_native("csgo_add_money", "_csgo_add_money", 1);
	register_native("csgo_set_money", "_csgo_set_money", 1);

	register_native("csgo_get_menu", "_csgo_get_menu", 1);
	register_native("csgo_get_hud", "_csgo_get_hud", 1);
	register_native("csgo_get_skin", "_csgo_get_skin", 1);
	register_native("csgo_get_weapon_skin", "_csgo_get_weapon_skin", 1);
	register_native("csgo_get_skin_name", "_csgo_get_skin_name", 1);
	register_native("csgo_get_current_skin_name", "_csgo_get_current_skin_name", 1);
	register_native("csgo_get_min_players", "_csgo_get_min_players", 0);
	register_native("csgo_give_random_skin", "_csgo_give_random_skin", 1);
}

public plugin_end()
{
	SQL_FreeHandle(sql);
	SQL_FreeHandle(connection);

	ArrayDestroy(skins);

	for (new i = 1; i <= MAX_PLAYERS; i++) ArrayDestroy(playerSkins[i]);
}

public client_disconnected(id)
{
	save_data(id, end ? 2 : 1);

	remove_task(id + TASK_AIM);
	remove_task(id + TASK_DATA);
	remove_task(id + TASK_SKINS);
	remove_task(id + TASK_AD);

	remove_seller(id);
}

public client_putinserver(id)
{
	for (new i = 1; i <= CSW_P90; i++) playerData[id][ACTIVE][i] = NONE;

	playerData[id][MONEY] = 0.0;
	playerData[id][SKIN] = NONE;
	playerData[id][SUBMODEL] = 0;

	rem_bit(id, force);

	ArrayClear(playerSkins[id]);

	for (new i = SKINS_LOADED; i <= SKINS_BLOCKED; i++) playerData[id][i] = false;

	if (is_user_hltv(id) || is_user_bot(id)) return;

	get_user_authid(id, playerData[id][STEAM_ID], charsmax(playerData[][STEAM_ID]));
	get_user_name(id, playerData[id][NAME], charsmax(playerData[][NAME]));

	mysql_escape_string(playerData[id][NAME], playerData[id][SAFE_NAME], charsmax(playerData[][SAFE_NAME]));

	set_task(0.1, "load_data", id + TASK_DATA);
	set_task(0.1, "load_skins", id + TASK_SKINS);
	set_task(15.0, "show_advertisement", id + TASK_AD);
}

public show_advertisement(id)
{
	id -= TASK_AD;

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_CREATED", PLUGIN, VERSION, AUTHOR);
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_HELP");
}

public skins_menu(id)
{
	if (!csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	new menuData[64];

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_MENU");

	new menu = menu_create(menuData, "skins_menu_handle");

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_ITEM_SET");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_ITEM_BUY");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_ITEM_DRAW");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_ITEM_MARKET");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_ITEM_TRANSFER");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_ITEM_EXCHANGE");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SKINS_ITEM_GIVE");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, playerData[id][MENU_BLOCKED] ? "CSGO_CORE_SKINS_ITEM_MENU_STANDARD" : "CSGO_CORE_SKINS_ITEM_MENU_NEW");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, playerData[id][EXCHANGE_BLOCKED] ? "CSGO_CORE_SKINS_ITEM_EXCHANGE_DISABLED" : "CSGO_CORE_SKINS_ITEM_EXCHANGE_ENABLED");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, playerData[id][HUD_BLOCKED] ? "CSGO_CORE_SKINS_ITEM_HUD_DISABLED" : "CSGO_CORE_SKINS_ITEM_HUD_ENABLED");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, playerData[id][SKINS_BLOCKED] ? "CSGO_CORE_SKINS_ITEM_SKINS_DISABLED" : "CSGO_CORE_SKINS_ITEM_SKINS_ENABLED");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public skins_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case MENU_SET, MENU_BUY, MENU_RANDOM: choose_weapon_menu(id, item);
		case 3: market_menu(id);
		case 4: client_cmd(id, "transfer");
		case 5: exchange_skin_menu(id);
		case 6: give_skin_menu(id);
		case 7: {
			playerData[id][MENU_BLOCKED] = !playerData[id][MENU_BLOCKED];

			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, playerData[id][MENU_BLOCKED] ? "CSGO_CORE_SKINS_MENU_STANDARD" : "CSGO_CORE_SKINS_MENU_NEW");

			save_data(id);

			skins_menu(id);
		} case 8: {
			playerData[id][EXCHANGE_BLOCKED] = !playerData[id][EXCHANGE_BLOCKED];

			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, playerData[id][EXCHANGE_BLOCKED] ? "CSGO_CORE_SKINS_EXCHANGE_DISABLED" : "CSGO_CORE_SKINS_EXCHANGE_ENABLED");

			save_data(id);

			skins_menu(id);
		} case 9: {
			playerData[id][HUD_BLOCKED] = !playerData[id][HUD_BLOCKED];

			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, playerData[id][HUD_BLOCKED] ? "CSGO_CORE_SKINS_HUD_DISABLED" : "CSGO_CORE_SKINS_HUD_ENABLED");

			save_data(id);

			skins_menu(id);
		} case 10: {
			playerData[id][SKINS_BLOCKED] = !playerData[id][SKINS_BLOCKED];

			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, playerData[id][SKINS_BLOCKED] ? "CSGO_CORE_SKINS_SKINS_DISABLED" : "CSGO_CORE_SKINS_SKINS_ENABLED");

			reset_skin(id);

			save_data(id);

			skins_menu(id);
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public skins_help(id)
{
	new motdTitle[32], motdFile[32];

	formatex(motdTitle, charsmax(motdTitle), "%L", id, "CSGO_CORE_HELP_MOTD_TITLE");
	formatex(motdFile, charsmax(motdFile), "%L", id, "CSGO_CORE_HELP_MOTD_FILE");

	show_motd(id, motdFile, motdTitle);

	skins_menu(id);

	return PLUGIN_HANDLED;
}

public set_skin_menu(id)
{
	if (!csgo_check_account(id)) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, MENU_SET);

	return PLUGIN_HANDLED;
}

public buy_skin_menu(id)
{
	if (!csgo_check_account(id)) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, MENU_BUY);

	return PLUGIN_HANDLED;
}

public random_skin_menu(id)
{
	if (!csgo_check_account(id)) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, MENU_RANDOM);

	return PLUGIN_HANDLED;
}

public add_skin_menu(id)
{
	if (!csgo_check_account(id) || !(get_user_flags(id) & ADMIN_FLAG)) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, MENU_ADD);

	return PLUGIN_HANDLED;
}

public choose_weapon_menu(id, type)
{
	new menuData[64], itemData[32], weapon[32], skin[skinsInfo], count = 0, skinCount = 0, playerSkinCount = 0;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_CHOOSE_WEAPON_MENU");

	new menu = menu_create(menuData, "choose_weapon_menu_handle");

	for (new i = (type == MENU_RANDOM && randomSkinPrice[WEAPON_ALL]) ? 0 : 1; i < ArraySize(weapons); i++) {
		ArrayGetString(weapons, i, weapon, charsmax(weapon));

		if (type == MENU_ADD) {
			formatex(itemData, charsmax(itemData), "%s#%i", weapon, type);

			menu_additem(menu, weapon, itemData);

			count++;

			continue;
		}

		skinCount = 0;
		playerSkinCount = 0;

		for (new i = 0; i < ArraySize(skins); i++) {
			ArrayGetArray(skins, i, skin);

			if (equal(weapon, skin[SKIN_WEAPON])) {
				skinCount++;

				if (has_skin(id, i, 1) != NONE) {
					playerSkinCount++;
				}
			}
		}

		if (i == 0 && type == MENU_RANDOM) {
			formatex(weapon, charsmax(weapon), "%L", id, "CSGO_CORE_ALL");
			formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_ALL");
		} else {
			formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_CHOOSE_WEAPON_ITEM", weapon, playerSkinCount, skinCount);
		}

		formatex(itemData, charsmax(itemData), "%s#%i", weapon, type);

		if (type != MENU_RANDOM || i == 0 || randomSkinPrice[get_weapon_id(weapon)] > 0.0) {
			menu_additem(menu, menuData, itemData);

			count++;
		}
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	if (!count) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_CHOOSE_WEAPON_NONE");

		menu_destroy(menu);
	} else {
		menu_display(id, menu);
	}

	return PLUGIN_HANDLED;
}

public choose_weapon_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[32], weapon[32], itemType[2], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	strtok2(itemData, weapon, charsmax(weapon), itemType, charsmax(itemType), '#');

	switch (str_to_num(itemType)) {
		case MENU_SET: set_weapon_skin(id, weapon);
		case MENU_BUY: buy_weapon_skin(id, weapon);
		case MENU_RANDOM: random_weapon_skin(id, weapon);
		case MENU_ADD: add_weapon_skin(id, weapon);
	}

	return PLUGIN_HANDLED;
}

public set_weapon_skin(id, weapon[])
{
	new menuData[128], tempId[5], skin[skinsInfo], skinId, skinsCount;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SET_MENU");

	new menu = menu_create(menuData, "set_weapon_skin_handle");

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_DEFAULT");

	menu_additem(menu, menuData, weapon);

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(weapon, skin[SKIN_WEAPON])) {
			skinId = has_skin(id, i, 1);

			if (skinId == NONE) continue;

			skinsCount = 0;

			if (multipleSkins) skinsCount = get_player_skin_info(id, skinId, SKIN_COUNT);

			if (skinsCount > 1) {
				formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SET_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY], skinsCount);
			} else {
				formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SET_ITEM2", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY]);
			}

			num_to_str(i, tempId, charsmax(tempId));

			menu_additem(menu, menuData, tempId);
		}
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public set_weapon_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if (item) {
		new skin[skinsInfo], itemData[5], itemAccess, itemCallback;

		menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

		new skinId = str_to_num(itemData);

		ArrayGetArray(skins, skinId, skin);

		remove_active_skin(id, skin[SKIN_WEAPON_SHORT]);

		set_skin(id, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME], skinId, 1);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SET_NEW", skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

		if (!is_skin_knife(skin[SKIN_WEAPON_SHORT])) {
			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SET_INFO");
		}
	} else {
		new itemData[16], itemAccess, itemCallback;

		menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

		remove_active_skin(id, itemData);

		set_skin(id, itemData);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SET_DEFAULT", itemData);

		if (!is_skin_knife(itemData)) {
			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SET_INFO");
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public buy_weapon_skin(id, weapon[])
{
	new menuData[128], skin[skinsInfo], tempId[5], count;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_BUY_MENU");

	new menu = menu_create(menuData, "buy_weapon_skin_handle");

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(weapon, skin[SKIN_WEAPON]) && skin[SKIN_RARITY] != RARITY_IMMORTAL) {
			if (!multipleSkins && has_skin(id, i)) continue;

			num_to_str(i, tempId, charsmax(tempId));

			formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_BUY_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY], skin[SKIN_PRICE]);

			menu_additem(menu, menuData, tempId);

			count++;
		}
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	if (!count) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_BUY_NONE");

		menu_destroy(menu);
	} else {
		menu_display(id, menu);
	}
}

public buy_weapon_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[32], itemAccess, itemCallback, skinId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	skinId = str_to_num(itemData);

	menu_destroy(menu);

	if (!multipleSkins && has_skin(id, skinId)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ALREADY_HAVE");

		return PLUGIN_HANDLED;
	}

	new skin[skinsInfo];

	ArrayGetArray(skins, skinId, skin);

	if (playerData[id][MONEY] < skin[SKIN_PRICE]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_MONEY");

		return PLUGIN_HANDLED;
	}

	playerData[id][TEMP][BUY_SKIN] = skinId;
	playerData[id][TEMP][BUY_SUBMODEL] = skin[SKIN_SUBMODEL];
	playerData[id][TEMP][BUY_WEAPON] = get_weapon_id(skin[SKIN_WEAPON]);

	buy_weapon_skin_confirm(id);

	return PLUGIN_HANDLED;
}

public buy_weapon_skin_confirm(id)
{
	new skin[skinsInfo], menuData[256], itemData[32];

	ArrayGetArray(skins, playerData[id][TEMP][BUY_SKIN], skin);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_BUY_CONFIRMATION", skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME], skin[SKIN_PRICE]);

	new menu = menu_create(menuData, "buy_weapon_skin_confirm_handle");

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_BUY_TRY");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_BUY_BUY");
	menu_additem(menu, menuData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_BACK");
	menu_setprop(menu, MPROP_EXITNAME, itemData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, itemData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public buy_weapon_skin_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if (!multipleSkins && has_skin(id, playerData[id][TEMP][BUY_SKIN])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ALREADY_HAVE");

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			set_bit(id, force);

			#if !defined DISABLE_SUBMODELS
			set_pev(id, pev_viewmodel2, "");

			set_task(0.1, "deploy_weapon_switch", id + TASK_DEPLOY);
			#else
			deploy_weapon_switch(id);
			#endif

			playerData[id][TEMP][COUNTDOWN] = get_gametime();

			set_task(0.1, "show_countdown", id + TASK_FORCE, .flags = "b");

			buy_weapon_skin_confirm(id);

			return PLUGIN_HANDLED;
		} case 1: {
			new skin[skinsInfo];

			ArrayGetArray(skins, playerData[id][TEMP][BUY_SKIN], skin);

			if (playerData[id][MONEY] < skin[SKIN_PRICE]) {
				client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_MONEY");

				return PLUGIN_HANDLED;
			}

			playerData[id][MONEY] -= skin[SKIN_PRICE];

			save_data(id);

			add_skin(id, playerData[id][TEMP][BUY_SKIN], skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_BUY_SUCCESS", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);

			log_to_file("csgo-buy.log", "Player %s bought skin %s (%s)", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);

			skins_menu(id);
		} case 2: {
			choose_weapon_menu(id, 1);
		}
	}


	if (task_exists(id + TASK_FORCE)) {
		client_print(id, print_center, "");

		remove_task(id + TASK_FORCE);

		reset_skin(id);
	}

	return PLUGIN_HANDLED;
}

public random_weapon_skin(id, weapon[])
{
	new menuData[256], itemData[32], allName[32], Float:chance = (csgo_get_user_svip(id) ? skinChanceSVIP : skinChance) + csgo_get_clan_members(csgo_get_user_clan(id)) * skinChancePerMember;

	formatex(allName, charsmax(allName), "%L", id, "CSGO_CORE_ALL");

	if (equal(weapon, allName)) {
		formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_DRAW_RANDOM_SKIN_MENU", randomSkinPrice[WEAPON_ALL], chance);
	} else {
		formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_DRAW_SKIN_MENU", weapon, randomSkinPrice[get_weapon_id(weapon)], chance);
	}

	new menu = menu_create(menuData, "random_weapon_skin_handle");

	formatex(itemData, charsmax(itemData), "\y%L", id, "CSGO_MENU_YES");
	menu_additem(menu, itemData, weapon);

	formatex(itemData, charsmax(itemData), "\w%L^n", id, "CSGO_MENU_NO");
	menu_additem(menu, itemData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_DRAW_INFO", skinChanceSVIP - skinChance, skinChancePerMember);

	menu_addtext(menu, menuData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, itemData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public random_weapon_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT || item) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new weapon[32], allName[32], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, weapon, charsmax(weapon), _, _, itemCallback);

	formatex(allName, charsmax(allName), "%L", id, "CSGO_CORE_ALL");

	if (!multipleSkins && !get_missing_weapon_skins_count(id, weapon, 1)) {
		if (equal(weapon, allName)) {
			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ALREADY_HAVE_ALL", weapon);
		} else {
			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ALREADY_HAVE_ALL_WEAPON", weapon);
		}

		return PLUGIN_HANDLED;
	}

	new Float:price = randomSkinPrice[equal(weapon, allName) ? WEAPON_ALL : get_weapon_id(weapon)];

	if (playerData[id][MONEY] < price) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_MONEY");

		return PLUGIN_HANDLED;
	} else {
		playerData[id][MONEY] -= price;
	}

	new chance = (csgo_get_user_svip(id) ? skinChanceSVIP : skinChance) + floatround(csgo_get_clan_members(csgo_get_user_clan(id)) * skinChancePerMember, floatround_floor);

	if (random_num(1, 100) <= chance) {
		new skin[skinsInfo], skinId, skinsChance = 0, skinChance = random_num(1, multipleSkins ? get_weapon_skins_count(id, weapon, CHANCE) : get_missing_weapon_skins_count(id, weapon, CHANCE));

		for (new i = 0; i < ArraySize(skins); i++) {
			ArrayGetArray(skins, i, skin);

			if (equali(weapon, skin[SKIN_WEAPON]) || equal(weapon, allName)) {
				if (skin[SKIN_RARITY] == RARITY_IMMORTAL || (!multipleSkins && has_skin(id, i))) continue;

				skinsChance += get_skin_chance(skin[SKIN_RARITY]);

				if (skinsChance >= skinChance) {
					skinId = i;

					break;
				}
			}
		}

		ArrayGetArray(skins, skinId, skin);

		add_skin(id, skinId, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

		for (new player = 1; player <= MAX_PLAYERS; player++) {
			if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(player)) continue;

			client_print_color(player, id, "%s %L", CHAT_PREFIX, player, "CSGO_CORE_DRAW_SUCCESS", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);
		}

		log_to_file("csgo-random.log", "Player %s has drawn a skin %s (%s)", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);
	} else {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_DRAW_NEXT_TIME");
	}

	save_data(id);

	skins_menu(id);

	return PLUGIN_HANDLED;
}

public add_weapon_skin(id, weapon[])
{
	new menuData[128], skin[skinsInfo], tempId[5], count;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_ADD_MENU");

	new menu = menu_create(menuData, "add_weapon_skin_handle");

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(weapon, skin[SKIN_WEAPON])) {
			num_to_str(i, tempId, charsmax(tempId));

			menu_additem(menu, skin[SKIN_NAME], tempId);

			count++;
		}
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	if (!count) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ADD_NONE");

		menu_destroy(menu);
	} else {
		menu_display(id, menu);
	}
}

public add_weapon_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[32], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	playerData[id][TEMP][ADD_SKIN] = str_to_num(itemData);

	menu_destroy(menu);

	add_weapon_skin_player(id);

	return PLUGIN_HANDLED;
}

public add_weapon_skin_player(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new menuData[64], userName[32], userId[6];

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_ADD_PLAYER_MENU");

	new menu = menu_create(menuData, "add_weapon_skin_player_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(player)) continue;

		get_user_name(player, userName, charsmax(userName));

		num_to_str(player, userId, charsmax(userId));

		menu_additem(menu, userName, userId);
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public add_weapon_skin_player_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new userName[32], itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), userName, charsmax(userName), itemCallback);

	new player = str_to_num(itemData);

	if (!is_user_connected(player)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ADD_UNAVAILABLE");

		return PLUGIN_HANDLED;
	}

	if (!multipleSkins && has_skin(player, playerData[id][TEMP][ADD_SKIN])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ADD_ALREADY_HAVE");

		return PLUGIN_HANDLED;
	}

	new skin[skinsInfo];

	ArrayGetArray(skins, playerData[id][TEMP][ADD_SKIN], skin);

	add_skin(player, playerData[id][TEMP][ADD_SKIN], skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

	client_print_color(player, player, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ADD_SUCCESS", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ADD_SUCCESS2", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], playerData[id][NAME]);

	log_to_file("csgo-add.log", "Admin %s added skin %s (%s) to player %s", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], playerData[player][NAME]);

	return PLUGIN_HANDLED;
}

public exchange_skin_menu(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	new menuData[128], playerId[3], skinsCount, players;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_MENU");

	new menu = menu_create(menuData, "exchange_skin_menu_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || id == player || is_user_bot(player) || is_user_hltv(player) || !ArraySize(playerSkins[player]) || playerData[player][EXCHANGE_BLOCKED]) continue;

		skinsCount = ArraySize(playerSkins[player]);

		formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_ITEM", playerData[player][NAME], skinsCount);

		num_to_str(player, playerId, charsmax(playerId));

		menu_additem(menu, menuData, playerId);

		players++;
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	if (!players) {
		menu_destroy(menu);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_NONE");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public exchange_skin_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new playerId[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, playerId, charsmax(playerId), _, _, itemCallback);

	new player = str_to_num(playerId);

	menu_destroy(menu);

	if (!is_user_connected(player)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PLAYER_DISCONNECTED");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[player])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_SKINS_PLAYER");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[id])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_SKINS");

		return PLUGIN_HANDLED;
	}

	playerData[id][TEMP][EXCHANGE_PLAYER] = player;

	new menuData[128], skin[skinsInfo], tempId[5], skinId, skinsCount;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_OWN_MENU");

	new menu = menu_create(menuData, "exchange_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID), skinsCount = get_player_skin_info(id, i, SKIN_COUNT);

		if (!multipleSkins && has_skin(player, skinId)) continue;

		ArrayGetArray(skins, skinId, skin);

		num_to_str(skinId, tempId, charsmax(tempId));

		if (multipleSkins && skinsCount > 1) {
			formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_OWN_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY], skinsCount);
		} else {
			formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_OWN_ITEM2", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY]);
		}

		menu_additem(menu, menuData, tempId);
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public exchange_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new player = playerData[id][TEMP][EXCHANGE_PLAYER];

	if (!is_user_connected(player)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PLAYER_DISCONNECTED");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[player])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_SKINS_PLAYER");

		return PLUGIN_HANDLED;
	}

	new itemData[5], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	playerData[id][TEMP][EXCHANGE] = str_to_num(itemData);

	menu_destroy(menu);

	if (has_skin(id, playerData[id][TEMP][EXCHANGE], 1) == NONE) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_OWN_NONE");

		return PLUGIN_HANDLED;
	}

	new menuData[128], skin[skinsInfo], tempId[5], skinsCount = 0, skinId;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_THEIR_MENU");

	new menu = menu_create(menuData, "exchange_for_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[player]); i++) {
		skinId = get_player_skin_info(player, i, SKIN_ID);

		if (!multipleSkins && has_skin(id, skinId)) continue;

		ArrayGetArray(skins, skinId, skin);

		formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_THEIR_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY]);

		menu_additem(menu, menuData, tempId);

		skinsCount++;
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	if (!skinsCount) {
		menu_destroy(menu);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ALREADY_HAVE_ALL_PLAYER");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public exchange_for_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new player = playerData[id][TEMP][EXCHANGE_PLAYER];

	if (!is_user_connected(player)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PLAYER_DISCONNECTED");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[player])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_SKINS_PLAYER");

		return PLUGIN_HANDLED;
	}

	new menuData[256], itemData[32], skin[skinsInfo], playerSkin[skinsInfo], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	playerData[id][TEMP][EXCHANGE_FOR_SKIN] = str_to_num(itemData);

	if (playerData[id][TEMP][EXCHANGE_FOR_SKIN] == playerData[id][TEMP][EXCHANGE]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_SAME_SKIN");

		return PLUGIN_HANDLED;
	}

	if (has_skin(player, playerData[id][TEMP][EXCHANGE_FOR_SKIN], 1) == NONE) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	ArrayGetArray(skins, playerData[id][TEMP][EXCHANGE], skin);
	ArrayGetArray(skins, playerData[id][TEMP][EXCHANGE_FOR_SKIN], playerSkin);

	playerData[player][TEMP][EXCHANGE_PLAYER] = id;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_EXCHANGE_QUESTION",
		playerData[id][NAME], playerSkin[SKIN_NAME], playerSkin[SKIN_WEAPON_SHORT], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);

	show_menu(player, (MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0), menuData, -1, "Exchange");

	return PLUGIN_HANDLED;
}

public exchange_question_handle(id, key)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new player = playerData[id][TEMP][EXCHANGE_PLAYER], exchangeSkin = playerData[player][TEMP][EXCHANGE], exchangeForSkin = playerData[player][TEMP][EXCHANGE_FOR_SKIN];

	if (!is_user_connected(player)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_NO_PLAYER");

		return PLUGIN_HANDLED;
	}

	if (has_skin(player, exchangeSkin, 1) == NONE) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_NO_SKIN2");

		return PLUGIN_HANDLED;
	}

	if (has_skin(id, exchangeForSkin, 1) == NONE) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_NO_SKIN3");

		return PLUGIN_HANDLED;
	}

	switch (key + 1) {
		case 8: {
			new skin[skinsInfo], playerSkin[skinsInfo];

			ArrayGetArray(skins, exchangeSkin, playerSkin);
			ArrayGetArray(skins, exchangeForSkin, skin);

			remove_skin(player, exchangeSkin, playerSkin[SKIN_WEAPON_SHORT], playerSkin[SKIN_NAME]);
			remove_skin(id, exchangeForSkin, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

			add_skin(player, exchangeForSkin, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);
			add_skin(id, exchangeSkin, playerSkin[SKIN_WEAPON_SHORT], playerSkin[SKIN_NAME]);

			client_print_color(player, player, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_SUCCESS", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);
			client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_SUCCESS", playerData[player][NAME], playerSkin[SKIN_NAME], playerSkin[SKIN_WEAPON_SHORT]);

			log_to_file("csgo-exchange.log", "Player %s has exchanged skin %s (%s) z graczem %s with player %s (%s)", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], playerData[player][NAME], playerSkin[SKIN_NAME], playerSkin[SKIN_WEAPON_SHORT]);
		} default: {
			client_print_color(player, player, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_EXCHANGE_DECLINED");
		}
	}

	return PLUGIN_HANDLED;
}

public give_skin_menu(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	new menuData[128], playerId[3], skinsCount, players;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_GIVE_MENU");

	new menu = menu_create(menuData, "give_skin_menu_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || id == player || is_user_hltv(player) || is_user_bot(player)) continue;

		skinsCount = ArraySize(playerSkins[player]);

		formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_GIVE_ITEM", playerData[player][NAME], skinsCount);

		num_to_str(player, playerId, charsmax(playerId));

		menu_additem(menu, menuData, playerId);

		players++;
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	if (!players) {
		menu_destroy(menu);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_GIVE_NONE");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public give_skin_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new playerId[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, playerId, charsmax(playerId), _, _, itemCallback);

	new player = str_to_num(playerId);

	menu_destroy(menu);

	if (!is_user_connected(player)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PLAYER_DISCONNECTED");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[id])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_SKINS");

		return PLUGIN_HANDLED;
	}

	playerData[id][TEMP][GIVE_PLAYER] = player;

	new menuData[128], skin[skinsInfo], tempId[5], skinsCount = 0, skinId, skinCount;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_GIVE_SELECT_MENU");

	new menu = menu_create(menuData, "give_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID), skinCount = get_player_skin_info(id, i, SKIN_COUNT);

		if (!multipleSkins && has_skin(player, skinId)) continue;

		ArrayGetArray(skins, skinId, skin);

		num_to_str(skinId, tempId, charsmax(tempId));

		if (multipleSkins && skinCount > 1) formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_GIVE_SELECT_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY], skinCount);
		else formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_GIVE_SELECT_ITEM2", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY]);

		menu_additem(menu, menuData, tempId);

		skinsCount++;
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	if (!skinsCount) {
		menu_destroy(menu);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_GIVE_SELECT_ALREADY");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public give_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new player = playerData[id][TEMP][GIVE_PLAYER];

	if (!is_user_connected(player)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PLAYER_DISCONNECTED");

		return PLUGIN_HANDLED;
	}

	new itemData[5], itemAccess, itemCallback, skinId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	skinId = str_to_num(itemData);

	menu_destroy(menu);

	if (has_skin(id, skinId, 1) == NONE) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_GIVE_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	if (!multipleSkins && has_skin(player, skinId)) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_GIVE_ALREADY");

		return PLUGIN_HANDLED;
	}

	new skin[skinsInfo];

	ArrayGetArray(skins, skinId, skin);

	remove_skin(id, skinId, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

	add_skin(player, skinId, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

	client_print_color(player, player, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_GIVE_SUCCESS", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_GIVE_SUCCESS2", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], playerData[player][NAME]);

	log_to_file("csgo-give.log", "Player %s gave skin %s (%s) to player %s", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], playerData[player][NAME]);

	return PLUGIN_HANDLED;
}

public market_menu(id)
{
	if (!csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	new menuData[64], callback = menu_makecallback("market_menu_callback");

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_MARKET_MENU");

	new menu = menu_create(menuData, "market_menu_handle");

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_MARKET_SELL");
	menu_additem(menu, menuData, _, _, callback);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_MARKET_PURCHASE");
	menu_additem(menu, menuData, _, _, callback);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_MARKET_WITHDRAW");
	menu_additem(menu, menuData, _, _, callback);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public market_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: market_sell_skin(id);
		case 1: market_buy_skin(id);
		case 2: market_withdraw_skin(id);
	}

	return PLUGIN_HANDLED;
}

public market_menu_callback(id, menu, item)
{
	switch (item) {
		case 0: if (!ArraySize(playerSkins[id]) || get_market_skins(id) >= maxMarketSkins) return ITEM_DISABLED;
		case 1: if (!ArraySize(market)) return ITEM_DISABLED;
		case 2: if (!get_market_skins(id)) return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public market_sell_skin(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[id])) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_SKINS");

		return PLUGIN_HANDLED;
	}

	if (get_market_skins(id) >= maxMarketSkins) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SELL_MAX", maxMarketSkins);

		return PLUGIN_HANDLED;
	}

	new menuTitle[128], menuData[128], skin[skinsInfo], tempId[5], skinId, skinsCount;

	if (marketCommision > 0.0) {
		formatex(menuTitle, charsmax(menuTitle), "%L", id, "CSGO_CORE_SELL_MENU_COMISSION", marketCommision);
	} else {
		formatex(menuTitle, charsmax(menuTitle), "%L", id, "CSGO_CORE_SELL_MENU");
	}

	new menu = menu_create(menuTitle, "market_sell_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID), skinsCount = get_player_skin_info(id, i, SKIN_COUNT);

		ArrayGetArray(skins, skinId, skin);

		num_to_str(skinId, tempId, charsmax(tempId));

		if (multipleSkins && skinsCount > 1) {
			formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SELL_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY], skinsCount);
		} else {
			formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_SELL_ITEM2", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY]);
		}

		menu_additem(menu, menuData, tempId);
	}

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public market_sell_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[5], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	playerData[id][SALE_SKIN] = str_to_num(itemData);

	menu_destroy(menu);

	if (has_skin(id, playerData[id][SALE_SKIN], 1) == NONE) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SELL_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "messagemode SKIN_PRICE");

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SELL_PRICE");

	client_print(id, print_center, "%L", id, "CSGO_CORE_SELL_PRICE2");

	return PLUGIN_HANDLED;
}

public set_skin_price(id)
{
	if (!csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (has_skin(id, playerData[id][SALE_SKIN], 1) == NONE) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SELL_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	if (get_market_skins(id) >= maxMarketSkins) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SELL_MAX", maxMarketSkins);

		return PLUGIN_HANDLED;
	}

	new priceData[16], Float:price;

	read_args(priceData, charsmax(priceData));
	remove_quotes(priceData);

	price = str_to_float(priceData);

	if (price < 1.0 || price > 99999.0) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_SELL_WRONG_PRICE");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo];

	marketSkin[MARKET_ID] = marketSkins++;
	marketSkin[MARKET_SKIN] = playerData[id][SALE_SKIN];
	marketSkin[MARKET_OWNER] = id;
	marketSkin[MARKET_PRICE] = price;

	ArrayPushArray(market, marketSkin);

	ArrayGetArray(skins, playerData[id][SALE_SKIN], skin);

	change_local_skin(id, playerData[id][SALE_SKIN]);

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(player)) continue;

		client_print_color(player, id, "%s %L", CHAT_PREFIX, player, "CSGO_CORE_SELL_ISSUED", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], price);
	}

	return PLUGIN_HANDLED;
}

public market_buy_skin(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], itemData[128], skinIds[16], skinsCounts = 0;

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_CORE_PURCHASE_MENU");

	new menu = menu_create(itemData, "market_buy_skin_handle");

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if ((marketSkin[MARKET_OWNER] == id) || (!multipleSkins && has_skin(id, marketSkin[MARKET_SKIN]))) continue;

		ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

		formatex(skinIds, charsmax(skinIds), "%i#%i#%i", marketSkin[MARKET_ID], marketSkin[MARKET_SKIN], marketSkin[MARKET_OWNER]);

		formatex(itemData, charsmax(itemData), "%L", id, "CSGO_CORE_PURCHASE_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY], marketSkin[MARKET_PRICE]);

		menu_additem(menu, itemData, skinIds);

		skinsCounts++;
	}

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, itemData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, itemData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, itemData);

	if (!skinsCounts) {
		menu_destroy(menu);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PURCHASE_NONE");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public market_buy_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemIds[16], skinIds[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemIds, charsmax(itemIds), _, _, itemCallback);

	explode_num(itemIds, '#', skinIds, sizeof(skinIds));

	new skinId = check_market_skin(skinIds[0], skinIds[1], skinIds[2]);

	if (skinId < 0) {
		market_menu(id);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PURCHASE_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], menuData[512], itemData[32];

	ArrayGetArray(market, skinId, marketSkin);
	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_PURCHASE_CONFIRMATION",
		playerData[marketSkin[MARKET_OWNER]][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], marketSkin[MARKET_PRICE]);

	new menu = menu_create(menuData, "market_buy_confirm_handle");

	formatex(itemData, charsmax(itemData), "\y%L", id, "CSGO_MENU_YES");
	menu_additem(menu, itemData, itemIds);

	formatex(itemData, charsmax(itemData), "\w%L^n", id, "CSGO_MENU_NO");
	menu_additem(menu, itemData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, itemData);

	menu_display(id, menu);

	return PLUGIN_CONTINUE;
}

public market_buy_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT || item) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemIds[16], skinIds[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemIds, charsmax(itemIds), _, _, itemCallback);

	explode_num(itemIds, '#', skinIds, sizeof(skinIds));

	new skinId = check_market_skin(skinIds[0], skinIds[1], skinIds[2]);

	if (skinId < 0) {
		market_menu(id);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PURCHASE_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo];

	ArrayGetArray(market, skinId, marketSkin);

	if (playerData[id][MONEY] < marketSkin[MARKET_PRICE]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_NO_MONEY");

		return PLUGIN_HANDLED;
	}

	new skin[skinsInfo], Float:priceAfterCommision = marketSkin[MARKET_PRICE] * ((100.0 - marketCommision) / 100.0);

	change_local_skin(marketSkin[MARKET_OWNER], marketSkin[MARKET_SKIN], 1);

	ArrayDeleteItem(market, skinId);

	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	playerData[marketSkin[MARKET_OWNER]][MONEY] += priceAfterCommision;
	playerData[id][MONEY] -= marketSkin[MARKET_PRICE];

	add_skin(id, marketSkin[MARKET_SKIN], skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);
	remove_skin(marketSkin[MARKET_OWNER], marketSkin[MARKET_SKIN], skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PURCHASE_BOUGHT", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);

	client_print_color(marketSkin[MARKET_OWNER], marketSkin[MARKET_OWNER], "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PURCHASE_BOUGHT2", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], playerData[id][NAME]);
	client_print_color(marketSkin[MARKET_OWNER], marketSkin[MARKET_OWNER], "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PURCHASE_BOUGHT3", priceAfterCommision);

	log_to_file("csgo-sell.log", "Player %s sold skin %s (%s) to player %s for %.2f Euro", playerData[marketSkin[MARKET_OWNER]][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], playerData[id][NAME], marketSkin[MARKET_PRICE]);

	return PLUGIN_CONTINUE;
}

public market_withdraw_skin(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_INFO_LOADING");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], itemData[128], skinIds[16], skinsCounts = 0;

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_CORE_WITHDRAW_MENU");

	new menu = menu_create(itemData, "market_withdraw_skin_handle");

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if (marketSkin[MARKET_OWNER] != id) continue;

		ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

		formatex(skinIds, charsmax(skinIds), "%i#%i#%i", marketSkin[MARKET_ID], marketSkin[MARKET_SKIN], marketSkin[MARKET_OWNER]);

		formatex(itemData, charsmax(itemData), "%L", id, "CSGO_CORE_WITHDRAW_ITEM", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], skin[SKIN_RARITY], marketSkin[MARKET_PRICE]);

		menu_additem(menu, itemData, skinIds);

		skinsCounts++;
	}

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, itemData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, itemData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, itemData);

	if (!skinsCounts) {
		menu_destroy(menu);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_WITHDRAW_NONE");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public market_withdraw_skin_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemIds[16], skinIds[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemIds, charsmax(itemIds), _, _, itemCallback);

	explode_num(itemIds, '#', skinIds, sizeof(skinIds));

	new skinId = check_market_skin(skinIds[0], skinIds[1], skinIds[2]);

	if (skinId < 0) {
		market_menu(id);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_WITHDRAW_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], menuData[512], itemData[32];

	ArrayGetArray(market, skinId, marketSkin);
	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_CORE_WITHDRAW_CONFIRMATION",
		skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT], marketSkin[MARKET_PRICE]);

	new menu = menu_create(menuData, "market_withdraw_confirm_handle");

	formatex(itemData, charsmax(itemData), "\y%L", id, "CSGO_MENU_YES");
	menu_additem(menu, itemData, itemIds);

	formatex(itemData, charsmax(itemData), "\w%L^n", id, "CSGO_MENU_NO");
	menu_additem(menu, itemData);

	formatex(itemData, charsmax(itemData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, itemData);

	menu_display(id, menu);

	return PLUGIN_CONTINUE;
}

public market_withdraw_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT || item) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemIds[16], skinIds[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemIds, charsmax(itemIds), _, _, itemCallback);

	explode_num(itemIds, '#', skinIds, sizeof(skinIds));

	new skinId = check_market_skin(skinIds[0], skinIds[1], skinIds[2]);

	if (skinId < 0) {
		market_menu(id);

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_WITHDRAW_NO_SKIN");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo];

	ArrayGetArray(market, skinId, marketSkin);
	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	change_local_skin(id, marketSkin[MARKET_SKIN], 1);

	ArrayDeleteItem(market, skinId);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_PURCHASE_SUCCESS", skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);

	return PLUGIN_CONTINUE;
}

public cmd_add_money(id)
{
	if (!csgo_check_account(id) || !(get_user_flags(id) & ADMIN_FLAG)) return PLUGIN_HANDLED;

	new playerName[32], tempMoney[4];

	read_argv(1, playerName, charsmax(playerName));
	read_argv(2, tempMoney, charsmax(tempMoney));

	new Float:addedMoney = str_to_float(tempMoney), player = cmd_target(id, playerName, 0);

	if (!player) {
		console_print(id, "%s %L", CONSOLE_PREFIX, id, "CSGO_CORE_ADD_MONEY_NO_PLAYER");

		return PLUGIN_HANDLED;
	}

	if (addedMoney < 0.1) {
		console_print(id, "%s %L", CONSOLE_PREFIX, id, "CSGO_CORE_ADD_MONEY_TOO_LOW");

		return PLUGIN_HANDLED;
	}

	playerData[player][MONEY] += addedMoney;

	save_data(player);

	client_print_color(player, player, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ADD_MONEY_GIVE", playerData[id][NAME], addedMoney);
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ADD_MONEY_GIVE2", addedMoney, playerData[player][NAME]);

	log_to_file("csgo-admin.log", "%s gave %.2f Euro to player %s.", playerData[id][NAME], addedMoney, playerData[player][NAME]);

	return PLUGIN_HANDLED;
}

public cmd_reset_data(id)
{
	if (!csgo_check_account(id) || !(get_user_flags(id) & ADMIN_FLAG)) return PLUGIN_HANDLED;

	log_to_file("csgo-admin.log", "Admin %s forced full data reset.", PLUGIN, playerData[id][NAME]);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_RESET_INFO");
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_RESET_INFO2");

	clear_database(id);

	new ret;

	ExecuteForward(resetHandle, ret);

	set_task(10.0, "restart_map");

	return PLUGIN_HANDLED;
}

public clear_database(id)
{
	for (new i = 1; i <= MAX_PLAYERS; i++) playerData[id][DATA_LOADED] = false;

	sqlConnected = false;

	new tempData[32];

	formatex(tempData, charsmax(tempData), "DROP TABLE `csgo_mod`;");

	SQL_ThreadQuery(sql, "ignore_handle", tempData);
}

public restart_map()
{
	new currentMap[64];

	get_mapname(currentMap, charsmax(currentMap));

	server_cmd("changelevel ^"%s^"", currentMap);
}

public client_death(killer, victim, weaponId, hitPlace, teamKill)
{
	if (!is_user_connected(killer) || !is_user_connected(victim) || !is_user_alive(killer) || get_user_team(victim) == get_user_team(killer) || !csgo_get_min_players()) return PLUGIN_CONTINUE;

	playerData[killer][MONEY] += killReward * get_multiplier(killer, victim);

	if (hitPlace == HIT_HEAD) playerData[killer][MONEY] += killHSReward * get_multiplier(killer, victim);

	save_data(killer);

	return PLUGIN_CONTINUE;
}

public log_event_operation()
{
	if (!csgo_get_min_players()) return PLUGIN_CONTINUE;

	new userLog[80], userAction[64], userName[32];

	read_logargv(0, userLog, charsmax(userLog));
	read_logargv(2, userAction, charsmax(userAction));
	parse_loguser(userLog, userName, charsmax(userName));

	new id = get_user_index(userName);

	if (!is_user_connected(id)) return PLUGIN_CONTINUE;

	if (equal(userAction, "Planted_The_Bomb")) {
		new Float:money = bombReward * get_multiplier(id);

		playerData[id][MONEY] += money;

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_BOMB_PLANTED", money);

		save_data(id);
	}

	if (equal(userAction, "Defused_The_Bomb")) {
		new Float:money = defuseReward * get_multiplier(id);

		playerData[id][MONEY] += money;

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_BOMB_DEFUSED", money);

		save_data(id);
	}

	return PLUGIN_CONTINUE;
}

public t_win_round()
	round_winner(1);

public ct_win_round()
	round_winner(2);

public round_winner(team)
{
	if (!csgo_get_min_players()) return;

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id) || get_user_team(id) != team) continue;

		new Float:money = winReward * get_multiplier(id);

		playerData[id][MONEY] += money;

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_ROUND_WIN", money);

		save_data(id);
	}
}

public hostages_rescued()
{
	if (!csgo_get_min_players()) return;

	new id = get_loguser_index(), Float:money = hostageReward * get_multiplier(id);

	playerData[id][MONEY] += money;

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_HOSTAGES_RESCUED", money);

	save_data(id);
}

stock get_loguser_index()
{
	new userLog[96], userName[32];

	read_logargv(0, userLog, charsmax(userLog));
	parse_loguser(userLog, userName, charsmax(userName));

	return get_user_index(userName);
}

public message_intermission()
{
	end = true;

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

		new Float:money;

		playerData[id][MONEY] += (money = random_float(1.0, 3.0));

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_CORE_MAP_REWARD", money);

		save_data(id, 1);
	}

	return PLUGIN_CONTINUE;
}

public set_fov(id)
{
	if (playerData[id][SKIN] > NONE && (!playerData[id][TEMP][WEAPON_ENT] || is_valid_ent(playerData[id][TEMP][WEAPON_ENT])) && (playerData[id][TEMP][WEAPON] == CSW_AWP || playerData[id][TEMP][WEAPON] == CSW_SCOUT)) {
		switch (read_data(1)) {
			case 10..55: {
				if (playerData[id][TEMP][WEAPON] == CSW_AWP) {
					set_pev(id, pev_viewmodel2, "models/v_awp.mdl");
				} else {
					set_pev(id, pev_viewmodel2, "models/v_scout.mdl");
				}
			} case 90: {
				if (is_valid_ent(playerData[id][TEMP][WEAPON_ENT])) {
					change_skin(id, playerData[id][TEMP][WEAPON], playerData[id][TEMP][WEAPON_ENT]);
				} else {
					change_skin(id, playerData[id][TEMP][WEAPON]);
				}
			}
		}
	}
}

public show_countdown(id)
{
	id -= TASK_FORCE;

	new Float:currentTime = (playerData[id][TEMP][COUNTDOWN] + 5.0) - get_gametime();

	if (currentTime <= 0.0) {
		client_print(id, print_center, "");

		remove_task(id + TASK_FORCE);

		reset_skin(id);

		return;
	}

	client_print(id, print_center, "%L", id, "CSGO_CORE_SKIN_COUNTDOWN", currentTime);
}

public reset_skin(id)
{
	rem_bit(id, force);

	if (!is_user_alive(id)) return;

	static weaponName[32];

	get_weaponname(playerData[id][TEMP][WEAPON], weaponName, charsmax(weaponName));

	ExecuteHamB(Ham_Item_Deploy, find_ent_by_owner(NONE, weaponName, id));
}

public client_command(id)
{
	static weapons[32], weaponsNum;

	playerData[id][TEMP][WEAPONS] = get_user_weapons(id, weapons, weaponsNum);
}

public event_money(id)
{
	if (!is_user_connected(id)) return;

	new oldWeapons = playerData[id][TEMP][WEAPONS];

	client_command(id);

	new newWeapon = playerData[id][TEMP][WEAPONS] & ~oldWeapons;

	if (newWeapon) {
		new x = NONE;
		do ++x; while ((newWeapon /= 2) >= 1);

		ExecuteHamB(Ham_GiveAmmo, id, maxBPAmmo[x], ammoType[x], maxBPAmmo[x]);
	}
}

public weapon_deploy_post(ent)
{
	if (pev_valid(ent) != VALID_PDATA) return HAM_IGNORED;

	new id = get_pdata_cbase(ent, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!pev_valid(id) || !is_user_alive(id)) return HAM_IGNORED;

	new weapon = weapon_entity(ent);

	playerData[id][TEMP][WEAPON] = weapon;
	playerData[id][SKIN] = NONE;
	playerData[id][SUBMODEL] = 0;

	if (playerData[id][SKINS_BLOCKED]) return HAM_IGNORED;

	if (weapon == CSW_P228 && csgo_get_user_zeus(id)) return HAM_IGNORED;

	#if !defined DISABLE_SUBMODELS
	if (weapon != CSW_HEGRENADE && weapon != CSW_SMOKEGRENADE && weapon != CSW_FLASHBANG && weapon != CSW_C4) {
		set_pev(id, pev_viewmodel2, "");
	}
	#endif

	change_skin(id, playerData[id][TEMP][WEAPON], ent);

	return HAM_IGNORED;
}

#if !defined DISABLE_SUBMODELS
public weapon_send_weapon_anim_post(ent, animation, skipLocal)
{
	if (pev_valid(ent) != VALID_PDATA) return HAM_IGNORED;

	new id = get_pdata_cbase(ent, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!pev_valid(id) || !is_user_alive(id) || playerData[id][SKINS_BLOCKED]) return HAM_IGNORED;

	new weapon = weapon_entity(ent);

	switch (weapon) {
		case CSW_C4, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: return HAM_IGNORED;
		default: {
			send_weapon_animation(id, get_bit(id, force) ? playerData[id][TEMP][BUY_SUBMODEL] : playerData[id][SUBMODEL], animation);
		}
	}

	return HAM_IGNORED;
}

public weapon_primary_attack(ent)
{
	if (pev_valid(ent) != VALID_PDATA) return HAM_IGNORED;

	new id = get_pdata_cbase(ent, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!pev_valid(id) || !is_user_alive(id) || playerData[id][SKINS_BLOCKED]) return HAM_IGNORED;

	new weapon = weapon_entity(ent);

	switch (weapon) {
		case CSW_C4, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: return HAM_IGNORED;
		default: {
			if (weapon == CSW_P228 && csgo_get_user_zeus(id)) return HAM_IGNORED;

			emulate_primary_attack(ent);
		}
	}

	return HAM_IGNORED;
}

public trace_attack_post(ent, attacker, Float:damage, Float:direction[3], ptr, damageType)
{
	if (pev_valid(attacker) != VALID_PDATA || playerData[attacker][SKINS_BLOCKED]) return HAM_IGNORED;

	new weapon = get_pdata_cbase(attacker, OFFSET_ACTIVE_ITEM, OFFSET_PLAYER_LINUX);

	if (!weapon || weapon_entity(weapon) == CSW_KNIFE) return HAM_IGNORED;

	static Float:vectorEnd[3];

	get_tr2(ptr, TR_vecEndPos, vectorEnd);

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vectorEnd, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, vectorEnd[0]);
	engfunc(EngFunc_WriteCoord, vectorEnd[1]);
	engfunc(EngFunc_WriteCoord, vectorEnd[2]);
	write_short(ent);
	write_byte(random_num(41, 45));
	message_end();

	return HAM_IGNORED;
}
#endif

public m4a1_secondary_attack(ent)
{
	if (pev_valid(ent) != VALID_PDATA) return HAM_IGNORED;

	new id = get_pdata_cbase(ent, OFFSET_PLAYER, OFFSET_ITEM_LINUX);

	if (!pev_valid(id) || !is_user_alive(id) || playerData[id][SKINS_BLOCKED]) return HAM_IGNORED;

	new skin = get_weapon_skin(id, weapon_entity(ent));

	if (skin > NONE) {
		static skinName[64];

		get_weapon_skin_name(id, ent, skinName, charsmax(skinName));

		if (is_skin_m4a4(skinName)) {
			cs_set_weapon_silen(ent, 0, 0);

			set_pdata_float(ent, OFFSET_SECONDARY_ATTACK, 9999.0, OFFSET_ITEM_LINUX);

			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}

public player_spawn(id)
{
	if (!is_user_alive(id)) return;

	if (!task_exists(id + TASK_AIM)) set_task(0.1, "check_aim_weapon", id + TASK_AIM, .flags="b");

	new weapons[32], weaponsNum, weapon;

	get_user_weapons(id, weapons, weaponsNum);

	for (new i = 0; i < weaponsNum; i++) {
		weapon = weapons[i];

		ExecuteHamB(Ham_GiveAmmo, id, maxBPAmmo[weapon], ammoType[weapon], maxBPAmmo[weapon]);
	}
}

public add_player_item(id, ent)
{
	if (pev_valid(ent) != VALID_PDATA || !is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) return HAM_IGNORED;

	new owner = entity_get_int(ent, EV_INT_iuser1);

	if (!is_user_connected(owner)) {
		new weapon = weapon_entity(ent), skin = get_weapon_skin(id, weapon);

		entity_set_int(ent, EV_INT_iuser1, id);
		entity_set_int(ent, EV_INT_iuser2, skin);

		if (skin > NONE) {
			new skinName[64];

			get_weapon_skin_name(id, ent, skinName, charsmax(skinName));

			if (is_skin_m4a4(skinName)) {
				cs_set_weapon_silen(ent, 0, 0);

				set_pdata_float(ent, OFFSET_SECONDARY_ATTACK, 9999.0, OFFSET_ITEM_LINUX);

				return HAM_IGNORED;
			}
		}

		if (silencerAttached && (weapon == CSW_USP || weapon == CSW_M4A1)) {
			cs_set_weapon_silen(ent, 1, 0);
		}
	}

	return HAM_IGNORED;
}

public set_model(ent, model[])
{
	if (!pev_valid(ent)) return HAM_IGNORED;

	new id = entity_get_edict(ent, EV_ENT_owner);

	if (!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || !fm_get_weaponbox_type(ent)) return HAM_IGNORED;

	new owner = entity_get_int(ent, EV_INT_iuser1);

	if (!is_user_connected(owner)) {
		entity_set_int(ent, EV_INT_iuser1, id);
		entity_set_int(ent, EV_INT_iuser2, get_weapon_skin(id, fm_get_weaponbox_type(ent)));
	}

	return HAM_IGNORED;
}

#if !defined DISABLE_SUBMODELS
public update_client_data_post(id, sendWeapons, handleCD)
{
	if (!pev_valid(id)) return FMRES_IGNORED;

	enum { SPEC_MODE, SPEC_TARGET, SPEC_END };

	static specInfo[MAX_PLAYERS + 1][SPEC_END], Float:gameTime, Float:lastEventCheck, specMode;

	new target = (specMode = pev(id, pev_iuser1)) ? pev(id, pev_iuser2) : id;

	if (pev_valid(target) != VALID_PDATA || !is_user_alive(target) || playerData[id][SKINS_BLOCKED]) return FMRES_IGNORED;

	new ent = get_pdata_cbase(target, OFFSET_ACTIVE_ITEM, OFFSET_PLAYER_LINUX);

	if (!ent || pev_valid(ent) != VALID_PDATA) return FMRES_IGNORED;

	new weapon = weapon_entity(ent);

	if (weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4) return FMRES_IGNORED;

	new owner = get_pdata_int(ent, OFFSET_ID, OFFSET_ITEM_LINUX);

	if (!owner) return FMRES_IGNORED;

	gameTime = get_gametime();
	lastEventCheck = get_pdata_float(ent, OFFSET_LAST_EVENT_CHECK, OFFSET_ITEM_LINUX);

	if (specMode) {
		if (specInfo[id][SPEC_MODE] != specMode) {
			specInfo[id][SPEC_MODE] = specMode;
			specInfo[id][SPEC_TARGET] = 0;
		}

		if (specMode == OBSERVER && specInfo[id][SPEC_TARGET] != target) {
			specInfo[id][SPEC_TARGET] = target;

			new data[3];
			data[0] = id;
			data[1] = get_bit(target, force) ? playerData[target][TEMP][BUY_SUBMODEL] : playerData[target][SUBMODEL];
			data[2] = 0;

			set_task(0.1, "observer_animation", id + TASK_SPEC, data, sizeof(data));
		}
	}

	if (!lastEventCheck) {
		set_cd(handleCD, CD_flNextAttack, gameTime + 0.001);
		set_cd(handleCD, CD_WeaponAnim, 0);

		return FMRES_HANDLED;
	}

	if (lastEventCheck <= gameTime) {
		if (get_bit(target, force)) {
			send_weapon_animation(target, playerData[target][TEMP][BUY_SUBMODEL], get_weapon_draw_animation(ent, playerData[target][TEMP][BUY_WEAPON]));
		} else {
			send_weapon_animation(target, playerData[target][SUBMODEL], get_weapon_draw_animation(ent));
		}

		set_pdata_float(ent, OFFSET_LAST_EVENT_CHECK, 0.0, OFFSET_ITEM_LINUX);
	}

	return FMRES_IGNORED;
}

public observer_animation(data[])
{
	if (!is_user_connected(data[0])) return;

	send_weapon_animation(data[0], data[1], data[2]);
}

public client_playback_event(flags, id, event, Float:delay, Float:origin[3], Float:angle[3], Float:param1, Float:param2, param3, param4, param5, param6)
{
	if (!pev_valid(id) || !is_user_connected(id) || playerData[id][SKINS_BLOCKED]) return FMRES_IGNORED;

	static i, count, spectator, spectators[MAX_PLAYERS];

	get_players(spectators, count, "bch");

	for (i = 0; i < count; i++) {
		spectator = spectators[i];

		if (!is_user_connected(spectator) || pev(spectator, pev_iuser1) != OBSERVER || pev(spectator, pev_iuser2) != id) continue;

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public client_user_info_changed(id)
{
	if (playerData[id][SKINS_BLOCKED]) return FMRES_IGNORED;

	static userInfo[6] = "cl_lw", clientValue[2], serverValue[2] = "1";

	if (get_user_info(id, userInfo, clientValue, charsmax(clientValue))) {
		set_user_info(id, userInfo, serverValue);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}
#endif

public check_aim_weapon(id)
{
	id -= TASK_AIM;

	if (!pev_valid(id) || !is_user_alive(id)) return FMRES_IGNORED;

	new ent = fm_get_user_aiming_ent(id, "weaponbox");

	if (!pev_valid(ent) || task_exists(ent)) {
		if (canPickup[id]) ClearSyncHud(id, weaponHud);

		canPickup[id] = false;

		return FMRES_IGNORED;
	}

	static Float:origin[2][3];

	pev(id, pev_origin, origin[0]);
	pev(ent, pev_origin, origin[1]);

	if (get_distance_f(origin[0], origin[1]) >= 120.0) {
		if (canPickup[id]) ClearSyncHud(id, weaponHud);

		canPickup[id] = false;

		return FMRES_IGNORED;
	}

	new skinName[64], weapon = fm_get_weaponbox_type(ent);

	if ((weapon == CSW_C4 && get_user_team(id) != 1) || !weapon) return FMRES_IGNORED;

	canPickup[id] = true;

	get_weapon_skin_name(id, ent, skinName, charsmax(skinName), weapon);

	set_hudmessage(0, 120, 250, -1.0, 0.7, 0, 1.0, 1.0, 0.1, 0.1, 3);

	ShowSyncHudMsg(id, weaponHud, "%L", id, "CSGO_CORE_PICKUP", skinName);

	if (get_user_button(id) & IN_USE) {
		static weaponName[32], data[2];

		data[0] = id;
		data[1] = ent;

		for (new i = 1; i <= CSW_P90; i++) {
			if (weaponSlots[i] == weaponSlots[weapon] && user_has_weapon(id, i)) {
				get_weaponname(i, weaponName, charsmax(weaponName));

				engclient_cmd(id, "drop", weaponName);

				break;
			}
		}

		set_task(0.1, "give_weapons", ent, data, sizeof(data));

		ClearSyncHud(id, weaponHud);
	}

	return FMRES_IGNORED;
}

public give_weapons(data[2])
{
	if (!is_user_alive(data[0])) return;

	if (pev_valid(data[1])) {
		ExecuteHamB(Ham_Touch, data[0], data[1]);
		ExecuteHamB(Ham_Touch, data[1], data[0]);

		emit_sound(data[0], CHAN_ITEM, "items/gunpickup2.wav", 1.0, 0.8, SND_SPAWNING, PITCH_NORM);
	}
}

stock change_skin(id, weapon, ent = 0)
{
	remove_task(id + TASK_DEPLOY);

	playerData[id][SKIN] = NONE;
	playerData[id][SUBMODEL] = 0;
	playerData[id][TEMP][WEAPON_ENT] = 0;

	if (!is_user_alive(id) || !weapon || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4) return;

	#if !defined DISABLE_SUBMODELS
	set_pev(id, pev_viewmodel2, "");
	#endif

	static skin[skinsInfo];

	if (is_valid_ent(ent) && weapon != CSW_KNIFE && weapon != CSW_HEGRENADE && weapon != CSW_SMOKEGRENADE && weapon != CSW_FLASHBANG && weapon != CSW_C4) {
		new weaponOwner = entity_get_int(ent, EV_INT_iuser1);

		if (is_user_connected(weaponOwner) && !is_user_hltv(weaponOwner) && !is_user_bot(weaponOwner)) {
			playerData[id][TEMP][WEAPON_ENT] = ent;

			new weaponSkin = entity_get_int(ent, EV_INT_iuser2);

			if (weaponSkin > NONE) {
				static weaponName[32];

				ArrayGetArray(skins, weaponSkin, skin);

				get_weaponname(weapon, weaponName, charsmax(weaponName));

				if (weapon != get_weapon_id(skin[SKIN_WEAPON])) {
					entity_set_int(ent, EV_INT_iuser1, 0);
					entity_set_int(ent, EV_INT_iuser2, NONE);

					playerData[id][SKIN] = NONE;
					playerData[id][SUBMODEL] = 0;
				} else {
					playerData[id][SKIN] = weaponSkin;
					playerData[id][SUBMODEL] = skin[SKIN_SUBMODEL];
				}
			}

			#if !defined DISABLE_SUBMODELS
			set_task(0.1, "deploy_weapon_switch", id + TASK_DEPLOY);
			#else
			deploy_weapon_switch(id);
			#endif

			return;
		}
	}

	if (playerData[id][ACTIVE][weapon] > NONE) {
		ArrayGetArray(skins, playerData[id][ACTIVE][weapon], skin);

		playerData[id][SKIN] = playerData[id][ACTIVE][weapon];
		playerData[id][SUBMODEL] = skin[SKIN_SUBMODEL];
	}

	#if !defined DISABLE_SUBMODELS
	set_task(0.1, "deploy_weapon_switch", id + TASK_DEPLOY);
	#else
	deploy_weapon_switch(id);
	#endif
}

public deploy_weapon_switch(id)
{
	#if !defined DISABLE_SUBMODELS
	id -= TASK_DEPLOY;
	#endif

	if (pev_valid(id) != VALID_PDATA || !is_user_alive(id)) return;

	static skin[skinsInfo], defaultSkin[128];

	new weapon = get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_PLAYER_LINUX);

	if (!weapon || pev_valid(weapon) != VALID_PDATA) return;

	if (get_bit(id, force) && playerData[id][TEMP][BUY_SKIN] > NONE) {
		ArrayGetArray(skins, playerData[id][TEMP][BUY_SKIN], skin);

		set_pev(id, pev_viewmodel2, skin[SKIN_MODEL]);
		set_pev(id, pev_body, skin[SKIN_SUBMODEL]);
	} else if (playerData[id][SKIN] > NONE) {
		ArrayGetArray(skins, playerData[id][SKIN], skin);

		set_pev(id, pev_viewmodel2, skin[SKIN_MODEL]);
		set_pev(id, pev_body, skin[SKIN_SUBMODEL]);
	} else if (defaultSkins) {
		#if !defined DISABLE_SUBMODELS
		static weaponName[32];

		get_weaponname(playerData[id][TEMP][WEAPON], weaponName, charsmax(weaponName));

		formatex(defaultSkin, charsmax(defaultSkin), "models/%s/%s/v_%s_0.mdl", skinsPath, weaponName[7], weaponName[7]);

		set_pev(id, pev_body, 0);
		set_pev(id, pev_viewmodel2, defaultSkin);
		#endif
	}

	#if !defined DISABLE_SUBMODELS
	set_pdata_float(weapon, OFFSET_LAST_EVENT_CHECK, get_gametime() + 0.001, OFFSET_ITEM_LINUX);

	send_weapon_animation(id, get_bit(id, force) ? playerData[id][TEMP][BUY_SUBMODEL] : playerData[id][SUBMODEL]);
	#else
	set_pev(id, pev_body, 0);
	#endif
}

#if !defined DISABLE_SUBMODELS
stock send_weapon_animation(id, submodel, animation = 0)
{
	static i, count, spectator, spectators[MAX_PLAYERS];

	if (!pev_valid(id) || !is_user_alive(id)) return;

	set_pev(id, pev_weaponanim, animation);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id);
	write_byte(animation);
	write_byte(submodel);
	message_end();

	if (pev(id, pev_iuser1)) return;

	get_players(spectators, count, "bch");

	for (i = 0; i < count; i++) {
		spectator = spectators[i];

		if (!is_user_connected(spectator) || !pev_valid(spectator) || pev(spectator, pev_iuser1) != OBSERVER || pev(spectator, pev_iuser2) != id) continue;

		set_pev(spectator, pev_weaponanim, animation);

		message_begin(MSG_ONE, SVC_WEAPONANIM, _, spectator);
		write_byte(animation);
		write_byte(submodel);
		message_end();
	}
}

stock get_weapon_draw_animation(entity, temp = NONE)
{
	static animation, weaponState;

	if (get_pdata_int(entity, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_USP_SILENCED || get_pdata_int(entity, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_M4A1_SILENCED) {
		weaponState = SILENCED;
	} else {
		weaponState = UNSILENCED;
	}

	new weapon = temp != NONE ? temp : weapon_entity(entity);

	switch (weapon) {
		case CSW_P228, CSW_XM1014, CSW_M3: animation = 6;
		case CSW_SCOUT, CSW_SG550, CSW_M249, CSW_G3SG1: animation = 4;
		case CSW_MAC10, CSW_AUG, CSW_UMP45, CSW_GALIL, CSW_FAMAS, CSW_MP5NAVY, CSW_TMP, CSW_SG552, CSW_AK47, CSW_P90: animation = 2;
		case CSW_ELITE: animation = 15;
		case CSW_FIVESEVEN, CSW_AWP, CSW_DEAGLE: animation = 5;
		case CSW_GLOCK18: animation = 8;
		case CSW_KNIFE, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: animation = 3;
		case CSW_C4: animation = 1;
		case CSW_USP: {
			switch (weaponState) {
				case SILENCED: animation = 6;
				case UNSILENCED: animation = 14;
			}
		}
		case CSW_M4A1: {
			switch (weaponState) {
				case SILENCED: animation = 5;
				case UNSILENCED: animation = 12;
			}
		}
	}

	return animation;
}

stock emulate_primary_attack(ent)
{
	switch (weapon_entity(ent)) {
		case CSW_GLOCK18: weapon_shoot_info(ent, 5, "weapons/dryfire_pistol.wav", "weapons/glock18-2.wav", 0, WEAPONTYPE_GLOCK18);
		case CSW_AK47: weapon_shoot_info(ent, 3, "weapons/dryfire_rifle.wav", "weapons/ak47-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_AUG: weapon_shoot_info(ent, 3, "weapons/dryfire_rifle.wav", "weapons/aug-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_AWP: weapon_shoot_info(ent, 2, "weapons/dryfire_rifle.wav", "weapons/awp1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_DEAGLE: weapon_shoot_info(ent, 2, "weapons/dryfire_pistol.wav", "weapons/deagle-2.wav", 0, WEAPONTYPE_OTHER);
		case CSW_ELITE: weapon_shoot_info(ent, 12, "weapons/dryfire_pistol.wav", "weapons/elite_fire.wav", 0, WEAPONTYPE_ELITE);
		case CSW_FAMAS: weapon_shoot_info(ent, 3, "weapons/dryfire_rifle.wav", "weapons/famas-1.wav", 1, WEAPONTYPE_FAMAS);
		case CSW_FIVESEVEN: weapon_shoot_info(ent, 1, "weapons/dryfire_pistol.wav", "weapons/fiveseven-1.wav", 0, WEAPONTYPE_OTHER);
		case CSW_G3SG1: weapon_shoot_info(ent, 1, "weapons/dryfire_rifle.wav", "weapons/g3sg1-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_GALIL: weapon_shoot_info(ent, 5, "weapons/dryfire_rifle.wav", "weapons/galil-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_M3: weapon_shoot_info(ent, 2, "weapons/dryfire_rifle.wav", "weapons/m3-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_XM1014: weapon_shoot_info(ent, 2, "weapons/dryfire_rifle.wav", "weapons/xm1014-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_M4A1: weapon_shoot_info(ent, 10, "weapons/dryfire_rifle.wav", "weapons/m4a1_unsil-1.wav", 1, WEAPONTYPE_M4A1);
		case CSW_M249: weapon_shoot_info(ent, 2, "weapons/dryfire_rifle.wav", "weapons/m249-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_MAC10: weapon_shoot_info(ent, 3, "weapons/dryfire_rifle.wav", "weapons/mac10-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_MP5NAVY: weapon_shoot_info(ent, 3, "weapons/dryfire_rifle.wav", "weapons/mp5-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_P90: weapon_shoot_info(ent, 3, "weapons/dryfire_rifle.wav", "weapons/p90-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_P228: weapon_shoot_info(ent, 2, "weapons/dryfire_pistol.wav", "weapons/p228-1.wav", 0, WEAPONTYPE_OTHER);
		case CSW_SCOUT: weapon_shoot_info(ent, 1, "weapons/dryfire_rifle.wav", "weapons/scout_fire-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_SG550: weapon_shoot_info(ent, 1, "weapons/dryfire_rifle.wav", "weapons/sg550-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_SG552: weapon_shoot_info(ent, 4, "weapons/dryfire_rifle.wav", "weapons/sg552-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_TMP: weapon_shoot_info(ent, 5, "weapons/dryfire_rifle.wav", "weapons/tmp-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_UMP45: weapon_shoot_info(ent, 4, "weapons/dryfire_rifle.wav", "weapons/ump45-1.wav", 1, WEAPONTYPE_OTHER);
		case CSW_USP: weapon_shoot_info(ent, 11, "weapons/dryfire_pistol.wav", "weapons/usp_unsil-1.wav", 0, WEAPONTYPE_USP);
	}

	return HAM_IGNORED;
}

stock weapon_shoot_info(ent, animation, const soundEmpty[], const soundFire[], autoShoot, weaponType)
{
	new id, clip;

	if (pev_valid(ent) != VALID_PDATA) return HAM_IGNORED;

	id = get_pdata_cbase(ent, OFFSET_PLAYER, OFFSET_ITEM_LINUX);
	clip = get_pdata_int(ent, OFFSET_CLIP, OFFSET_ITEM_LINUX);

	if (!clip) {
		emit_sound(id, CHAN_AUTO, soundEmpty, 0.8, ATTN_NORM, 0, PITCH_NORM);

		set_pdata_float(ent, OFFSET_PRIMARY_ATTACK, 0.2, OFFSET_ITEM_LINUX);

		return HAM_SUPERCEDE;
	}

	if (get_pdata_int(ent, OFFSET_SHOTS_FIRED, OFFSET_ITEM_LINUX) && !autoShoot) return HAM_SUPERCEDE;

	switch (weaponType) {
		case WEAPONTYPE_ELITE: {
			if (get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_ELITE_LEFT) {
				play_weapon_state(id, "weapons/elite_fire.wav", 6);
			}
		} case WEAPONTYPE_GLOCK18: {
			if (get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_GLOCK18_BURST_MODE) {
				play_weapon_state(id, "weapons/glock18-2.wav", 4);

				emit_sound(id, CHAN_WEAPON, "weapons/glock18-2.wav", VOL_NORM, ATTN_IDLE, 0, PITCH_LOW);
			}
		} case WEAPONTYPE_FAMAS: {
			if (get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_FAMAS_BURST_MODE) {
				play_weapon_state(id, "weapons/famas-burst.wav", 4);
			}
		} case WEAPONTYPE_M4A1: {
			if (get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_M4A1_SILENCED) {
				play_weapon_state(id, "weapons/m4a1-1.wav", 3);
			}
		} case WEAPONTYPE_USP: {
			if (get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_USP_SILENCED) {
				play_weapon_state(id, "weapons/usp1.wav", 3);
			}
		}
	}

	if (!(get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX))) {
		play_weapon_state(id, soundFire, animation);
	}

	eject_brass(id, ent);

	return HAM_IGNORED;
}

stock play_weapon_state(id, const soundFire[], animation)
{
	if (!is_user_alive(id)) return;

	emit_sound(id, CHAN_WEAPON, soundFire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	send_weapon_animation(id, get_bit(id, force) ? playerData[id][TEMP][BUY_SUBMODEL] : playerData[id][SUBMODEL], animation);
}

stock eject_brass(id, ent)
{
	static shellRifle, shotgunShell;

	if (!shellRifle || !shotgunShell) {
		shellRifle = engfunc(EngFunc_PrecacheModel, defaultShell);
		shotgunShell = engfunc(EngFunc_PrecacheModel, shotgunShell);
	}

	if (pev_valid(ent) != VALID_PDATA) return;

	switch (weapon_entity(ent)) {
		case CSW_M3, CSW_XM1014: set_pdata_int(ent, OFFSET_SHELL, shotgunShell, OFFSET_ITEM_LINUX);
		case CSW_ELITE: return;
		default: set_pdata_int(ent, OFFSET_SHELL, shellRifle, OFFSET_ITEM_LINUX);
	}

	if (get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_FAMAS_BURST_MODE || get_pdata_int(ent, OFFSET_SILENCER, OFFSET_ITEM_LINUX) & WPNSTATE_GLOCK18_BURST_MODE) {
		set_task(0.1, "eject_shell", id + TASK_SHELL);
	}

	eject_shell(id + TASK_SHELL);
}

public eject_shell(id)
{
	id -= TASK_SHELL;

	if (!is_user_alive(id) || pev_valid(id) != VALID_PDATA) return;

	set_pdata_float(id, OFFSET_EJECT, get_gametime(), OFFSET_PLAYER_LINUX);
}
#endif

stock get_weapon_skin(id, weapon)
{
	if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id) || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4 || !weapon || weapon > CSW_P90) {
		return NONE;
	}

	if (playerData[id][ACTIVE][weapon] > NONE) {
		return playerData[id][ACTIVE][weapon];
	}

	return NONE;
}

public load_data(id)
{
	if (!sqlConnected) {
		set_task(1.0, "load_data", id);

		return;
	}

	id -= TASK_DATA;

	new playerId[1], queryData[128];

	playerId[0] = id;

	switch (saveType) {
		case SAVE_NAME: formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_data` WHERE `name` = ^"%s^" LIMIT 1;", playerData[id][SAFE_NAME]);
		case SAVE_STEAM_ID: formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_data` WHERE `steamid` = ^"%s^" LIMIT 1;", playerData[id][STEAM_ID]);
	}

	SQL_ThreadQuery(sql, "load_data_handle", queryData, playerId, sizeof(playerId));
}

public load_data_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO] SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0];

	if (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "money"), playerData[id][MONEY]);

		if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "exchange"))) playerData[id][EXCHANGE_BLOCKED] = true;
		if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "menu"))) playerData[id][MENU_BLOCKED] = true;
		if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "hud"))) playerData[id][HUD_BLOCKED] = true;
		if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "skins"))) playerData[id][SKINS_BLOCKED] = true;
	} else {
		new queryData[256];

		formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_data` (`name`, `steamid`, `money`, `exchange`, `menu`, `hud`, `skins`, `online`) VALUES (^"%s^",^"%s^", '0', '0', '0', '0', '0', '0');",
			playerData[id][SAFE_NAME], playerData[id][STEAM_ID]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	playerData[id][DATA_LOADED] = true;

	save_data(id);
}

stock save_data(id, end = 0)
{
	if (!playerData[id][DATA_LOADED]) return;

	new queryData[256];

	switch (saveType) {
		case SAVE_NAME: {
			formatex(queryData, charsmax(queryData), "UPDATE `csgo_data` SET `money` = %f, `exchange` = %i, `menu` = %i,  `hud` = %i, `skins` = %i, `online` = %i, `steamid` = ^"%s^" WHERE `name` = ^"%s^";",
				playerData[id][MONEY], playerData[id][EXCHANGE_BLOCKED], playerData[id][MENU_BLOCKED], playerData[id][HUD_BLOCKED], playerData[id][SKINS_BLOCKED], end ? 0 : 1, playerData[id][STEAM_ID], playerData[id][SAFE_NAME]);
		}
		case SAVE_STEAM_ID: {
			formatex(queryData, charsmax(queryData), "UPDATE `csgo_data` SET `money` = %f, `exchange` = %i, `menu` = %i, `hud` = %i, `skins` = %i, `online` = %i, `name` = ^"%s^" WHERE `steamid` = ^"%s^";",
				playerData[id][MONEY], playerData[id][EXCHANGE_BLOCKED], playerData[id][MENU_BLOCKED], playerData[id][HUD_BLOCKED], playerData[id][SKINS_BLOCKED], end ? 0 : 1, playerData[id][SAFE_NAME], playerData[id][STEAM_ID]);
		}
	}

	switch (end) {
		case 0, 1: SQL_ThreadQuery(sql, "ignore_handle", queryData);
		case 2: {
			static error[128], errorNum, Handle:query;

			query = SQL_PrepareQuery(connection, queryData);

			if (!SQL_Execute(query)) {
				errorNum = SQL_QueryError(query, error, charsmax(error));

				log_to_file("csgo-error.log", "Save Query Nonthreaded failed. [%d] %s", errorNum, error);

				SQL_FreeHandle(query);

				return;
			}

			SQL_FreeHandle(query);
		}
	}

	if (end) playerData[id][DATA_LOADED] = false;
}

public load_skins(id)
{
	if (!sqlConnected) {
		set_task(1.0, "load_skins", id);

		return;
	}

	id -= TASK_SKINS;

	new playerId[1], queryData[128];

	playerId[0] = id;

	switch (saveType) {
		case SAVE_NAME: formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_skins` WHERE `name` = ^"%s^";", playerData[id][SAFE_NAME]);
		case SAVE_STEAM_ID: formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_skins` WHERE `steamid` = ^"%s^";", playerData[id][STEAM_ID]);
	}

	SQL_ThreadQuery(sql, "load_skins_handle", queryData, playerId, sizeof(playerId));
}

public load_skins_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO] SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0], skin[skinsInfo];

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "skin"), skin[SKIN_NAME], charsmax(skin[SKIN_NAME]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "weapon"), skin[SKIN_WEAPON_SHORT], charsmax(skin[SKIN_WEAPON_SHORT]));

		if (contain(skin[SKIN_WEAPON_SHORT], "ACTIVE") != NONE) {
			replace(skin[SKIN_WEAPON_SHORT], charsmax(skin[SKIN_WEAPON_SHORT]), " ACTIVE", "");

			set_skin(id, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME], get_skin_id(skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]));
		} else {
			new skinId = get_skin_id(skin[SKIN_NAME], skin[SKIN_WEAPON_SHORT]);

			if (skinId > NONE) {
				static playerSkin[playerSkinsInfo];

				playerSkin[SKIN_ID] = skinId;
				playerSkin[SKIN_COUNT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "count"));

				ArrayPushArray(playerSkins[id], playerSkin);
			}
		}

		SQL_NextRow(query);
	}

	playerData[id][SKINS_LOADED] = true;
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) {
			log_to_file("csgo-error.log", "[CS:GO] Could not connect to SQL database. [%d] %s", errorNum, error);
		} else if (failState == TQUERY_QUERY_FAILED) {
			log_to_file("csgo-error.log", "[CS:GO] Query failed. [%d] %s", errorNum, error);
		}
	}

	return PLUGIN_CONTINUE;
}

public Float:_csgo_get_money(id)
	return Float:playerData[id][MONEY];

public _csgo_add_money(id, Float:amount)
{
	playerData[id][MONEY] = floatmax(0.0, playerData[id][MONEY] + amount);

	save_data(id);
}

public _csgo_set_money(id, Float:amount)
{
	playerData[id][MONEY] = floatmax(0.0, amount);

	save_data(id);
}

public _csgo_get_menu(id)
	return playerData[id][MENU_BLOCKED];

public _csgo_get_hud(id)
	return !playerData[id][HUD_BLOCKED];

public _csgo_get_skin(id)
	return playerData[id][SKIN];

public _csgo_get_weapon_skin(id, weapon)
	return get_weapon_skin(id, weapon);

public _csgo_get_skin_name(id, skin, dataReturn[], dataLength)
{
	param_convert(3);

	if (skin > NONE) {
		get_skin_info(skin, SKIN_NAME, dataReturn, dataLength);
	} else {
		formatex(dataReturn, dataLength, "%L", id, "CSGO_CORE_DEFAULT");
	}
}

public _csgo_get_current_skin_name(id, dataReturn[], dataLength)
{
	param_convert(2);

	if (get_weapon_skin_name(id, playerData[id][TEMP][WEAPON_ENT], dataReturn, dataLength, 0, 1)) return;

	if (playerData[id][SKIN] > NONE) {
		get_skin_info(playerData[id][SKIN], SKIN_NAME, dataReturn, dataLength);
	} else {
		formatex(dataReturn, dataLength, "%L", id, "CSGO_CORE_DEFAULT");
	}
}

public bool:_csgo_get_min_players()
{
	static players[32], playersCount;

	switch (minPlayerFilter) {
		case 0: playersCount = get_playersnum();
		case 1: get_players(players, playersCount, "c");
		case 2: get_players(players, playersCount, "h");
		case 3: get_players(players, playersCount, "ch");
	}

	return playersCount >= minPlayers;
}

public _csgo_give_random_skin(id)
{
	new skin[skinsInfo], skinId = random_num(0, ArraySize(skins) - 1);

	ArrayGetArray(skins, skinId, skin);

	add_skin(id, skinId, skin[SKIN_WEAPON_SHORT], skin[SKIN_NAME]);
}

stock get_weapon_skin_name(id, ent, dataReturn[], dataLength, weapon = 0, check = 0)
{
	static ownerName[32], weaponName[32], skinWeapon[32], defaultName[32];

	formatex(defaultName, charsmax(defaultName), "%L", id, "CSGO_CORE_DEFAULT");

	if (is_valid_ent(ent)) {
		new weaponOwner = entity_get_int(ent, EV_INT_iuser1);

		if (is_user_connected(weaponOwner) && !is_user_hltv(weaponOwner) && !is_user_bot(weaponOwner)) {
			new weaponSkin = entity_get_int(ent, EV_INT_iuser2);

			if (weaponSkin > NONE) {
				get_skin_info(weaponSkin, SKIN_WEAPON_SHORT, skinWeapon, charsmax(skinWeapon));

				if (!weapon || weapon == get_weapon_id(skinWeapon)) {
					get_skin_info(weaponSkin, SKIN_NAME, dataReturn, dataLength);
				} else {
					entity_set_int(ent, EV_INT_iuser1, 0);
					entity_set_int(ent, EV_INT_iuser2, NONE);

					copy(dataReturn, dataLength, defaultName);
				}
			} else {
				copy(dataReturn, dataLength, defaultName);
			}

			if (check && weaponOwner != id) {
				get_user_name(weaponOwner, ownerName, charsmax(ownerName));

				format(dataReturn, dataLength, "%s (%s)", dataReturn, ownerName);

				return true;
			}
		}

		if (weapon) {
			get_weaponname(weapon, weaponName, charsmax(weaponName));

			strtoupper(weaponName);

			if (equal(dataReturn, defaultName) || !dataReturn[0]) {
				formatex(dataReturn, dataLength, weaponName[7]);
			} else if (!is_skin_m4a4(dataReturn)) {
				format(dataReturn, dataLength, "%s | %s", weaponName[7], dataReturn);
			}
		}
	}

	return false;
}

stock Float:get_multiplier(id, target = 0)
{
	if (is_user_bot(target)) return botMultiplier;
	else if (csgo_get_user_svip(id)) return svipMultiplier;
	else if (csgo_get_user_vip(id)) return vipMultiplier;
	else return 1.0;
}

stock get_weapon_skins_count(id, weapon[], action = 0)
{
	new skin[skinsInfo], allName[32], weaponSkinsCount = 0;

	formatex(allName, charsmax(allName), "%L", id, "CSGO_CORE_ALL");

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (action == CHANCE && skin[SKIN_RARITY] == RARITY_IMMORTAL) continue;

		if (equal(weapon, skin[SKIN_WEAPON]) || equal(weapon, allName)) {
			weaponSkinsCount += action == CHANCE ? get_skin_chance(skin[SKIN_RARITY]) : 1;
		}
	}

	return weaponSkinsCount;
}

stock get_missing_weapon_skins_count(id, weapon[], action = 0)
{
	new skin[skinsInfo], marketSkin[marketInfo], allName[32], playerSkinsCount = 0, skinId;

	formatex(allName, charsmax(allName), "%L", id, "CSGO_CORE_ALL");

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID);

		ArrayGetArray(skins, skinId, skin);

		if (action == CHANCE && skin[SKIN_RARITY] == RARITY_IMMORTAL) continue;

		if (equal(weapon, skin[SKIN_WEAPON]) || equal(weapon, allName)) {
			playerSkinsCount += action == CHANCE ? get_skin_chance(skin[SKIN_RARITY]) : 1;
		}
	}

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if (marketSkin[MARKET_OWNER] == id) {
			ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

			if (action == CHANCE && skin[SKIN_RARITY] == RARITY_IMMORTAL) continue;

			if (equal(weapon, skin[SKIN_WEAPON]) || equal(weapon, allName)) {
				playerSkinsCount += action == CHANCE ? get_skin_chance(skin[SKIN_RARITY]) : 1;
			}
		}
	}

	return get_weapon_skins_count(id, weapon, action) - playerSkinsCount;
}

stock get_skin_chance(rarity)
{
	return power(2, RARITY_EXCEEDINGLY_RARE - rarity);
}

stock get_weapon_id(weapon[])
{
	if (is_skin_knife(weapon)) {
		return CSW_KNIFE;
	}

	if (is_skin_m4a4(weapon)) {
		return CSW_M4A1;
	}

	new weaponName[32];

	format(weaponName, charsmax(weaponName), "weapon_%s", weapon);

	strtolower(weaponName);

	return get_weaponid(weaponName);
}

stock is_skin_m4a4(skinName[])
{
	return containi(skinName, M4A4) != -1;
}

stock is_skin_knife(skinName[])
{
	return containi(skinName, KNIFE) != -1;
}

stock has_skin(id, skin, check = 0)
{
	if (!check) {
		static marketSkin[marketInfo];

		for (new i = 0; i < ArraySize(market); i++) {
			ArrayGetArray(market, i, marketSkin);

			if (marketSkin[MARKET_OWNER] == id && marketSkin[MARKET_SKIN] == skin) {
				return 1;
			}
		}
	}

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		if (get_player_skin_info(id, i, SKIN_ID) == skin) {
			return check ? i : 1;
		}
	}

	return check ? NONE : 0;
}

stock change_local_skin(id, skinId, add = 0)
{
	new playerSkin[playerSkinsInfo], skinIndex = has_skin(id, skinId, 1);

	if (skinIndex > NONE) {
		ArrayGetArray(playerSkins[id], skinIndex, playerSkin);

		if (!add) {
			playerSkin[SKIN_COUNT]--;

			if (playerSkin[SKIN_COUNT] <= 0) {
				ArrayDeleteItem(playerSkins[id], skinIndex);

				return false;
			}
		} else playerSkin[SKIN_COUNT]++;

		ArraySetArray(playerSkins[id], skinIndex, playerSkin);
	} else if (add) {
		playerSkin[SKIN_ID] = skinId;
		playerSkin[SKIN_COUNT] = 1;

		ArrayPushArray(playerSkins[id], playerSkin);
	} else {
		return false;
	}

	return true;
}

stock remove_skin(id, skinId, weapon[], skin[])
{
	if (!playerData[id][SKINS_LOADED]) return;

	new queryData[256], skinSafeName[64];

	mysql_escape_string(skin, skinSafeName, charsmax(skinSafeName));

	if (!change_local_skin(id, skinId)) {
		switch (saveType) {
			case SAVE_NAME: formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_skins` WHERE name = ^"%s^" AND weapon = '%s' AND skin = '%s'", playerData[id][SAFE_NAME], weapon, skinSafeName);
			case SAVE_STEAM_ID: formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_skins` WHERE steamid = ^"%s^" AND weapon = '%s' AND skin = '%s'", playerData[id][STEAM_ID], weapon, skinSafeName);
		}
	} else {
		switch (saveType) {
			case SAVE_NAME: formatex(queryData, charsmax(queryData), "UPDATE `csgo_skins` SET count = count - 1, steamid = ^"%s^" WHERE name = ^"%s^" AND weapon = '%s' AND skin = '%s';", playerData[id][STEAM_ID], playerData[id][SAFE_NAME], weapon, skinSafeName);
			case SAVE_STEAM_ID: formatex(queryData, charsmax(queryData), "UPDATE `csgo_skins` SET count = count - 1, name = ^"%s^" WHERE steamid = ^"%s^" AND weapon = '%s' AND skin = '%s';", playerData[id][SAFE_NAME], playerData[id][STEAM_ID], weapon, skinSafeName);
		}
	}

	if (playerData[id][ACTIVE][get_weapon_id(weapon)] == skinId) {
		set_skin(id, weapon);

		remove_active_skin(id, weapon);
	}

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock remove_active_skin(id, weapon[])
{
	if (!playerData[id][SKINS_LOADED]) return;

	new queryData[256];

	switch (saveType) {
		case SAVE_NAME: formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_skins` WHERE name = ^"%s^" AND weapon = '%s ACTIVE';", playerData[id][SAFE_NAME], weapon);
		case SAVE_STEAM_ID: formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_skins` WHERE steamid = ^"%s^" AND weapon = '%s ACTIVE';", playerData[id][STEAM_ID], weapon);
	}

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock add_skin(id, skinId, weapon[], skin[])
{
	if (!playerData[id][SKINS_LOADED] || (!multipleSkins && has_skin(id, skinId))) return;

	new queryData[256], skinSafeName[64];

	mysql_escape_string(skin, skinSafeName, charsmax(skinSafeName));

	formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_skins` (`name`, `steamid`, `weapon`, `skin`) VALUES (^"%s^", ^"%s^", '%s', '%s') ON DUPLICATE KEY UPDATE count = count + 1;", playerData[id][SAFE_NAME], playerData[id][STEAM_ID], weapon, skinSafeName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if (skinId > NONE) {
		change_local_skin(id, skinId, 1);

		if (playerData[id][ACTIVE][get_weapon_id(weapon)] == NONE) {
			set_skin(id, weapon, skin, skinId, 1);
		}
	}
}

stock set_skin(id, weapon[], skin[] = "", skinId = NONE, active = 0)
{
	if (skinId >= ArraySize(skins) || skinId < NONE) return;

	new weaponId = get_weapon_id(weapon);

	playerData[id][ACTIVE][weaponId] = skinId;

	if (playerData[id][TEMP][WEAPON] == weaponId) {
		reset_skin(id);
	}

	if (active && playerData[id][SKINS_LOADED]) {
		new queryData[256], skinSafeName[64];

		mysql_escape_string(skin, skinSafeName, charsmax(skinSafeName));

		formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_skins` (`name`, `steamid`, `weapon`, `skin`) VALUES (^"%s^", ^"%s^", '%s ACTIVE', '%s');", playerData[id][SAFE_NAME], playerData[id][STEAM_ID], weapon, skinSafeName);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}
}

stock get_skin_id(const name[], const weapon[])
{
	static skin[skinsInfo];

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(name, skin[SKIN_NAME]) && equal(weapon, skin[SKIN_WEAPON_SHORT])) {
			return i;
		}
	}

	return NONE;
}

stock get_skin_info(skinId, info, dataReturn[] = "", dataLength = 0)
{
	static skin[skinsInfo];

	ArrayGetArray(skins, skinId, skin);

	if (info == SKIN_NAME || info == SKIN_WEAPON || info == SKIN_MODEL) {
		copy(dataReturn, dataLength, skin[info]);

		return 0;
	}

	return skin[info];
}

stock get_player_skin_info(id, skinId, info)
{
	static playerSkin[playerSkinsInfo];

	ArrayGetArray(playerSkins[id], skinId, playerSkin);

	return playerSkin[info];
}

stock get_market_skins(id)
{
	if (!is_user_connected(id)) return 0;

	new marketSkin[marketInfo], amount = 0;

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if (marketSkin[MARKET_OWNER] == id) amount++;
	}

	return amount;
}

stock check_market_skin(marketId, skinId, ownerId)
{
	static marketSkin[marketInfo];

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if (marketSkin[MARKET_ID] == marketId && marketSkin[MARKET_SKIN] == skinId && marketSkin[MARKET_OWNER] == ownerId) {
			return i;
		}
	}

	return NONE;
}

stock remove_seller(id)
{
	static marketSkin[marketInfo];

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if (marketSkin[MARKET_OWNER] == id) {
			ArrayDeleteItem(market, i);

			i -= 1;
		}
	}
}

stock fm_get_user_aiming_ent(id, const className[])
{
	if (!pev_valid(id) || !is_user_alive(id)) return 0;

	new Float:origin[3];

	fm_get_aim_origin(id, origin);

	new ent = -1, tempClass[32];

	while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, origin, 0.005))) {
		if (!pev_valid(ent)) continue;

		pev(ent, pev_classname, tempClass, charsmax(tempClass));

		if (equali(className, tempClass)) return ent;
	}

	return 0;
}

stock explode_num(const string[], const character, output[], const maxParts)
{
	new currentPart = 0, stringLength = strlen(string), currentLength = 0, number[32];

	do {
		currentLength += (1 + copyc(number, charsmax(number), string[currentLength], character));

		output[currentPart++] = str_to_num(number);
	} while (currentLength < stringLength && currentPart < maxParts);
}
