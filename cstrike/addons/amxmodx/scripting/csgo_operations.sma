#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <nvault>
#include <csgomod>

#define PLUGIN	"CS:GO Operations"
#define AUTHOR	"O'Zone"

enum _:operationType { TYPE_NONE, TYPE_KILL, TYPE_HEADSHOT, TYPE_BOMB, TYPE_DAMAGE };
enum _:playerInfo { PLAYER_ID, PLAYER_TYPE, PLAYER_ADDITIONAL, PLAYER_PROGRESS, PLAYER_NAME[32] };
enum _:operationsInfo { OPERATION_AMOUNT, OPERATION_TYPE, OPERATION_REWARD };

new const commandQuest[][] = { "say /operation", "say_team /operation", "say /mission", "say_team /mission", "say /operacja", "say_team /operacja", "say /misja", "say_team /misja",
	"say /misje", "say_team /misje", "say /operacje", "say_team /operacje", "say /operations", "say_team /operations", "say /missions", "say_team /missions", "misje" };
new const commandProgress[][] = { "say /progress", "say_team /progress", "say /progres", "say_team /progres", "say /postep", "say_team /postep", "postep" };
new const commandEnd[][] = { "say /koniec", "say_team /koniec", "say /zakoncz", "say_team /zakoncz", "zakoncz", "say_team /przerwij", "say /przerwij",
	"say_team /cancel", "say /cancel", "say_team /end", "say /end", "przerwij" };

new playerData[MAX_PLAYERS + 1][playerInfo], Array:operationList, minPlayers, operations, loaded;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(get_cvar_pointer("csgo_min_players"), minPlayers);

	for(new i; i < sizeof commandQuest; i++) register_clcmd(commandQuest[i], "operation_menu");
	for(new i; i < sizeof commandProgress; i++) register_clcmd(commandProgress[i], "check_operation");
	for(new i; i < sizeof commandEnd; i++) register_clcmd(commandEnd[i], "reset_operation");

	RegisterHam(Ham_TakeDamage, "player", "player_take_damage_post", 1);

	register_logevent("log_event_operation", 3, "1=triggered");

	operations = nvault_open("csgo_operations");

	if (operations == INVALID_HANDLE) set_fail_state("Nie mozna otworzyc pliku csgo_operations.vault");

	operationList = ArrayCreate(operationsInfo);
}

public plugin_natives()
{
	register_native("csgo_get_user_operation", "_csgo_get_user_operation", 1);
	register_native("csgo_get_user_operation_text", "_csgo_get_user_operation_text", 1);
	register_native("csgo_get_user_operation_progress", "_csgo_get_user_operation_progress", 1);
	register_native("csgo_get_user_operation_need", "_csgo_get_user_operation_need", 1);
}

public plugin_cfg()
{
	new filePath[64];

	get_localinfo("amxx_configsdir", filePath, charsmax(filePath));
	format(filePath, charsmax(filePath), "%s/csgo_operations.ini", filePath);

	if (!file_exists(filePath)) {
		new error[128];

		formatex(error, charsmax(error), "[CS:GO Operations] Config file csgo_operations.ini has not been found in %s", filePath);

		set_fail_state(error);
	}

	new lineData[128], operationData[4][16], operationInfo[operationsInfo], file = fopen(filePath, "r");

	ArrayPushArray(operationList, operationInfo);

	while (!feof(file)) {
		fgets(file, lineData, charsmax(lineData));

		if (lineData[0] == ';' || lineData[0] == '^0') continue;

		parse(lineData, operationData[0], charsmax(operationData[]), operationData[1], charsmax(operationData[]), operationData[2], charsmax(operationData[]));

		operationInfo[OPERATION_AMOUNT] = str_to_num(operationData[0]);
		operationInfo[OPERATION_TYPE] = str_to_num(operationData[1]);
		operationInfo[OPERATION_REWARD] = str_to_num(operationData[2]);

		ArrayPushArray(operationList, operationInfo);
	}

	fclose(file);
}

public plugin_end()
	nvault_close(operations);

public csgo_reset_data()
{
	for (new i = 1; i <= MAX_PLAYERS; i++) rem_bit(i, loaded);

	nvault_prune(operations, 0, get_systime() + 1);
}

public client_disconnected(id)
	rem_bit(id, loaded);

public client_putinserver(id)
{
	reset_operation(id, 1, 1);

	if (is_user_bot(id) || is_user_hltv(id)) return PLUGIN_HANDLED;

	get_user_name(id, playerData[id][PLAYER_NAME], charsmax(playerData[][PLAYER_NAME]));

	load_operation(id);

	return PLUGIN_HANDLED;
}

