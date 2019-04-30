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

#define PLUGIN "CS:GO Mod"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_SKINS 3045
#define TASK_DATA 4592
#define TASK_AIM 5309
#define TASK_AD 6234

#define WEAPON_ALL 31

new const commandSkins[][] = { "skiny", "say /skins", "say_team /skins", "say /skin", "say_team /skin", "say /skiny",
	"say_team /skiny", "say /modele", "say_team /modele", "say /model", "say_team /model", "say /jackpot", "say_team /jackpot" };
new const commandHelp[][] = { "pomoc", "say /pomoc", "say_team /pomoc", "say /help", "say_team /help" };
new const commandSet[][] = { "ustaw", "say /ustaw", "say_team /ustaw", "say /set", "say_team /set" };
new const commandBuy[][] = { "kup", "say /kup", "say_team /kup", "say /buy", "say_team /buy", "say /sklep", "say_team /sklep", "say /shop", "say_team /shop" };
new const commandRandom[][] = { "losuj", "say /los", "say_team /los", "say /losuj", "say_team /losuj" };
new const commandExchange[][] = { "wymien", "say /exchange", "say_team /exchange", "say /zamien", "say_team /zamien", "say /wymien", "say_team /wymien", "say /wymiana", "say_team /wymiana" };
new const commandGive[][] = { "daj", "say /give", "say_team /give", "say /oddaj", "say_team /oddaj", "say /daj", "say_team /daj" };
new const commandMarket[][] = { "rynek", "say /market", "say_team /market", "say /rynek", "say_team /rynek" };
new const commandSell[][] = { "wystaw", "say /wystaw", "say_team /wystaw" };
new const commandPurchase[][] = { "wykup", "say /wykup", "say_team /wykup" };
new const commandWithdraw[][] = { "wycofaj", "say /wycofaj", "say_team /wycofaj" };

new const defaultSkin[][] = { "", "models/csr_csgo/default/v_p228.mdl", "", "models/csr_csgo/default/v_scout.mdl", "", "models/csr_csgo/default/v_xm1014.mdl", "",
	"models/csr_csgo/default/v_mac10.mdl", "models/csr_csgo/default/v_aug2.mdl", "", "models/csr_csgo/default/v_elite.mdl", "models/csr_csgo/default/v_fiveseven2.mdl",
	"models/csr_csgo/default/v_ump45.mdl", "models/csr_csgo/default/v_sg5502.mdl", "models/csr_csgo/default/v_galil.mdl", "models/csr_csgo/default/v_famas2.mdl",
	"models/csr_csgo/default/v_usp2.mdl","models/csr_csgo/default/v_glock18.mdl", "models/csr_csgo/default/v_awp.mdl", "models/csr_csgo/default/v_mp5navy.mdl",
	"models/csr_csgo/default/v_m249.mdl", "models/csr_csgo/default/v_m3.mdl", "models/csr_csgo/default/v_m4a12.mdl", "models/csr_csgo/default/v_tmp2.mdl",
	"models/csr_csgo/default/v_g3sg1.mdl", "", "models/csr_csgo/default/v_deagle.mdl", "models/csr_csgo/default/v_sg552.mdl",
	"models/csr_csgo/default/v_ak47.mdl", "models/csr_csgo/default/v_knife.mdl", "models/csr_csgo/default/v_p90.mdl", "models/csr_csgo/default/v_knife_t.mdl"
};

new const weaponSlots[] = { -1, 2, -1, 1, 4, 1, 5, 1, 1, 4, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 4, 2, 1, 1, 3, 1 };
new const maxBPAmmo[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 };
new const ammoType[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp", "556nato", "556nato", "556nato",
						"45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot", "556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" };

enum _:tempInfo { WEAPON, WEAPONS, WEAPON_ENT, EXCHANGE_PLAYER, EXCHANGE_SKIN, EXCHANGE_FOR_SKIN, GIVE_PLAYER, SALE_SKIN };
enum _:playerInfo { ACTIVE[CSW_P90 + 1], Float:MONEY, SKIN, bool:SKINS_LOADED, bool:DATA_LOADED, bool:SKINS_DISABLED, bool:EXCHANGE_BLOCKED, bool:MENU_BLOCKED, TEMP[tempInfo], NAME[32], SAFE_NAME[64] };
enum _:playerSkinsInfo { SKIN_ID, SKIN_COUNT };
enum _:skinsInfo { SKIN_NAME[64], SKIN_WEAPON[32], SKIN_MODEL[64], SKIN_PRICE, SKIN_CHANCE };
enum _:marketInfo { MARKET_ID, MARKET_SKIN, MARKET_OWNER, Float:MARKET_PRICE };

new playerData[MAX_PLAYERS + 1][playerInfo], Array:playerSkins[MAX_PLAYERS + 1], Float:randomSkinPrice[WEAPON_ALL + 1], overallSkinChance[WEAPON_ALL + 1], Array:skins, Array:weapons, Array:market,
	Handle:sql, Handle:connection, marketSkins, multipleSkins, defaultSkins, skinChance, skinChanceSVIP, Float:skinChancePerMember, maxMarketSkins, Float:marketCommision,
	Float:killReward, Float:killHSReward, Float:bombReward, Float:defuseReward, Float:hostageReward, Float:winReward, minPlayers, bool:end, bool:sqlConnected,
	sqlHost[64], sqlUser[64], sqlPassword[64], sqlDatabase[64];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("csgo_version", VERSION, FCVAR_SERVER);

	bind_pcvar_string(create_cvar("csgo_sql_host", "localhost", FCVAR_SPONLY | FCVAR_PROTECTED), sqlHost, charsmax(sqlHost));
	bind_pcvar_string(create_cvar("csgo_sql_user", "user", FCVAR_SPONLY | FCVAR_PROTECTED), sqlUser, charsmax(sqlUser));
	bind_pcvar_string(create_cvar("csgo_sql_pass", "password", FCVAR_SPONLY | FCVAR_PROTECTED), sqlPassword, charsmax(sqlPassword));
	bind_pcvar_string(create_cvar("csgo_sql_db", "database", FCVAR_SPONLY | FCVAR_PROTECTED), sqlDatabase, charsmax(sqlDatabase));

	bind_pcvar_num(create_cvar("csgo_multiple_skins", "1"), multipleSkins);
	bind_pcvar_num(create_cvar("csgo_default_skins", "1"), defaultSkins);
	bind_pcvar_num(create_cvar("csgo_min_players", "4"), minPlayers);
	bind_pcvar_num(create_cvar("csgo_max_market_skins", "5"), maxMarketSkins);
	bind_pcvar_num(create_cvar("csgo_skin_chance", "20"), skinChance);
	bind_pcvar_num(create_cvar("csgo_svip_skin_chance", "25"), skinChanceSVIP);
	bind_pcvar_float(create_cvar("csgo_market_commision", "5"), marketCommision);
	bind_pcvar_float(create_cvar("csgo_clan_skin_chance_per_member", "1"), skinChancePerMember);
	bind_pcvar_float(create_cvar("csgo_kill_reward", "0.35"), killReward);
	bind_pcvar_float(create_cvar("csgo_killhs_reward", "0.15"), killHSReward);
	bind_pcvar_float(create_cvar("csgo_bomb_reward", "2.0"), bombReward);
	bind_pcvar_float(create_cvar("csgo_defuse_reward", "2.0"), defuseReward);
	bind_pcvar_float(create_cvar("csgo_hostages_reward", "2.0"), hostageReward);
	bind_pcvar_float(create_cvar("csgo_round_reward", "0.5"), winReward);

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

	register_concmd("CENA_SKINA", "set_skin_price");

	register_concmd("csgo_add_money", "cmd_add_money", ADMIN_ADMIN, "<player> <money>");

	register_logevent("log_event_operation", 3, "1=triggered");

	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("SendAudio", "t_win_round" , "a", "2&%!MRAD_terwin");
	register_event("SendAudio", "ct_win_round", "a", "2=%!MRAD_ctwin");
	register_event("SetFOV", "set_fov" , "be");
	register_event("Money", "event_money", "be");

	register_message(SVC_INTERMISSION, "message_intermission");

	register_forward(FM_SetModel, "set_model", 0);

	RegisterHam(Ham_AddPlayerItem, "player", "add_player_item", 1);
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);

	new const weapons[][] = { "weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
		"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil",
		"weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
		"weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" };

	for (new i = 0; i < sizeof weapons; i++) RegisterHam(Ham_Item_Deploy, weapons[i], "weapon_deploy_post", 1);
}

