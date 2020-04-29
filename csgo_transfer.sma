#include <amxmodx>
#include <csgomod>

#define PLUGIN "CS:GO Transfer"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

new const commandTransfer[][] = { "say /transferuj", "say_team /transferuj", "say /transfer", "say_team /transfer", "transfer" };

new transferPlayer[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof commandTransfer; i++) register_clcmd(commandTransfer[i], "transfer_menu");

	register_clcmd("ILOSC_KASY", "transfer_handle");
}

public transfer_menu(id)
{
	if (!csgo_check_account(id)) return PLUGIN_HANDLED;

	new menuData[256], playerName[32], playerId[3], players, menu = menu_create("\yWybierz \rGracza\y, ktoremu chcesz przetransferowac \rpieniadze\w:", "transfer_menu_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(player) || player == id) continue;

		get_user_name(player, playerName, charsmax(playerName));

		formatex(menuData, charsmax(menuData), "%s \y[%.2f Euro]", playerName, csgo_get_money(player));

		num_to_str(player, playerId, charsmax(playerId));

		menu_additem(menu, menuData, playerId);

		players++;
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!players) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Na serwerze nie ma gracza, ktoremu moglbys przetransferowac^x03 pieniadze^x01!");
	} else {
		menu_display(id, menu);
	}

	return PLUGIN_HANDLED;
}

public transfer_menu_handle(id, menu, item)
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
		client_print_color(id, id, "^x04[CS:GO]^x01 Tego gracza nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	transferPlayer[id] = player;

	client_cmd(id, "messagemode ILOSC_KASY");

	client_print_color(id, id, "^x04[CS:GO]^x01 Wpisz ilosc^x03 pieniedzy^x01, ktora chcesz przetransferowac!");
	client_print(id, print_center, "Wpisz ilosc pieniedzy, ktora chcesz przetransferowac!");

	return PLUGIN_HANDLED;
}

public transfer_handle(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id)) return PLUGIN_HANDLED;

	if (!is_user_connected(transferPlayer[id])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Gracza, ktoremu chcesz przetransferowac^x03 pieniadze^x01 nie ma juz na serwerze!");

		return PLUGIN_HANDLED;
	}

	new cashData[16], Float:cashAmount;

	read_args(cashData, charsmax(cashData));
	remove_quotes(cashData);

	cashAmount = str_to_float(cashData);

	if (cashAmount < 0.1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz przetransferowac mniej niz^x03 0.1 Euro^x01!");

		return PLUGIN_HANDLED;
	}

	if (csgo_get_money(id) - cashAmount < 0.0) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz tyle^x03 pieniedzy^x01!");

		return PLUGIN_HANDLED;
	}

	new playerName[32], playerIdName[32];

	get_user_name(id, playerName, charsmax(playerName));
	get_user_name(transferPlayer[id], playerIdName, charsmax(playerIdName));

	csgo_add_money(transferPlayer[id], cashAmount);
	csgo_add_money(id, -cashAmount);

	client_print_color(0, id, "^x04[CS:GO]^x03 %s^x01 przetransferowal^x04 %.2f Euro^x01 na konto^x03 %s^x01.", playerName, cashAmount, playerIdName);
	log_to_file("csgo-transfer.log", "Gracz %s przetransferowal %.2f Euro na konto gracza %s.", playerName, cashAmount, playerIdName);

	return PLUGIN_HANDLED;
}