public operation_menu(id)
{
	if (!csgo_check_account(id)) return PLUGIN_HANDLED;

	new title[64], menu, callback = menu_makecallback("operation_menu_callback");

	formatex(title, charsmax(title), "%L", id, "CSGO_OPERATIONS_TITLE_MENU");
	menu = menu_create(title, "operation_menu_handle");

	formatex(title, charsmax(title), "%L", id, "CSGO_OPERATIONS_ITEM_SELECT");
	menu_additem(menu, title, _, _, callback);

	formatex(title, charsmax(title), "%L", id, "CSGO_OPERATIONS_ITEM_CANCEL");
	menu_additem(menu, title, _, _, callback);

	formatex(title, charsmax(title), "%L", id, "CSGO_OPERATIONS_ITEM_PROGRESS");
	menu_additem(menu, title, _, _, callback);

	formatex(title, charsmax(title), "%L", id, "CSGO_OPERATIONS_PRICE_INFO_FIRST");
	menu_addtext(menu, title, 0);

	formatex(title, charsmax(title), "%L", id, "CSGO_OPERATIONS_PRICE_INFO_SECOND");
	menu_addtext(menu, title, 0);

	formatex(title, charsmax(title), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, title);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public operation_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
    }

	switch (item) {
		case 0: select_operation(id);
		case 1: reset_operation(id, 0, 0);
		case 2: check_operation(id);
	}

	return PLUGIN_HANDLED;
}