public plugin_precache()
{
	skins = ArrayCreate(skinsInfo);
	market = ArrayCreate(marketInfo);
	weapons = ArrayCreate(32, 32);

	new file[128];

	get_localinfo("amxx_configsdir", file, charsmax(file));
	format(file, charsmax(file), "%s/csgo_skins.ini", file);

	if (!file_exists(file)) set_fail_state("[CS:GO] Brak pliku csgo_skins.ini!");

	new skin[skinsInfo], lineData[256], tempValue[4][64], bool:error, fileOpen = fopen(file, "r");

	while (!feof(fileOpen)) {
		fgets(fileOpen, lineData, charsmax(lineData)); trim(lineData);

		if (lineData[0] == ';' || lineData[0] == '^0' || lineData[0] == '/') continue;

		if (lineData[0] == '[') {
			replace_all(lineData, charsmax(lineData), "[", "");
			replace_all(lineData, charsmax(lineData), "]", "");

			split(lineData, skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), tempValue[0], charsmax(tempValue[]), " - ");

			ArrayPushString(weapons, skin[SKIN_WEAPON]);

			continue;
		} else {
			parse(lineData, tempValue[0], charsmax(tempValue[]), tempValue[1], charsmax(tempValue[]), tempValue[2], charsmax(tempValue[]), tempValue[3], charsmax(tempValue[]));

			formatex(skin[SKIN_NAME], charsmax(skin[SKIN_NAME]), tempValue[0]);
			formatex(skin[SKIN_MODEL], charsmax(skin[SKIN_MODEL]), tempValue[1]);

			skin[SKIN_PRICE] = str_to_num(tempValue[2]);
			skin[SKIN_CHANCE] = (str_to_num(tempValue[3]) > 1 ? str_to_num(tempValue[3]) : 1);

			if (!file_exists(skin[SKIN_MODEL])) {
				log_to_file("csgo-error.log", "[CS:GO] Plik %s nie istnieje!", skin[SKIN_MODEL]);

				error = true;
			} else precache_model(skin[SKIN_MODEL]);

			ArrayPushArray(skins, skin);
		}
	}

	fclose(fileOpen);

	if (error) set_fail_state("[CS:GO] Nie zaladowano wszystkich skinow. Sprawdz logi bledow!");

	if (!ArraySize(skins)) set_fail_state("[CS:GO] Nie zaladowano zadnego skina. Sprawdz plik konfiguracyjny csgo_skins.ini!");

	for (new i = 1; i <= MAX_PLAYERS; i++) playerSkins[i] = ArrayCreate(playerSkinsInfo);

	for (new i = 0; i < sizeof(defaultSkin); i++) {
		if (!defaultSkin[i][0]) continue;

		if (!file_exists(defaultSkin[i])) {
			log_to_file("csgo-error.log", "[CS:GO] Plik %s nie istnieje!", defaultSkin[i]);

			error = true;
		} else precache_model(defaultSkin[i]);
	}

	if (error) set_fail_state("[CS:GO] Nie zaladowano wszystkich standardowych skinow. Sprawdz logi bledow!");

	set_task(0.1, "load_skins_details");
}

public load_skins_details()
{
	new file[128];

	get_localinfo("amxx_configsdir", file, charsmax(file));
	format(file, charsmax(file), "%s/csgo_skins.ini", file);

	if (!file_exists(file)) set_fail_state("[CS:GO] Brak pliku csgo_skins.ini!");

	new skin[skinsInfo], lineData[256], tempValue[4][64], tempPrice[16], fileOpen = fopen(file, "r");

	while (!feof(fileOpen)) {
		fgets(fileOpen, lineData, charsmax(lineData)); trim(lineData);

		if (lineData[0] == ';' || lineData[0] == '^0' || lineData[0] == '/') continue;

		if (lineData[0] == '[') {
			replace_all(lineData, charsmax(lineData), "[", "");
			replace_all(lineData, charsmax(lineData), "]", "");

			split(lineData, skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), tempPrice, charsmax(tempPrice), " - ");

			randomSkinPrice[equal(skin[SKIN_WEAPON], "Wszystkie") ? WEAPON_ALL : get_weapon_id(skin[SKIN_WEAPON])] = str_to_float(tempPrice);

			continue;
		} else {
			parse(lineData, tempValue[0], charsmax(tempValue[]), tempValue[1], charsmax(tempValue[]), tempValue[2], charsmax(tempValue[]), tempValue[3], charsmax(tempValue[]));

			overallSkinChance[get_weapon_id(skin[SKIN_WEAPON])] += (str_to_num(tempValue[3]) > 1 ? str_to_num(tempValue[3]) : 1);
		}
	}
}


public plugin_cfg()
{
	new configPath[64], host[32], user[32], pass[32], db[32], error[128], errorNum;

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
		log_to_file("csgo-error.log", "Error: %s (%i)", error, errorNum);

		return;
	}

	new queryData[192];

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_skins` (name VARCHAR(35), weapon VARCHAR(35), skin VARCHAR(64), count INT NOT NULL DEFAULT 1, PRIMARY KEY(name, weapon, skin))");

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_data` (name VARCHAR(35), money FLOAT NOT NULL, disabled INT NOT NULL, exchange INT NOT NULL, menu INT NOT NULL, online INT NOT NULL, PRIMARY KEY(name))");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);

	sqlConnected = true;
}

public plugin_natives()
{
	register_native("csgo_get_money", "_csgo_get_money", 1);
	register_native("csgo_add_money", "_csgo_add_money", 1);
	register_native("csgo_set_money", "_csgo_set_money", 1);

	register_native("csgo_get_menu", "_csgo_get_menu", 1);
	register_native("csgo_get_skin", "_csgo_get_skin", 1);
	register_native("csgo_get_weapon_skin", "_csgo_get_weapon_skin", 1);
	register_native("csgo_get_skin_name", "_csgo_get_skin_name", 1);
	register_native("csgo_get_current_skin_name", "_csgo_get_current_skin_name", 1);
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
	for (new i = 1; i <= CSW_P90; i++) playerData[id][ACTIVE][i] = -1;

	playerData[id][MONEY] = 0.0;
	playerData[id][SKIN] = -1;

	ArrayClear(playerSkins[id]);

	for (new i = SKINS_LOADED; i <= MENU_BLOCKED; i++) playerData[id][i] = false;

	if (is_user_hltv(id) || is_user_bot(id)) return;

	get_user_name(id, playerData[id][NAME], charsmax(playerData[][NAME]));

	mysql_escape_string(playerData[id][NAME], playerData[id][SAFE_NAME], charsmax(playerData[][SAFE_NAME]));

	set_task(0.1, "load_data", id + TASK_DATA);
	set_task(0.1, "load_skins", id + TASK_SKINS);
	set_task(15.0, "show_advertisement", id + TASK_AD);
}

public show_advertisement(id)
{
	id -= TASK_AD;

	client_print_color(id, id, "^x04[CS:GO]^x01 Grasz na serwerze^x03 %s^x01 stworzonym przez^x03 %s^x01.", PLUGIN, AUTHOR);
	client_print_color(id, id, "W celu uzyskania informacji o komendach wpisz^x03 /menu^x01 (klawisz^x03 ^"v^"^x01).");
}

public skins_menu(id)
{
	if (!csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	new menuData[64], menu = menu_create("\yMenu \rSkinow\w:", "skins_menu_handle");

	menu_additem(menu, "\wUstaw \ySkin \r(/ustaw)");
	menu_additem(menu, "\wKup \ySkin \r(/kup)");
	menu_additem(menu, "\wWylosuj \ySkin \r(/losuj)");
	menu_additem(menu, "\wRynek \ySkinow \r(/rynek)");
	menu_additem(menu, "\wDoladuj \yPieniadze \r(/sklepsms)");
	menu_additem(menu, "\wTransferuj \yPieniadze \r(/transfer)");
	menu_additem(menu, "\wWymien \ySkin \r(/wymien)");
	menu_additem(menu, "\wOddaj \ySkin \r(/oddaj)");

	formatex(menuData, charsmax(menuData), "\wMenu \yKupowania \r[%s]", playerData[id][MENU_BLOCKED] ? "Standardowe" : "Nowe");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wPropozycje \yWymiany \r[%s]", playerData[id][EXCHANGE_BLOCKED] ? "Wylaczone" : "Wlaczone");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wWyswietlanie \ySkinow \r[%s]", playerData[id][SKINS_DISABLED] ? "Wylaczone" : "Wlaczone");
	menu_additem(menu, menuData);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

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
		case 0, 1, 2: choose_weapon_menu(id, item);
		case 3: market_menu(id);
		case 4: client_cmd(id, "say /sklepsms");
		case 5: client_cmd(id, "transfer");
		case 6: exchange_skin_menu(id);
		case 7: give_skin_menu(id);
		case 8: {
			playerData[id][MENU_BLOCKED] = !playerData[id][MENU_BLOCKED];

			client_print_color(id, id, "^x04[CS:GO]^x01 Ustawiles^x03 %s^x01 menu kupowania.", playerData[id][MENU_BLOCKED] ? "standardowe" : "nowe");

			save_data(id);

			skins_menu(id);
		} case 9: {
			playerData[id][EXCHANGE_BLOCKED] = !playerData[id][EXCHANGE_BLOCKED];

			client_print_color(id, id, "^x04[CS:GO]^x01 Mozliwosc wysylania ci ofert wymiany zostala^x03 %s^x01.", playerData[id][EXCHANGE_BLOCKED] ? "wylaczona" : "wlaczona");

			save_data(id);

			skins_menu(id);
		} case 10: {
			playerData[id][SKINS_DISABLED] = !playerData[id][SKINS_DISABLED];

			client_print_color(id, id, "^x04[CS:GO]^x01 Wyswietlanie skinow zostalo^x03 %s^x01.", playerData[id][SKINS_DISABLED] ? "wylaczone" : "wlaczone");

			save_data(id);

			skins_menu(id);
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public skins_help(id)
{
	show_motd(id, "skiny.txt", "CS:GO Mod - Pomoc");

	skins_menu(id);

	return PLUGIN_HANDLED;
}

public set_skin_menu(id)
{
	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, 0);

	return PLUGIN_HANDLED;
}

public buy_skin_menu(id)
{
	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, 1);

	return PLUGIN_HANDLED;
}

