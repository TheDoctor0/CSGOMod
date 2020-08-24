#include <amxmodx>
#include <sqlx>
#include <csx>
#include <fakemeta>
#include <hamsandwich>
#include <unixtime>
#include <nvault>
#include <csgomod>

#define PLUGIN	"CS:GO Rank System"
#define AUTHOR	"O'Zone"

#define get_elo(%1,%2) (1.0 / (1.0 + floatpower(10.0, ((%1 - %2) / 400.0))))
#define set_elo(%1,%2,%3) (%1 + 30.0 * (%2 - %3))

#define TASK_HUD 7501
#define TASK_TIME 6701

#define MAX_RANKS 18

#define STATS 1
#define TEAM_RANK 2
#define ENEMY_RANK 4
#define BELOW_HEAD 8

new const rankName[MAX_RANKS + 1][] = {
	"Unranked",
	"Silver I",
	"Silver II",
	"Silver III",
	"Silver IV",
	"Silver Elite",
	"Silver Elite Master",
	"Gold Nova I",
	"Gold Nova II",
	"Gold Nova III",
	"Gold Nova Master",
	"Master Guardian I",
	"Master Guardian II",
	"Master Guardian Elite",
	"Distinguished Master Guardian",
	"Legendary Eagle",
	"Legendary Eagle Master",
	"Supreme Master First Class",
	"Global Elite"
};

new const rankElo[MAX_RANKS + 1] = {
	-1,
	0,
	100,
	120,
	140,
	160,
	180,
	200,
	215,
	230,
	245,
	260,
	275,
	290,
	315,
	340,
	370,
	410,
	450
};

new const commandMenu[][] = { "menustaty", "say /statsmenu", "say_team /statsmenu", "say /statymenu", "say_team /statymenu",
	"say /menustaty", "say_team /menustaty" };
new const commandRank[][] = { "ranga", "say /ranga", "say_team /ranga", "say /myrank", "say_team /myrank" };
new const commandRanks[][] = { "rangi", "say /rangi", "say_team /rangi", "say /ranks", "say_team /ranks" };
new const commandTopRanks[][] = { "toprangi", "say /toprangi", "say_team /toprangi", "say /topranks", "say_team /topranks",
	"say /rangitop15", "say_team /rangitop15", "say /rankstop15", "say_team /rankstop15", "say /rtop15", "say_team /rtop15"};
new const commandTime[][] = { "czas", "say /czas", "say_team /czas", "say /time", "say_team /time" };
new const commandTopTime[][] = { "topczas", "say /topczas", "say_team /topczas", "say /toptime", "say_team /toptime", "say /czastop15",
	"say_team /czastop15", "say /timetop15", "say_team /timetop15", "say /ttop15", "say_team /ttop15", "say /ctop15", "say_team /ctop15" };
new const commandMedals[][] = { "medale", "say /medale", "say_team /medale", "say /medals", "say_team /medals" };
new const commandTopMedals[][] = { "topmedale", "say /topmedale", "say_team /topmedale", "say /topmedals", "say_team /topmedals",
	"say /medalstop15", "say_team /medalstop15", "say /medaletop15", "say_team /medaletop15", "say /mtop15", "say_team /mtop15"};
new const commandStats[][] = { "staty", "say /staty", "say_team /staty", "say /beststats", "say_team /beststats" };
new const commandTopStats[][] = { "topstaty", "say /topstaty", "say_team /topstaty", "say /topstats", "say_team /topstats",
	"say /statytop15", "say_team /statytop15", "say /statstop15", "say_team /statstop15", "say /stop15", "say_team /stop15"};
new const commandHud[][] = { "hud", "say /hud", "say_team /hud", "say /zmienhud", "say_team /zmienhud", "say /changehud", "say_team /changehud" };

enum _:playerInfo { KILLS, RANK, TIME, FIRST_VISIT, LAST_VISIT, BRONZE, SILVER, GOLD, MEDALS, BEST_STATS, BEST_KILLS,
	BEST_DEATHS, BEST_HS, CURRENT_STATS, CURRENT_KILLS, CURRENT_DEATHS, CURRENT_HS, PLAYER_HUD_RED, PLAYER_HUD_GREEN,
	PLAYER_HUD_BLUE, PLAYER_HUD_POSX, PLAYER_HUD_POSY, Float:ELO_RANK, PLAYER_NAME[32], SAFE_NAME[64] };

enum _:winners { THIRD, SECOND, FIRST };

new playerData[MAX_PLAYERS + 1][playerInfo], sprites[MAX_RANKS + 1], Handle:sql, bool:sqlConnected, bool:mapChange,
	bool:block, loaded, hudLoaded, visit, hud, aimHUD, defaultInfo, round, hudSite[64], hudAccount, hudClan, hudOperation,
	iconFlags[8], unrankedKills, minPlayers, Float:winnerReward;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("csgo_ranks_unranked_kills", "100"), unrankedKills);
	bind_pcvar_float(create_cvar("csgo_ranks_winner_reward", "10.0"), winnerReward);
	bind_pcvar_string(create_cvar("csgo_ranks_icon_flags", "abcd"), iconFlags, charsmax(iconFlags));

	bind_pcvar_string(create_cvar("csgo_ranks_hud_site", ""), hudSite, charsmax(hudSite));
	bind_pcvar_num(create_cvar("csgo_ranks_hud_account", "0"), hudAccount);
	bind_pcvar_num(create_cvar("csgo_ranks_hud_clan", "0"), hudClan);
	bind_pcvar_num(create_cvar("csgo_ranks_hud_operation", "0"), hudOperation);

	bind_pcvar_num(get_cvar_pointer("csgo_min_players"), minPlayers);

	for (new i; i < sizeof commandMenu; i++) register_clcmd(commandMenu[i], "cmd_menu");
	for (new i; i < sizeof commandRank; i++) register_clcmd(commandRank[i], "cmd_rank");
	for (new i; i < sizeof commandRanks; i++) register_clcmd(commandRanks[i], "cmd_ranks");
	for (new i; i < sizeof commandTopRanks; i++) register_clcmd(commandTopRanks[i], "cmd_topranks");
	for (new i; i < sizeof commandTime; i++) register_clcmd(commandTime[i], "cmd_time");
	for (new i; i < sizeof commandTopTime; i++) register_clcmd(commandTopTime[i], "cmd_toptime");
	for (new i; i < sizeof commandMedals; i++) register_clcmd(commandMedals[i], "cmd_medals");
	for (new i; i < sizeof commandTopMedals; i++) register_clcmd(commandTopMedals[i], "cmd_topmedals");
	for (new i; i < sizeof commandStats; i++) register_clcmd(commandStats[i], "cmd_stats");
	for (new i; i < sizeof commandTopStats; i++) register_clcmd(commandTopStats[i], "cmd_topstats");
	for (new i; i < sizeof commandHud; i++) register_clcmd(commandHud[i], "change_hud");

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);

	register_message(SVC_INTERMISSION, "message_intermission");

	register_event("TextMsg", "restart_round", "a", "2&#Game_C", "2&#Game_w");
	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("StatusValue", "show_icon", "be", "1=2", "2!0");
	register_event("StatusValue", "hide_icon", "be", "1=1", "2=0");

	register_message(get_user_msgid("SayText"), "say_text");

	defaultInfo = get_xvar_id("PlayerName");

	hud = CreateHudSyncObj();
	aimHUD = CreateHudSyncObj();
}

