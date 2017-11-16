#include <amxmodx>
#include <sqlx>
#include <csx>
#include <fakemeta>
#include <hamsandwich>
#include <unixtime>
#include <nvault>
#include <csgomod>

#define PLUGIN "CS:GO Rank System"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

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

new const commandRank[][] = { "ranga", "say /ranga", "say_team /ranga"};
new const commandRanks[][] = { "rangi", "say /rangi", "say_team /rangi"};
new const commandTopRanks[][] = { "toprangi", "say /toprangi", "say_team /toprangi", "say /rangitop15", "say_team /rangitop15", "say /rtop15", "say_team /rtop15"};
new const commandTime[][] = { "czas", "say /czas", "say_team /czas"};
new const commandTopTime[][] = { "topczas", "say /topczas", "say_team /topczas", "say /czastop15", "say_team /czastop15", "say /ctop15", "say_team /ctop15"};
new const commandMedals[][] = { "medale", "say /medale", "say_team /medale"};
new const commandTopMedals[][] = { "topmedale", "say /topmedale", "say_team /topmedale", "say /medaletop15", "say_team /medaletop15", "say /mtop15", "say_team /mtop15"};
new const commandStats[][] = { "staty", "say /staty", "say_team /staty"};
new const commandTopStats[][] = { "topstaty", "say /topstaty", "say_team /topstaty", "say /statytop15", "say_team /statytop15", "say /stop15", "say_team /stop15"};
new const commandSounds[][] = { "dzwieki", "say /dzwieki", "say_team /dzwieki", "say /dzwiek", "say_team /dzwiek" };

enum _:playerInfo { KILLS, RANK, TIME, FIRST_VISIT, LAST_VISIT, BRONZE, SILVER, GOLD, MEDALS, BEST_STATS, BEST_KILLS, BEST_DEATHS, 
	BEST_HS, CURRENT_STATS, CURRENT_KILLS, CURRENT_DEATHS, CURRENT_HS, Float:ELO_RANK, PLAYER_NAME[32], SAFE_NAME[64] };

enum _:winers { THIRD, SECOND, FIRST };

new playerData[MAX_PLAYERS + 1][playerInfo], sprites[MAX_RANKS + 1], Handle:sql, bool:oneAndOnly, bool:mapChange,
	bool:block, loaded, visit, hud, aimHUD, defaultInfo, round, sounds, soundMayTheForce, soundOneAndOnly, 
	soundPrepare, soundHumiliation, soundLastLeft, forum[64], iconFlags[8], unrankedKills;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("csgo_unrankedKills", "100"), unrankedKills);
	bind_pcvar_string(create_cvar("csgo_forum", "CS-Reload.pl"), forum, charsmax(forum));
	bind_pcvar_string(create_cvar("csgo_icon_flags", "abcd"), iconFlags, charsmax(iconFlags));

	for (new i; i < sizeof commandRank; i++) register_clcmd(commandRank[i], "cmd_rank");
	for (new i; i < sizeof commandRanks; i++) register_clcmd(commandRanks[i], "cmd_ranks");
	for (new i; i < sizeof commandTopRanks; i++) register_clcmd(commandTopRanks[i], "cmd_topranks");
	for (new i; i < sizeof commandTime; i++) register_clcmd(commandTime[i], "cmd_time");
	for (new i; i < sizeof commandTopTime; i++) register_clcmd(commandTopTime[i], "cmd_toptime");
	for (new i; i < sizeof commandMedals; i++) register_clcmd(commandMedals[i], "cmd_medals");
	for (new i; i < sizeof commandTopMedals; i++) register_clcmd(commandTopMedals[i], "cmd_topmedals");
	for (new i; i < sizeof commandStats; i++) register_clcmd(commandStats[i], "cmd_stats");
	for (new i; i < sizeof commandTopStats; i++) register_clcmd(commandTopStats[i], "cmd_topstats");
	for (new i; i < sizeof commandSounds; i++) register_clcmd(commandSounds[i], "cmd_sounds");

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

	sounds = nvault_open("stats_sound");
}