public random_skin_menu(id)
{
	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, 2);

	return PLUGIN_HANDLED;
}

public choose_weapon_menu(id, type)
{
	new menuData[32], tempType[2], menu = menu_create("\yWybierz \rBron\w:", "choose_weapon_menu_handle");

	num_to_str(type, tempType, charsmax(tempType));

	for (new i = type == 2 ? 0 : (randomSkinPrice[WEAPON_ALL] > 0.0 ? 1 : 0); i < ArraySize(weapons); i++) {
		ArrayGetString(weapons, i, menuData, charsmax(menuData));

		menu_additem(menu, menuData, tempType);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public choose_weapon_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[32], itemType[2], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemType, charsmax(itemType), itemData, charsmax(itemData), itemCallback);

	switch (str_to_num(itemType)) {
		case 0: set_weapon_skin(id, itemData);
		case 1: buy_weapon_skin(id, itemData);
		case 2: random_weapon_skin(id, itemData);
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public set_weapon_skin(id, weapon[])
{
	new menuData[64], tempId[5], skin[skinsInfo], skinId, skinsCount, menu = menu_create("\yWybierz \rSkin\w:", "set_weapon_skin_handle"), callback = menu_makecallback("set_weapon_skin_callback");

	menu_additem(menu, "Domyslny", weapon);

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(weapon, skin[SKIN_WEAPON])) {
			skinId = has_skin(id, i, 1);
			skinsCount = 0;

			if (multipleSkins && skinId != -1) skinsCount = get_player_skin_info(id, skinId, SKIN_COUNT);

			if (skinsCount > 1) formatex(menuData, charsmax(menuData), "%s \y(%s) \r(%i)", skin[SKIN_NAME], skin[SKIN_WEAPON], skinsCount);
			else formatex(menuData, charsmax(menuData), "%s \y(%s)", skin[SKIN_NAME], skin[SKIN_WEAPON]);

			num_to_str(i, tempId, charsmax(tempId));

			menu_additem(menu, menuData, tempId, _, callback);
		}
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public set_weapon_skin_callback(id, menu, item)
{
	static itemData[5], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	return has_skin(id, str_to_num(itemData), 1) > -1 ? ITEM_ENABLED : ITEM_DISABLED;
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

		remove_active_skin(id, skin[SKIN_WEAPON]);

		set_skin(id, skin[SKIN_WEAPON], skin[SKIN_NAME], skinId, 1);

		client_print_color(id, id, "^x04[CS:GO]^x01 Twoj nowy skin^x03 %s^x01 to^x03 %s^x01.", skin[SKIN_WEAPON], skin[SKIN_NAME]);
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany skin zostanie^x03 od tego momentu^x01 ustawiony dla tej broni po kazdym zakupie^x01.");
	} else {
		new itemData[16], itemAccess, itemCallback;

		menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

		remove_active_skin(id, itemData);

		set_skin(id, itemData);

		client_print_color(id, id, "^x04[CS:GO]^x01 Przywrociles domyslny skin broni^x03 %s^x01.", itemData);
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany skin zostanie^x03 od tego momentu^x01 ustawiony dla tej broni po kazdym zakupie^x01.");
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public buy_weapon_skin(id, weapon[])
{
	new menuData[64], skin[skinsInfo], tempId[5], count, menu = menu_create("\yWybierz \rSkin\w:", "buy_weapon_skin_handle");

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(weapon, skin[SKIN_WEAPON])) {
			if (!multipleSkins && has_skin(id, i)) continue;

			num_to_str(i, tempId, charsmax(tempId));

			formatex(menuData, charsmax(menuData), "\y%s \w- \r%i Euro", skin[SKIN_NAME], skin[SKIN_PRICE]);

			menu_additem(menu, menuData, tempId);

			count++;
		}
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!count) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Do kupienia nie ma^x03 zadnych^x01 skinow tej broni.");

		menu_destroy(menu);
	} else menu_display(id, menu);
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
		client_print_color(id, id, "^x04[CS:GO]^x01 Juz posiadasz ten skin!");

		return PLUGIN_HANDLED;
	}

	new skin[skinsInfo];

	ArrayGetArray(skins, skinId, skin);

	if (playerData[id][MONEY] < skin[SKIN_PRICE]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz wystarczajacej ilosci^x03 pieniedzy^x01.");

		return PLUGIN_HANDLED;
	}

	playerData[id][MONEY] -= skin[SKIN_PRICE];

	save_data(id);

	add_skin(id, skinId, skin[SKIN_WEAPON], skin[SKIN_NAME]);

	client_print_color(id, id, "^x04[CS:GO]^x01 Pomyslnie zakupiles skin^x03 %s^x01 do broni^x03 %s^x01.", skin[SKIN_NAME], skin[SKIN_WEAPON]);

	log_to_file("csgo-buy.log", "Gracz %s kupil skina %s (%s)", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON]);

	skins_menu(id);

	return PLUGIN_HANDLED;
}

public random_weapon_skin(id, weapon[])
{
	new menuData[256], Float:chance = (csgo_get_user_svip(id) ? skinChanceSVIP : skinChance) + csgo_get_clan_members(csgo_get_user_clan(id)) * skinChancePerMember;

	if (equal(weapon, "Wszystkie")) {
		formatex(menuData, charsmax(menuData), "\yCzy chcesz sprobowac \rwylosowac \yskina dowolnej broni za \r%.2f Euro\y?\w^nSzansa na wylosowanie: \y%.2f%%\w.", randomSkinPrice[WEAPON_ALL], chance);
	} else {
		formatex(menuData, charsmax(menuData), "\yCzy chcesz sprobowac \rwylosowac \yskina broni %s za \r%.2f Euro\y?\w^nSzansa na wylosowanie: \y%.2f%%\w.", weapon, randomSkinPrice[get_weapon_id(weapon)], chance);
	}

	new menu = menu_create(menuData, "random_weapon_skin_handle");

	menu_additem(menu, "\yTak", weapon);
	menu_additem(menu, "Nie^n");

	formatex(menuData, charsmax(menuData), "\wAby zwiekszyc szanse wylosowania kup \ySVIPa \r(+%i%%)^n\wlub \ydolacz do klanu \r(+%.2f%% za kazdego czlonka)\w.", skinChanceSVIP - skinChance, skinChancePerMember);

	menu_addtext(menu, menuData);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

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

	new weapon[32], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, weapon, charsmax(weapon), _, _, itemCallback);

	if (!multipleSkins && !get_missing_weapon_skins_count(id, weapon)) {
		if (equal(weapon, "Wszystkie")) {
			client_print_color(id, id, "^x04[CS:GO]^x01 Masz juz wszystkie dostepne skiny^x01.", weapon);
		} else {
			client_print_color(id, id, "^x04[CS:GO]^x01 Masz juz wszystkie dostepne skiny broni^x03 %s^x01.", weapon);
		}

		return PLUGIN_HANDLED;
	}

	new Float:price = randomSkinPrice[equal(weapon, "Wszystkie") ? WEAPON_ALL : get_weapon_id(weapon)];

	if (playerData[id][MONEY] < price) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz wystarczajacej ilosci^x03 pieniedzy^x01.");

		return PLUGIN_HANDLED;
	} else playerData[id][MONEY] -= price;

	new chance = (csgo_get_user_svip(id) ? skinChanceSVIP : skinChance) + floatround(csgo_get_clan_members(csgo_get_user_clan(id)) * skinChancePerMember, floatround_floor);

	if (random_num(1, 100) <= chance) {
		new skin[skinsInfo], skinId, skinsChance = 0, skinChance = random_num(1, multipleSkins ? get_weapon_skins_count(weapon, 1) : get_missing_weapon_skins_count(id, weapon, 1));

		for (new i = 0; i < ArraySize(skins); i++) {
			ArrayGetArray(skins, i, skin);

			if (equali(weapon, skin[SKIN_WEAPON]) || equal(weapon, "Wszystkie")) {
				if (!multipleSkins && has_skin(id, i)) continue;

				skinsChance += skin[SKIN_CHANCE];

				if (skinsChance >= skinChance) {
					skinId = i;

					break;
				}
			}
		}

		ArrayGetArray(skins, skinId, skin);

		add_skin(id, skinId, skin[SKIN_WEAPON], skin[SKIN_NAME]);

		client_print_color(0, id, "^x04[CS:GO]^x03 %s^x01 wylosowal skin^x03 %s^x01 do broni^x03 %s^x01.", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON]);

		log_to_file("csgo-random.log", "Gracz %s wylosowal skina %s (%s)", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON]);
	} else client_print_color(id, id, "^x04[CS:GO]^x01 Niestety tym razem nie udalo ci sie wylosowac skina. Probuj dalej.");

	save_data(id);

	skins_menu(id);

	return PLUGIN_HANDLED;
}