public plugin_cfg()
	set_task(0.1, "sql_init");

public plugin_end()
	SQL_FreeHandle(sql);

public plugin_natives()
{
	register_native("csgo_add_kill", "_csgo_add_kill", 1);
	register_native("csgo_get_kills", "_csgo_get_kills", 1);
	register_native("csgo_get_rank", "_csgo_get_rank", 1);
	register_native("csgo_get_rank_name", "_csgo_get_rank_name", 1);
	register_native("csgo_get_current_rank_name", "_csgo_get_current_rank_name", 1);
}

public plugin_precache()
{
	new spriteFile[32], bool:error;

	for (new i = 0; i <= MAX_RANKS; i++) {
		spriteFile[0] = '^0';

		formatex(spriteFile, charsmax(spriteFile), "sprites/csgo_ranks/%d.spr", i);

		if (!file_exists(spriteFile)) {
			log_to_file("csgo-error.log", "[CS:GO] Missing sprite file: ^"%s^"", spriteFile);

			error = true;
		} else {
			sprites[i] = precache_model(spriteFile);
		}
	}

	if (error) set_fail_state("Missing sprite files, loading the plugin is impossible! Check the logs in csgo_error.log!");
}

public sql_init()
{
	new host[64], user[64], pass[64], database[64], error[256], errorNum;

	get_cvar_string("csgo_sql_host", host, charsmax(host));
	get_cvar_string("csgo_sql_user", user, charsmax(user));
	get_cvar_string("csgo_sql_pass", pass, charsmax(pass));
	get_cvar_string("csgo_sql_db", database, charsmax(database));

	sql = SQL_MakeDbTuple(host, user, pass, database);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] Init SQL Error: %s (%i)", error, errorNum);

		return;
	}

	new queryData[1024], bool:hasError;

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_ranks` (`name` varchar(32) NOT NULL, `kills` int(10) NOT NULL DEFAULT 0, `rank` int(10) NOT NULL DEFAULT 0, `time` int(10) NOT NULL DEFAULT 0, ");
	add(queryData, charsmax(queryData), "`firstvisit` int(10) NOT NULL DEFAULT 0, `lastvisit` int(10) NOT NULL DEFAULT 0, `gold` int(10) NOT NULL DEFAULT 0, `silver` int(10) NOT NULL DEFAULT 0, `bronze` int(10) NOT NULL DEFAULT 0, `medals` int(10) NOT NULL DEFAULT 0, ");
	add(queryData, charsmax(queryData), "`bestkills` int(10) NOT NULL DEFAULT 0, `bestdeaths` int(10) NOT NULL DEFAULT 0, `besths` int(10) NOT NULL DEFAULT 0, `beststats` int(10) NOT NULL DEFAULT 0, `elorank` double NOT NULL DEFAULT 0, PRIMARY KEY (`name`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	if (!SQL_Execute(query)) {
		SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "[CS:GO Ranks] Init SQL Error: %s", error);

		hasError = true;
	}

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_hud` (`name` varchar(32) NOT NULL, `red` int(10) NOT NULL DEFAULT 0, `green` int(10) NOT NULL DEFAULT 0, `blue` int(10) NOT NULL DEFAULT 0, `x` int(10) NOT NULL DEFAULT 0, `y` int(10) NOT NULL DEFAULT 0, PRIMARY KEY (`name`));");

	query = SQL_PrepareQuery(connectHandle, queryData);

	if (!SQL_Execute(query)) {
		SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "[CS:GO Ranks] Init SQL Error: %s", error);

		hasError = true;
	}

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);

	if (!hasError) sqlConnected = true;
}

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return;

	get_user_name(id, playerData[id][PLAYER_NAME], charsmax(playerData[][PLAYER_NAME]));

	mysql_escape_string(playerData[id][PLAYER_NAME], playerData[id][SAFE_NAME], charsmax(playerData[][SAFE_NAME]));

	for (new i = KILLS; i <= CURRENT_HS; i++) playerData[id][i] = 0;

	playerData[id][ELO_RANK] = _:100.0;

	playerData[id][PLAYER_HUD_RED] = 0;
	playerData[id][PLAYER_HUD_GREEN] = 255;
	playerData[id][PLAYER_HUD_BLUE] = 0;
	playerData[id][PLAYER_HUD_POSX] = 70;
	playerData[id][PLAYER_HUD_POSY] = 6;

	rem_bit(id, loaded);
	rem_bit(id, hudLoaded);
	rem_bit(id, visit);

	set_task(0.1, "load_data", id);
}