public plugin_cfg()
	sql_init();
	
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
			log_to_file("csgo-error.log", "[CS:GO] Brakujacy plik sprite: ^"%s^"", spriteFile);

			error = true;
		} else sprites[i] = precache_model(spriteFile);
	}
	
	if (error) set_fail_state("Brakuje plikow sprite, zaladowanie pluginu niemozliwe! Sprawdz logi w pliku csgo/error.log!");

	precache_sound("misc/csr/maytheforce.wav");
	precache_sound("misc/csr/oneandonly.wav");
	precache_sound("misc/csr/prepare.wav");
	precache_sound("misc/csr/humiliation.wav");
	precache_sound("misc/csr/lastleft.wav");
}

public sql_init()
{
	new host[32], user[32], pass[32], database[32], error[128], errorNum;
	
	get_cvar_string("csgo_sql_host", host, charsmax(host));
	get_cvar_string("csgo_sql_user", user, charsmax(user));
	get_cvar_string("csgo_sql_pass", pass, charsmax(pass));
	get_cvar_string("csgo_sql_db", database, charsmax(database));
	
	sql = SQL_MakeDbTuple(host, user, pass, database);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum) {
		log_to_file("csgo-error.log", "Error: %s (%i)", error, errorNum);
		
		return;
	}

	new queryData[512];
	
	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_ranks` (`name` varchar(32) NOT NULL, `kills` int(10) NOT NULL, `rank` int(10) NOT NULL, `time` int(10) NOT NULL, ");
	add(queryData, charsmax(queryData), "`firstvisit` int(10) NOT NULL, `lastvisit` int(10) NOT NULL, `gold` int(10) NOT NULL, `silver` int(10) NOT NULL, `bronze` int(10) NOT NULL, `medals` int(10) NOT NULL, ");
	add(queryData, charsmax(queryData), "`bestkills` int(10) NOT NULL, `bestdeaths` int(10) NOT NULL, `besths` int(10) NOT NULL, `beststats` int(10) NOT NULL, `elorank` double NOT NULL, PRIMARY KEY (`name`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);
	
	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return;
		
	get_user_name(id, playerData[id][PLAYER_NAME], charsmax(playerData[][PLAYER_NAME]));

	mysql_escape_string(playerData[id][PLAYER_NAME], playerData[id][SAFE_NAME], charsmax(playerData[][SAFE_NAME]));

	for (new i = KILLS; i <= CURRENT_HS; i++) playerData[id][i] = 0;

	playerData[id][ELO_RANK] = _:100.0;

	rem_bit(id, loaded);
	rem_bit(id, visit);
	rem_bit(id, soundMayTheForce);
	rem_bit(id, soundOneAndOnly);
	rem_bit(id, soundHumiliation);
	rem_bit(id, soundLastLeft);
	rem_bit(id, soundPrepare);
	
	set_task(0.1, "load_data", id);
}
	
public client_disconnected(id)
{
	save_data(id, mapChange ? 2 : 1);
	
	remove_task(id);
	remove_task(id + TASK_HUD);
	remove_task(id + TASK_TIME);

	rem_bit(id, soundMayTheForce);
	rem_bit(id, soundOneAndOnly);
	rem_bit(id, soundHumiliation);
	rem_bit(id, soundLastLeft);
	rem_bit(id, soundPrepare);
}

public load_data(id)
{
	new playerId[1], queryData[128];
	
	playerId[0] = id;
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_ranks` WHERE name = ^"%s^";", playerData[id][SAFE_NAME]);
	
	SQL_ThreadQuery(sql, "load_data_handle", queryData, playerId, sizeof(playerId));
}