public operation_menu_callback(id, menu, item)
{
	switch (item) {
		case 0: if (playerData[id][PLAYER_TYPE]) return ITEM_DISABLED;
		case 1, 2: if (!playerData[id][PLAYER_TYPE]) return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public select_operation(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (playerData[id][PLAYER_TYPE]) {
		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_OPERATIONS_ALREADY_IN_PROGRESS");

		return PLUGIN_HANDLED;
	}

	new menuData[128], operationId[3], operationInfo[operationsInfo], menu;

	formatex(menuData, charsmax(menuData), "%L", id, "CSGO_OPERATIONS_TITLE_SELECT");
	menu = menu_create(menuData, "select_operation_handle");

	for (new i = 0; i < ArraySize(operationList); i++) {
		ArrayGetArray(operationList, i, operationInfo);

		switch (operationInfo[OPERATION_TYPE]) {
			case TYPE_KILL: formatex(menuData, charsmax(menuData), "%L", id, "CSGO_OPERATIONS_TYPE_KILL", operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_HEADSHOT: formatex(menuData, charsmax(menuData), "%L", id, "CSGO_OPERATIONS_TYPE_HEADSHOT",  operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_BOMB: formatex(menuData, charsmax(menuData), "%L", id, "CSGO_OPERATIONS_TYPE_BOMB",  operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_DAMAGE: formatex(menuData, charsmax(menuData), "%L", id, "CSGO_OPERATIONS_TYPE_DAMAGE",  operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_NONE: continue;
		}

		num_to_str(i, operationId, charsmax(operationId));

		menu_additem(menu, menuData, operationId);
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

public select_operation_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new operationId[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, operationId, charsmax(operationId), _, _, itemCallback);

	reset_operation(id, 1, 1);

	playerData[id][PLAYER_ID] = str_to_num(operationId);
	playerData[id][PLAYER_TYPE] = get_operation_info(playerData[id][PLAYER_ID], OPERATION_TYPE);

	save_operation(id);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_OPERATIONS_STARTED");

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public client_death(killer, victim, weaponId, hitPlace, teamKill)
{
	if (!is_user_connected(killer) || !is_user_connected(victim) || !is_user_alive(killer) || get_user_team(victim) == get_user_team(killer)) return PLUGIN_CONTINUE;

	switch (playerData[killer][PLAYER_TYPE]) {
		case TYPE_KILL: add_progress(killer);
		case TYPE_HEADSHOT: if (hitPlace == HIT_HEAD) add_progress(killer);
	}

	return HAM_IGNORED;
}

public player_take_damage_post(victim, inflictor, attacker, Float:damage, damageBits)
{
	if (!is_user_connected(attacker) || !is_user_connected(victim) || get_user_team(victim) == get_user_team(attacker)) return HAM_IGNORED;

	if (playerData[attacker][PLAYER_TYPE] == TYPE_DAMAGE) add_progress(attacker, floatround(damage));

	return HAM_IGNORED;
}

public log_event_operation()
{
	new userLog[80], userAction[64], userName[32];

	read_logargv(0, userLog, charsmax(userLog));
	read_logargv(2, userAction, charsmax(userAction));
	parse_loguser(userLog, userName, charsmax(userName));

	new id = get_user_index(userName);

	if (!is_user_connected(id) || playerData[id][PLAYER_TYPE] == TYPE_NONE) return PLUGIN_HANDLED;

	if ((equal(userAction, "Planted_The_Bomb") || equal(userAction, "Defused_The_Bomb")) && playerData[id][PLAYER_TYPE] == TYPE_BOMB) add_progress(id);

	return PLUGIN_HANDLED;
}

public give_reward(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new reward = get_operation_info(playerData[id][PLAYER_ID], OPERATION_REWARD);

	csgo_add_money(id, float(reward));

	reset_operation(id, 0, 1);

	client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_OPERATIONS_COMPLETED", reward);

	return PLUGIN_HANDLED;
}

public check_operation(id)
{
	if (!playerData[id][PLAYER_TYPE]) client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_OPERATIONS_NONE");
	else {
		new message[128];

		switch (playerData[id][PLAYER_TYPE]) {
			case TYPE_KILL: formatex(message, charsmax(message), "%L", id, "CSGO_OPERATIONS_TYPE_KILL_INFO", (get_progress_need(id) - get_progress(id)));
			case TYPE_HEADSHOT: formatex(message, charsmax(message), "%L", id, "CSGO_OPERATIONS_TYPE_HEADSHOT_INFO",  (get_progress_need(id) - get_progress(id)));
			case TYPE_BOMB: formatex(message, charsmax(message), "%L", id, "CSGO_OPERATIONS_TYPE_BOMB_INFO",  (get_progress_need(id) - get_progress(id)));
			case TYPE_DAMAGE: formatex(message, charsmax(message), "%L", id, "CSGO_OPERATIONS_TYPE_DAMAGE_INFO", (get_progress_need(id) - get_progress(id)));
			case TYPE_NONE: formatex(message, charsmax(message), "%L", id, "CSGO_OPERATIONS_TYPE_NONE_INFO");
		}

		client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_OPERATIONS_PROGRESS", message);
	}

	return PLUGIN_HANDLED;
}

public save_operation(id)
{
	if (!get_bit(id, loaded)) return PLUGIN_HANDLED;

	new vaultKey[64], vaultData[64];

	formatex(vaultKey, charsmax(vaultKey), "%s", playerData[id][PLAYER_NAME]);
	formatex(vaultData, charsmax(vaultData), "%i %i %i %i", playerData[id][PLAYER_ID], playerData[id][PLAYER_TYPE], playerData[id][PLAYER_ADDITIONAL], playerData[id][PLAYER_PROGRESS]);

	nvault_set(operations, vaultKey, vaultData);

	return PLUGIN_HANDLED;
}

public load_operation(id)
{
	new vaultKey[64], vaultData[64], operationData[4][16], operationParam[4];

	formatex(vaultKey, charsmax(vaultKey), "%s", playerData[id][PLAYER_NAME]);

	if (nvault_get(operations, vaultKey, vaultData, charsmax(vaultData))) {
		parse(vaultData, operationData[0], charsmax(operationData[]), operationData[1], charsmax(operationData[]), operationData[2], charsmax(operationData[]), operationData[3], charsmax(operationData[]));

		for (new i = 0; i < sizeof operationParam; i++) operationParam[i] = str_to_num(operationData[i]);

		if (operationParam[0] > -1) {
			playerData[id][PLAYER_ID] = operationParam[0];
			playerData[id][PLAYER_TYPE] = operationParam[1];
			playerData[id][PLAYER_ADDITIONAL] = operationParam[2];
			playerData[id][PLAYER_PROGRESS] = operationParam[3];
		}
	}

	set_bit(id, loaded);

	return PLUGIN_HANDLED;
}

public reset_operation(id, data, silent)
{
	playerData[id][PLAYER_TYPE] = TYPE_NONE;
	playerData[id][PLAYER_ID] = -1;
	playerData[id][PLAYER_PROGRESS] = 0;

	if (!data) save_operation(id);

	if (!silent) client_print_color(id, id, "%s %L", CHAT_PREFIX, id, "CSGO_OPERATIONS_CANCELLED");

	return PLUGIN_HANDLED;
}

stock get_operation_info(operation, info)
{
	new operationInfo[operationsInfo];

	ArrayGetArray(operationList, operation, operationInfo);

	return operationInfo[info];
}

stock add_progress(id, amount = 1)
{
	if (!is_user_connected(id) || get_playersnum() < minPlayers) return PLUGIN_HANDLED;

	playerData[id][PLAYER_PROGRESS] += amount;

	if (get_progress(id) >= get_progress_need(id)) give_reward(id);
	else save_operation(id);

	return PLUGIN_HANDLED;
}

stock get_progress(id)
	return playerData[id][PLAYER_ID] > -1 ? playerData[id][PLAYER_PROGRESS] : -1;

stock get_progress_need(id)
	return playerData[id][PLAYER_TYPE] ? get_operation_info(playerData[id][PLAYER_ID], OPERATION_AMOUNT) : -1;

public _csgo_get_user_operation(id)
	return playerData[id][PLAYER_ID];

public _csgo_get_user_operation_text(id, dataReturn[], dataLength)
{
	param_convert(2);

	if (playerData[id][PLAYER_ID] > -1) formatex(dataReturn, dataLength, "%L", id, "CSGO_OPERATIONS_TEXT_PROGRESS", get_progress(id), get_progress_need(id), float(get_progress(id)) / float(get_progress_need(id)) * 100.0, "%");
	else formatex(dataReturn, dataLength, "%L", id, "CSGO_OPERATIONS_TEXT_COMMAND");
}

public _csgo_get_user_operation_progress(id)
	return get_progress(id);

public _csgo_get_user_operation_need(id)
	return get_progress_need(id);