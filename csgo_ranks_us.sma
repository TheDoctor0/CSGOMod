#include <amxmodx>
#include <sqlx>
#include <fakemeta>
#include <csgomod>
#include <ultimate_stats>

#define PLUGIN "CS:GO Rank System (Ultimate Stats)"
#define VERSION "1.5"
#define AUTHOR "O'Zone"

#define TASK_HUD 7501

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
	360,
	380,
	400
};

new const commandRank[][] = { "ranga", "say /ranga", "say_team /ranga"};
new const commandRanks[][] = { "rangi", "say /rangi", "say_team /rangi"};
new const commandTopRanks[][] = { "toprangi", "say /toprangi", "say_team /toprangi", "say /rangitop15", "say_team /rangitop15", "say /rtop15", "say_team /rtop15"};

enum _:playerInfo { KILLS, RANK, Float:ELO_RANK, PLAYER_NAME[32], SAFE_NAME[64] };

new playerData[MAX_PLAYERS + 1][playerInfo], sprites[MAX_RANKS + 1], Handle:sql, bool:sqlConnected, loaded, hud, aimHUD, defaultInfo, forum[64], iconFlags[8], unrankedKills, minPlayers;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("csgo_min_players", "4"), minPlayers);
	bind_pcvar_num(create_cvar("csgo_unranked_kills", "100"), unrankedKills);
	bind_pcvar_string(create_cvar("csgo_forum", "AdresForum.pl"), forum, charsmax(forum));
	bind_pcvar_string(create_cvar("csgo_icon_flags", "abcd"), iconFlags, charsmax(iconFlags));

	for (new i; i < sizeof commandRank; i++) register_clcmd(commandRank[i], "cmd_rank");
	for (new i; i < sizeof commandRanks; i++) register_clcmd(commandRanks[i], "cmd_ranks");
	for (new i; i < sizeof commandTopRanks; i++) register_clcmd(commandTopRanks[i], "cmd_topranks");

	register_event("TextMsg", "hostages_rescued", "a", "2&#All_Hostages_R");
	register_event("StatusValue", "show_icon", "be", "1=2", "2!0");
	register_event("StatusValue", "hide_icon", "be", "1=1", "2=0");

	defaultInfo = get_xvar_id("PlayerName");

	hud = CreateHudSyncObj();
	aimHUD = CreateHudSyncObj();
}

public plugin_cfg()
	sql_init();

public plugin_end()
	SQL_FreeHandle(sql);