public client_disconnected(id)
{
	save_data(id, mapChange ? 2 : 1);

	remove_task(id);
	remove_task(id + TASK_HUD);
	remove_task(id + TASK_TIME);
}

public load_data(id)
{
	if (!sqlConnected) {
		set_task(1.0, "load_data", id);

		return;
	}

	new playerId[1], queryData[128];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_ranks` WHERE name = ^"%s^";", playerData[id][SAFE_NAME]);

	SQL_ThreadQuery(sql, "load_data_handle", queryData, playerId, sizeof(playerId));
}

public load_data_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0];

	if (SQL_NumRows(query)) {
		playerData[id][KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "kills"));
		playerData[id][RANK] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rank"));
		playerData[id][TIME] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "time"));
		playerData[id][FIRST_VISIT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "firstvisit"));
		playerData[id][LAST_VISIT] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "lastvisit"));
		playerData[id][BRONZE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "bronze"));
		playerData[id][SILVER] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "silver"));
		playerData[id][GOLD] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "gold"));
		playerData[id][MEDALS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "medals"));
		playerData[id][BEST_STATS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "beststats"));
		playerData[id][BEST_KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "bestkills"));
		playerData[id][BEST_HS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "besths"));
		playerData[id][BEST_DEATHS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "bestdeaths"));

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "elorank"), playerData[id][ELO_RANK]);

		check_rank(id, 1);
	} else {
		new queryData[192], firstVisit = get_systime();

		formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO `csgo_ranks` (`name`, `firstvisit`, `elorank`) VALUES ('%s', '%i', '100');", playerData[id][SAFE_NAME], firstVisit);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	set_bit(id, loaded);

	new playerId[1], queryData[128];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_hud` WHERE name = ^"%s^";", playerData[id][SAFE_NAME]);

	SQL_ThreadQuery(sql, "load_hud_handle", queryData, playerId, sizeof(playerId));
}

public load_hud_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return;
	}

	new id = playerId[0];

	if (SQL_NumRows(query)) {
		playerData[id][PLAYER_HUD_RED] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "red"));
		playerData[id][PLAYER_HUD_GREEN] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "green"));
		playerData[id][PLAYER_HUD_BLUE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "blue"));
		playerData[id][PLAYER_HUD_POSX] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "x"));
		playerData[id][PLAYER_HUD_POSY] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "y"));
	} else {
		new queryData[192];

		formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO `csgo_hud` VALUES ('%s', '%i', '%i', '%i', '%i', '%i');",
			playerData[id][SAFE_NAME], playerData[id][PLAYER_HUD_RED], playerData[id][PLAYER_HUD_GREEN], playerData[id][PLAYER_HUD_BLUE], playerData[id][PLAYER_HUD_POSX], playerData[id][PLAYER_HUD_POSY]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	if (!task_exists(id + TASK_HUD)) set_task(0.1, "display_hud", id + TASK_HUD, .flags = "b");

	set_bit(id, hudLoaded);
}

stock save_data(id, end = 0)
{
	if (!get_bit(id, loaded)) return;

	new queryData[512], queryDataStats[128], queryDataMedals[128], playerId[1], time = playerData[id][TIME] + get_user_time(id);

	playerId[0] = id;

	playerData[id][CURRENT_STATS] = playerData[id][CURRENT_KILLS] * 2 + playerData[id][CURRENT_HS] - playerData[id][CURRENT_DEATHS] * 2;

	if (playerData[id][CURRENT_STATS] > playerData[id][BEST_STATS]) {
		formatex(queryDataStats, charsmax(queryDataStats), ", `bestkills` = %d, `besths` = %d, `bestdeaths` = %d, `beststats` = %d",
			playerData[id][CURRENT_KILLS], playerData[id][CURRENT_HS], playerData[id][CURRENT_DEATHS], playerData[id][CURRENT_STATS]);
	}

	new medals = playerData[id][GOLD] * 3 + playerData[id][SILVER] * 2 + playerData[id][BRONZE];

	if (medals > playerData[id][MEDALS]) {
		formatex(queryDataMedals, charsmax(queryDataMedals), ", `gold` = %d, `silver` = %d, `bronze` = %d, `medals` = %d",
			playerData[id][GOLD], playerData[id][SILVER], playerData[id][BRONZE], medals);
	}

	formatex(queryData, charsmax(queryData), "UPDATE `csgo_ranks` SET `kills` = %i, `rank` = %i, `elorank` = %f, `time` = %i, `lastvisit` = %i%s%s WHERE name = ^"%s^" AND `time` <= %i",
		playerData[id][KILLS], playerData[id][RANK], playerData[id][ELO_RANK], time, get_systime(), queryDataStats, queryDataMedals, playerData[id][SAFE_NAME], time);

	switch(end) {
		case 0, 1: SQL_ThreadQuery(sql, "ignore_handle", queryData, playerId, sizeof(playerId));
		case 2: {
			static error[128], errorNum, Handle:sqlConnection, Handle:query;

			sqlConnection = SQL_Connect(sql, errorNum, error, charsmax(error));

			if (!sqlConnection) return;

			query = SQL_PrepareQuery(sqlConnection, queryData);

			if (!SQL_Execute(query)) {
				errorNum = SQL_QueryError(query, error, charsmax(error));

				log_to_file("csgo-error.log", "Save suery nonthreaded failed. [%d] %s", errorNum, error);

				SQL_FreeHandle(query);
				SQL_FreeHandle(sqlConnection);

				return;
			}

			SQL_FreeHandle(query);
			SQL_FreeHandle(sqlConnection);
		}
	}

	if (end) rem_bit(id, loaded);
}

public ignore_handle(failState, Handle:query, error[], errorCode, data[], dataSize)
{
	if (failState == TQUERY_CONNECT_FAILED) log_to_file("csgo-error.log", "[CS:GO Ranks] Could not connect to SQL database. [%d] %s", errorCode, error);
	else if (failState == TQUERY_QUERY_FAILED) log_to_file("csgo-error.log", "[CS:GO Ranks] Query failed. [%d] %s", errorCode, error);
}

