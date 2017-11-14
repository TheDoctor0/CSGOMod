#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <nvault>
#include <csgomod>

#define PLUGIN "CS:GO Operacje"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

new operationDescription[][] = {
	"Brak operacji %i",
	"Musisz zabic jeszcze %i osob",
	"Musisz zabic jeszcze %i osob headshotem",
	"Musisz podlozyc/rozbroic bombe jeszcze %i razy",
	"Musisz zadac jeszcze %i obrazen"
};

enum _:operationType { TYPE_NONE, TYPE_KILL, TYPE_HEADSHOT, TYPE_BOMB, TYPE_DAMAGE };
enum _:playerInfo { PLAYER_ID, PLAYER_TYPE, PLAYER_ADDITIONAL, PLAYER_PROGRESS, PLAYER_NAME[32] };
enum _:operationsInfo { OPERATION_AMOUNT, OPERATION_TYPE, OPERATION_REWARD };

new const commandQuest[][] = { "say /operacja", "say_team /operacja", "say /misja", "say_team /misja", "say /misje", "say_team /misje", "say /operacje", "say_team /operacje", "misje" };
new const commandProgress[][] = { "say /progress", "say_team /progress", "say /progres", "say_team /progres", "say /postep", "say_team /postep", "postep" };
new const commandEnd[][] = { "say /koniec", "say_team /koniec", "say /zakoncz", "say_team /zakoncz", "zakoncz", "say_team /przerwij", "say /przerwij", "przerwij" };

new playerData[MAX_PLAYERS + 1][playerInfo], Array:operationList, minPlayers, operations, loaded;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(register_cvar("csgo_operations_min_players", "4"), minPlayers);
	
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

		formatex(error, charsmax(error), "[CS:GO] Nie mozna znalezc pliku csgo_operations.ini w lokalizacji %s", filePath);

		set_fail_state(error);
	}
	
	new lineData[128], operationData[4][16], operationInfo[operationsInfo], file = fopen(filePath, "r");
	
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
	
	new menu = menu_create("\yMenu \rOperacji\w:", "operation_menu_handle"), callback = menu_makecallback("operation_menu_callback");
	
	menu_additem(menu, "Wybierz \yOperacje", _, _, callback);
	menu_additem(menu, "Przerwij \yOperacje", _, _, callback);
	menu_additem(menu, "Postep \yOperacji", _, _, callback);
	
	menu_addtext(menu, "^n\wPo ukonczeniu \yoperacji\w zostaniesz wynagrodzony \rpieniedzmi\w.", 0);
	menu_addtext(menu, "\wMozesz \ywielokrotnie\w wykonywac ta sama operacje.", 0);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
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
	
	switch(item) {
		case 0: select_operation(id);
		case 1: reset_operation(id, 0, 0);
		case 2: check_operation(id);
	}
	
	return PLUGIN_HANDLED;
}

public operation_menu_callback(id, menu, item)
{
	switch(item) {
		case 0: if (playerData[id][PLAYER_TYPE]) return ITEM_DISABLED;
		case 1, 2: if (!playerData[id][PLAYER_TYPE]) return ITEM_DISABLED;
	}
	
	return ITEM_ENABLED;
}

public select_operation(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (playerData[id][PLAYER_TYPE]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Najpierw dokoncz lub zrezygnuj z obecnej^x03 operacji^x01.");

		return PLUGIN_HANDLED;
	}
	
	new menuData[128], operationId[3], operationInfo[operationsInfo], menu = menu_create("\yWybierz \rMisje\w:", "select_operation_handle");
	
	for (new i = 0; i < ArraySize(operationList); i++) {	
		ArrayGetArray(operationList, i, operationInfo);

		switch(operationInfo[OPERATION_TYPE]) {
			case TYPE_KILL: formatex(menuData, charsmax(menuData), "Zabij %i osob \y(Nagroda: %i Euro)", operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_HEADSHOT: formatex(menuData, charsmax(menuData), "Zabij %i osob z HS \y(Nagroda: %i Euro)",  operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_BOMB: formatex(menuData, charsmax(menuData), "Podloz/Rozbroj %i bomb \y(Nagroda: %i Euro)",  operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_DAMAGE: formatex(menuData, charsmax(menuData), "Zadaj %i obrazen \y(Nagroda: %i Euro)",  operationInfo[OPERATION_AMOUNT], operationInfo[OPERATION_REWARD]);
			case TYPE_NONE: continue;
		}

		num_to_str(i, operationId, charsmax(operationId));
		
		menu_additem(menu, menuData, operationId);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
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

	client_print_color(id, id, "^x04[CS:GO]^x01 Rozpoczales nowa^x03 operacje^x01. Powodzenia!");
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public client_death(killer, victim, weaponId, hitPlace, teamKill)
{	
	if (!is_user_connected(killer) || !is_user_connected(victim) || !is_user_alive(killer) || get_user_team(victim) == get_user_team(killer)) return PLUGIN_CONTINUE;

	switch(playerData[killer][PLAYER_TYPE]) {
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

	client_print_color(id, id, "^x04[CS:GO]^x01 Gratulacje! Ukonczyles operacje - w nagrode otrzymujesz^x03 %i Euro^x01.", reward);
	
	return PLUGIN_HANDLED;
}

public check_operation(id)
{
	if (!playerData[id][PLAYER_TYPE]) client_print_color(id, id, "^x04[CS:GO]^x01 Nie jestes w trakcie wykonywania zadnej operacji.");
	else {
		new message[128];

		formatex(message, charsmax(message), operationDescription[playerData[id][PLAYER_TYPE]], (get_progress_need(id) - get_progress(id)));

		client_print_color(id, id, "^x04[CS:GO]^x01 Postep operacji:^x03 %s^x01.", message);
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

	if (!silent) client_print_color(id, id, "^x04[CS:GO]^x01 Zrezygnowales z wykonywania rozpoczetej przez ciebie^x03 operacji^x01.");

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
	return playerData[id][PLAYER_PROGRESS] ? playerData[id][PLAYER_PROGRESS] : -1;

stock get_progress_need(id)
	return playerData[id][PLAYER_TYPE] ? get_operation_info(playerData[id][PLAYER_ID], OPERATION_AMOUNT) : -1;

public _csgo_get_user_operation(id)
	return playerData[id][PLAYER_ID];

public _csgo_get_user_operation_progress(id)
	return get_progress(id);

public _csgo_get_user_operation_need(id)
	return get_progress_need(id);