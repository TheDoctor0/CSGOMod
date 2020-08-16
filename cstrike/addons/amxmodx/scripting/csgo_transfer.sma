#include <amxmodx>
#include <csgomod>

#define PLUGIN "CS:GO Transfer"
#define VERSION "2.0"
#define AUTHOR "O'Zone"

new const commandTransfer[][] = { "say /transferuj", "say_team /transferuj", "say /transfer", "say_team /transfer", "transfer" };

new transferPlayer[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof commandTransfer; i++) register_clcmd(commandTransfer[i], "CSGO_TRANSFER");

	register_clcmd("EURO_AMOUNT", "transfer_handle");
}

public CSGO_TRANSFER(id)
{
	if (!csgo_check_account(id)) return PLUGIN_HANDLED;

	new menuData[256], title[64], playerName[32], playerId[3], players, menu;

	formatex(title, charsmax(title), "%L", id, "CSGO_TRANSFER_TITLE");
	menu = menu_create(title, "CSGO_TRANSFER_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(player) || player == id) continue;

		get_user_name(player, playerName, charsmax(playerName));

		formatex(menuData, charsmax(menuData), "%L", id, "CSGO_TRANSFER_ITEM", playerName, csgo_get_money(player));

		num_to_str(player, playerId, charsmax(playerId));

		menu_additem(menu, menuData, playerId);

		players++;
	}

	formatex(title, charsmax(title), "%L", id, "CSGO_MENU_PREVIOUS");
	menu_setprop(menu, MPROP_BACKNAME, title);

	formatex(title, charsmax(title), "%L", id, "CSGO_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, title);

	formatex(title, charsmax(title), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, title);

	if (!players) {
		menu_destroy(menu);

		client_print_color(id, id, "%L", id, "^4[CS:GO]^1 CSGO_TRANSFER_NONE");
	} else {
		menu_display(id, menu);
	}

	return PLUGIN_HANDLED;
}

public CSGO_TRANSFER_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new playerId[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, playerId, charsmax(playerId), _, _, itemCallback);

	new player = str_to_num(playerId);

	menu_destroy(menu);

	if (!is_user_connected(player)) {
		client_print_color(id, id,  "^4[CS:GO]^1 %L", id, "CSGO_TRANSFER_NO_PLAYER");

		return PLUGIN_HANDLED;
	}

	transferPlayer[id] = player;

	client_cmd(id, "messagemode EURO_AMOUNT");

	client_print_color(id, id, "^4[CS:GO]^1 %L", id, "CSGO_TRANSFER_INFO_CHAT");
	client_print(id, print_center, "%L", id, "CSGO_TRANSFER_INFO_CENTER");

	return PLUGIN_HANDLED;
}

public transfer_handle(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id)) return PLUGIN_HANDLED;

	if (!is_user_connected(transferPlayer[id])) {
		client_print_color(id, id, "^4[CS:GO]^1 %L", id, "CSGO_TRANSFER_NO_PLAYER");

		return PLUGIN_HANDLED;
	}

	new cashData[16], Float:cashAmount;

	read_args(cashData, charsmax(cashData));
	remove_quotes(cashData);

	cashAmount = str_to_float(cashData);

	if (cashAmount < 0.1) {
		client_print_color(id, id, "^4[CS:GO]^1 %L", id, "CSGO_TRANSFER_TOO_LOW");

		return PLUGIN_HANDLED;
	}

	if (csgo_get_money(id) - cashAmount < 0.0) {
		client_print_color(id, id, "^4[CS:GO]^1 %L", id, "CSGO_TRANSFER_NO_MONEY");

		return PLUGIN_HANDLED;
	}

	new playerName[32], playerIdName[32];

	get_user_name(id, playerName, charsmax(playerName));
	get_user_name(transferPlayer[id], playerIdName, charsmax(playerIdName));

	csgo_add_money(transferPlayer[id], cashAmount);
	csgo_add_money(id, -cashAmount);

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i)) continue;

		client_print_color(i, id, "^4[CS:GO]^3 %L", i, "CSGO_TRANSFER_COMPLETED", playerName, cashAmount, playerIdName);
	}

	log_to_file("csgo-transfer.log", "Player %s transfered %.2f Euro to the %s account.", playerName, cashAmount, playerIdName);

	return PLUGIN_HANDLED;
}