public exchange_skin_menu(id)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	new menuData[128], playerId[3], skinsCount, players, menu = menu_create("\yWybierz \rGracza\y, z ktorym chcesz sie wymienic skinem\w:", "exchange_skin_menu_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || id == player || is_user_bot(player) || is_user_hltv(player) || !ArraySize(playerSkins[player]) || playerData[player][EXCHANGE_BLOCKED]) continue;

		skinsCount = ArraySize(playerSkins[player]);

		formatex(menuData, charsmax(menuData), "%s \y(%i Skin%s)", playerData[player][NAME], skinsCount, skinsCount % 10 == 0 ? "ow" : (skinsCount == 1 ? "" : ((skinsCount % 10 < 5 && (skinsCount < 10 || skinsCount > 20)) ? "y" : "ow")));

		num_to_str(player, playerId, charsmax(playerId));

		menu_additem(menu, menuData, playerId);

		players++;
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!players) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Na serwerze nie ma gracza, z ktorym moglbys sie wymienic skinem!");
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
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[player])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany gracz nie ma zadnych skinow.");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[id])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz zadnych skinow.");

		return PLUGIN_HANDLED;
	}

	playerData[id][TEMP][EXCHANGE_PLAYER] = player;

	new menuData[64], skin[skinsInfo], tempId[5], skinId, skinsCount, menu = menu_create("\yWybierz twoj \rSkin\y, ktory chcesz wymienic\w:", "exchange_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID), skinsCount = get_player_skin_info(id, i, SKIN_COUNT);

		if (!multipleSkins && has_skin(player, skinId)) continue;

		ArrayGetArray(skins, skinId, skin);

		num_to_str(skinId, tempId, charsmax(tempId));

		if (multipleSkins && skinsCount > 1) formatex(menuData, charsmax(menuData), "%s \y(%s) \r(%i)", skin[SKIN_NAME], skin[SKIN_WEAPON], skinsCount);
		else formatex(menuData, charsmax(menuData), "%s \y(%s)", skin[SKIN_NAME], skin[SKIN_WEAPON]);

		menu_additem(menu, menuData, tempId);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

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
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[player])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany gracz nie ma zadnych skinow.");

		return PLUGIN_HANDLED;
	}

	new itemData[5], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	playerData[id][TEMP][EXCHANGE_SKIN] = str_to_num(itemData);

	menu_destroy(menu);

	if (has_skin(id, playerData[id][TEMP][EXCHANGE_SKIN], 1) == -1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz juz skina, za ktory chcialbys sie zamienic.");

		return PLUGIN_HANDLED;
	}

	new menuData[64], skin[skinsInfo], tempId[5], skinsCount = 0, skinId, menu = menu_create("\yWybierz \rSkin\y, za ktory chcesz sie wymienic\w:", "exchange_for_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[player]); i++) {
		skinId = get_player_skin_info(player, i, SKIN_ID);

		if (!multipleSkins && has_skin(id, skinId)) continue;

		ArrayGetArray(skins, skinId, skin);

		num_to_str(skinId, tempId, charsmax(tempId));

		formatex(menuData, charsmax(menuData), "%s \y(%s)", skin[SKIN_NAME], skin[SKIN_WEAPON]);

		menu_additem(menu, menuData, tempId);

		skinsCount++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!skinsCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Masz juz wszystkie skiny, ktore posiada wybrany gracz!");
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
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[player])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany gracz nie ma zadnych skinow.");

		return PLUGIN_HANDLED;
	}

	new menuData[256], itemData[32], skin[skinsInfo], playerSkin[skinsInfo], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	playerData[id][TEMP][EXCHANGE_FOR_SKIN] = str_to_num(itemData);

	if (playerData[id][TEMP][EXCHANGE_FOR_SKIN] == playerData[id][TEMP][EXCHANGE_SKIN]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz wymienic sie za ten sam skin.");

		return PLUGIN_HANDLED;
	}

	if (has_skin(player, playerData[id][TEMP][EXCHANGE_FOR_SKIN], 1) == -1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany gracz nie ma juz tego skina.");

		return PLUGIN_HANDLED;
	}

	ArrayGetArray(skins, playerData[id][TEMP][EXCHANGE_SKIN], skin);
	ArrayGetArray(skins, playerData[id][TEMP][EXCHANGE_FOR_SKIN], playerSkin);

	playerData[player][TEMP][EXCHANGE_PLAYER] = id;

	formatex(menuData, charsmax(menuData), "\wGracz \y%s \wzaproponowal ci wymiane:^n\wTwoj skin: \r%s \y(%s)^n\wJego skin: \r%s \y(%s)\w^n^n\r8. \wWymien^n\r9. \wOdrzuc^n^n\r0. \wWyjscie",
		playerData[id][NAME], playerSkin[SKIN_NAME], playerSkin[SKIN_WEAPON], skin[SKIN_NAME], skin[SKIN_WEAPON]);

	show_menu(player, (MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0), menuData, -1, "Exchange");

	return PLUGIN_HANDLED;
}

public exchange_question_handle(id, key)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	new player = playerData[id][TEMP][EXCHANGE_PLAYER], exchangeSkin = playerData[player][TEMP][EXCHANGE_SKIN], exchangeForSkin = playerData[player][TEMP][EXCHANGE_FOR_SKIN];

	if (!is_user_connected(player)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Gracza proponujacego wymiane nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	if (has_skin(player, exchangeSkin, 1) == -1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Gracz proponujacy wymiane nie ma juz tego skina.");

		return PLUGIN_HANDLED;
	}

	if (has_skin(id, exchangeForSkin, 1) == -1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz juz zapronowanego w wymianie skina.");

		return PLUGIN_HANDLED;
	}

	switch (key + 1) {
		case 8: {
			new skin[skinsInfo], playerSkin[skinsInfo];

			ArrayGetArray(skins, exchangeSkin, playerSkin);
			ArrayGetArray(skins, exchangeForSkin, skin);

			remove_skin(player, exchangeSkin, playerSkin[SKIN_WEAPON], playerSkin[SKIN_NAME]);
			remove_skin(id, exchangeForSkin, skin[SKIN_WEAPON], skin[SKIN_NAME]);

			add_skin(player, exchangeForSkin, skin[SKIN_WEAPON], skin[SKIN_NAME]);
			add_skin(id, exchangeSkin, playerSkin[SKIN_WEAPON], playerSkin[SKIN_NAME]);

			client_print_color(player, player, "^x04[CS:GO]^x01 Wymieniles sie skinem z^x03 %s^x01. Otrzymales^x03 %s (%s)^x01.", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON]);
			client_print_color(id, id, "^x04[CS:GO]^x01 Wymieniles sie skinem z^x03 %s^x01. Otrzymales^x03 %s (%s)^x01.", playerData[player][NAME], playerSkin[SKIN_NAME], playerSkin[SKIN_WEAPON]);

			log_to_file("csgo-exchange.log", "Gracz %s wymienil sie skinem %s (%s) z graczem %s za skin %s (%s)", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON], playerData[player][NAME], playerSkin[SKIN_NAME], playerSkin[SKIN_WEAPON]);
		} default: client_print_color(player, player, "^x04[CS:GO]^x01 Wybrany gracz nie zgodzil sie na wymiane skinami.");
	}

	return PLUGIN_HANDLED;
}