stock check_rank(id, check = 0)
{
	playerData[id][RANK] = 0;

	if (playerData[id][KILLS] < unrankedKills) return;

	while (playerData[id][RANK] < MAX_RANKS && playerData[id][ELO_RANK] >= rankElo[playerData[id][RANK] + 1]) {
		playerData[id][RANK]++;
	}

	if (!check) save_data(id);
}

public display_hud(id)
{
	id -= TASK_HUD;

	if (is_user_bot(id) || !is_user_connected(id) || !get_bit(id, hudLoaded)) return PLUGIN_CONTINUE;

	static address[64], clan[64], operation[64], skin[64], statTrak[64], account[64], weaponStatTrak = -1, target;

	target = id;

	if (!is_user_alive(id)) {
		target = pev(id, pev_iuser2);

		set_hudmessage(255, 255, 255, 0.7, 0.25, 0, 0.0, 0.3, 0.0, 0.0, 3);
	} else {
		set_hudmessage(playerData[id][PLAYER_HUD_RED], playerData[id][PLAYER_HUD_GREEN], playerData[id][PLAYER_HUD_BLUE], float(playerData[id][PLAYER_HUD_POSX]) / 100.0, float(playerData[id][PLAYER_HUD_POSY]) / 100.0, 0, 0.0, 0.3, 0.0, 0.0, 3);
	}

	if (!target || !get_bit(target, loaded)) return PLUGIN_CONTINUE;

	static seconds, minutes, hours;

	seconds = (playerData[target][TIME] + get_user_time(target))
	minutes = 0;
	hours = 0;

	while (seconds >= 60) {
		seconds -= 60;
		minutes++;
	}

	while (minutes >= 60) {
		minutes -= 60;
		hours++;
	}

	csgo_get_user_clan_name(target, clan, charsmax(clan));
	csgo_get_user_operation_text(target, operation, charsmax(operation));
	csgo_get_current_skin_name(target, skin, charsmax(skin));

	format(skin, charsmax(skin), "%L", id, "CSGO_RANKS_HUD_SKIN", skin);

	if (hudAccount) {
		if (csgo_get_user_svip(target)) {
			formatex(account, charsmax(account), "%L", id, "CSGO_RANKS_HUD_SUPERVIP");
		} else if (csgo_get_user_vip(target)) {
			formatex(account, charsmax(account), "%L", id, "CSGO_RANKS_HUD_VIP");
		} else {
			formatex(account, charsmax(account), "%L", id, "CSGO_RANKS_HUD_DEFAULT");
		}
	} else {
		account = "";
	}

	if (hudClan) {
		format(clan, charsmax(clan), "%L", id, "CSGO_RANKS_HUD_CLAN", clan);
	} else {
		clan = "";
	}

	if (hudOperation) {
		format(operation, charsmax(operation), "%L", id, "CSGO_RANKS_HUD_OPERATION", operation);
	} else {
		operation = "";
	}

	if (strlen(hudSite)) {
		formatex(address, charsmax(address), "%L", id, "CSGO_RANKS_HUD_SITE", hudSite);
	} else {
		address = "";
	}

	weaponStatTrak = csgo_get_weapon_stattrak(target, get_user_weapon(target));

	if (weaponStatTrak > -1) {
		format(statTrak, charsmax(statTrak), "%L", id, "CSGO_RANKS_HUD_STATTRAK", weaponStatTrak);
	} else {
		statTrak = "";
	}

	if (!playerData[target][RANK]) {
		ShowSyncHudMsg(id, hud, "%L", id, "CSGO_RANKS_HUD_NO_RANK", address, account, clan, rankName[playerData[target][RANK]], playerData[target][KILLS], unrankedKills, skin, statTrak, csgo_get_money(target), operation, hours, minutes, seconds);
	} else if (playerData[target][RANK] < MAX_RANKS) {
		ShowSyncHudMsg(id, hud, "%L", id, "CSGO_RANKS_HUD_RANK", address, account, clan, rankName[playerData[target][RANK]], playerData[target][ELO_RANK], rankElo[playerData[target][RANK] + 1], skin, statTrak, csgo_get_money(target), operation, hours, minutes, seconds);
	} else {
		ShowSyncHudMsg(id, hud, "%L", id, "CSGO_RANKS_HUD_MAX_RANK", address, account, clan, rankName[playerData[target][RANK]], playerData[target][ELO_RANK], skin, statTrak, csgo_get_money(target), operation, hours, minutes, seconds);
	}

	return PLUGIN_CONTINUE;
}

public player_spawn(id)
{
	if (!is_user_alive(id)) return;

	if (!task_exists(id + TASK_HUD)) set_task(0.1, "display_hud", id + TASK_HUD, .flags="b");

	if (!get_bit(id, visit)) set_task(3.0, "check_time", id + TASK_TIME);

	save_data(id);
}

public first_round()
	block = false;

public restart_round()
	round = 0;

public new_round()
{
	if (mapChange) return;

	if (!round) {
		set_task(30.0, "first_round");

		block = true;
	}

	round++;

	new bestId, bestFrags, tempFrags, bestDeaths, tempDeaths;

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) continue;

		tempFrags = get_user_frags(id);
		tempDeaths = get_user_deaths(id);

		if (tempFrags > 0 && tempFrags > bestFrags) {
			bestFrags = tempFrags;
			bestDeaths = tempDeaths;
			bestId = id;
		}
	}

	if (is_user_connected(bestId) && bestFrags) {
		new bestName[64];

		get_user_name(bestId, bestName, charsmax(bestName));

		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i)) continue;

			client_print_color(i, bestId, "%L", i, "CSGO_RANKS_CURRENT_LEADER", bestName, bestFrags, bestDeaths);
		}
	}
}