public load_data_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
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
	
	if (!task_exists(id + TASK_HUD)) set_task(1.0, "display_hud", id + TASK_HUD, .flags = "b");

	set_bit(id, loaded);
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
				
				log_to_file("csgo-error.log", "Save Query Nonthreaded failed. [%d] %s", errorNum, error);
				
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

public ignore_handle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if (FailState == TQUERY_CONNECT_FAILED) log_to_file("csgo-error.log", "[CS:GO Ranks] Could not connect to SQL database. [%d] %s", ErrCode, Error);
	else if (FailState == TQUERY_QUERY_FAILED) log_to_file("csgo-error.log", "[CS:GO Ranks] Query failed. [%d] %s", ErrCode, Error);
}

stock check_rank(id, check = 0)
{
	playerData[id][RANK] = 0;

	if (playerData[id][KILLS] < unrankedKills) return;

	while (playerData[id][RANK] < MAX_RANKS && playerData[id][ELO_RANK] >= rankElo[playerData[id][RANK] + 1]) playerData[id][RANK]++;

	if (!check) save_data(id);
}

public display_hud(id) 
{
	id -= TASK_HUD;

	if (is_user_bot(id) || !is_user_connected(id)) return PLUGIN_CONTINUE;

	remove_task(id + 768, 1);

	static operation[64], skin[64], target;

	target = id;

	if (!is_user_alive(id)) {
		target = pev(id, pev_iuser2);

		set_hudmessage(255, 255, 255, 0.7, 0.25, 0, 0.0, 1.2, 0.0, 0.0, 3);
	} else set_hudmessage(0, 255, 0, 0.7, 0.06, 0, 0.0, 1.2, 0.0, 0.0, 3);

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

	csgo_get_user_operation_text(target, operation, charsmax(operation));
	csgo_get_current_skin_name(target, skin, charsmax(skin));

	format(skin, charsmax(skin), "^n[Skin : %s]", skin);
	format(operation, charsmax(operation), "^n[Operacja : %s]", operation);
	
	if (!playerData[target][RANK]) ShowSyncHudMsg(id, hud, "[Forum : %s]^n[Konto : %s]^n[Ranga : %s (%i / %i)]%s^n[Stan Konta : %.2f Euro]%s^n[Czas Gry : %i h %i min %i s]", 
		forum, (csgo_get_user_svip(target) ? "SuperVIP" : csgo_get_user_vip(target) ? "VIP" : "Zwykle"), rankName[playerData[target][RANK]], playerData[target][KILLS], unrankedKills, skin, csgo_get_money(target), operation, hours, minutes, seconds);
	else if (playerData[target][RANK] < MAX_RANKS) ShowSyncHudMsg(id, hud, "[Forum : %s]^n[Konto : %s]^n[Ranga : %s]^n[Punkty Elo : %.2f / %d]%s^n[Stan Konta : %.2f Euro]%s^n[Czas Gry : %i h %i min %i s]", 
		forum, (csgo_get_user_svip(target) ? "SuperVIP" : csgo_get_user_vip(target) ? "VIP" : "Zwykle"), rankName[playerData[target][RANK]], playerData[target][ELO_RANK], rankElo[playerData[target][RANK] + 1], skin, csgo_get_money(target), operation, hours, minutes, seconds);
	else ShowSyncHudMsg(id, hud, "[Forum : %s]^n[Konto : %s]^n[Ranga : %s]^n[Punkty Elo : %.2f]%s^n[Stan Konta : %.2f Euro]%s^n[Czas Gry : %i h %i min %i s]", 
		forum, (csgo_get_user_svip(target) ? "SuperVIP" : csgo_get_user_vip(target) ? "VIP" : "Zwykle"), rankName[playerData[target][RANK]], playerData[target][ELO_RANK], skin, csgo_get_money(target), operation, hours, minutes, seconds);

	return PLUGIN_CONTINUE;
}