public give_skin_menu(id)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	new menuData[128], playerId[3], skinsCount, players, menu = menu_create("\yWybierz \rGracza\y, ktoremu chcesz oddac skina\w:", "give_skin_menu_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || id == player || is_user_hltv(player) || is_user_bot(player)) continue;

		skinsCount = ArraySize(playerSkins[player]);

		formatex(menuData, charsmax(menuData), "%s \y(%i Skin%s)", playerData[player][NAME], skinsCount, skinsCount % 10 == 0 ? "ow" : (skinsCount == 1 ? "" : ((skinsCount % 10 < 5 && (skinsCount < 10 || skinsCount > 20)) ? "y" : "ow")));

		num_to_str(player, playerId, charsmax(playerId));

		menu_additem(menu, menuData, playerId);

		players++;
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!players) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Na serwerze nie ma gracza, ktoremu moglbys oddac skina!");
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
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[id])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz zadnych skinow.");

		return PLUGIN_HANDLED;
	}

	playerData[id][TEMP][GIVE_PLAYER] = player;

	new menuData[64], skin[skinsInfo], tempId[5], skinsCount = 0, skinId, skinCount, menu = menu_create("\yWybierz \rSkin\y, ktory chcesz oddac\w:", "give_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID), skinCount = get_player_skin_info(id, i, SKIN_COUNT);

		if (!multipleSkins && has_skin(player, skinId)) continue;

		ArrayGetArray(skins, skinId, skin);

		num_to_str(skinId, tempId, charsmax(tempId));

		if (multipleSkins && skinCount > 1) formatex(menuData, charsmax(menuData), "%s \y(%s) \r(%i)", skin[SKIN_NAME], skin[SKIN_WEAPON], skinCount);
		else formatex(menuData, charsmax(menuData), "%s \y(%s)", skin[SKIN_NAME], skin[SKIN_WEAPON]);

		menu_additem(menu, menuData, tempId);

		skinsCount++;
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	if (!skinsCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany gracz ma juz wszystkie skiny, ktore ty posiadasz!");
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
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	new itemData[5], itemAccess, itemCallback, skinId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	skinId = str_to_num(itemData);

	menu_destroy(menu);

	if (has_skin(id, skinId, 1) == -1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz juz skina, ktorego mialbys oddac.");

		return PLUGIN_HANDLED;
	}

	if (!multipleSkins && has_skin(player, skinId)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany gracz ma juz tego skina.");

		return PLUGIN_HANDLED;
	}

	new skin[skinsInfo];

	ArrayGetArray(skins, skinId, skin);

	remove_skin(id, skinId, skin[SKIN_WEAPON], skin[SKIN_NAME]);

	add_skin(player, skinId, skin[SKIN_WEAPON], skin[SKIN_NAME]);

	client_print_color(player, player, "^x04[CS:GO]^x01 Gracz^x03 %s^x01 podarowal ci skin^x03 %s (%s)^x01.", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON]);
	client_print_color(id, id, "^x04[CS:GO]^x01 Podarowales skin^x03 %s (%s)^x01 graczowi^x03 %s^x01.", skin[SKIN_NAME], skin[SKIN_WEAPON], playerData[player][NAME]);

	log_to_file("csgo-give.log", "Gracz %s oddal skina %s (%s) graczowi %s", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON], playerData[player][NAME]);

	return PLUGIN_HANDLED;
}

public market_menu(id)
{
	if (!csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\yMenu \rRynku", "market_menu_handle"), callback = menu_makecallback("market_menu_callback");

	menu_additem(menu, "Wystaw \ySkin \r(/wystaw)", _, _, callback);
	menu_additem(menu, "Wykup \ySkin \r(/wykup)", _, _, callback);
	menu_additem(menu, "Wycofaj \ySkin \r(/wycofaj)", _, _, callback);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

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
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	if (!ArraySize(playerSkins[id])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz zadnych skinow.");

		return PLUGIN_HANDLED;
	}

	if (get_market_skins(id) >= maxMarketSkins) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wystawiles juz maksymalne^x03 %i^x01 skinow na rynek!", maxMarketSkins);

		return PLUGIN_HANDLED;
	}

	new menuTitle[128], menuData[64], skin[skinsInfo], tempId[5], skinId, skinsCount;

	if (marketCommision > 0.0) formatex(menuTitle, charsmax(menuTitle), "\yWybierz \rSkin\y, ktory chcesz wystawic na rynek\w:^n\yOd kazdej sprzedazy pobierana jest prowizja w wysokosci\r %.2f%%\y.^n", marketCommision);
	else  formatex(menuTitle, charsmax(menuTitle), "\yWybierz \rSkin\y, ktory chcesz wystawic na rynek\w:");

	new menu = menu_create(menuTitle, "market_sell_skin_handle");

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID), skinsCount = get_player_skin_info(id, i, SKIN_COUNT);

		ArrayGetArray(skins, skinId, skin);

		num_to_str(skinId, tempId, charsmax(tempId));

		if (multipleSkins && skinsCount > 1) formatex(menuData, charsmax(menuData), "%s \y(%s) \r(%i)", skin[SKIN_NAME], skin[SKIN_WEAPON], skinsCount);
		else formatex(menuData, charsmax(menuData), "%s \y(%s)", skin[SKIN_NAME], skin[SKIN_WEAPON]);

		menu_additem(menu, menuData, tempId);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

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

	if (has_skin(id, playerData[id][SALE_SKIN], 1) == -1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz juz tego skina.");

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "messagemode CENA_SKINA");

	client_print_color(id, id, "^x04[CS:GO]^x01 Wpisz^x03 cene^x01, za ktora chcesz sprzedac skina.");

	client_print(id, print_center, "Wpisz cene, za ktora chcesz sprzedac skina.");

	return PLUGIN_HANDLED;
}

public set_skin_price(id)
{
	if (!csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (has_skin(id, playerData[id][SALE_SKIN], 1) == -1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz juz tego skina.");

		return PLUGIN_HANDLED;
	}

	if (get_market_skins(id) >= maxMarketSkins) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wystawiles juz maksymalne^x03 %i^x01 skinow na rynek!", maxMarketSkins);

		return PLUGIN_HANDLED;
	}

	new priceData[16], Float:price;

	read_args(priceData, charsmax(priceData));
	remove_quotes(priceData);

	price = str_to_float(priceData);

	if (price < 1.0 || price > 9999.0) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Cena musi nalezec do przedzialu^x03 1 - 9999 Euro^x01!");

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

	client_print_color(0, id, "^x04[CS:GO]^x03 %s^x01 wystawil^x03 %s (%s)^x01 na rynek za^x03 %.2f Euro^x01.", playerData[id][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON], price);

	return PLUGIN_HANDLED;
}

public market_buy_skin(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], itemData[128], skinIds[16], skinsCounts = 0, menu = menu_create("\yWybierz \rSkin\y, ktory chcesz wykupic\w:", "market_buy_skin_handle");

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if ((marketSkin[MARKET_OWNER] == id) || (!multipleSkins && has_skin(id, marketSkin[MARKET_SKIN]))) continue;

		ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

		formatex(skinIds, charsmax(skinIds), "%i#%i#%i", marketSkin[MARKET_ID], marketSkin[MARKET_SKIN], marketSkin[MARKET_OWNER]);

		formatex(itemData, charsmax(itemData), "\w%s \r(%s) \y(%.2f Euro)", skin[SKIN_NAME], skin[SKIN_WEAPON], marketSkin[MARKET_PRICE]);

		menu_additem(menu, itemData, skinIds);

		skinsCounts++;
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!skinsCounts) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Na rynku nie ma zadnych skinow, ktore moglbys kupic!");
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

		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany skin zostal juz wykupiony lub wycofany z rynku!");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], menuData[512], length = 0, maxLength = charsmax(menuData);

	ArrayGetArray(market, skinId, marketSkin);

	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	length += formatex(menuData[length], maxLength - length, "\yPotwierdzenie kupna od: \r%s^n", playerData[marketSkin[MARKET_OWNER]][NAME]);
	length += formatex(menuData[length], maxLength - length, "\wSkin: \y%s (%s)^n", skin[SKIN_NAME], skin[SKIN_WEAPON]);
	length += formatex(menuData[length], maxLength - length, "\wKoszt: \y%.2f Euro^n", marketSkin[MARKET_PRICE]);
	length += formatex(menuData[length], maxLength - length, "\wCzy na pewno chcesz \rkupic\w tego skina?^n^n");

	new menu = menu_create(menuData, "market_buy_confirm_handle");

	menu_additem(menu, "\yTak", itemIds);
	menu_additem(menu, "\wNie");

	menu_setprop(menu, MPROP_EXITNAME, "\wWyjscie");

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

		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany skin zostal juz wykupiony lub wycofany z rynku!");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo];

	ArrayGetArray(market, skinId, marketSkin);

	if (playerData[id][MONEY] < marketSkin[MARKET_PRICE]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz wystarczajacej ilosci pieniedzy!");

		return PLUGIN_HANDLED;
	}

	new skin[skinsInfo], Float:priceAfterCommision = marketSkin[MARKET_PRICE] * ((100.0 - marketCommision) / 100.0);

	change_local_skin(marketSkin[MARKET_OWNER], marketSkin[MARKET_SKIN], 1);

	ArrayDeleteItem(market, skinId);

	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	playerData[marketSkin[MARKET_OWNER]][MONEY] += priceAfterCommision;
	playerData[id][MONEY] -= marketSkin[MARKET_PRICE];

	add_skin(id, marketSkin[MARKET_SKIN], skin[SKIN_WEAPON], skin[SKIN_NAME]);
	remove_skin(marketSkin[MARKET_OWNER], marketSkin[MARKET_SKIN], skin[SKIN_WEAPON], skin[SKIN_NAME]);

	client_print_color(id, id, "^x04[CS:GO]^x01 Skin^x03 %s (%s)^x01 zostal pomyslnie zakupiony.", skin[SKIN_NAME], skin[SKIN_WEAPON]);

	client_print_color(marketSkin[MARKET_OWNER], marketSkin[MARKET_OWNER], "^x04[CS:GO]^x01 Twoj skin^x03 %s (%s)^x01 zostal zakupiony przez^x03 %s^x01.", skin[SKIN_NAME], skin[SKIN_WEAPON], playerData[id][NAME]);
	client_print_color(marketSkin[MARKET_OWNER], marketSkin[MARKET_OWNER], "^x04[CS:GO]^x01 Za sprzedaz otrzymujesz^x03 %.2f Euro^x01.", priceAfterCommision);

	log_to_file("csgo-sell.log", "Gracz %s sprzedal skina %s (%s) graczowi %s za %.2f Euro", playerData[marketSkin[MARKET_OWNER]][NAME], skin[SKIN_NAME], skin[SKIN_WEAPON], playerData[id][NAME], marketSkin[MARKET_PRICE]);

	return PLUGIN_CONTINUE;
}