public client_death(killer, victim, weapon, hitPlace, TK)
{
	if (!is_user_connected(victim) || !is_user_connected(killer) || killer == victim) return;

	playerData[victim][CURRENT_DEATHS]++;

	playerData[killer][CURRENT_KILLS]++;
	playerData[killer][KILLS]++;

	if (hitPlace == HIT_HEAD) playerData[killer][CURRENT_HS]++;

	playerData[killer][ELO_RANK] = _:set_elo(playerData[killer][ELO_RANK], 1.0, get_elo(playerData[victim][ELO_RANK], playerData[killer][ELO_RANK]));
	playerData[victim][ELO_RANK] = floatmax(1.0, set_elo(playerData[victim][ELO_RANK], 0.0, get_elo(playerData[killer][ELO_RANK], playerData[victim][ELO_RANK])));

	check_rank(killer);
	check_rank(victim);

	client_print_color(victim, killer, "%L", victim, "CSGO_RANKS_KILLED", playerData[killer][PLAYER_NAME], get_user_health(killer));

	if (block) return;

	new tCount, ctCount, lastT, lastCT;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_alive(i)) continue;

		switch (get_user_team(i)) {
			case 1: {
				tCount++;
				lastT = i;
			} case 2: {
				ctCount++;
				lastCT = i;
			}
		}
	}

	if (tCount == 1 && ctCount == 1) {
		new nameT[32], nameCT[32];

		get_user_name(lastT, nameT, charsmax(nameT));
		get_user_name(lastCT, nameCT, charsmax(nameCT));

		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i)) continue;

			set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
			show_dhudmessage(i, "%L", i, "CSGO_RANKS_VS_NAMES", nameT, nameCT);
		}
	} else if (tCount == 1 && ctCount > 1) {
		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i)) continue;

			set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
			show_dhudmessage(i, "%L", i, "CSGO_RANKS_VS_NUMBERS", tCount, ctCount);
		}
	} else if (tCount > 1 && ctCount == 1) {
		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i)) continue;

			set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
			show_dhudmessage(i, "%L", i, "CSGO_RANKS_VS_NUMBERS", ctCount, tCount);
		}
	}
}

public bomb_explode(planter, defuser)
{
	if (get_playersnum() < minPlayers) return;

	playerData[planter][KILLS] += 3;
	playerData[planter][ELO_RANK] += 3.0;

	check_rank(planter);
}

public bomb_defused(defuser)
{
	if (get_playersnum() < minPlayers) return;

	playerData[defuser][KILLS] += 3;
	playerData[defuser][ELO_RANK] += 3.0;

	check_rank(defuser);
}

public hostages_rescued()
{
	if (get_playersnum() < minPlayers) return;

	new rescuer = get_loguser_index();

	playerData[rescuer][KILLS] += 3;
	playerData[rescuer][ELO_RANK] += 3.0;

	check_rank(rescuer);
}

public check_time(id)
{
	id -= TASK_TIME;

	if (get_bit(id, visit)) return;

	if (!get_bit(id, loaded)) {
		set_task(3.0, "check_time", id + TASK_TIME);

		return;
	}

	set_bit(id, visit);

	new time = get_systime(), visitYear, Year, visitMonth, Month, visitDay, Day, visitHour, visitMinutes, visitSeconds;

	UnixToTime(time, visitYear, visitMonth, visitDay, visitHour, visitMinutes, visitSeconds, UT_TIMEZONE_SERVER);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_VISIT_HOUR", visitHour, visitMinutes, visitSeconds, visitDay, visitMonth, visitYear);

	if (playerData[id][FIRST_VISIT] == playerData[id][LAST_VISIT]) client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_VISIT_FIRST");
	else {
		UnixToTime(playerData[id][LAST_VISIT], Year, Month, Day, visitHour, visitMinutes, visitSeconds, UT_TIMEZONE_SERVER);

		if (visitYear == Year && visitMonth == Month && visitDay == Day) client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_VISIT_TODAY", visitHour, visitMinutes, visitSeconds);
		else if (visitYear == Year && visitMonth == Month && (visitDay - 1) == Day) client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_VISIT_YESTERDAY", visitHour, visitMinutes, visitSeconds);
		else client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_VISIT_BEFORE", visitHour, visitMinutes, visitSeconds, Day, Month, Year);
	}
}

public cmd_menu(id)
{
	new menuData[64];

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_TITLE");

	new menu = menu_create(menuData, "cmd_menu_handle");

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_RANKS");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_RANK");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_TOP_RANKS");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_TIME");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_TOP_TIME");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_STATS");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_TOP_STATS");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_MEDALS");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_MENU_TOP_MEDALS");
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

public cmd_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: cmd_ranks(id);
		case 1: cmd_rank(id);
		case 2: cmd_topranks(id);
		case 3: cmd_time(id);
		case 4: cmd_toptime(id);
		case 5: cmd_stats(id);
		case 6: cmd_topstats(id);
		case 7: cmd_medals(id);
		case 8: cmd_topmedals(id);
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public cmd_ranks(id)
{
	new motdTitle[32], motdFile[32];

	formatex(motdTitle, charsmax(motdTitle), "%L", id, "CSGO_RANKS_MOTD_TITLE");
	formatex(motdFile, charsmax(motdFile), "%L", id, "CSGO_RANKS_MOTD_FILE");

	show_motd(id, motdFile, motdTitle);

	return PLUGIN_HANDLED;
}

public cmd_rank(id)
{
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_CURRENT_RANK", rankName[playerData[id][RANK]]);

	if (playerData[id][RANK] < MAX_RANKS && playerData[id][RANK] > 0) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_NEXT_RANK", rankName[playerData[id][RANK] + 1], rankElo[playerData[id][RANK] + 1] - playerData[id][ELO_RANK]);
	}

	return PLUGIN_HANDLED;
}