public plugin_natives()
{
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

	new queryData[128];

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_ranks` (`name` varchar(32) NOT NULL, `rank` int(10) NOT NULL, `elorank` double NOT NULL, PRIMARY KEY (`name`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);

	sqlConnected = true;
}

stock save_rank(id)
{
	if (!get_bit(id, loaded) || !sqlConnected) return;

	new queryData[256], playerId[1];

	playerId[0] = id;

	formatex(queryData, charsmax(queryData), "REPLACE INTO `csgo_ranks` (`name`, `rank`, `elorank`) VALUES (^"%s^", '%i', '%f');",
	playerData[id][SAFE_NAME], playerData[id][RANK], playerData[id][ELO_RANK]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData, playerId, sizeof(playerId));
}

public ignore_handle(FailState, Handle:Query, Error[], ErrCode, Data[], DataSize)
{
	if (FailState == TQUERY_CONNECT_FAILED) log_to_file("csgo-error.log", "[CS:GO Ranks] Could not connect to SQL database. [%d] %s", ErrCode, Error);
	else if (FailState == TQUERY_QUERY_FAILED) log_to_file("csgo-error.log", "[CS:GO Ranks] Query failed. [%d] %s", ErrCode, Error);
}

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return;

	get_user_name(id, playerData[id][PLAYER_NAME], charsmax(playerData[][PLAYER_NAME]));

	mysql_escape_string(playerData[id][PLAYER_NAME], playerData[id][SAFE_NAME], charsmax(playerData[][SAFE_NAME]));
}

public client_disconnected(id)
{
	playerData[id][KILLS] = 0;
	playerData[id][ELO_RANK] = _:100.0;

	remove_task(id + TASK_HUD);

	rem_bit(id, loaded);
}

public stats_loaded(id)
{
	set_bit(id, loaded);

	check_rank(id);

	if (!task_exists(id + TASK_HUD)) set_task(1.0, "display_hud", id + TASK_HUD, .flags = "b");
}

stock check_rank(id)
{
	new stats[8], body[8];

	get_user_stats(id, stats, body);

	playerData[id][KILLS] = stats[0];
	playerData[id][RANK] = 0;

	if (playerData[id][KILLS] >= unrankedKills) {
		playerData[id][ELO_RANK] = _:get_user_elo(id);

		while (playerData[id][RANK] < MAX_RANKS && playerData[id][ELO_RANK] >= rankElo[playerData[id][RANK] + 1]) playerData[id][RANK]++;
	}

	save_rank(id);
}

public display_hud(id)
{
	id -= TASK_HUD;

	if (is_user_bot(id) || !is_user_connected(id)) return PLUGIN_CONTINUE;

	remove_task(id + 768, 1);

	static clan[64], operation[64], skin[64], target;

	target = id;

	if (!is_user_alive(id)) {
		target = pev(id, pev_iuser2);

		set_hudmessage(255, 255, 255, 0.7, 0.25, 0, 0.0, 1.2, 0.0, 0.0, 3);
	} else set_hudmessage(0, 255, 0, 0.7, 0.06, 0, 0.0, 1.2, 0.0, 0.0, 3);

	if (!target || !get_bit(target, loaded)) return PLUGIN_CONTINUE;

	static seconds, minutes, hours;

	seconds = get_user_total_time(target);
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

	csgo_get_clan_name(csgo_get_user_clan(target), clan, charsmax(clan));
	csgo_get_user_operation_text(target, operation, charsmax(operation));
	csgo_get_current_skin_name(target, skin, charsmax(skin));

	format(skin, charsmax(skin), "^n[Skin : %s]", skin);
	format(operation, charsmax(operation), "^n[Operacja : %s]", operation);
	format(clan, charsmax(clan), "^n[Klan : %s]", clan);

	if (!playerData[target][RANK]) ShowSyncHudMsg(id, hud, "[Forum : %s]^n[Konto : %s]%s^n[Ranga : %s (%i / %i)]%s^n[Stan Konta : %.2f Euro]%s^n[Czas Gry : %i h %i min %i s]",
		forum, (csgo_get_user_svip(target) ? "SuperVIP" : csgo_get_user_vip(target) ? "VIP" : "Zwykle"), clan, rankName[playerData[target][RANK]], playerData[target][KILLS], unrankedKills, skin, csgo_get_money(target), operation, hours, minutes, seconds);
	else if (playerData[target][RANK] < MAX_RANKS) ShowSyncHudMsg(id, hud, "[Forum : %s]^n[Konto : %s]%s^n[Ranga : %s]^n[Punkty Elo : %.2f / %d]%s^n[Stan Konta : %.2f Euro]%s^n[Czas Gry : %i h %i min %i s]",
		forum, (csgo_get_user_svip(target) ? "SuperVIP" : csgo_get_user_vip(target) ? "VIP" : "Zwykle"), clan, rankName[playerData[target][RANK]], playerData[target][ELO_RANK], rankElo[playerData[target][RANK] + 1], skin, csgo_get_money(target), operation, hours, minutes, seconds);
	else ShowSyncHudMsg(id, hud, "[Forum : %s]^n[Konto : %s]%s^n[Ranga : %s]^n[Punkty Elo : %.2f]%s^n[Stan Konta : %.2f Euro]%s^n[Czas Gry : %i h %i min %i s]",
		forum, (csgo_get_user_svip(target) ? "SuperVIP" : csgo_get_user_vip(target) ? "VIP" : "Zwykle"), clan, rankName[playerData[target][RANK]], playerData[target][ELO_RANK], skin, csgo_get_money(target), operation, hours, minutes, seconds);

	return PLUGIN_CONTINUE;
}

public client_death(killer, victim, weapon, hitPlace, TK)
{
	if (!is_user_connected(victim) || !is_user_connected(killer) || killer == victim) return;

	check_rank(killer);
	check_rank(victim);
}

public bomb_explode(planter, defuser)
{
	if (get_playersnum() < minPlayers) return;

	add_user_elo(planter, 2.0);

	check_rank(planter);
}

public bomb_defused(defuser)
{
	if (get_playersnum() < minPlayers) return;

	add_user_elo(defuser, 2.0);

	check_rank(defuser);
}

public hostages_rescued()
{
	if (get_playersnum() < minPlayers) return;

	new rescuer = get_loguser_index();

	add_user_elo(rescuer, 2.0);

	check_rank(rescuer);
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
		log_to_file("csgo-error.log", "[CS:GO Ranks] SQL Error: %s (%d)", error, errorNum);

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

			if (weapon) {
				get_weaponname(weapon, weaponName, charsmax(weaponName));

				replace_all(weaponName, charsmax(weaponName), "weapon_", "");

				ucfirst(weaponName);
			}

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