public market_withdraw_skin(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	if (!playerData[id][SKINS_LOADED]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], itemData[128], skinIds[16], skinsCounts = 0, menu = menu_create("\yWybierz \rSkin\y, ktory chcesz wycofac z rynku\w:", "market_withdraw_skin_handle");

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if (marketSkin[MARKET_OWNER] != id) continue;

		ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

		formatex(skinIds, charsmax(skinIds), "%i#%i#%i", marketSkin[MARKET_ID], marketSkin[MARKET_SKIN], marketSkin[MARKET_OWNER]);

		formatex(itemData, charsmax(itemData), "\w%s \r(%s) \y(%.2f Euro)", skin[SKIN_NAME], skin[SKIN_WEAPON], marketSkin[MARKET_PRICE]);

		menu_additem(menu, itemData, skinIds);

		skinsCounts++;
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!skinsCounts) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Na rynku nie ma zadnych twoich skinow!");
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

		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany skin zostal juz wykupiony!");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo], menuData[512], length = 0, maxLength = charsmax(menuData);

	ArrayGetArray(market, skinId, marketSkin);
	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	length += formatex(menuData[length], maxLength - length, "Potwierdzenie wycofania skina z rynku:^n");
	length += formatex(menuData[length], maxLength - length, "\wSkin: \y%s (%s)^n", skin[SKIN_NAME], skin[SKIN_WEAPON]);
	length += formatex(menuData[length], maxLength - length, "\wKoszt: \y%.2f Euro^n", marketSkin[MARKET_PRICE]);
	length += formatex(menuData[length], maxLength - length, "\wCzy na pewno chcesz \rwycofac\w tego skina?^n^n");

	new menu = menu_create(menuData, "market_withdraw_confirm_handle");

	menu_additem(menu, "\yTak", itemIds);
	menu_additem(menu, "\wNie");

	menu_setprop(menu, MPROP_EXITNAME, "\wWyjscie");

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

		client_print_color(id, id, "^x04[CS:GO]^x01 Wybrany skin zostal juz wykupiony!");

		return PLUGIN_HANDLED;
	}

	new marketSkin[marketInfo], skin[skinsInfo];

	ArrayGetArray(market, skinId, marketSkin);
	ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

	change_local_skin(id, marketSkin[MARKET_SKIN], 1);

	ArrayDeleteItem(market, skinId);

	client_print_color(id, id, "^x04[CS:GO]^x01 Skin^x03 %s (%s)^x01 zostal pomyslnie wycofany z rynku.", skin[SKIN_NAME], skin[SKIN_WEAPON]);

	return PLUGIN_CONTINUE;
}

public cmd_add_money(id)
{
	if (!(get_user_flags(id) & ADMIN_ADMIN)) return PLUGIN_HANDLED;

	new playerName[32], tempMoney[4];

	read_argv(1, playerName, charsmax(playerName));
	read_argv(2, tempMoney, charsmax(tempMoney));

	new Float:addedMoney = str_to_float(tempMoney), player = cmd_target(id, playerName, 0);

	if (!player) {
		console_print(id, "[CS:GO] Nie znaleziono podanego gracza!", playerName);

		return PLUGIN_HANDLED;
	}

	if (addedMoney < 0.1) {
		console_print(id, "[CS:GO] Minimalnie mozna dodac 0.1 Euro!");

		return PLUGIN_HANDLED;
	}

	playerData[player][MONEY] += addedMoney;

	save_data(player);

	client_print_color(player, player, "^x04[CS:GO]^x03 %s^x01 przyznal ci^x04 %.2f Euro^x01!", playerData[id][NAME], addedMoney);
	client_print_color(id, id, "^x04[CS:GO]^x01 Przyznales^x04 %.2f Euro^x01 graczowi^x03 %s^x01.", addedMoney, playerData[player][NAME]);

	log_to_file("csgo-admin.log", "%s przyznal %.2f Euro graczowi %s.", playerData[id][NAME], addedMoney, playerData[player][NAME]);

	return PLUGIN_HANDLED;
}

public client_death(killer, victim, weaponId, hitPlace, teamKill)
{
	if (!is_user_connected(killer) || !is_user_connected(victim) || !is_user_alive(killer) || get_user_team(victim) == get_user_team(killer) || get_playersnum() < minPlayers) return PLUGIN_CONTINUE;

	playerData[killer][MONEY] += killReward * get_multiplier(killer);

	if (hitPlace == HIT_HEAD) playerData[killer][MONEY] += killHSReward * get_multiplier(killer);

	save_data(killer);

	return PLUGIN_CONTINUE;
}

public log_event_operation()
{
	if (get_playersnum() < minPlayers) return PLUGIN_CONTINUE;

	new userLog[80], userAction[64], userName[32];

	read_logargv(0, userLog, charsmax(userLog));
	read_logargv(2, userAction, charsmax(userAction));
	parse_loguser(userLog, userName, charsmax(userName));

	new id = get_user_index(userName);

	if (!is_user_connected(id)) return PLUGIN_CONTINUE;

	if (equal(userAction, "Planted_The_Bomb")) {
		new Float:money = bombReward * get_multiplier(id);

		playerData[id][MONEY] += money;

		client_print_color(id, id, "^x04[CS:GO]^x01 Dostales^x03 %.2f Euro^x01 za podlozenie bomby.", money);

		save_data(id);
	}

	if (equal(userAction, "Defused_The_Bomb")) {
		new Float:money = defuseReward * get_multiplier(id);

		playerData[id][MONEY] += money;

		client_print_color(id, id, "^x04[CS:GO]^x01 Dostales^x03 %.2f Euro^x01 za rozbrojenie bomby.", money);

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
	if (get_playersnum() < minPlayers) return;

	for (new id = 1; id < MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || get_user_team(id) != team) continue;

		new Float:money = winReward * get_multiplier(id);

		playerData[id][MONEY] += money;

		client_print_color(id, id, "^x04[CS:GO]^x01 Dostales^x03 %.2f Euro^x01 za wygrana runde.", money);

		save_data(id);
	}
}

public hostages_rescued()
{
	if (get_playersnum() < minPlayers) return;

	new id = get_loguser_index(), Float:money = hostageReward * get_multiplier(id);

	playerData[id][MONEY] += money;

	client_print_color(id, id, "^x04[CS:GO]^x01 Dostales^x03 %.2f Euro^x01 za uratowanie zakladnikow.", money);

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

		client_print_color(id, id, "^x04[CS:GO]^x01 Za gre na tej mapie otrzymujesz^x03 %.2f Euro^x01.", money);

		save_data(id, 1);
	}

	return PLUGIN_CONTINUE;
}