public cmd_topranks(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;

	format(queryData, charsmax(queryData), "SELECT name, elorank, rank FROM `csgo_ranks` WHERE rank > 0 ORDER BY elorank DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_topranks", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_topranks(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], nick[16], ranks[16], points[16], Float:elo, rank, topLength, place;

	topLength = 0, place = 0;

	new id = playerId[0];

	formatex(nick, charsmax(nick), "%L", id, "CSGO_RANKS_TOP_NICK");
	formatex(ranks, charsmax(ranks), "%L", id, "CSGO_RANKS_TOP_RANK");
	formatex(points, charsmax(points), "%L", id, "CSGO_RANKS_TOP_ELO");

	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %13s %4s^n", "#", nick, ranks, points);

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		SQL_ReadResult(query, 1, elo);

		rank = SQL_ReadResult(query, 2);

		if (place >= 10) topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %1s %12.2f^n", place, name, rankName[rank], elo);
		else topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %2s %12.2f^n", place, name, rankName[rank], elo);

		SQL_NextRow(query);
	}

	formatex(name, charsmax(name), "%L", id, "CSGO_RANKS_TOP15_RANKS");

	show_motd(id, topData, name);

	return PLUGIN_HANDLED;
}

public cmd_time(id)
{
	new queryData[192], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `csgo_ranks`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `csgo_ranks` WHERE `time` > '%i' ORDER BY `time` DESC) b", playerData[id][TIME] + get_user_time(id));

	SQL_ThreadQuery(sql, "show_time", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_time(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = playerId[0];

	new rank = SQL_ReadResult(query, 0) + 1, players = SQL_ReadResult(query, 1), seconds = (playerData[id][TIME] + get_user_time(id)), minutes, hours;

	while (seconds >= 60) {
		seconds -= 60;
		minutes++;
	}

	while (minutes >= 60) {
		minutes -= 60;
		hours++;
	}

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_TIME_INFO", hours, minutes, seconds);
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_TIME_TOP", rank, players);

	return PLUGIN_HANDLED;
}

public cmd_toptime(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;

	format(queryData, charsmax(queryData), "SELECT name, time FROM `csgo_ranks` ORDER BY time DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_toptime", queryData, playerId, sizeof(playerId));
}

public show_toptime(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], nick[16], time[16], topLength, place, seconds, minutes, hours;

	topLength = 0, place = 0;

	new id = playerId[0];

	formatex(nick, charsmax(nick), "%L", id, "CSGO_RANKS_TOP_NICK");
	formatex(time, charsmax(time), "%L", id, "CSGO_RANKS_TOP_TIME");

	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %9s^n", "#", nick, time);

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		seconds = SQL_ReadResult(query, 1);
		minutes = 0;
		hours = 0;

		while (seconds >= 60) {
			seconds -= 60;
			minutes++;
		}

		while (minutes >= 60) {
			minutes -= 60;
			hours++;
		}

		if (place >= 10) topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %0ih %1imin %1is^n", place, name, hours, minutes, seconds);
		else topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %1ih %1imin %1is^n", place, name, hours, minutes, seconds);

		SQL_NextRow(query);
	}

	formatex(name, charsmax(name), "%L", id, "CSGO_RANKS_TOP15_TIME");

	show_motd(id, topData, name);

	return PLUGIN_HANDLED;
}