public player_spawn(id)
{
	if (!is_user_alive(id)) return;
		
	if (!task_exists(id + TASK_HUD)) set_task(1.0, "display_hud", id + TASK_HUD, .flags="b");

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

	oneAndOnly = false;

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

		client_print_color(0, bestId, "** ^x03 %s^x01 prowadzi w grze z^x04 %i^x01 fragami i^x04 %i^x01 zgonami. **", bestName, bestFrags, bestDeaths);
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

	client_print_color(victim, killer, "** Zostales zabity przez^x03 %s^x01, ktoremu zostalo^x04 %i^x01 HP. **", playerData[killer][PLAYER_NAME], get_user_health(killer));

	if (weapon == CSW_KNIFE) {
		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i)) continue;

			if ((pev(i, pev_iuser2) == victim || i == victim) && get_bit(i, soundHumiliation)) client_cmd(i, "spk misc/csr/humiliation");
		}
	}

	if (block) return;

	new tCount, ctCount, lastT, lastCT;

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_alive(i)) continue;

		switch(get_user_team(i)) {
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
		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i)) continue;

			if ((pev(i, pev_iuser2) == lastT || pev(i, pev_iuser2) == lastCT || i == lastT || i == lastCT) && get_bit(i, soundMayTheForce)) client_cmd(i, "spk misc/csr/maytheforce");
		}

		new nameT[32], nameCT[32];

		get_user_name(lastT, nameT, charsmax(nameT));
		get_user_name(lastCT, nameCT, charsmax(nameCT));

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
		show_dhudmessage(0, "%s vs. %s", nameT, nameCT);
	}

	if (tCount == 1 && ctCount > 1 && !oneAndOnly) {
		oneAndOnly = true;

		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i)) continue;

			if (((is_user_alive(i) && get_user_team(i) == 2) || (!is_user_alive(i) && get_user_team(pev(i, pev_iuser2)) == 2)) && get_bit(i, soundLastLeft)) client_cmd(i, "spk misc/csr/lastleft");

			if ((pev(i, pev_iuser2) == lastT || i == lastT) && get_bit(i, soundOneAndOnly)) client_cmd(i, "spk misc/csr/oneandonly");
		}

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
		show_dhudmessage(0, "%i vs %i", tCount, ctCount);
	}

	if (tCount > 1 && ctCount == 1 && !oneAndOnly) {
		oneAndOnly = true;

		for (new i = 1; i <= MAX_PLAYERS; i++) {
			if (!is_user_connected(i)) continue;
			
			if (((is_user_alive(i) && get_user_team(i) == 1) || (!is_user_alive(i) && get_user_team(pev(i, pev_iuser2)) == 1)) && get_bit(i, soundLastLeft)) client_cmd(i, "spk misc/csr/lastleft");

			if ((pev(i, pev_iuser2) == lastCT || i == lastCT) && get_bit(i, soundOneAndOnly)) client_cmd(i, "spk misc/csr/oneandonly");
		}

		set_dhudmessage(255, 128, 0, -1.0, 0.30, 0, 5.0, 5.0, 0.5, 0.15);
		show_dhudmessage(0, "%i vs %i", ctCount, tCount);
	}
}

public bomb_planted(planter)
{
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i)) continue;

		if (((is_user_alive(i) && get_user_team(i) == 2) || (!is_user_alive(i) && get_user_team(pev(i, pev_iuser2)) == 2)) && get_bit(i, soundPrepare)) client_cmd(i, "spk misc/csr/prepare");
	}
}

public bomb_explode(planter, defuser)
{
	playerData[planter][KILLS] += 3;
	playerData[planter][ELO_RANK] += 3.0;

	check_rank(planter);
}

public bomb_defused(defuser)
{
	playerData[defuser][KILLS] += 3;
	playerData[defuser][ELO_RANK] += 3.0;

	check_rank(defuser);
}