public set_fov(id)
{
	if (playerData[id][SKIN] > -1 && (!playerData[id][TEMP][WEAPON_ENT] || is_valid_ent(playerData[id][TEMP][WEAPON_ENT])) && (playerData[id][TEMP][WEAPON] == CSW_AWP || playerData[id][TEMP][WEAPON] == CSW_SCOUT)) {
		switch (read_data(1)) {
			case 10..55: {
				if (playerData[id][TEMP][WEAPON] == CSW_AWP) set_pev(id, pev_viewmodel2, "models/v_awp.mdl");
				else set_pev(id, pev_viewmodel2, "models/v_scout.mdl");
			} case 90: {
				if (is_valid_ent(playerData[id][TEMP][WEAPON_ENT])) change_skin(id, playerData[id][TEMP][WEAPON], playerData[id][TEMP][WEAPON_ENT]);
				else change_skin(id, playerData[id][TEMP][WEAPON]);
			}
		}
	}
}

public client_command(id)
{
	static weapons[32], weaponsNum;

	playerData[id][TEMP][WEAPONS] = get_user_weapons(id, weapons, weaponsNum);
}

public event_money(id)
{
	new oldWeapons = playerData[id][TEMP][WEAPONS];

	client_command(id);

	new newWeapon = playerData[id][TEMP][WEAPONS] & ~oldWeapons;

	if (newWeapon) {
		new x = -1;
		do ++x; while ((newWeapon /= 2) >= 1);

		ExecuteHamB(Ham_GiveAmmo, id, maxBPAmmo[x], ammoType[x], maxBPAmmo[x]);
	}
}

public weapon_deploy_post(ent)
{
	static id; id = get_pdata_cbase(ent, 41, 4);

	if (!is_user_alive(id)) return HAM_IGNORED;

	playerData[id][TEMP][WEAPON] = cs_get_weapon_id(ent);

	change_skin(id, playerData[id][TEMP][WEAPON], ent);

	return HAM_IGNORED;
}

