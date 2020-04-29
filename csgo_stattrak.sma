#include <amxmodx>
#include <csgomod>
#include <sqlx>
#include <csx>

#define PLUGIN "CS:GO StatTrak"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

#define CSW_SHIELD	2
#define TASK_LOAD	9321

new const excludedWeapons = (1<<CSW_SHIELD) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_HEGRENADE) | (1<<CSW_C4);

new playerData[MAX_PLAYERS + 1][CSW_P90 + 1], playerName[MAX_PLAYERS + 1][64], Handle:sql, bool:sqlConnected, dataLoaded, statTrakEnabled;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("csgo_stattrak_enabled", "1"), statTrakEnabled);
}

public plugin_natives()
{
	register_native("csgo_get_weapon_stattrak", "_csgo_get_weapon_stattrak", 1);
}

public plugin_cfg()
	sql_init();

public plugin_end()
	SQL_FreeHandle(sql);

public client_disconnected(id)
	remove_task(id + TASK_LOAD);

public client_putinserver(id)
{
	for (new weapon = 1; weapon <= CSW_P90; weapon++) playerData[id][weapon] = 0;

	rem_bit(id, dataLoaded);

	if (is_user_hltv(id) || is_user_bot(id)) return;

	get_user_name(id, playerName[id], charsmax(playerName[]));

	mysql_escape_string(playerName[id], playerName[id], charsmax(playerName[]));

	set_task(0.1, "load_data", id + TASK_LOAD);
}

public client_death(killer, victim, weapon, hitPlace, TK)
{
	if (!is_user_connected(victim) || !is_user_connected(killer) || killer == victim) return;

	playerData[killer][weapon]++;

	save_data(killer);
}

public load_data(id)
{
	id -= TASK_LOAD;

	if (!sqlConnected) {
		set_task(1.0, "load_data", id + TASK_LOAD);

		return;
	}

	new queryData[128], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_stattrak` WHERE name = ^"%s^";", playerName[id]);

	SQL_ThreadQuery(sql, "load_data_handle", queryData, tempId, sizeof(tempId));
}

public load_data_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	new id = tempId[0];

	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO StratTrak] SQL Error: %s (%d)", error, errorNum);

		return;
	}

	if (SQL_MoreResults(query)) {
		new weaponName[32];

		for (new weapon = 1; weapon <= CSW_P90; weapon++) {
			if ((1<<weapon) & excludedWeapons) continue;

			get_weaponname(weapon, weaponName, charsmax(weaponName));

			playerData[id][weapon] = SQL_ReadResult(query, SQL_FieldNameToNum(query, weaponName));
		}
	} else {
		new queryData[128];

		formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_stattrak` (`name`) VALUES(^"%s^");", playerName[id]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	set_bit(id, dataLoaded);
}

public save_data(id)
{
	if (!get_bit(id, dataLoaded)) return;

	new queryData[1024], queryTemp[64], weaponName[32];

	formatex(queryData, charsmax(queryData), "UPDATE `csgo_stattrak` SET ");

	for (new weapon = 1; weapon <= CSW_P90; weapon++) {
		if ((1<<weapon) & excludedWeapons) continue;

		get_weaponname(weapon, weaponName, charsmax(weaponName));

		formatex(queryTemp, charsmax(queryTemp), "%s = %d, ", weaponName, playerData[id][weapon]);

		add(queryData, charsmax(queryData), queryTemp);
	}

	formatex(queryTemp, charsmax(queryTemp), "name = ^"%s^" WHERE name = ^"%s^";", playerName[id], playerName[id]);

	add(queryData, charsmax(queryData), queryTemp);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) log_to_file("csgo-error.log", "[CS:GO StatTrak] Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("csgo-error.log", "[CS:GO StatTrak] Query failed. [%d] %s", errorNum, error);
	}

	return PLUGIN_CONTINUE;
}

public sql_init()
{
	new host[64], user[64], pass[64], db[64], queryData[1024], error[128], queryTemp[64], weaponName[32], errorNum;

	get_cvar_string("csgo_sql_host", host, charsmax(host));
	get_cvar_string("csgo_sql_user", user, charsmax(user));
	get_cvar_string("csgo_sql_pass", pass, charsmax(pass));
	get_cvar_string("csgo_sql_db", db, charsmax(db));

	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file("csgo-error.log", "Error: %s", error);

		sql = Empty_Handle;

		set_task(5.0, "sql_init");

		return;
	}

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_stattrak` (`name` VARCHAR(64), ");

	for (new weapon = 1; weapon <= CSW_P90; weapon++) {
		if ((1<<weapon) & excludedWeapons) continue;

		get_weaponname(weapon, weaponName, charsmax(weaponName));

		formatex(queryTemp, charsmax(queryTemp), "`%s` int(10) NOT NULL, ", weaponName);

		add(queryData, charsmax(queryData), queryTemp);
	}

	add(queryData, charsmax(queryData), "PRIMARY KEY(`name`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);

	sqlConnected = true;
}

public _csgo_get_weapon_stattrak(id, weapon)
{
	if (!statTrakEnabled || (1<<weapon) & excludedWeapons || !get_bit(id, dataLoaded)) {
		return -1;
	}

	return playerData[id][weapon];
}