public cmd_medals(id)
{
	new queryData[192], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `csgo_ranks`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `csgo_ranks` WHERE `medals` > '%i' ORDER BY `medals` DESC) b", playerData[id][MEDALS]);

	SQL_ThreadQuery(sql, "show_medals", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_medals(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = playerId[0], rank = SQL_ReadResult(query, 0) + 1, players = SQL_ReadResult(query, 1);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_MEDALS_INFO", playerData[id][GOLD], playerData[id][SILVER], playerData[id][BRONZE]);
	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_MEDALS_TOP", rank, players);

	return PLUGIN_HANDLED;
}

public cmd_topmedals(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;

	format(queryData, charsmax(queryData), "SELECT name, gold, silver, bronze, medals FROM `csgo_ranks` ORDER BY medals DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_topmedals", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_topmedals(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], nick[16], sum[16], goldTitle[16], silverTitle[16], bronzeTitle[16], topLength, place, gold, silver, bronze, medals;

	topLength = 0, place = 0;

	new id = playerId[0];

	formatex(nick, charsmax(nick), "%L", id, "CSGO_RANKS_TOP_NICK");
	formatex(sum, charsmax(sum), "%L", id, "CSGO_RANKS_TOP_SUM");
	formatex(goldTitle, charsmax(goldTitle), "%L", id, "CSGO_RANKS_TOP_GOLD");
	formatex(silverTitle, charsmax(silverTitle), "%L", id, "CSGO_RANKS_TOP_SILVER");
	formatex(bronzeTitle, charsmax(bronzeTitle), "%L", id, "CSGO_RANKS_TOP_BRONZE");

	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %6s %8s %8s %5s^n", "#", nick, goldTitle, silverTitle, bronzeTitle, sum);

	while (SQL_MoreResults(query)) {
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		gold = SQL_ReadResult(query, 1);
		silver = SQL_ReadResult(query, 2);
		bronze = SQL_ReadResult(query, 3);
		medals = SQL_ReadResult(query, 4);

		if (place >= 10) topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %2d %7d %8d %7d^n", place, name, gold, silver, bronze, medals);
		else topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %3d %7d %8d %7d^n", place, name, gold, silver, bronze, medals);

		SQL_NextRow(query);
	}

	formatex(name, charsmax(name), "%L", id, "CSGO_RANKS_TOP15_MEDALS");

	show_motd(id, topData, name);

	return PLUGIN_HANDLED;
}

public cmd_stats(id)
{
	new queryData[192], playerId[1];

	playerId[0] = id;

	playerData[id][CURRENT_STATS] = playerData[id][CURRENT_KILLS]*2 + playerData[id][CURRENT_HS] - playerData[id][CURRENT_DEATHS]*2;

	formatex(queryData, charsmax(queryData), "SELECT rank, count FROM (SELECT COUNT(*) as count FROM `csgo_ranks`) a CROSS JOIN (SELECT COUNT(*) as rank FROM `csgo_ranks` WHERE `beststats` > '%i' ORDER BY `beststats` DESC) b",
	playerData[id][CURRENT_STATS] > playerData[id][BEST_STATS] ? playerData[id][CURRENT_STATS] : playerData[id][BEST_STATS]);

	SQL_ThreadQuery(sql, "show_stats", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_stats(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = playerId[0], rank = SQL_ReadResult(query, 0) + 1, players = SQL_ReadResult(query, 1);

	if (playerData[id][CURRENT_STATS] > playerData[id][BEST_STATS]) client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_STATS_INFO", playerData[id][CURRENT_KILLS], playerData[id][CURRENT_HS], playerData[id][CURRENT_DEATHS]);
	else client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_STATS_INFO", playerData[id][BEST_KILLS], playerData[id][BEST_HS], playerData[id][BEST_DEATHS]);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_STATS_TOP", rank, players);

	return PLUGIN_HANDLED;
}

public cmd_topstats(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;

	format(queryData, charsmax(queryData), "SELECT name, bestkills, besths, bestdeaths FROM `csgo_ranks` ORDER BY beststats DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_topstats", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_topstats(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], nick[16], killsTitle[16], deathsTitle[16], topLength, place, kills, headShots, deaths;

	topLength = 0, place = 0;

	new id = playerId[0];

	formatex(nick, charsmax(nick), "%L", id, "CSGO_RANKS_TOP_NICK");
	formatex(killsTitle, charsmax(killsTitle), "%L", id, "CSGO_RANKS_TOP_KILLS");
	formatex(deathsTitle, charsmax(deathsTitle), "%L", id, "CSGO_RANKS_TOP_DEATHS");

	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %19s %4s^n", "#", nick, killsTitle, deathsTitle);

	while (SQL_MoreResults(query))
	{
		place++;

		SQL_ReadResult(query, 0, name, charsmax(name));

		replace_all(name, charsmax(name), "<", "");
		replace_all(name, charsmax(name), ">", "");

		kills = SQL_ReadResult(query, 1);
		headShots = SQL_ReadResult(query, 2);
		deaths = SQL_ReadResult(query, 3);

		if (place >= 10) topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %1d (%i HS) %12d^n", place, name, kills, headShots, deaths);
		else topLength += format(topData[topLength], charsmax(topData) - topLength, "%1i %-22.22s %2d (%i HS) %12d^n", place, name, kills, headShots, deaths);

		SQL_NextRow(query);
	}

	formatex(name, charsmax(name), "%L", id, "CSGO_RANKS_TOP15_STATS");

	show_motd(id, topData, name);

	return PLUGIN_HANDLED;
}

public hide_icon(id)
{
	if (get_xvar_num(defaultInfo)) return;

	ClearSyncHud(id, aimHUD);
}

public show_icon(id)
{
	new target = read_data(2);

	if (!is_user_alive(id) || !is_user_alive(target)) return;

	new color[2], Float:height, defaultHUD = get_xvar_num(defaultInfo), flags = read_flags(iconFlags), rank = playerData[target][RANK];

	if (get_user_team(target) == 1) color[0] = 255;
	else color[1] = 255;

	if (flags & BELOW_HEAD) height = 0.6;
	else height = 0.35;

	if (get_user_team(id) == get_user_team(target)) {
		if (flags && !defaultHUD) {
			new weaponName[32], weapon = get_user_weapon(target);

			if (weapon) xmod_get_wpnname(weapon, weaponName, charsmax(weaponName));

			set_hudmessage(color[0], 50, color[1], -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);

			if (flags & TEAM_RANK) {
				if (flags & STATS) ShowSyncHudMsg(id, aimHUD, "%s : %s^n%d HP | %d AP | %s", playerData[target][PLAYER_NAME], rankName[rank], get_user_health(target), get_user_armor(target), weaponName);
				else ShowSyncHudMsg(id, aimHUD, "%s : %s", playerData[target][PLAYER_NAME], rankName[rank]);
			} else {
				if (flags & STATS) ShowSyncHudMsg(id, aimHUD, "%s^n%d HP | %d AP | %s", playerData[target][PLAYER_NAME], get_user_health(target), get_user_armor(target), weaponName);
				else ShowSyncHudMsg(id, aimHUD, "%s", playerData[target][PLAYER_NAME]);
			}
		}

		create_attachment(id, target, 45, sprites[rank], 15);
	} else if (flags && !defaultHUD) {
		set_hudmessage(color[0], 50, color[1], -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);

		if (flags & ENEMY_RANK) ShowSyncHudMsg(id, aimHUD, "%s : %s", playerData[target][PLAYER_NAME], rankName[rank]);
		else ShowSyncHudMsg(id, aimHUD, "%s", playerData[target][PLAYER_NAME]);
	}
}

public message_intermission()
{
	mapChange = true;

	new playerName[32], medal[16], winnersId[3], winnersFrags[3], tempFrags, swapFrags, swapId;

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

		tempFrags = get_user_frags(id);

		if (tempFrags > winnersFrags[THIRD]) {
			winnersFrags[THIRD] = tempFrags;
			winnersId[THIRD] = id;

			if (tempFrags > winnersFrags[SECOND]) {
				swapFrags = winnersFrags[SECOND];
				swapId = winnersId[SECOND];
				winnersFrags[SECOND] = tempFrags;
				winnersId[SECOND] = id;
				winnersFrags[THIRD] = swapFrags;
				winnersId[THIRD] = swapId;

				if (tempFrags > winnersFrags[FIRST]) {
					swapFrags = winnersFrags[FIRST];
					swapId = winnersId[FIRST];
					winnersFrags[FIRST] = tempFrags;
					winnersId[FIRST] = id;
					winnersFrags[SECOND] = swapFrags;
					winnersId[SECOND] = swapId;
				}
			}
		}
	}

	if (!winnersId[FIRST]) return PLUGIN_CONTINUE;

	for (new i = 2; i >= 0; i--) {
		switch (i) {
			case THIRD: playerData[winnersId[i]][BRONZE]++;
			case SECOND: playerData[winnersId[i]][SILVER]++;
			case FIRST: {
				playerData[winnersId[i]][GOLD]++;

				csgo_add_money(winnersId[i], winnerReward);
			}
		}

		save_data(winnersId[i], 1);

		get_user_name(winnersId[i], playerName, charsmax(playerName));
	}

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_MEDALS_BEST");

		for (new i = 2; i >= 0; i--) {
			switch (i) {
				case THIRD: formatex(medal, charsmax(medal), "%L", id, "CSGO_RANKS_MEDALS_BRONZE");
				case SECOND: formatex(medal, charsmax(medal), "%L", id, "CSGO_RANKS_MEDALS_SILVER");
				case FIRST: formatex(medal, charsmax(medal), "%L", id, "CSGO_RANKS_MEDALS_GOLD");
			}

			if (i == FIRST) {
				client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_MEDALS_BEST_MVP", playerName, winnersFrags[i], medal);
			} else {
				client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_RANKS_MEDALS_BEST_EVP", playerName, winnersFrags[i], medal);
			}
		}
	}

	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) continue;

		save_data(id, 1);
	}

	return PLUGIN_CONTINUE;
}