public player_spawn(id)
{
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
	if (!pev_valid(ent) || !is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) return HAM_IGNORED;

	new owner = entity_get_int(ent, EV_INT_iuser1);

	if (!is_user_connected(owner)) {
		entity_set_int(ent, EV_INT_iuser1, id);
		entity_set_int(ent, EV_INT_iuser2, get_weapon_skin(id, cs_get_weapon_id(ent)));
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

public check_aim_weapon(id)
{
	id -= TASK_AIM;

	if (!is_user_alive(id)) return FMRES_IGNORED;

	static bool:canPickup[MAX_PLAYERS + 1], weaponHud, ent;

	ent = fm_get_user_aiming_ent(id, "weaponbox");

	if (!weaponHud) weaponHud = CreateHudSyncObj();

	if (!is_valid_ent(ent) || task_exists(ent)) {
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

	new playerWeapon[32], weapon = fm_get_weaponbox_type(ent);

	if ((weapon == CSW_C4 && get_user_team(id) != 1) || !weapon) return FMRES_IGNORED;

	canPickup[id] = true;

	get_weapon_skin_name(id, ent, playerWeapon, charsmax(playerWeapon), weapon);

	set_hudmessage(0, 120, 250, -1.0, 0.7, 0, 1.0, 1.0, 0.1, 0.1, 3);

	ShowSyncHudMsg(id, weaponHud, "[E] Podnies %s", playerWeapon);

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
	if (pev_valid(data[1]) && is_user_alive(data[0])) {
		ExecuteHamB(Ham_Touch, data[0], data[1]);
		ExecuteHamB(Ham_Touch, data[1], data[0]);

		emit_sound(data[0], CHAN_ITEM, "items/gunpickup2.wav", 1.0, 0.8, SND_SPAWNING, PITCH_NORM);
	}
}

stock change_skin(id, weapon, ent = 0)
{
	playerData[id][SKIN] = -1;
	playerData[id][TEMP][WEAPON_ENT] = 0;

	if (!is_user_alive(id) || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4 || !weapon || playerData[id][SKINS_DISABLED]) return;

	static skin[skinsInfo];

	if (is_valid_ent(ent) && weapon != CSW_KNIFE) {
		static weaponOwner, weaponSkin;

		weaponOwner = entity_get_int(ent, EV_INT_iuser1);

		if (is_user_connected(weaponOwner) && !is_user_hltv(weaponOwner) && !is_user_bot(weaponOwner)) {
			playerData[id][TEMP][WEAPON_ENT] = ent;

			weaponSkin = entity_get_int(ent, EV_INT_iuser2);

			if (weaponSkin > -1) {
				static weaponName[32];

				ArrayGetArray(skins, weaponSkin, skin);

				get_weaponname(weapon, weaponName, charsmax(weaponName));

				playerData[id][SKIN] = weaponSkin;

				set_pev(id, pev_viewmodel2, skin[SKIN_MODEL]);

				if (weapon == get_weapon_id(skin[SKIN_WEAPON])) {
					playerData[id][SKIN] = weaponSkin;

					set_pev(id, pev_viewmodel2, skin[SKIN_MODEL]);
				} else {
					entity_set_int(ent, EV_INT_iuser1, 0);
					entity_set_int(ent, EV_INT_iuser2, -1);
				}
			} else if (defaultSkins) set_pev(id, pev_viewmodel2, defaultSkin[weapon]);

			return;
		}
	}

	if (playerData[id][ACTIVE][weapon] > -1) {
		ArrayGetArray(skins, playerData[id][ACTIVE][weapon], skin);

		playerData[id][SKIN] = playerData[id][ACTIVE][weapon];

		set_pev(id, pev_viewmodel2, skin[SKIN_MODEL]);
	} else if (defaultSkins) set_pev(id, pev_viewmodel2, (weapon == CSW_KNIFE && get_user_team(id) == 1) ? defaultSkin[weapon + 2] : defaultSkin[weapon]);
}

stock get_weapon_skin(id, weapon)
{
	if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id) || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4 || !weapon || weapon > CSW_P90) return -1;

	if (playerData[id][ACTIVE][weapon] > -1) {
		static skin[skinsInfo];

		ArrayGetArray(skins, playerData[id][ACTIVE][weapon], skin);

		return playerData[id][ACTIVE][weapon];
	}

	return -1;
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

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_data` WHERE name = ^"%s^"", playerData[id][SAFE_NAME]);

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

		if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "disabled"))) playerData[id][SKINS_DISABLED] = true;
		if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "exchange"))) playerData[id][EXCHANGE_BLOCKED] = true;
		if (SQL_ReadResult(query, SQL_FieldNameToNum(query, "menu"))) playerData[id][MENU_BLOCKED] = true;
	} else {
		new queryData[192];

		formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_data` (`name`, `money`, `disabled`, `exchange`, `menu`, `online`) VALUES (^"%s^", '0', '0', '0', '0', '0');", playerData[id][SAFE_NAME]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	playerData[id][DATA_LOADED] = true;

	save_data(id);
}

stock save_data(id, end = 0)
{
	if (!playerData[id][DATA_LOADED]) return;

	new queryData[192];

	formatex(queryData, charsmax(queryData), "UPDATE `csgo_data` SET `money` = %f, `disabled` = %i, `exchange` = %i, `menu` = %i, `online` = %i WHERE name = ^"%s^"",
		playerData[id][MONEY], playerData[id][SKINS_DISABLED], playerData[id][EXCHANGE_BLOCKED], playerData[id][MENU_BLOCKED], end ? 0 : 1, playerData[id][SAFE_NAME]);

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

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_skins` WHERE name = ^"%s^"", playerData[id][SAFE_NAME]);

	SQL_ThreadQuery(sql, "load_skins_handle", queryData, playerId, sizeof(playerId));
}

public load_skins_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO] SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0], skin[skinsInfo];

	while(SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "skin"), skin[SKIN_NAME], charsmax(skin[SKIN_NAME]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "weapon"), skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]));

		if (contain(skin[SKIN_WEAPON], "ACTIVE") != -1) {
			replace(skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), " ACTIVE", "");

			set_skin(id, skin[SKIN_WEAPON], skin[SKIN_NAME], get_skin_id(skin[SKIN_NAME], skin[SKIN_WEAPON]));
		} else {
			new skinId = get_skin_id(skin[SKIN_NAME], skin[SKIN_WEAPON]);

			if (skinId > -1) {
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
		if (failState == TQUERY_CONNECT_FAILED) log_to_file("csgo-error.log", "[CS:GO] Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("csgo-error.log", "[CS:GO] Query failed. [%d] %s", errorNum, error);
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

public _csgo_get_skin(id)
	return playerData[id][SKIN];

public _csgo_get_weapon_skin(id, weapon)
	return get_weapon_skin(id, weapon);

public _csgo_get_skin_name(skin, dataReturn[], dataLength)
{
	param_convert(2);

	if (skin > -1) get_skin_info(skin, SKIN_NAME, dataReturn, dataLength);
	else formatex(dataReturn, dataLength, "Domyslny");
}

public _csgo_get_current_skin_name(id, dataReturn[], dataLength)
{
	param_convert(2);

	if (get_weapon_skin_name(id, playerData[id][TEMP][WEAPON_ENT], dataReturn, dataLength, 0, 1)) return;

	if (playerData[id][SKIN] > -1) get_skin_info(playerData[id][SKIN], SKIN_NAME, dataReturn, dataLength);
	else formatex(dataReturn, dataLength, "Domyslny");
}

stock get_weapon_skin_name(id, ent, dataReturn[], dataLength, weapon = 0, check = 0)
{
	static ownerName[32], weaponName[32], skinWeapon[32], weaponOwner, weaponSkin;
	weaponOwner = 0, weaponSkin = -1;

	if (is_valid_ent(ent)) {
		weaponOwner = entity_get_int(ent, EV_INT_iuser1);

		if (is_user_connected(weaponOwner) && !is_user_hltv(weaponOwner) && !is_user_bot(weaponOwner)) {
			weaponSkin = entity_get_int(ent, EV_INT_iuser2);

			if (weaponSkin > -1) {
				get_skin_info(weaponSkin, SKIN_WEAPON, skinWeapon, charsmax(skinWeapon));

				if (!weapon || weapon == get_weapon_id(skinWeapon)) get_skin_info(weaponSkin, SKIN_NAME, dataReturn, dataLength);
				else {
					entity_set_int(ent, EV_INT_iuser1, 0);
					entity_set_int(ent, EV_INT_iuser2, -1);

					formatex(dataReturn, dataLength, "Domyslny");
				}
			} else formatex(dataReturn, dataLength, "Domyslny");

			if (check && weaponOwner != id) {
				get_user_name(weaponOwner, ownerName, charsmax(ownerName));

				format(dataReturn, dataLength, "%s (%s)", dataReturn, ownerName);

				return true;
			}
		}

		if (weapon) {
			get_weaponname(weapon, weaponName, charsmax(weaponName));

			strtoupper(weaponName);

			if (equal(dataReturn, "Domyslny") || !dataReturn[0]) formatex(dataReturn, dataLength, weaponName[7]);
			else format(dataReturn, dataLength, "%s | %s", weaponName[7], dataReturn);
		}
	}

	return false;
}

stock Float:get_multiplier(id)
{
	if (csgo_get_user_svip(id)) return 1.5;
	else if (csgo_get_user_vip(id)) return 1.25;
	else return 1.0;
}

stock get_weapon_skins_count(weapon[], chance = 0)
{
	new skin[skinsInfo], weaponSkinsCount = 0;

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(weapon, skin[SKIN_WEAPON]) || equal(weapon, "Wszystkie")) weaponSkinsCount += chance ? skin[SKIN_CHANCE] : 1;
	}

	return weaponSkinsCount;
}

stock get_missing_weapon_skins_count(id, weapon[], chance = 0)
{
	new skin[skinsInfo], marketSkin[marketInfo], playerSkinsCount = 0, skinId;

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		skinId = get_player_skin_info(id, i, SKIN_ID);

		ArrayGetArray(skins, skinId, skin);

		if (equal(weapon, skin[SKIN_WEAPON]) || equal(weapon, "Wszystkie")) playerSkinsCount += chance ? skin[SKIN_CHANCE] : 1;
	}

	for (new i = 0; i < ArraySize(market); i++) {
		ArrayGetArray(market, i, marketSkin);

		if (marketSkin[MARKET_OWNER] == id) {
			ArrayGetArray(skins, marketSkin[MARKET_SKIN], skin);

			if (equal(weapon, skin[SKIN_WEAPON]) || equal(weapon, "Wszystkie")) playerSkinsCount += chance ? skin[SKIN_CHANCE] : 1;
		}
	}

	return get_weapon_skins_count(weapon) - playerSkinsCount;
}

stock get_weapon_id(weapon[])
{
	new weaponName[32];

	formatex(weaponName, charsmax(weaponName), "weapon_%s", weapon);

	strtolower(weaponName);

	return get_weaponid(weaponName);
}

stock has_skin(id, skin, check = 0)
{
	if (!check) {
		static marketSkin[marketInfo];

		for (new i = 0; i < ArraySize(market); i++) {
			ArrayGetArray(market, i, marketSkin);

			if (marketSkin[MARKET_OWNER] == id && marketSkin[MARKET_SKIN] == skin) return 1;
		}
	}

	for (new i = 0; i < ArraySize(playerSkins[id]); i++) {
		if (get_player_skin_info(id, i, SKIN_ID) == skin) return check ? i : 1;
	}

	return check ? -1 : 0;
}

stock change_local_skin(id, skinId, add = 0)
{
	new playerSkin[playerSkinsInfo], skinIndex = has_skin(id, skinId, 1);

	if (skinIndex > -1) {
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
	} else return false;

	return true;
}

stock remove_skin(id, skinId, weapon[], skin[])
{
	if (!playerData[id][SKINS_LOADED]) return;

	new queryData[192], skinSafeName[64];

	mysql_escape_string(skin, skinSafeName, charsmax(skinSafeName));

	if (!change_local_skin(id, skinId)) formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_skins` WHERE name = ^"%s^" AND weapon = '%s' AND skin = '%s'", playerData[id][SAFE_NAME], weapon, skinSafeName);
	else formatex(queryData, charsmax(queryData), "UPDATE `csgo_skins` SET count = count - 1 WHERE name = ^"%s^" AND weapon = '%s' AND skin = '%s'", playerData[id][SAFE_NAME], weapon, skinSafeName);

	if (playerData[id][ACTIVE][get_weapon_id(weapon)] == skinId) {
		set_skin(id, weapon);

		remove_active_skin(id, weapon);
	}

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock remove_active_skin(id, weapon[])
{
	if (!playerData[id][SKINS_LOADED]) return;

	new queryData[192];

	formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_skins` WHERE name = ^"%s^" AND weapon = '%s ACTIVE'", playerData[id][SAFE_NAME], weapon);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock add_skin(id, skinId, weapon[], skin[])
{
	if (!playerData[id][SKINS_LOADED] || (!multipleSkins && has_skin(id, skinId))) return;

	new queryData[192], skinSafeName[64];

	mysql_escape_string(skin, skinSafeName, charsmax(skinSafeName));

	formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_skins` (`name`, `weapon`, `skin`) VALUES (^"%s^", '%s', '%s') ON DUPLICATE KEY UPDATE count = count + 1;", playerData[id][SAFE_NAME], weapon, skinSafeName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if (skinId > -1) {
		change_local_skin(id, skinId, 1);

		if (playerData[id][ACTIVE][get_weapon_id(weapon)] == -1) set_skin(id, weapon, skin, skinId, 1);
	}
}

stock set_skin(id, weapon[], skin[] = "", skinId = -1, active = 0)
{
	if (skinId >= ArraySize(skins) || skinId < 0) return;

	playerData[id][ACTIVE][get_weapon_id(weapon)] = skinId;

	if (active && playerData[id][SKINS_LOADED]) {
		new queryData[192], skinSafeName[64];

		mysql_escape_string(skin, skinSafeName, charsmax(skinSafeName));

		formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_skins` (`name`, `weapon`, `skin`) VALUES (^"%s^", '%s ACTIVE', '%s');", playerData[id][SAFE_NAME], weapon, skinSafeName);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}
}

stock get_skin_id(const name[], const weapon[])
{
	static skin[skinsInfo];

	for (new i = 0; i < ArraySize(skins); i++) {
		ArrayGetArray(skins, i, skin);

		if (equal(name, skin[SKIN_NAME]) && equal(weapon, skin[SKIN_WEAPON])) return i;
	}

	return -1;
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

		if (marketSkin[MARKET_ID] == marketId && marketSkin[MARKET_SKIN] == skinId && marketSkin[MARKET_OWNER] == ownerId) return i;
	}

	return -1;
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

stock fm_get_user_aiming_ent(index, const sClassName[])
{
	new Float:vOrigin[3];

	fm_get_aim_origin(index, vOrigin);

	new ent, sTempClass[32], iLen = sizeof(sTempClass) - 1;

	do {
		pev(ent, pev_classname, sTempClass, iLen);

		if (equali(sClassName, sTempClass)) return ent;
	} while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, vOrigin, 0.005)));

	return 0;
}

stock explode_num(const string[], const character, output[], const maxParts)
{
	new currentPart = 0, stringLength = strlen(string), currentLength = 0, number[32];

	do {
		currentLength += (1 + copyc(number, charsmax(number), string[currentLength], character));

		output[currentPart++] = str_to_num(number);
	} while(currentLength < stringLength && currentPart < maxParts);
}