public hostages_rescued()
{
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
	
	client_print_color(id, id, "^x04[CS:GO]^x01 Aktualnie jest godzina^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01.", visitHour, visitMinutes, visitSeconds, visitDay, visitMonth, visitYear);
	
	if (playerData[id][FIRST_VISIT] == playerData[id][LAST_VISIT]) client_print_color(id, id, "^x03[CS:GO]^x01 To twoja^x04 pierwsza wizyta^x01 na serwerze. Zyczymy milej gry!" );
	else {
		UnixToTime(playerData[id][LAST_VISIT], Year, Month, Day, visitHour, visitMinutes, visitSeconds, UT_TIMEZONE_SERVER);
		
		if (visitYear == Year && visitMonth == Month && visitDay == Day) client_print_color(id, id, "^x04[CS:GO]^x01 Twoja ostatnia wizyta miala miejsce^x03 dzisiaj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", visitHour, visitMinutes, visitSeconds);
		else if (visitYear == Year && visitMonth == Month && (visitDay - 1) == Day) client_print_color(id, id, "^x04[CS:GO]^x01 Twoja ostatnia wizyta miala miejsce^x03 wczoraj^x01 o^x03 %02d:%02d:%02d^x01. Zyczymy milej gry!", visitHour, visitMinutes, visitSeconds);
		else client_print_color(id, id, "^x04[CS:GO]^x01 Twoja ostatnia wizyta:^x03 %02d:%02d:%02d (Data: %02d.%02d.%02d)^x01. Zyczymy milej gry!", visitHour, visitMinutes, visitSeconds, Day, Month, Year);
	}
}

public cmd_ranks(id)
{
	show_motd(id, "ranks.txt", "Lista Dostepnych Rang");

	return PLUGIN_HANDLED;
}

public cmd_rank(id)
{
	if (playerData[id][RANK] == MAX_RANKS) client_print_color(id, id, "^x04[CS:GO]^x01 Twoja aktualna ranga to:^x03 %s^x01.", rankName[playerData[id][RANK]]);
	else {
		client_print_color(id, id, "^x04[CS:GO]^x01 Twoja aktualna ranga to:^x03 %s^x01. ", rankName[playerData[id][RANK]]);
		client_print_color(id, id, "^x04[CS:GO]^x01 Do kolejnej rangi (^x03%s^x01) potrzebujesz^x03 %.2f^x01 punktow Elo.", rankName[playerData[id][RANK] + 1], rankElo[playerData[id][RANK] + 1] - playerData[id][ELO_RANK]);
	}

	return PLUGIN_HANDLED;
}

public cmd_topranks(id)
{
	new queryData[128], playerId[1];

	playerId[0] = id;
	
	format(queryData, charsmax(queryData), "SELECT name, elorank, rank FROM `csgo_ranks` ORDER BY elorank DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_topranks", queryData, playerId, sizeof(playerId));

	return PLUGIN_HANDLED;
}