public say_text(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);

	if (is_user_connected(id)) {
		new tempMessage[192], message[192], playerName[32], chatPrefix[16], stats[8], body[8], rank;

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));
		rank = get_user_stats(id, stats, body);

		if (rank > 3) return PLUGIN_CONTINUE;

		switch (rank) {
			case 1: formatex(chatPrefix, charsmax(chatPrefix), "^4[TOP1]");
			case 2: formatex(chatPrefix, charsmax(chatPrefix), "^4[TOP2]");
			case 3: formatex(chatPrefix, charsmax(chatPrefix), "^4[TOP3]");
		}

		if (!equal(tempMessage, "#Cstrike_Chat_All")) {
			add(message, charsmax(message), chatPrefix);
			add(message, charsmax(message), " ");
			add(message, charsmax(message), tempMessage);
		} else {
	        get_user_name(id, playerName, charsmax(playerName));

	        get_msg_arg_string(4, tempMessage, charsmax(tempMessage));
	        set_msg_arg_string(4, "");

	        add(message, charsmax(message), chatPrefix);
	        add(message, charsmax(message), "^3 ");
	        add(message, charsmax(message), playerName);
	        add(message, charsmax(message), "^1 :  ");
	        add(message, charsmax(message), tempMessage);
		}

		set_msg_arg_string(2, message);
	}

	return PLUGIN_CONTINUE;
}

public change_hud(id)
{
	if (!is_user_connected(id) || !get_bit(id, hudLoaded)) return PLUGIN_HANDLED;

	new menuData[64], menu;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_HUD_SETTINGS_TITLE");

	menu = menu_create(menuData, "change_hud_handle");

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_HUD_SETTINGS_RED", playerData[id][PLAYER_HUD_RED]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_HUD_SETTINGS_GREEN", playerData[id][PLAYER_HUD_GREEN]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_HUD_SETTINGS_BLUE", playerData[id][PLAYER_HUD_BLUE]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_HUD_SETTINGS_X", playerData[id][PLAYER_HUD_POSX]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_HUD_SETTINGS_Y", playerData[id][PLAYER_HUD_POSY]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_RANKS_HUD_SETTINGS_DEFAULT");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, menuData);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public change_hud_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: if ((playerData[id][PLAYER_HUD_RED] += 15) > 255) playerData[id][PLAYER_HUD_RED] = 0;
		case 1: if ((playerData[id][PLAYER_HUD_GREEN] += 15) > 255) playerData[id][PLAYER_HUD_GREEN] = 0;
		case 2: if ((playerData[id][PLAYER_HUD_BLUE] += 15) > 255) playerData[id][PLAYER_HUD_BLUE] = 0;
		case 3: if ((playerData[id][PLAYER_HUD_POSX] += 3) > 100) playerData[id][PLAYER_HUD_POSX] = 0;
		case 4: if ((playerData[id][PLAYER_HUD_POSY] += 3) > 100) playerData[id][PLAYER_HUD_POSY] = 0;
		case 5: {
			playerData[id][PLAYER_HUD_RED] = 0;
			playerData[id][PLAYER_HUD_GREEN] = 255;
			playerData[id][PLAYER_HUD_BLUE] = 0;
			playerData[id][PLAYER_HUD_POSX] = 70;
			playerData[id][PLAYER_HUD_POSY] = 6;
		}
	}

	menu_destroy(menu);

	save_hud(id);

	change_hud(id);

	return PLUGIN_CONTINUE;
}

public save_hud(id)
{
	if (!get_bit(id, hudLoaded)) return;

	new tempData[256];

	formatex(tempData, charsmax(tempData), "UPDATE `csgo_hud` SET `red` = '%i', `green` = '%i', `blue` = '%i', `x` = '%i', `y` = '%i' WHERE `name` = ^"%s^"",
			playerData[id][PLAYER_HUD_RED], playerData[id][PLAYER_HUD_GREEN], playerData[id][PLAYER_HUD_BLUE], playerData[id][PLAYER_HUD_POSX], playerData[id][PLAYER_HUD_POSY], playerData[id][PLAYER_NAME]);

	SQL_ThreadQuery(sql, "ignore_handle", tempData);
}

public _csgo_add_kill(id)
{
	playerData[id][CURRENT_KILLS]++;
	playerData[id][KILLS]++;
}

public _csgo_get_kills(id)
	return playerData[id][KILLS];

public _csgo_get_rank(id)
	return playerData[id][RANK];

public _csgo_get_rank_name(rank, dataReturn[], dataLength)
{
	param_convert(2);

	formatex(dataReturn, dataLength, rankName[rank]);
}

public _csgo_get_current_rank_name(id, dataReturn[], dataLength)
{
	param_convert(2);

	formatex(dataReturn, dataLength, rankName[playerData[id][RANK]]);
}

stock get_loguser_index()
{
	new logUser[80], name[32];

	read_logargv(0, logUser, charsmax(logUser));
	parse_loguser(logUser, name, charsmax(name));

	return get_user_index(name);
}

stock create_attachment(id, target, offset, sprite, life)
{
	if (!is_user_alive(id) || !is_user_alive(target)) return;

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(target);
	write_coord(offset);
	write_short(sprite);
	write_short(life);
	message_end();
}