public show_topranks(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], Float:elo, rank, topLength, place;

	topLength = 0, place = 0;
	
	new id = playerId[0];
	
	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %13s %4s^n", "#", "Nick", "Ranga", "Elo");
	
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
	
	show_motd(id, topData, "Top15 Rang");
	
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
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
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
	
	client_print_color(id, id, "^x04[CS:GO]^x01 Spedziles na serwerze lacznie^x03 %i h %i min %i s^x01.", hours, minutes, seconds);
	client_print_color(id, id, "^x04[CS:GO]^x01 Zajmujesz^x03 %i/%i^x01 miejsce w rankingu czasu gry.", rank, players);

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
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], topLength, place, seconds, minutes, hours;

	topLength = 0, place = 0;
	
	new id = playerId[0];
	
	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %9s^n", "#", "Nick", "Czas Gry");
	
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
	
	show_motd(id, topData, "Top15 Czasu Gry");
	
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
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = playerId[0], rank = SQL_ReadResult(query, 0) + 1, players = SQL_ReadResult(query, 1);
	
	client_print_color(id, id, "^x04[CS:GO]^x01 Twoje medale:^x03 %i Zlote^x01,^x03 %i Srebre^x01,^x03 %i Brazowe^x01.", playerData[id][GOLD], playerData[id][SILVER], playerData[id][BRONZE]);
	client_print_color(id, id, "^x04[CS:GO]^x01 Zajmujesz^x03 %i/%i^x01 miejsce w rankingu medalowym.", rank, players);
	
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
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], topLength, place, gold, silver, bronze, medals;

	topLength = 0, place = 0;
	
	new id = playerId[0];
	
	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %6s %8s %8s %5s^n", "#", "Nick", "Zlote", "Srebrne", "Brazowe", "Suma");
	
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
	
	show_motd(id, topData, "Top15 Medali");
	
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
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = playerId[0], rank = SQL_ReadResult(query, 0) + 1, players = SQL_ReadResult(query, 1);
	
	if (playerData[id][CURRENT_STATS] > playerData[id][BEST_STATS]) client_print_color(id, id, "^x04[CS:GO]^x01 Twoje najlepsze staty to^x03 %i^x01 zabic (w tym^x03 %i^x01 z HS) i^x03 %i^x01 zgonow^x01.", playerData[id][CURRENT_KILLS], playerData[id][CURRENT_HS], playerData[id][CURRENT_DEATHS]);
	else client_print_color(id, id, "^x04[CS:GO]^x01 Twoje najlepsze staty to^x03 %i^x01 zabic (w tym^x03 %i^x01 z HS) i^x03 %i^x01 zgonow^x01.", playerData[id][BEST_KILLS], playerData[id][BEST_HS], playerData[id][BEST_DEATHS]);
		
	client_print_color(id, id, "^x04[CS:GO]^x01 Zajmujesz^x03 %i/%i^x01 miejsce w rankingu najlepszych statystyk.", rank, players);
	
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
		log_to_file("csgo-error.log", "[CS:GO Stats] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}

	static topData[2048], name[32], topLength, place, kills, headShots, deaths;

	topLength = 0, place = 0;
	
	new id = playerId[0];
	
	topLength = format(topData, charsmax(topData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	topLength += format(topData[topLength], charsmax(topData) - topLength, "%1s %-22.22s %19s %4s^n", "#", "Nick", "Zabojstwa", "Zgony");
	
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
	
	show_motd(id, topData, "Top15 Statystyk");
	
	return PLUGIN_HANDLED;
}

public hide_icon(id)
{
	if (get_xvar_num(defaultInfo)) return;

	ClearSyncHud(id, aimHUD);
}

public show_icon(id)
{
	new color[2], Float:height, defaultHUD = get_xvar_num(defaultInfo), flags = read_flags(iconFlags), target = read_data(2), rank = playerData[target][RANK];

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

	new playerName[32], winnersId[3], winnersFrags[3], tempFrags, swapFrags, swapId;

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

	new const medals[][] = { "Brazowy", "Srebrny", "Zloty" };

	client_print_color(0, 0, "^x04[CS:GO]^x01 Gratulacje dla^x03 Najlepszych Graczy^x01!");
	
	for (new i = 2; i >= 0; i--) {
		switch(i) {
			case THIRD: playerData[winnersId[i]][BRONZE]++;
			case SECOND: playerData[winnersId[i]][SILVER]++;
			case FIRST: {
				playerData[winnersId[i]][GOLD]++;

				csgo_add_money(winnersId[i], 10.0);
			}
		}

		save_data(winnersId[i], 1);
		
		get_user_name(winnersId[i], playerName, charsmax(playerName));

		client_print_color(0, 0, "^x04[CS:GO]^x03 %s^x01 -^x03 %i^x01 Zabojstw - %s Medal%s.", playerName, winnersFrags[i], medals[i], i == FIRST ? " (MVP)" : "");
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
			case 1: formatex(chatPrefix, charsmax(chatPrefix), "^x04[TOP1]");
			case 2: formatex(chatPrefix, charsmax(chatPrefix), "^x04[TOP2]");
			case 3: formatex(chatPrefix, charsmax(chatPrefix), "^x04[TOP3]");
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
	        add(message, charsmax(message), "^x03 ");
	        add(message, charsmax(message), playerName);
	        add(message, charsmax(message), "^x01 :  ");
	        add(message, charsmax(message), tempMessage);
		}
		
		set_msg_arg_string(2, message);
	}

	return PLUGIN_CONTINUE;
}

public save_sounds(id)
{
	new vaultKey[64], vaultData[16];
	
	formatex(vaultKey, charsmax(vaultKey), "%s-sounds", playerData[id][PLAYER_NAME]);
	formatex(vaultData, charsmax(vaultData), "%d %d %d %d %d", get_bit(id, soundMayTheForce), get_bit(id, soundOneAndOnly), get_bit(id, soundHumiliation), get_bit(id, soundPrepare), get_bit(id, soundLastLeft));
	
	nvault_set(sounds, vaultKey, vaultData);
	
	return PLUGIN_CONTINUE;
}

public load_sounds(id)
{
	new vaultKey[64], vaultData[16], soundsData[5][5];
	
	formatex(vaultKey, charsmax(vaultKey), "%s-sounds", playerData[id][PLAYER_NAME]);
	
	if (nvault_get(sounds, vaultKey, vaultData, charsmax(vaultData)))
	{
		parse(vaultData, soundsData[0], charsmax(soundsData), soundsData[1], charsmax(soundsData), soundsData[2], charsmax(soundsData), soundsData[3], charsmax(soundsData), soundsData[4], charsmax(soundsData));

		if (str_to_num(soundsData[0])) set_bit(id, soundMayTheForce);
		if (str_to_num(soundsData[1])) set_bit(id, soundOneAndOnly);
		if (str_to_num(soundsData[2])) set_bit(id, soundHumiliation);
		if (str_to_num(soundsData[3])) set_bit(id, soundPrepare);
		if (str_to_num(soundsData[4])) set_bit(id, soundLastLeft);
	}

	return PLUGIN_CONTINUE;
} 

public cmd_sounds(id)
{
	new menuData[64], menu = menu_create("\yUstawienia \rDzwiekow\w:", "cmd_sounds_Handle");

	formatex(menuData, charsmax(menuData), "\wThe Force Will Be With You \w[\r%s\w]", get_bit(id, soundMayTheForce) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wI Am The One And Only \w[\r%s\w]", get_bit(id, soundOneAndOnly) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wDziabnal Mnie \w[\r%s\w]", get_bit(id, soundHumiliation) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wKici Kici Tas Tas \w[\r%s\w]", get_bit(id, soundLastLeft) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "\wNie Obijac Sie \w[\r%s\w]", get_bit(id, soundPrepare) ? "Wlaczony" : "Wylaczony");
	menu_additem(menu, menuData);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public cmd_sounds_Handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	
	switch(item) {
		case 0: get_bit(id, soundMayTheForce) ? rem_bit(id, soundMayTheForce) : set_bit(id, soundMayTheForce);
		case 1: get_bit(id, soundOneAndOnly) ? rem_bit(id, soundOneAndOnly) : set_bit(id, soundOneAndOnly);
		case 2: get_bit(id, soundHumiliation) ? rem_bit(id, soundHumiliation) : set_bit(id, soundHumiliation);
		case 3: get_bit(id, soundLastLeft) ? rem_bit(id, soundLastLeft) : set_bit(id, soundLastLeft);
		case 4: get_bit(id, soundPrepare) ? rem_bit(id, soundPrepare) : set_bit(id, soundPrepare);
	}
	
	save_sounds(id);

	cmd_sounds(id);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
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

stock create_attachment(id, entity, offset, sprite, life)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(entity);
	write_coord(offset);
	write_short(sprite);
	write_short(life);
	message_end();
}