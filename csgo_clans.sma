#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <sqlx>
#include <csgomod>

#define PLUGIN "CS:GO Clans"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define TASK_INFO 9843

new const commandClan[][] = { "say /clan", "say_team /clan", "say /clans", "say_team /clans", "say /klany", "say_team /klany", "say /klan", "say_team /klan", "klan" };

enum _:clanInfo { CLAN_ID, CLAN_LEVEL, Float:CLAN_MONEY, CLAN_KILLS, CLAN_MEMBERS, CLAN_WINS, Trie:CLAN_STATUS, CLAN_NAME[32] };
enum _:warInfo { WAR_ID, WAR_CLAN, WAR_CLAN2, WAR_PROGRESS, WAR_PROGRESS2, WAR_DURATION, WAR_REWARD };
enum _:statusInfo { STATUS_NONE, STATUS_MEMBER, STATUS_DEPUTY, STATUS_LEADER };

new Float:cvarCreateFee, Float:cvarJoinFee, cvarMembersStart, cvarLevelMax, cvarChatPrefix, Float:cvarLevelCost, Float:cvarNextLevelCost, cvarMembersPerLevel;

new playerName[MAX_PLAYERS + 1][64], chosenName[MAX_PLAYERS + 1][64], clan[MAX_PLAYERS + 1], chosenId[MAX_PLAYERS + 1], warFrags[MAX_PLAYERS + 1],
	warReward[MAX_PLAYERS + 1], Handle:sql, bool:sqlConnected, Array:csgoClans, Array:csgoWars, Handle:connection, bool:end, info, loaded;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	csgoClans = ArrayCreate(clanInfo);
	csgoWars = ArrayCreate(warInfo);

	for (new i; i < sizeof commandClan; i++) register_clcmd(commandClan[i], "show_clan_menu");

	register_clcmd("PODAJ_NAZWE_KLANU", "create_clan_handle");
	register_clcmd("PODAJ_NOWA_NAZWE_KLANU", "change_name_handle");
	register_clcmd("PODAJ_ILOSC_WPLACANEGO_EURO", "deposit_money_handle");
	register_clcmd("PODAJ_ILOSC_WYPLACANEGO_EURO", "withdraw_money_handle");
	register_clcmd("PODAJ_LICZBE_FRAGOW", "set_war_frags_handle");
	register_clcmd("PODAJ_WYSOKOSC_NAGRODY", "set_war_reward_handle");

	bind_pcvar_float(create_cvar("csgo_clans_create_fee", "250"), cvarCreateFee);
	bind_pcvar_float(create_cvar("csgo_clans_join_fee", "50"), cvarJoinFee);
	bind_pcvar_num(create_cvar("csgo_clans_members_start", "3"), cvarMembersStart);
	bind_pcvar_num(create_cvar("csgo_clans_members_per_level", "1"), cvarMembersPerLevel);
	bind_pcvar_num(create_cvar("csgo_clans_level_max", "7"), cvarLevelMax);
	bind_pcvar_num(create_cvar("csgo_clans_chat_prefix", "1"), cvarChatPrefix);
	bind_pcvar_float(create_cvar("csgo_clans_level_cost", "250"), cvarLevelCost);
	bind_pcvar_float(create_cvar("csgo_clans_next_level_cost", "125"), cvarNextLevelCost);

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);

	register_message(get_user_msgid("SayText"), "say_text");
	register_message(SVC_INTERMISSION, "message_intermission");

	register_forward(FM_AddToFullPack, "add_to_full_pack", 1);
}

public plugin_natives()
{
	register_native("csgo_get_user_clan", "_csgo_get_user_clan", 1);
	register_native("csgo_get_clan_name", "_csgo_get_clan_name", 1);
	register_native("csgo_get_clan_members", "_csgo_get_clan_members", 1);
}

public plugin_cfg()
{
	new csgoClan[clanInfo];

	csgoClan[CLAN_NAME] = "Brak";

	ArrayPushArray(csgoClans, csgoClan);

	sql_init();
}

public plugin_end()
{
	SQL_FreeHandle(sql);
	SQL_FreeHandle(connection);

	ArrayDestroy(csgoClans);
}

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return;

	clan[id] = 0;

	warFrags[id] = 25;
	warReward[id] = 100;

	get_user_name(id, playerName[id], charsmax(playerName));

	mysql_escape_string(playerName[id], playerName[id], charsmax(playerName));

	set_task(0.1, "load_clan_data", id);
}

public client_disconnected(id)
{
	remove_task(id);
	remove_task(id + TASK_INFO);

	rem_bit(id, loaded);
	rem_bit(id, info);

	clan[id] = 0;
}

public client_death(killer, victim, weaponId, hitPlace, teamKill)
{
	if (!clan[killer] || !is_user_connected(killer) || !is_user_connected(victim) || !is_user_alive(killer) || get_user_team(victim) == get_user_team(killer)) return PLUGIN_CONTINUE;

	set_clan_info(clan[killer], CLAN_KILLS, 1);

	if (clan[victim]) check_war(killer, victim);

	return PLUGIN_CONTINUE;
}

public show_clan_menu(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new csgoClan[clanInfo], menuData[128], menu, callback = menu_makecallback("show_clan_menu_callback");

	if (clan[id]) {
		ArrayGetArray(csgoClans, get_clan_id(clan[id]), csgoClan);

		formatex(menuData, charsmax(menuData), "\yMenu \rKlanu^n\wAktualny Klan:\y %s^n\wStan: \y%i/%i Czlonkow \w| \y%.2f Euro\w", csgoClan[CLAN_NAME], csgoClan[CLAN_MEMBERS], csgoClan[CLAN_LEVEL] * cvarMembersPerLevel + cvarMembersStart, csgoClan[CLAN_MONEY]);

		menu = menu_create(menuData, "show_clan_menu_handle");

		menu_additem(menu, "\wZarzadzaj \yKlanem", "1", _, callback);
		menu_additem(menu, "\wOpusc \yKlan", "2", _, callback);
		menu_additem(menu, "\wCzlonkowie \yOnline", "3", _, callback);
		menu_additem(menu, "\wBank \yKlanu", "4", _, callback);
	} else {
		menu = menu_create("\yMenu \rKlanu^n\wAktualny Klan:\y Brak", "show_clan_menu_handle");

		formatex(menuData, charsmax(menuData), "\wZaloz \yKlan \r(Wymagane %i Euro)", floatround(cvarCreateFee));

		menu_additem(menu, menuData, "0", _, callback);

		menu_additem(menu, "\wZloz \yPodanie", "6", _, callback);
	}

	menu_additem(menu, "\wTop15 \yKlanow", "5", _, callback);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public show_clan_menu_callback(id, menu, item)
{
	new itemData[2], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	switch (str_to_num(itemData)) {
		case 0: return csgo_get_money(id) >= cvarCreateFee ? ITEM_ENABLED : ITEM_DISABLED;
		case 1: return get_user_status(id) > STATUS_MEMBER ? ITEM_ENABLED : ITEM_DISABLED;
		case 2, 3, 4, 5: return clan[id] ? ITEM_ENABLED : ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public show_clan_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[2], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	menu_destroy(menu);

	switch (str_to_num(itemData)) {
		case 0: {
			if (clan[id]) {
				client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz utworzyc klanu, jesli w jakims jestes!");

				return PLUGIN_HANDLED;
			}

			if (csgo_get_money(id) < cvarCreateFee) {
				client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz wystarczajaco duzo Euro, aby zalozyc klan (Wymagane^x03 %i Euro^x01)!", floatround(cvarCreateFee));

				return PLUGIN_HANDLED;
			}

			client_cmd(id, "messagemode PODAJ_NAZWE_KLANU");
		}
		case 1: {
			if (get_user_status(id) > STATUS_MEMBER) {
				leader_menu(id);

				return PLUGIN_HANDLED;
			}
		}
		case 2: leave_confim_menu(id);
		case 3: members_online_menu(id);
		case 4: bank_menu(id);
		case 5: clans_top15(id);
		case 6: application_menu(id);
	}

	return PLUGIN_HANDLED;
}

public create_clan_handle(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || clan[id] || end) return PLUGIN_HANDLED;

	if (csgo_get_money(id) < cvarCreateFee) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz wystarczajaco duzo Euro, aby zalozyc klan (Wymagane^x03 %i Euro^x01)!", floatround(cvarCreateFee));

		return PLUGIN_HANDLED;
	}

	new clanName[32];

	read_args(clanName, charsmax(clanName));
	remove_quotes(clanName);
	trim(clanName);

	if (equal(clanName, "")) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie wpisales nazwy klanu.");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	if (strlen(clanName) < 3) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nazwa klanu musi miec co najmniej 3 znaki.");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	if (check_clan_name(clanName)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Klan z taka nazwa juz istnieje.");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	csgo_add_money(id, -cvarCreateFee);

	create_clan(id, clanName);

	client_print_color(id, id, "^x04[CS:GO]^x01 Pomyslnie zalozyles klan^x03 %s^01.", clanName);

	return PLUGIN_HANDLED;
}

public leave_confim_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \ropuscic \wklan?", "leave_confim_menu_handle");

	menu_additem(menu, "Tak");
	menu_additem(menu, "Nie^n");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public leave_confim_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			if (get_user_status(id) == STATUS_LEADER) {
				client_print_color(id, id, "^x04[CS:GO]^x01 Oddaj przywodctwo klanu jednemu z czlonkow zanim go upuscisz.");

				show_clan_menu(id);

				return PLUGIN_HANDLED;
			}

			set_user_clan(id);

			client_print_color(id, id, "^x04[CS:GO]^x01 Opusciles swoj klan.");

			show_clan_menu(id);
		}
		case 1: show_clan_menu(id);
	}

	return PLUGIN_HANDLED;
}

public members_online_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new clanName[32], playersAvailable = 0;

	new menu = menu_create("\yCzlonkowie \rOnline:", "members_online_menu_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(id) || clan[id] != clan[player]) continue;

		playersAvailable++;

		get_user_name(player, clanName, charsmax(clanName));

		switch (get_user_status(player)) {
			case STATUS_MEMBER: add(clanName, charsmax(clanName), " \y[Czlonek]");
			case STATUS_DEPUTY: add(clanName, charsmax(clanName), " \y[Zastepca]");
			case STATUS_LEADER: add(clanName, charsmax(clanName), " \y[Przywodca]");
		}

		menu_additem(menu, clanName);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!playersAvailable) client_print_color(id, id, "^x04[CS:GO]^x01 Na serwerze nie ma zadnego czlonka twojego klanu!");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public members_online_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	menu_destroy(menu);

	if (item == MENU_EXIT) show_clan_menu(id);
	else members_online_menu(id);

	return PLUGIN_HANDLED;
}

public bank_menu(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new menuData[128], menu, callback = menu_makecallback("bank_menu_callback");

	formatex(menuData, charsmax(menuData), "\wBank \rKlanu^n\wStan Konta: \y%.2f Euro\w", get_clan_info(clan[id], CLAN_MONEY));

	menu = menu_create(menuData, "bank_menu_handle");

	menu_additem(menu, "\wLista \yWplat i Wyplat", _, _, callback);
	menu_additem(menu, "\wWplac \yPieniadze", _, _, callback);
	menu_additem(menu, "\wWyplac \yPieniadze", _, _, callback);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public bank_menu_callback(id, menu, item)
{
	if (item == 2) return get_user_status(id) > STATUS_MEMBER ? ITEM_ENABLED : ITEM_DISABLED;

	return ITEM_ENABLED;
}

public bank_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: payments_list(id);
		case 1: {
			client_cmd(id, "messagemode PODAJ_ILOSC_WPLACANEGO_EURO");

			client_print(id, print_center, "Wpisz ilosc Euro, ktora chcesz wplacic");

			client_print_color(id, id, "^x04[CS:GO]^x01 Wpisz ilosc Euro, ktora chcesz^x03 wplacic^x01.");
		} case 2: {
			client_cmd(id, "messagemode PODAJ_ILOSC_WYPLACANEGO_EURO");

			client_print(id, print_center, "Wpisz ilosc Euro, ktora chcesz wyplacic");

			client_print_color(id, id, "^x04[CS:GO]^x01 Wpisz ilosc Euro, ktora chcesz^x03 wyplacic^x01.");
		}
	}

	return PLUGIN_HANDLED;
}

public leader_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new csgoClan[clanInfo], menuData[128];

	ArrayGetArray(csgoClans, get_clan_id(clan[id]), csgoClan);

	formatex(menuData, charsmax(menuData), "\yZarzadzaj \rKlanem^n\wStan: \y%i/%i Czlonkow \w| \y%.2f Euro\w", csgoClan[CLAN_MEMBERS], csgoClan[CLAN_LEVEL] * cvarMembersPerLevel + cvarMembersStart, csgoClan[CLAN_MONEY]);

	new menu = menu_create(menuData, "leader_menu_handle"), callback = menu_makecallback("leader_menu_callback");

	if (csgoClan[CLAN_LEVEL] != cvarLevelMax) formatex(menuData, charsmax(menuData), "Rozbudowa \yKlanu \w[\rPoziom: \y%i/%i\w] [\rKoszt: \y%i Euro\w]", csgoClan[CLAN_LEVEL], cvarLevelMax, floatround(cvarLevelCost + cvarNextLevelCost * csgoClan[CLAN_LEVEL]));
	else formatex(menuData, charsmax(menuData), "Rozbudowa \yKlanu \w[\rPoziom: \y%i/%i\w]", csgoClan[CLAN_LEVEL], cvarLevelMax);

	menu_additem(menu, menuData, _, _, callback);
	menu_additem(menu, "\wRozwiaz \yKlan", _, _, callback);
	menu_additem(menu, "\wZapros \yGracza", _, _, callback);
	menu_additem(menu, "\wZarzadzaj \yCzlonkami", _, _, callback);
	menu_additem(menu, "\wRozpatrz \yPodania", _, _, callback);
	menu_additem(menu, "\wWojny \yKlanu", _, _, callback);
	menu_additem(menu, "\wZmien \yNazwe Klanu^n", _, _, callback);

	menu_setprop(menu, MPROP_EXITNAME, "Wroc");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public leader_menu_callback(id, menu, item)
{
	switch (item) {
		case 0: get_user_status(id) == STATUS_LEADER ? ITEM_ENABLED : ITEM_DISABLED;
		case 2: if (((get_clan_info(clan[id], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[id], CLAN_MEMBERS)) return ITEM_DISABLED;
		case 4: if (((get_clan_info(clan[id], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[id], CLAN_MEMBERS) || !get_applications_count(clan[id])) return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public leader_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			new csgoClan[clanInfo];

			ArrayGetArray(csgoClans, get_clan_id(clan[id]), csgoClan);

			if (csgoClan[CLAN_LEVEL] == cvarLevelMax) {
				client_print_color(id, id, "^x04[CS:GO]^x01 Twoj klan jest juz rozbudowany na maksymalny Poziom.");

				leader_menu(id);

				return PLUGIN_HANDLED;
			}

			new Float:remainingEuro = csgoClan[CLAN_MONEY] - (cvarLevelCost + cvarNextLevelCost * csgoClan[CLAN_LEVEL]);

			if (remainingEuro < 0.0) {
				client_print_color(id, id, "^x04[CS:GO]^x01 Twoj klan nie ma wystarczajacej ilosci Euro w banku.");

				leader_menu(id);

				return PLUGIN_HANDLED;
			}

			csgoClan[CLAN_LEVEL]++;
			csgoClan[CLAN_MONEY] = _:remainingEuro;

			new name[32];

			get_user_name(id, name, charsmax(name));

			for (new player = 1; player <= MAX_PLAYERS; player++) {
				if (!is_user_connected(id) || player == id || clan[player] != clan[id]) continue;

				client_print_color(player, player, "^x04[CS:GO]^x03 %s^x01 rozbudowal klan do^x03 %i Poziomu^x01!", name, csgoClan[CLAN_LEVEL]);
			}

			client_print_color(id, id, "^x04[CS:GO]^x01 Rozbudowales klan do^x03 %i Poziomu^x01!", csgoClan[CLAN_LEVEL]);

			ArraySetArray(csgoClans, get_clan_id(clan[id]), csgoClan);

			save_clan(clan[id]);

			leader_menu(id);
		} case 1: disband_menu(id);
		case 2: invite_menu(id);
		case 3: members_menu(id);
		case 4: applications_menu(id);
		case 5: wars_menu(id);
		case 6: client_cmd(id, "messagemode PODAJ_NOWA_NAZWE_KLANU");
	}

	return PLUGIN_HANDLED;
}

public disband_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \rrozwiazac\w klan?", "disband_menu_handle");

	menu_additem(menu, "Tak", "0");
	menu_additem(menu, "Nie^n", "1");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public disband_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	switch (item) {
		case 0: {
			client_print_color(id, id, "^x04[CS:GO]^x01 Rozwiazales swoj klan.");

			remove_clan(id);

			show_clan_menu(id);
		}
		case 1: show_clan_menu(id);
	}

	return PLUGIN_HANDLED;
}

public invite_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new userName[32], userId[6], playersAvailable = 0;

	new menu = menu_create("\yWybierz \rGracza \ydo zaproszenia:", "invite_menu_handle");

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(id) || player == id || clan[player]) continue;

		playersAvailable++;

		get_user_name(player, userName, charsmax(userName));

		num_to_str(player, userId, charsmax(userId));

		menu_additem(menu, userName, userId);
	}

	if (!playersAvailable) client_print_color(id, id, "^x04[CS:GO]^x01 Na serwerze nie ma gracza, ktorego moglbys zaprosic!");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public invite_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)  || !clan[id] || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	new userName[32], itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), userName, charsmax(userName), itemCallback);

	new player = str_to_num(itemData);

	if (!is_user_connected(player)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	if (get_clan_money(clan[id]) < cvarJoinFee) {
		client_print_color(id, id, "^x04[CS:GO]^x01 W banku klanu nie ma wystarczajaco pieniedzy na oplate wpisowa (^x04Wymagane %i Euro^x01).", floatround(cvarJoinFee));

		return PLUGIN_HANDLED;
	}

	invite_confirm_menu(id, player);

	client_print_color(id, id, "^x04[CS:GO]^x01 Zaprosiles^x03 %s^x01 do do twojego klanu.", userName);

	show_clan_menu(id);

	return PLUGIN_HANDLED;
}

public invite_confirm_menu(id, player)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new menuData[128], clanName[32], userName[32], userId[6];

	get_user_name(id, userName, charsmax(userName));

	get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));

	formatex(menuData, charsmax(menuData), "\r%s\w zaprosil cie do klanu \y%s\w.", userName, clanName);

	new menu = menu_create(menuData, "invite_confirm_menu_handle");

	num_to_str(id, userId, charsmax(userId));

	menu_additem(menu, "Dolacz", userId);
	menu_additem(menu, "Odrzuc");

	menu_display(player, menu);

	return PLUGIN_HANDLED;
}

public invite_confirm_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT || item) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	new player = str_to_num(itemData);

	if (!is_user_connected(id)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Gracza, ktory cie zaprosil nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	if (clan[id]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz dolaczyc do klanu, jesli nalezysz do innego.");

		return PLUGIN_HANDLED;
	}

	if (((get_clan_info(clan[player], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[player], CLAN_MEMBERS)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Niestety, w tym klanie nie ma juz wolnego miejsca.");

		return PLUGIN_HANDLED;
	}

	if (get_clan_money(clan[id]) < cvarJoinFee) {
		client_print_color(id, id, "^x04[CS:GO]^x01 W banku klanu nie ma wystarczajaco pieniedzy na oplate wpisowa (^x04Wymagane %i Euro^x01).", floatround(cvarJoinFee));

		return PLUGIN_HANDLED;
	}

	new clanName[32];

	get_clan_info(clan[player], CLAN_NAME, clanName, charsmax(clanName));

	set_user_clan(id, clan[player]);

	set_clan_info(clan[id], CLAN_MONEY, _, -cvarJoinFee);

	client_print_color(id, id, "^x04[CS:GO]^x01 Dolaczyles do klanu^x03 %s^01.", clanName);

	return PLUGIN_HANDLED;
}

public change_name_handle(id)
{
	if (!is_user_connected(id) || !csgo_check_account(id) || get_user_status(id) != STATUS_LEADER || end) return PLUGIN_HANDLED;

	new clanName[32];

	read_args(clanName, charsmax(clanName));
	remove_quotes(clanName);
	trim(clanName);

	if (equal(clanName, "")) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie wpisano nowej nazwy klanu.");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	if (strlen(clanName) < 3) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nazwa klanu musi miec co najmniej 3 znaki.");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	if (check_clan_name(clanName)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Klan z taka nazwa juz istnieje.");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	set_clan_info(clan[id], CLAN_NAME, _, _, clanName, charsmax(clanName));

	client_print_color(id, id, "^x04[CS:GO]^x01 Zmieniles nazwe klanu na^x03 %s^x01.", clanName);

	return PLUGIN_CONTINUE;
}

public members_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new queryData[128], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans_members` WHERE clan = '%i' ORDER BY flag DESC", clan[id]);

	SQL_ThreadQuery(sql, "members_menu_handle", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public members_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemData[64], userName[32], status, menu = menu_create("\yZarzadzaj \rCzlonkami:^n\wWybierz \yczlonka\w, aby pokazac mozliwe opcje.", "member_menu_handle");

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), userName, charsmax(userName));

		status = SQL_ReadResult(query, SQL_FieldNameToNum(query, "flag"));

		formatex(itemData, charsmax(itemData), "%s#%i", userName, status);

		switch (status) {
			case STATUS_MEMBER: add(userName, charsmax(userName), " \y[Czlonek]");
			case STATUS_DEPUTY: add(userName, charsmax(userName), " \y[Zastepca]");
			case STATUS_LEADER: add(userName, charsmax(userName), " \y[Przywodca]");
		}

		menu_additem(menu, userName, itemData);

		SQL_NextRow(query);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public member_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[64], userName[32], tempFlag[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	strtok(itemData, userName, charsmax(userName), tempFlag, charsmax(tempFlag), '#');

	new flag = str_to_num(tempFlag), userId = get_user_index(userName);

	if (userId == id) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz zarzadzac soba!");

		members_menu(id);

		return PLUGIN_HANDLED;
	}

	if (clan[userId]) chosenId[id] = get_user_userid(userId);

	if (flag == STATUS_LEADER) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozna zarzadzac przywodca klanu!");

		members_menu(id);

		return PLUGIN_HANDLED;
	}

	formatex(chosenName[id], charsmax(chosenName), userName);

	new menu = menu_create("\yWybierz \rOpcje:", "member_options_menu_handle");

	if (get_user_status(id) == STATUS_LEADER) {
		menu_additem(menu, "Przekaz \yPrzywodctwo", "1");

		if (flag == STATUS_MEMBER) menu_additem(menu, "Mianuj \yZastepce", "2");
		if (flag == STATUS_DEPUTY) menu_additem(menu, "Degraduj \yZastepce", "3");
	}

	menu_additem(menu, "Wyrzuc \yGracza", "4");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_CONTINUE;
}

public member_options_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	new itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	switch (str_to_num(itemData)) {
		case 1: update_member(id, STATUS_LEADER);
		case 2:	update_member(id, STATUS_DEPUTY);
		case 3:	update_member(id, STATUS_MEMBER);
		case 4: update_member(id, STATUS_NONE);
	}

	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}

public update_member(id, status)
{
	new bool:playerOnline;

	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || clan[player] != clan[id]) continue;

		if (get_user_userid(player) == chosenId[id]) {
			switch (status) {
				case STATUS_LEADER: {
					set_user_status(id, STATUS_DEPUTY);
					set_user_status(player, STATUS_LEADER);

					client_print_color(player, id, "^x04[CS:GO]^x01 Zostales mianowany przywodca klanu!");
				}
				case STATUS_DEPUTY: {
					set_user_status(player, STATUS_DEPUTY);

					client_print_color(player, id, "^x04[CS:GO]^x01 Zostales zastepca przywodcy klanu!");
				}
				case STATUS_MEMBER: {
					set_user_status(player, STATUS_MEMBER);

					client_print_color(player, id, "^x04[CS:GO]^x01 Zostales zdegradowany do rangi czlonka klanu.");
				}
				case STATUS_NONE: {
					set_user_clan(player);

					client_print_color(player, id, "^x04[CS:GO]^x01 Zostales wyrzucony z klanu.");
				}
			}

			playerOnline = true;

			continue;
		}

		switch (status) {
			case STATUS_LEADER: client_print_color(player, id, "^x04[CS:GO]^x03 %s^01 zostal nowym przywodca klanu.", chosenName[id]);
			case STATUS_DEPUTY: client_print_color(player, id, "^x04[CS:GO]^x03 %s^x01 zostal zastepca przywodcy klanu.", chosenName[id]);
			case STATUS_MEMBER: client_print_color(player, id, "^x04[CS:GO]^x03 %s^x01 zostal zdegradowany do rangi czlonka klanu.", chosenName[id]);
			case STATUS_NONE: client_print_color(player, id, "^x04[CS:GO]^x03 %s^01 zostal wyrzucony z klanu.", chosenName[id]);
		}
	}

	if (!playerOnline) {
		save_member(id, status, _, chosenName[id]);

		if (status == STATUS_NONE) set_clan_info(clan[id], CLAN_MEMBERS, -1);
		if (status == STATUS_LEADER) set_user_status(id, STATUS_DEPUTY);
	}

	show_clan_menu(id);

	return PLUGIN_HANDLED;
}

public applications_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new queryData[256], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.name, (SELECT money FROM `csgo_data` WHERE name = a.name) as money, (SELECT rank FROM `csgo_ranks` WHERE name = a.name) as rank FROM `csgo_clans_applications` a WHERE clan = '%i' ORDER BY rank DESC, money DESC", clan[id]);

	SQL_ThreadQuery(sql, "applications_menu_handle", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public applications_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], userName[32], rankName[32], Float:money, rank, usersCount = 0, menu = menu_create("\yRozpatrywanie \rPodan:^n\wWybierz \rpodanie\w, aby je \yzatwierdzic\w lub \yodrzucic\w.", "applications_confirm_menu");

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), userName, charsmax(userName));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "money"), money);

		rank = SQL_ReadResult(query, SQL_FieldNameToNum(query, "rank"));

		csgo_get_rank_name(rank, rankName, charsmax(rankName))

		formatex(itemName, charsmax(itemName), "\w%s \y(Ranga: \r%s\y | Euro: \r%.2f\y)", userName, rankName, money);

		menu_additem(menu, itemName, userName);

		SQL_NextRow(query);

		usersCount++;
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!usersCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Nie ma zadnych niezatwierdzonych podan do klanu!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public applications_confirm_menu(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		leader_menu(id);

		return PLUGIN_HANDLED;
	}

	new menuData[128], userName[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, userName, charsmax(userName), _, _, itemCallback);

	menu_destroy(menu);

	formatex(menuData, charsmax(menuData), "\wCo chcesz zrobic z podaniem gracza \y%s \w?", userName);

	new menu = menu_create(menuData, "applications_confirm_handle");

	menu_additem(menu, "Przymij - \rWpisowe z banku klanu", userName);
	menu_additem(menu, "Przymij - \yWpisowe z konta gracza", userName);
	menu_additem(menu, "Odrzuc", userName);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public applications_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new userName[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, userName, charsmax(userName), _, _, itemCallback);

	menu_destroy(menu);

	if (item == 2) {
		remove_application(id, userName);

		client_print_color(id, id, "^x04[CS:GO]^x01 Odrzuciles podanie gracza^x03 %s^01 o dolaczenie do klanu.", userName);

		return PLUGIN_HANDLED;
	}

	if (check_user_clan(userName)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Gracz dolaczyl juz do innego klanu!");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	if (((get_clan_info(clan[id], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[id], CLAN_MEMBERS)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Klan osiagnal maksymalna na ten moment liczbe czlonkow!");

		return PLUGIN_HANDLED;
	}

	if (!item) {
		if (get_clan_money(clan[id]) < cvarJoinFee) {
			client_print_color(id, id, "^x04[CS:GO]^x01 W banku klanu nie ma wystarczajaco pieniedzy na oplate wpisowa (^x04Wymagane %i Euro^x01).", floatround(cvarJoinFee));

			return PLUGIN_HANDLED;
		}

		set_clan_info(clan[id], CLAN_MONEY, _, -cvarJoinFee);
	} else {
		new userId = get_user_index(userName);

		if (is_user_connected(userId)) {
			if (csgo_get_money(id) < cvarJoinFee) {
				client_print_color(id, id, "^x04[CS:GO]^x01 Gracz nie ma wystarczajaco pieniedzy na oplate wpisowa (^x04Wymagane %i Euro^x01).", floatround(cvarJoinFee));

				return PLUGIN_HANDLED;
			}

			csgo_add_money(id, -cvarJoinFee);
		} else {
			new queryData[128], error[128], safeName[64], Handle:query, Float:money, errorNum;

			mysql_escape_string(userName, safeName, charsmax(safeName));

			formatex(queryData, charsmax(queryData), "SELECT money FROM `csgo_data` WHERE `name` = ^"%s^"", safeName);

			query = SQL_PrepareQuery(connection, queryData);

			if (SQL_Execute(query)) {
				if (SQL_MoreResults(query)) SQL_ReadResult(query, SQL_FieldNameToNum(query, "money"), money);
			} else {
				errorNum = SQL_QueryError(query, error, charsmax(error));

				log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
			}

			SQL_FreeHandle(query);

			if (money < cvarJoinFee) {
				client_print_color(id, id, "^x04[CS:GO]^x01 Gracz nie ma wystarczajaco pieniedzy na oplate wpisowa (^x04Wymagane %i Euro^x01).", floatround(cvarJoinFee));

				return PLUGIN_HANDLED;
			}

			formatex(queryData, charsmax(queryData), "UPDATE `csgo_data` SET money = money - %.2f WHERE `name` = ^"%s^"", cvarJoinFee, safeName);

			query = SQL_PrepareQuery(connection, queryData);

			if (!SQL_Execute(query)) {
				errorNum = SQL_QueryError(query, error, charsmax(error));

				log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
			}

			SQL_FreeHandle(query);
		}
	}

	accept_application(id, userName);

	client_print_color(id, id, "^x04[CS:GO]^x01 Zaakceptowales podanie gracza^x03 %s^01 o dolaczenie do klanu.", userName);

	return PLUGIN_HANDLED;
}

public wars_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new menu = menu_create("\yWojny \rKlanow\w", "wars_menu_handle"), callback = menu_makecallback("wars_menu_callback");

	menu_additem(menu, "Lista \yWojen", _, _, callback);
	menu_additem(menu, "Wypowiedz \yWojne", _, _, callback);
	menu_additem(menu, "Zaakceptuj \yWojne", _, _, callback);
	menu_additem(menu, "Anuluj \yWojne", _, _, callback);

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public wars_menu_callback(id, menu, item)
{
	switch (item) {
		case 0: return get_wars_count(clan[id], 1) ? ITEM_ENABLED : ITEM_DISABLED;
		case 2: return get_wars_count(clan[id], 0) ? ITEM_ENABLED : ITEM_DISABLED;
		case 3: return get_wars_count(clan[id], 0, 1) ? ITEM_ENABLED : ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public wars_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch(item) {
		case 0: war_list_menu(id);
		case 1: declare_war_menu(id);
		case 2: accept_war_menu(id);
		case 3: remove_war_menu(id);
	}

	return PLUGIN_HANDLED;
}

public war_list_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new queryData[256], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.*, (SELECT name FROM `csgo_clans` WHERE id = a.clan) as name, (SELECT name FROM `csgo_clans` WHERE id = a.clan2) as name2 FROM `csgo_clans_wars` a WHERE (clan = '%i' OR clan2 = '%i') AND started = '1'", clan[id], clan[id]);

	SQL_ThreadQuery(sql, "show_war_list_menu", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public show_war_list_menu(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], clanName[2][32], progress[2], warsCount = 0, clanId, ownClan, enemyClan, duration, reward, menu = menu_create("\yLista \rWojen\w:", "show_war_list_menu_handle");

	while (SQL_MoreResults(query)) {
		clanId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan"));

		if (clanId == clan[id]) {
			ownClan = 0;
			enemyClan = 1;
		} else {
			ownClan = 1;
			enemyClan = 0;
		}

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), clanName[0], charsmax(clanName[]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name2"), clanName[1], charsmax(clanName[]));

		progress[0] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "progress"));
		progress[1] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "progress2"));

		duration = SQL_ReadResult(query, SQL_FieldNameToNum(query, "duration"));
		reward = SQL_ReadResult(query, SQL_FieldNameToNum(query, "reward"));

		formatex(itemName, charsmax(itemName), "\w%s \y(\r%i\y) \rvs \w%s \y(\r%i\y) (Fragi: \r%i\y | Nagroda: \r%i Euro\y)", clanName[ownClan], progress[ownClan], clanName[enemyClan], progress[enemyClan], duration, reward);

		menu_additem(menu, itemName);

		SQL_NextRow(query);

		warsCount++;
	}

	menu_setprop(menu, MPROP_PERPAGE, 6);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!warsCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Twoj klan aktualnie nie prowadzi zadnych wojen!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public show_war_list_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	menu_destroy(menu);

	if (item != MENU_EXIT) wars_menu(id);

	return PLUGIN_HANDLED;
}

public declare_war_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new itemData[64], menu = menu_create("\yUstaw parametry \rwojny\w:", "declare_war_menu_handle");

	formatex(itemData, charsmax(itemData), "Liczba \rFragow\w: \y%i", warFrags[id]);
	menu_additem(menu, itemData);

	formatex(itemData, charsmax(itemData), "Wysokosc \rNagrody\w: \y%i Euro^n", warReward[id]);
	menu_additem(menu, itemData);

	menu_addtext(menu, "\wWybierz jeden z powyzszych \rparametrow\w, aby zmienic jego \ywartosc\w.^nKlan, ktoremu wypowiedzona zostanie wojna musi ja \rzaakceptowac\w, aby sie rozpoczela.^nW momencie rozpoczenia wojny z banku kazdego klanu pobierana jest \ypolowa nagrody\w.^nPo jej zakonczeniu zwycieski klan otrzymuje \ycala nagrode\w.^n", 0);

	menu_additem(menu, "Wypowiedz \rWojne");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public declare_war_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	menu_destroy(menu);

	if (item == MENU_EXIT) return PLUGIN_HANDLED;

	switch(item) {
		case 0: client_cmd(id, "messagemode PODAJ_LICZBE_FRAGOW");
		case 1: client_cmd(id, "messagemode PODAJ_WYSOKOSC_NAGRODY");
		case 2: {
			new queryData[256], tempId[1];

			tempId[0] = id;

			formatex(queryData, charsmax(queryData), "SELECT id, name, money, members FROM `csgo_clans` a WHERE id != '%i' AND NOT EXISTS (SELECT id FROM `csgo_clans_wars` WHERE (clan = '%i' AND clan2 = a.id) OR (clan2 = '%i' AND clan = a.id)) ORDER BY a.members DESC, a.kills DESC", clan[id], clan[id], clan[id]);

			SQL_ThreadQuery(sql, "declare_war_select", queryData, tempId, sizeof(tempId));
		}
	}

	return PLUGIN_HANDLED;
}

public declare_war_select(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], tempData[64], clanName[32], Float:money, clansCount = 0, members, clanId, menu = menu_create("\wWybierz \rklan\w, ktoremu chcesz wypowiedziec \ywojne\w:", "declare_war_confirm");

	while (SQL_MoreResults(query)) {
		clanId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
		members = SQL_ReadResult(query, SQL_FieldNameToNum(query, "members"));

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), clanName, charsmax(clanName));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "money"), money);

		formatex(tempData, charsmax(tempData), "%s#%i", clanName, clanId);
		formatex(itemName, charsmax(itemName), "\w%s \y(Czlonkowie: \r%i\y | Euro: \r%.2f\y)", clanName, members, money);

		menu_additem(menu, itemName, tempData);

		SQL_NextRow(query);

		clansCount++;
	}

	menu_setprop(menu, MPROP_PERPAGE, 6);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!clansCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Nie ma klanu, ktoremu mozna by wypowiedziec wojne!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public declare_war_confirm(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new tempData[192], itemData[64], clanName[32], tempClanId[6], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');

	formatex(tempData, charsmax(tempData), "\yPotwierdzasz wypowiedzenie wojny klanowi \r%s\y?^n\wLiczba \rFragow\w: \y%i^n\wWysokosc \rNagrody\w: \y%i Euro", clanName, warFrags[id], warReward[id]);

	new menu = menu_create(tempData, "declare_war_confirm_handle");

	menu_additem(menu, "\yTak", itemData);
	menu_additem(menu, "Nie");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public declare_war_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if (item) {
		menu_destroy(menu);

		declare_war_menu(id);

		return PLUGIN_HANDLED;
	}

	new itemData[64], clanName[32], tempClanId[6], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	menu_destroy(menu);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');

	declare_war(id, str_to_num(tempClanId));

	client_print_color(id, id, "^x04[CS:GO]^x01 Twoj klan wypowiedzial wojne klanowi^x03 %s^x01.", clanName);

	return PLUGIN_HANDLED;
}

public accept_war_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new queryData[256], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT id, clan, duration, reward, (SELECT name FROM `csgo_clans` WHERE id = a.clan2) as name, (SELECT name FROM `csgo_clans` WHERE id = a.clan) as name2 FROM `csgo_clans_wars` a WHERE clan2 = '%i' AND started = '0'", clan[id]);

	SQL_ThreadQuery(sql, "accept_war_menu_handle", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public accept_war_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], clanName[2][32], tempData[64], warsCount = 0, ownClan = 0, enemyClan = 1, warId, clanId, duration, reward, menu = menu_create("\yWybierz deklaracje \rwojny\w:", "accept_war_confirm");

	while (SQL_MoreResults(query)) {
		warId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
		clanId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan"));

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), clanName[0], charsmax(clanName[]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name2"), clanName[1], charsmax(clanName[]));

		duration = SQL_ReadResult(query, SQL_FieldNameToNum(query, "duration"));
		reward = SQL_ReadResult(query, SQL_FieldNameToNum(query, "reward"));

		formatex(itemName, charsmax(itemName), "\w%s \rvs \w%s \y(Fragi: \r%i\y | Nagroda: \r%i Euro\y)", clanName[ownClan], clanName[enemyClan], duration, reward);
		formatex(tempData, charsmax(tempData), "%s#%i#%i#%i#%i", clanName[enemyClan], clanId, warId, duration, reward);

		menu_additem(menu, itemName, tempData);

		SQL_NextRow(query);

		warsCount++;
	}

	menu_setprop(menu, MPROP_PERPAGE, 6);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!warsCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Nie ma zadnych deklaracji wojen do zaakceptowania!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public accept_war_confirm(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new dataParts[5][32], tempData[192], itemData[64], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	explode(itemData, '#', dataParts, sizeof(dataParts), charsmax(dataParts[]));

	formatex(tempData, charsmax(tempData), "\wCzy chcesz zaakceptowac \rwojne\w z klanem \y%s\w?^n\wLiczba \rFragow\w: \y%s^n\wWysokosc \rNagrody\w: \y%s Euro", dataParts[0], dataParts[3], dataParts[4]);

	new menu = menu_create(tempData, "accept_war_confirm_handle");

	menu_additem(menu, "\yAkceptuj", itemData);
	menu_additem(menu, "Odrzuc");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public accept_war_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new dataParts[5][32], itemData[96], itemAccess, menuCallback, warId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	menu_destroy(menu);

	explode(itemData, '#', dataParts, sizeof(dataParts), charsmax(dataParts[]));

	warId = str_to_num(dataParts[2]);

	if (item) {
		remove_war(warId);

		wars_menu(id);

		return PLUGIN_HANDLED;
	}

	new clanId = str_to_num(dataParts[1]), Float:halfReward = str_to_float(dataParts[4]) / 2.0;

	if (get_clan_money(clan[id]) < halfReward) {
		client_print_color(id, id, "^x04[CS:GO]^x01 W banku klanu nie ma wystarczajaco^x03 Euro^x01, aby pokryc polowe^x04 nagrody^x01!");

		wars_menu(id);

		return PLUGIN_HANDLED;
	}

	if (get_clan_money(clanId) < halfReward) {
		client_print_color(id, id, "^x04[CS:GO]^x01 W banku klanu^x03 %s^x01 nie ma wystarczajaco^x03 Euro^x01, aby pokryc polowe^x04 nagrody^x01!", dataParts[0]);

		wars_menu(id);

		return PLUGIN_HANDLED;
	}

	accept_war(id, warId, clanId, str_to_num(dataParts[3]), halfReward, dataParts[0]);

	return PLUGIN_HANDLED;
}

public remove_war_menu(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new queryData[256], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT id, duration, reward, (SELECT name FROM `csgo_clans` WHERE id = a.clan) as name, (SELECT name FROM `csgo_clans` WHERE id = a.clan2) as name2 FROM `csgo_clans_wars` a WHERE clan = '%i' AND started = '0'", clan[id]);

	SQL_ThreadQuery(sql, "remove_war_menu_handle", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public remove_war_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], clanName[2][32], tempData[64], warsCount = 0, ownClan = 0, enemyClan = 1, warId, duration, reward, menu = menu_create("\yWybierz deklaracje \rwojny\w do anulowania:", "remove_war_confirm");

	while (SQL_MoreResults(query)) {
		warId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), clanName[0], charsmax(clanName[]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name2"), clanName[1], charsmax(clanName[]));

		duration = SQL_ReadResult(query, SQL_FieldNameToNum(query, "duration"));
		reward = SQL_ReadResult(query, SQL_FieldNameToNum(query, "reward"));

		formatex(itemName, charsmax(itemName), "\w%s \rvs \w%s \y(Fragi: \r%i\y | Nagroda: \r%i Euro\y)", clanName[ownClan], clanName[enemyClan], duration, reward);
		formatex(tempData, charsmax(tempData), "%s#%i#%i#%i", clanName[enemyClan], warId, duration, reward);

		menu_additem(menu, itemName, tempData);

		SQL_NextRow(query);

		warsCount++;
	}

	menu_setprop(menu, MPROP_PERPAGE, 6);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!warsCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Nie ma zadnych deklaracji wojen do anulowania!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public remove_war_confirm(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new dataParts[4][32], tempData[192], itemData[64], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	explode(itemData, '#', dataParts, sizeof(dataParts), charsmax(dataParts[]));

	formatex(tempData, charsmax(tempData), "\wCzy chcesz anulowac \rdeklaracje wojny\w z klanem \y%s\w?^n\wLiczba \rFragow\w: \y%s^n\wWysokosc \rNagrody\w: \y%s Euro", dataParts[0], dataParts[2], dataParts[3]);

	new menu = menu_create(tempData, "remove_war_confirm_handle");

	menu_additem(menu, "\yTak", itemData);
	menu_additem(menu, "Nie");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public remove_war_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new dataParts[4][32], itemData[64], itemAccess, menuCallback, warId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	menu_destroy(menu);

	explode(itemData, '#', dataParts, sizeof(dataParts), charsmax(dataParts[]));

	warId = str_to_num(dataParts[1]);

	if (item) {
		wars_menu(id);

		return PLUGIN_HANDLED;
	}

	if (remove_war(warId)) client_print_color(id, id, "^x04[CS:GO]^x01 Anulowales deklaracje wojny z klanem^x03 %s^x01.", dataParts[0]);
	else client_print_color(id, id, "^x04[CS:GO]^x01 Wojna z klanem^x03 %s^x01 juz sie rozpoczela!", dataParts[0]);

	return PLUGIN_HANDLED;
}

public deposit_money_handle(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || end) return PLUGIN_HANDLED;

	new moneyData[32], Float:moneyAmount;

	read_args(moneyData, charsmax(moneyData));
	remove_quotes(moneyData);

	moneyAmount = str_to_float(moneyData);

	if (moneyAmount < 0.1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz wplacic mniej niz^x03 0.1 Euro^x01!");

		return PLUGIN_HANDLED;
	}

	if (csgo_get_money(id) - moneyAmount < 0.0) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie masz tyle^x03 Euro^x01!");

		return PLUGIN_HANDLED;
	}

	set_clan_info(clan[id], CLAN_MONEY, _, moneyAmount);

	csgo_add_money(id, -moneyAmount);

	add_payment(id, moneyAmount);

	client_print_color(id, id, "^x04[CS:GO]^x01 Wplaciles^x03 %.2f^x01 Euro na rzecz klanu.", moneyAmount);
	client_print_color(id, id, "^x04[CS:GO]^x01 Aktualnie twoj klan ma w banku^x03 %.2f^x01 Euro.", get_clan_info(clan[id], CLAN_MONEY));

	return PLUGIN_HANDLED;
}

public withdraw_money_handle(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || get_user_status(id) <= STATUS_MEMBER || end) return PLUGIN_HANDLED;

	new moneyData[32], Float:moneyAmount;

	read_args(moneyData, charsmax(moneyData));
	remove_quotes(moneyData);

	moneyAmount = str_to_float(moneyData);

	if (moneyAmount < 0.1) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz wyplacic mniej niz^x03 0.1 Euro^x01!");

		return PLUGIN_HANDLED;
	}

	if (moneyAmount > get_clan_money(clan[id])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 W banku klanu nie ma tyle^x03 Euro^x01!");

		return PLUGIN_HANDLED;
	}

	set_clan_info(clan[id], CLAN_MONEY, _, -moneyAmount);

	csgo_add_money(id, moneyAmount);

	add_payment(id, moneyAmount, true);

	client_print_color(id, id, "^x04[CS:GO]^x01 Wyplaciles^x03 %.2f^x01 Euro z banku klanu.", moneyAmount);
	client_print_color(id, id, "^x04[CS:GO]^x01 Aktualnie twoj klan ma w banku^x03 %.2f^x01 Euro.", get_clan_info(clan[id], CLAN_MONEY));

	return PLUGIN_HANDLED;
}

public set_war_frags_handle(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || get_user_status(id) <= STATUS_MEMBER || end) return PLUGIN_HANDLED;

	new fragsData[16], frags;

	read_args(fragsData, charsmax(fragsData));
	remove_quotes(fragsData);

	frags = str_to_num(fragsData);

	if (frags <= 0) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Liczba fragow w wojnie nie moze byc mniejsza od^x03 jednego^x01!");

		return PLUGIN_HANDLED;
	}

	warFrags[id] = frags;

	declare_war_menu(id);

	return PLUGIN_HANDLED;
}

public set_war_reward_handle(id)
{
	if (!is_user_connected(id) || !clan[id] || !csgo_check_account(id) || get_user_status(id) <= STATUS_MEMBER || end) return PLUGIN_HANDLED;

	new rewardData[16], reward;

	read_args(rewardData, charsmax(rewardData));
	remove_quotes(rewardData);

	reward = str_to_num(rewardData);

	if (reward <= 0) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nagroda za wygrana nie moze byc mniejsza od^x03 1 Euro^x01!");

		return PLUGIN_HANDLED;
	}

	warReward[id] = reward;

	declare_war_menu(id);

	return PLUGIN_HANDLED;
}

public payments_list(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return PLUGIN_HANDLED;

	new queryData[192], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, deposit, withdraw FROM `csgo_clans_members` WHERE clan = '%i' AND (deposit > 0 OR withdraw > 0) ORDER BY deposit DESC", clan[id]);

	SQL_ThreadQuery(sql, "show_payments_list", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public show_payments_list(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	static motdData[2048], playerName[32], motdLength, Float:deposit, Float:withdraw, rank;

	rank = 0;

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1s %-22.22s %12s %12s^n", "#", "Nick", "Wplaty", "Wyplaty");

	while (SQL_MoreResults(query)) {
		rank++;

		SQL_ReadResult(query, 0, playerName, charsmax(playerName));
		replace_all(playerName, charsmax(playerName), "<", "");
		replace_all(playerName,charsmax(playerName), ">", "");

		SQL_ReadResult(query, 1, deposit);
		SQL_ReadResult(query, 2, withdraw);

		if (rank >= 10) motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %5.2f %5.2f^n", rank, playerName, deposit, withdraw);
		else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %6.2f %5.2f^n", rank, playerName, deposit, withdraw);

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Lista Wplat i Wyplat");

	return PLUGIN_HANDLED;
}

public clans_top15(id)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	new queryData[192], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, members, kills, level, wins, money FROM `csgo_clans` ORDER BY kills DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_clans_top15", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public show_clans_top15(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	static motdData[2048], clanName[32], Float:money, motdLength, rank, members, kills, level, wins;

	rank = 0;

	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1s %-22.22s %4s %8s %6s %8s %s^n", "#", "Nazwa", "Czlonkowie", "Poziom", "Zabicia", "Wygrane Wojny", "Pieniadze");

	while (SQL_MoreResults(query)) {
		rank++;

		SQL_ReadResult(query, 0, clanName, charsmax(clanName));
		replace_all(clanName, charsmax(clanName), "<", "");
		replace_all(clanName,charsmax(clanName), ">", "");

		members = SQL_ReadResult(query, 1);
		kills = SQL_ReadResult(query, 2);
		level = SQL_ReadResult(query, 3);
		wins = SQL_ReadResult(query, 4);

		SQL_ReadResult(query, 5, money);

		if (rank >= 10) motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %5d %8d %10d %13d %8.2f^n", rank, clanName, members, level, kills, wins, money);
		else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %6d %8d %10d %13d %8.2f^n", rank, clanName, members, level, kills, wins, money);

		SQL_NextRow(query);
	}

	show_motd(id, motdData, "Top 15 Klanow");

	return PLUGIN_HANDLED;
}

public say_text(msgId, msgDest, msgEnt)
{
	if (!cvarChatPrefix) return PLUGIN_CONTINUE;

	new id = get_msg_arg_int(1);

	if (is_user_connected(id) && clan[id]) {
		new tempMessage[192], message[192], chatPrefix[32], steamId[33], playerName[32];

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));
		get_user_authid(id, steamId, charsmax(steamId));

		get_clan_info(clan[id], CLAN_NAME, chatPrefix, charsmax(chatPrefix));

		format(chatPrefix, charsmax(chatPrefix), "^x04[%s]", chatPrefix);

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

public message_intermission()
	end = true;

public add_to_full_pack(esHandle, e, ent, host, hostFlags, player, pSet)
{
	if (!is_user_alive(host) || !is_user_alive(ent) || !clan[host] || !clan[ent] || !check_war_enemy(host, ent)) return;

	set_es(esHandle, ES_RenderFx, kRenderFxGlowShell);
	set_es(esHandle, ES_RenderColor, 255, 0, 0);
	set_es(esHandle, ES_RenderMode, kRenderNormal);
	set_es(esHandle, ES_RenderAmt, 20);
}

public application_menu(id)
{
	if (!is_user_connected(id) || clan[id] || end) return PLUGIN_HANDLED;

	new queryData[512], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans` a WHERE NOT EXISTS (SELECT * FROM `csgo_clans_applications` WHERE clan = a.id AND name = ^"%s^") ORDER BY a.members DESC, a.kills DESC", playerName[id]);

	SQL_ThreadQuery(sql, "application_menu_handle", queryData, tempId, sizeof(tempId));

	return PLUGIN_HANDLED;
}

public application_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] SQL Error: %s (%d)", error, errorNum);

		return PLUGIN_HANDLED;
	}

	new id = tempId[0];

	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], itemData[64], clanName[32], Float:money, clansCount = 0, clanId, members, menu = menu_create("\yZlozenie \rPodania:^n\wWybierz \rklan\w, do ktorego chcesz zlozyc \ypodanie\w.", "application_handle");

	while (SQL_MoreResults(query)) {
		clanId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
		members = SQL_ReadResult(query, SQL_FieldNameToNum(query, "members"));

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), clanName, charsmax(clanName));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "money"), money);

		formatex(itemName, charsmax(itemName), "\w%s \y(Czlonkowie: \r%i\y | Euro: \r%.2f\y)", clanName, members, money);
		formatex(itemData, charsmax(itemData), "%s#%i", clanName, clanId);

		menu_additem(menu, itemName, itemData);

		SQL_NextRow(query);

		clansCount++;
	}

	menu_setprop(menu, MPROP_PERPAGE, 6);
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");

	if (!clansCount) {
		menu_destroy(menu);

		client_print_color(id, id, "^x04[CS:GO]^x01 Nie ma klanu, do ktorego moglbys zlozyc podanie!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public application_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	if (clan[id]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz zlozyc podania, jesli jestes juz w klanie!");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	new itemData[64], clanName[32], tempClanId[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');

	if (check_applications(id, str_to_num(tempClanId))) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Juz zlozyles podanie do tego klanu, poczekaj na jego rozpatrzenie!");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	new menuData[128];

	formatex(menuData, charsmax(menuData), "\yZlozenie \rPodania^n\wCzy na pewno chcesz zlozyc \rpodanie\w do klanu \y%s\w?", clanName);

	new menu = menu_create(menuData, "application_confirm_handle");

	menu_additem(menu, "Tak", itemData);
	menu_additem(menu, "Nie");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public application_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id) || end) return PLUGIN_HANDLED;

	if (item == MENU_EXIT || item) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[64], clanName[32], tempClanId[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');

	new clanId = str_to_num(tempClanId);

	if (clan[id]) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nie mozesz zlozyc podania, jesli jestes juz w klanie!");

		show_clan_menu(id);

		return PLUGIN_HANDLED;
	}

	add_application(id, clanId);

	client_print_color(id, id, "^x04[CS:GO]^x01 Zlozyles podanie do klanu^x03 %s^01.", clanName);

	return PLUGIN_HANDLED;
}

stock set_user_clan(id, playerClan = 0, owner = 0)
{
	if (!is_user_connected(id) || end) return;

	if (playerClan == 0) {
		set_clan_info(clan[id], CLAN_MEMBERS, -1);

		TrieDeleteKey(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id]);

		save_member(id, STATUS_NONE);

		clan[id] = 0;
	} else {
		clan[id] = playerClan;

		set_clan_info(clan[id], CLAN_MEMBERS, 1);

		TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], owner ? STATUS_LEADER : STATUS_MEMBER);

		save_member(id, owner ? STATUS_LEADER : STATUS_MEMBER, 1);
	}
}

stock set_user_status(id, status)
{
	if (!is_user_connected(id) || !clan[id] || end) return;

	TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);

	save_member(id, status);
}

stock get_user_status(id)
{
	if (!is_user_connected(id) || !clan[id] || end) return STATUS_NONE;

	new status;

	TrieGetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);

	return status;
}

public sql_init()
{
	new host[64], user[64], pass[64], db[64], queryData[512], error[128], errorNum;

	get_cvar_string("csgo_sql_host", host, charsmax(host));
	get_cvar_string("csgo_sql_user", user, charsmax(user));
	get_cvar_string("csgo_sql_pass", pass, charsmax(pass));
	get_cvar_string("csgo_sql_db", db, charsmax(db));

	sql = SQL_MakeDbTuple(host, user, pass, db);

	connection = SQL_Connect(sql, errorNum, error, charsmax(error));

	if (errorNum) {
		log_to_file("csgo-error.log", "[CS:GO Clans] Init SQL Error: %s", error);

		set_task(1.0, "sql_init");

		return;
	}

	sqlConnected = true;

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_clans` (`id` INT NOT NULL AUTO_INCREMENT, `name` VARCHAR(64) NOT NULL, `members` INT DEFAULT 1 NOT NULL, ");
	add(queryData, charsmax(queryData), "`money` DOUBLE(16, 2) NOT NULL, `kills` INT NOT NULL, `level` INT NOT NULL, `wins` INT NOT NULL, PRIMARY KEY (`id`));");

	new Handle:query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_clans_members` (`name` varchar(64) NOT NULL, `clan` INT NOT NULL, ");
	add(queryData, charsmax(queryData), "`flag` INT NOT NULL, `deposit` DOUBLE(16, 2) NOT NULL, `withdraw` DOUBLE(16, 2) NOT NULL, PRIMARY KEY (`name`));");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_clans_applications` (`name` varchar(64) NOT NULL, `clan` INT NOT NULL, PRIMARY KEY (`name`, `clan`));");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_clans_wars` (`id` INT NOT NULL AUTO_INCREMENT, `clan` INT NOT NULL, `clan2` INT NOT NULL, ");
	add(queryData, charsmax(queryData), "`progress` INT NOT NULL, `progress2` INT NOT NULL, `duration` INT NOT NULL, `reward` INT NOT NULL, `started` INT NOT NULL, PRIMARY KEY (`id`));");

	query = SQL_PrepareQuery(connection, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) log_to_file("csgo-error.log", "[CS:GO Clans] Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("csgo-error.log", "[CS:GO Clans] Query failed. [%d] %s", errorNum, error);
	}

	return PLUGIN_CONTINUE;
}

public save_clan(clanId)
{
	static queryData[256], safeClanName[64], csgoClan[clanInfo];

	ArrayGetArray(csgoClans, get_clan_id(clanId), csgoClan);

	mysql_escape_string(csgoClan[CLAN_NAME], safeClanName, charsmax(safeClanName));

	formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans` SET name = ^"%s^", level = '%i', money = '%.2f', kills = '%i', members = '%i', wins = '%i' WHERE id = '%i'",
	safeClanName, csgoClan[CLAN_LEVEL], csgoClan[CLAN_MONEY], csgoClan[CLAN_KILLS], csgoClan[CLAN_MEMBERS], csgoClan[CLAN_WINS], clanId);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public load_clan_data(id)
{
	if (!sqlConnected) {
		set_task(1.0, "load_clan_data", id);

		return;
	}

	new queryData[256], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.flag, b.* FROM `csgo_clans_members` a JOIN `csgo_clans` b ON a.clan = b.id WHERE a.name = ^"%s^"", playerName[id]);

	SQL_ThreadQuery(sql, "load_clan_data_handle", queryData, tempId, sizeof(tempId));
}

public load_clan_data_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] Data SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = tempId[0];

	if (SQL_MoreResults(query)) {
		new csgoClan[clanInfo];

		csgoClan[CLAN_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));

		if (!check_clan_loaded(csgoClan[CLAN_ID])) {
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), csgoClan[CLAN_NAME], charsmax(csgoClan[CLAN_NAME]));

			csgoClan[CLAN_LEVEL] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "level"));
			csgoClan[CLAN_KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "kills"));
			csgoClan[CLAN_WINS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "wins"));
			csgoClan[CLAN_MEMBERS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "members"));

			SQL_ReadResult(query, SQL_FieldNameToNum(query, "money"), csgoClan[CLAN_MONEY]);

			csgoClan[CLAN_STATUS] = _:TrieCreate();

			ArrayPushArray(csgoClans, csgoClan);

			new queryData[128];

			formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans_wars` WHERE clan = '%i' AND started = '1'", csgoClan[CLAN_ID]);

			SQL_ThreadQuery(sql, "load_wars_data_handle", queryData);
		}

		clan[id] = csgoClan[CLAN_ID];

		new status = SQL_ReadResult(query, SQL_FieldNameToNum(query, "flag"));

		TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);
	} else {
		new queryData[128];

		formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO `csgo_clans_members` (`name`) VALUES (^"%s^")", playerName[id]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}

	set_bit(id, loaded);
}

public player_spawn(id)
	if (!get_bit(id, info) && is_user_alive(id)) set_task(0.1, "show_clan_info", id + TASK_INFO);

public show_clan_info(id)
{
	id -= TASK_INFO;

	if (get_bit(id, info)) return;

	if (!get_bit(id, loaded)) {
		set_task(3.0, "show_clan_info", id + TASK_INFO);

		return;
	}

	set_bit(id, info);

	if (get_user_status(id) > STATUS_MEMBER) {
		new applications = get_applications_count(clan[id]), wars = get_wars_count(clan[id], 0);

		if (applications > 0 && wars > 0) client_print_color(id, id, "^x04[CS:GO]^x01 Masz do rozpatrzenia^x03 %i podania o dolaczenie^x01 i^x03 %i deklaracje wojny^x01 w^x04 klanie^x01.", applications, wars);
		else if(applications > 0) client_print_color(id, id, "^x04[CS:GO]^x01 Masz do rozpatrzenia^x03 %i podania o dolaczenie^x01 w^x04 klanie^x01.", applications);
		else if(wars > 0) client_print_color(id, id, "^x04[CS:GO]^x01 Masz do rozpatrzenia^x03 %i deklaracje wojny^x01 w^x04 klanie^x01.", wars);
	}
}

public load_wars_data_handle(failState, Handle:query, error[], errorNum)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] Wars SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new csgoWar[warInfo];

	while (SQL_MoreResults(query)) {
		csgoWar[WAR_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
		csgoWar[WAR_CLAN] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan"));
		csgoWar[WAR_CLAN2] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan2"));
		csgoWar[WAR_PROGRESS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "progress"));
		csgoWar[WAR_PROGRESS2] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "progress2"));
		csgoWar[WAR_DURATION] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "duration"));
		csgoWar[WAR_REWARD] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "reward"));

		ArrayPushArray(csgoWars, csgoWar);

		SQL_NextRow(query);
	}
}

public _csgo_get_user_clan(id)
	return clan[id];

public _csgo_get_clan_name(clanId, dataReturn[], dataLength)
{
	param_convert(2);

	get_clan_info(clanId, CLAN_NAME, dataReturn, dataLength);
}

public _csgo_get_clan_members(clanId)
	return get_clan_info(clanId, CLAN_MEMBERS);

stock save_member(id, status = 0, change = 0, const name[] = "")
{
	new queryData[256], safeName[64];

	if (strlen(name)) mysql_escape_string(name, safeName, charsmax(safeName));
	else copy(safeName, charsmax(safeName), playerName[id]);

	if (status) {
		if (change) formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans_members` SET clan = '%i', flag = '%i' WHERE name = ^"%s^"", clan[id], status, safeName);
		else formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans_members` SET flag = '%i' WHERE name = ^"%s^"", status, safeName);
	} else formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans_members` SET clan = '0', flag = '0', deposit = '0', withdraw = '0' WHERE name = ^"%s^"", safeName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if (change) {
		formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_clans_applications` WHERE name = ^"%s^"", safeName);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}
}

stock declare_war(id, clanId)
{
	new queryData[192], clanName[32];

	formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_clans_wars` (`clan`, `clan2`, `duration`, `reward`) VALUES ('%i', '%i', '%i', '%i')", clan[id], clanId, warFrags[id], warReward[id]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i) || clan[i] != clanId || get_user_status(i) <= STATUS_MEMBER) continue;

		client_print_color(i, i, "^x04[CS:GO]^x01 Klan^x03 %s^x01 wypowiedzial^x04 wojne^x01 twojemu klanowi! Zaakceptuj lub odrzuc wojne.", clanName);
	}
}

stock accept_war(id, warId, clanId, duration, Float:money, const enemyClanName[])
{
	new queryData[192], csgoWar[warInfo], clanName[32];

	formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans_wars` SET started = '1' WHERE id = '%i'", warId);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if (!get_clan_id(clanId)) {
		formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans` SET money = money - '%.2f' WHERE id = '%i'", money, clanId);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	} else set_clan_info(clanId, CLAN_MONEY, _, -money);

	set_clan_info(clan[id], CLAN_MONEY, _, -money);
	get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));

	csgoWar[WAR_ID] = warId;
	csgoWar[WAR_CLAN] = clanId;
	csgoWar[WAR_CLAN2] = clan[id];
	csgoWar[WAR_DURATION] = duration;
	csgoWar[WAR_REWARD] = floatround(money * 2);

	ArrayPushArray(csgoWars, csgoWar);

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i) || !clan[i] || (clan[i] != clan[id] && clan[i] != clanId)) continue;

		client_print_color(i, i, "^x04[CS:GO]^x01 Twoj klan rozpoczal wojne z klanem^x03 %s^x01 (Fragi:^x04 %i^x01 | Nagroda:^x04 %i Euro^x01).", clan[i] == clan[id] ? clanName : enemyClanName, csgoWar[WAR_DURATION], csgoWar[WAR_REWARD]);
	}
}

stock remove_war(warId, started = 0)
{
	new queryData[128], error[128], Handle:query, bool:result, errorNum;

	formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_clans_wars` WHERE id = '%i' AND started = '%i'", warId, started);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_AffectedRows(query)) result = true;
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return result;
}

public remove_clan_wars(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Clans] Remove Clan SQL Error: %s (%d)", error, errorNum);

		return;
	}

	new id = tempId[0], queryData[128], clanName[32], clanId[2], Float:reward, enemyClan;

	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), clanName, charsmax(clanName));

		clanId[0] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan"));
		clanId[1] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan2"));

		SQL_ReadResult(query, SQL_FieldNameToNum(query, "reward"), reward);

		enemyClan = id == clanId[0] ? clanId[1] : clanId[0];

		if (get_clan_id(enemyClan)) {
			set_clan_info(enemyClan, CLAN_MONEY, _, reward);

			for (new i = 1; i <= MAX_PLAYERS; i++) {
				if (!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i) || clan[i] != enemyClan) continue;

				client_print_color(i, i, "^x04[CS:GO]^x01 Klan^x03 %s^x01 zostal rozwiazany, a to konczy z nim wojne. Zwyciestwo!", clanName);
			}
		} else {
			formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans` SET money = money + %.2f WHERE id = '%i'", reward, enemyClan);

			SQL_ThreadQuery(sql, "ignore_handle", queryData);
		}

		SQL_NextRow(query);
	}

	formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_clans_wars` WHERE clan = '%i' OR clan2 = '%i'", id, id);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public save_war(warId)
{
	static queryData[128], csgoWar[warInfo];

	ArrayGetArray(csgoWars, warId, csgoWar);

	formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans_wars` SET progress = '%i', progress2 = '%i' WHERE id = '%i'", csgoWar[WAR_PROGRESS], csgoWar[WAR_PROGRESS2], csgoWar[WAR_ID]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock check_war(killer, victim)
{
	static csgoWar[warInfo], killerClan[32], victimClan[32], killerName[32], victimName[32];

	for (new i = 0; i < ArraySize(csgoWars); i++) {
		ArrayGetArray(csgoWars, i, csgoWar);

		if ((clan[killer] == csgoWar[WAR_CLAN] && clan[victim] == csgoWar[WAR_CLAN2]) || (clan[killer] == csgoWar[WAR_CLAN2] && clan[victim] == csgoWar[WAR_CLAN])) {
			new progress = clan[killer] == csgoWar[WAR_CLAN] ? WAR_PROGRESS : WAR_PROGRESS2;

			csgoWar[progress]++;

			get_clan_info(clan[victim], CLAN_NAME, victimClan, charsmax(victimClan));
			get_user_name(victim, victimName, charsmax(victimName));

			if (csgoWar[progress] == csgoWar[WAR_DURATION]) {
				get_clan_info(clan[killer], CLAN_NAME, killerClan, charsmax(killerClan));
				get_user_name(killer, killerName, charsmax(killerName));

				client_print_color(killer, killer, "^x04[CS:GO]^x01 Zabijajac^x03 %s^x01 zakonczyles wojne z klanem^x03 %s^x01. Zwyciestwo!", victimName, victimClan);
				client_print_color(victim, victim, "^x04[CS:GO]^x01 Ginac z rak^x03 %s^x01 zakonczyles wojne z klanem^x03 %s^x01. Porazka...", killerName, killerClan);

				for (new i = 1; i <= MAX_PLAYERS; i++) {
					if (!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i) || !clan[i] || i == killer || i == victim) continue;

					if (clan[i] == clan[killer]) client_print_color(i, killer, "^x04[CS:GO]^x03 %s^x01 zabijajac^x03 %s^x01 zakonczyl wojne z klanem^x03 %s^x01. Zwyciestwo!", killerName, victimName, victimClan);
					if (clan[i] == clan[victim]) client_print_color(i, victim, "^x04[CS:GO]^x03 %s^x01 ginac z rak^x03 %s^x01 zakonczyl wojne z klanem^x03 %s^x01. Porazka...", victimName, killerName, killerClan);
				}

				set_clan_info(clan[killer], CLAN_MONEY, _, float(csgoWar[WAR_REWARD]));
				set_clan_info(clan[killer], CLAN_WINS, 1);

				remove_war(csgoWar[WAR_ID], 1);

				ArrayDeleteItem(csgoWars, i);

			} else {
				client_print_color(killer, killer, "^x04[CS:GO]^x01 Zabijajac^x03 %s^x01 zdobyles fraga w wojnie z klanem^x03 %s^x01. Wynik:^x04 %i - %i / %i^x01.", victimName, victimClan, csgoWar[progress], csgoWar[progress == WAR_PROGRESS ? WAR_PROGRESS2 : WAR_PROGRESS], csgoWar[WAR_DURATION]);

				ArraySetArray(csgoWars, i, csgoWar);

				save_war(i);
			}

			break;
		}
	}
}

stock check_war_enemy(id, enemy)
{
	static csgoWar[warInfo];

	for (new i = 0; i < ArraySize(csgoWars); i++) {
		ArrayGetArray(csgoWars, i, csgoWar);

		if ((clan[id] == csgoWar[WAR_CLAN] && clan[enemy] == csgoWar[WAR_CLAN2]) || (clan[id] == csgoWar[WAR_CLAN2] && clan[enemy] == csgoWar[WAR_CLAN])) return true;
	}

	return false;
}

stock add_payment(id, Float:money, withdraw = false)
{
	new queryData[192], type[16];

	formatex(type, charsmax(type), "%s", withdraw ? "withdraw" : "deposit");
	formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans_members` SET %s = %s + %.2f WHERE name = ^"%s^"", type, type, money, playerName[id]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock add_application(id, clanId)
{
	new queryData[192], userName[32];

	formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO `csgo_clans_applications` (`name`, `clan`) VALUES (^"%s^", '%i');", playerName[id], clanId);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	get_user_name(id, userName, charsmax(userName));

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i) || clan[i] != clanId || get_user_status(i) <= STATUS_MEMBER) continue;

		client_print_color(i, i, "^x04[CS:GO]^x03 %s^x01 zlozyl podanie do klanu!", userName);
	}
}

stock check_applications(id, clanId)
{
	new queryData[192], error[128], Handle:query, bool:foundApplication, errorNum;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans_applications` WHERE `name` = ^"%s^" AND clan = '%i'", playerName[id], clanId);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) foundApplication = true;
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return foundApplication;
}

stock accept_application(id, const userName[])
{
	new player = get_user_index(userName);

	if (is_user_connected(player)) {
		new clanName[32];

		get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));

		set_user_clan(player, clan[id]);

		client_print_color(player, player, "^x04[CS:GO]^x01 Zostales przyjety do klanu^x03 %s^x01!", clanName);
	} else {
		set_clan_info(clan[id], CLAN_MEMBERS, 1);

		save_member(id, STATUS_MEMBER, 1, userName);
	}
}

stock remove_application(id, const name[] = "")
{
	new player = get_user_index(name);

	if (is_user_connected(player)) {
		new clanName[32], userName[32];

		get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));
		get_user_name(id, userName, charsmax(userName));

		client_print_color(player, player, "^x04[CS:GO]^x03 %s^x01 odrzucil twoje podanie do klanu^x03 %s^x01!", userName, clanName);
	}

	new queryData[192], safeName[64];

	if (strlen(name)) mysql_escape_string(name, safeName, charsmax(safeName));
	else copy(safeName, charsmax(safeName), playerName[id]);

	formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_clans_applications` WHERE name = ^"%s^" AND clan = '%i'", safeName, clan[id]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock check_clan_name(const clanName[])
{
	new queryData[192], error[128], safeClanName[64], Handle:query, bool:foundClan, errorNum;

	mysql_escape_string(clanName, safeClanName, charsmax(safeClanName));

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans` WHERE `name` = ^"%s^"", safeClanName);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) foundClan = true;
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return foundClan;
}

stock check_user_clan(const userName[])
{
	new queryData[192], error[128], safeUserName[64], Handle:query, bool:foundClan, errorNum;

	mysql_escape_string(userName, safeUserName, charsmax(safeUserName));

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans_members` WHERE `name` = ^"%s^" AND clan > 0", safeUserName);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) foundClan = true;
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return foundClan;
}

stock create_clan(id, const clanName[])
{
	new csgoClan[clanInfo], queryData[192], error[128], safeClanName[64], Handle:query, errorNum;

	mysql_escape_string(clanName, safeClanName, charsmax(safeClanName));

	formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_clans` (`name`) VALUES (^"%s^")", safeClanName);

	query = SQL_PrepareQuery(connection, queryData);

	if (!SQL_Execute(query)) {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	formatex(queryData, charsmax(queryData), "SELECT id FROM `csgo_clans` WHERE name = ^"%s^"", safeClanName);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) {
			clan[id] = SQL_ReadResult(query, 0);

			copy(csgoClan[CLAN_NAME], charsmax(csgoClan[CLAN_NAME]), clanName);
			csgoClan[CLAN_STATUS] = _:TrieCreate();
			csgoClan[CLAN_ID] = clan[id];

			ArrayPushArray(csgoClans, csgoClan);

			set_user_clan(id, clan[id], 1);
			set_user_status(id, STATUS_LEADER);
		}
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);
}

stock remove_clan(id)
{
	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(id) || player == id) continue;

		if (clan[player] == clan[id]) {
			clan[player] = 0;

			client_print_color(player, player, "^x04[CS:GO]^x01 Twoj klan zostal rozwiazany.");
		}
	}

	new queryData[192], tempId[1];

	tempId[0] = clan[id];

	formatex(queryData, charsmax(queryData), "SELECT a.*, (SELECT name FROM `csgo_clans` WHERE id = '%i') as name FROM `csgo_clans_wars` a WHERE (clan = '%i' OR clan2 = '%i') AND started = '1'", clan[id], clan[id], clan[id]);
	SQL_ThreadQuery(sql, "remove_clan_wars", queryData, tempId, sizeof(tempId));

	formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_clans` WHERE id = '%i'", clan[id]);
	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_clans_applications` WHERE clan = '%i'", clan[id]);
	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	formatex(queryData, charsmax(queryData), "UPDATE `csgo_clans_members` SET flag = '0', clan = '0', deposit = '0', withdraw = '0' WHERE clan = '%i'", clan[id]);
	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	ArrayDeleteItem(csgoClans, get_clan_id(clan[id]));

	clan[id] = 0;
}

stock check_clan_loaded(clanId)
{
	static csgoClan[clanInfo];

	for (new i = 1; i < ArraySize(csgoClans); i++) {
		ArrayGetArray(csgoClans, i, csgoClan);

		if (clanId == csgoClan[CLAN_ID]) return true;
	}

	return false;
}

stock get_applications_count(clanId)
{
	new queryData[128], error[128], Handle:query, applicationsCount = 0, errorNum;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans_applications` WHERE `clan` = '%i'", clanId);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		while (SQL_MoreResults(query)) {
			applicationsCount++;

			SQL_NextRow(query);
		}
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return applicationsCount;
}

stock get_wars_count(clanId, started = 1, iniciated = 0)
{
	new queryData[128], error[128], Handle:query, warsCount = 0, errorNum;

	if(started) formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans_wars` WHERE (clan = '%i' OR clan2 = '%i') AND started = '1'", clanId, clanId);
	else formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_clans_wars` WHERE %s = '%i' AND started = '0'", iniciated ? "clan" : "clan2", clanId);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		while (SQL_MoreResults(query)) {
			warsCount++;

			SQL_NextRow(query);
		}
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return warsCount;
}

stock Float:get_clan_money(clanId)
{
	if (get_clan_id(clanId)) {
		new csgoClan[clanInfo];

		ArrayGetArray(csgoClans, get_clan_id(clanId), csgoClan);

		return csgoClan[CLAN_MONEY];
	}

	new queryData[128], error[128], Handle:query, Float:money = 0.0, errorNum;

	formatex(queryData, charsmax(queryData), "SELECT money FROM `csgo_clans` WHERE id = '%i'", clanId);

	query = SQL_PrepareQuery(connection, queryData);

	if (SQL_Execute(query)) {
		if (SQL_NumResults(query)) SQL_ReadResult(query, 0, money);
	} else {
		errorNum = SQL_QueryError(query, error, charsmax(error));

		log_to_file("csgo-error.log", "SQL Query Error. [%d] %s", errorNum, error);
	}

	SQL_FreeHandle(query);

	return money;
}

stock get_clan_id(clanId)
{
	static csgoClan[clanInfo];

	for (new i = 1; i < ArraySize(csgoClans); i++) {
		ArrayGetArray(csgoClans, i, csgoClan);

		if (clanId == csgoClan[CLAN_ID]) return i;
	}

	return 0;
}

stock get_clan_info(clanId, info, dataReturn[] = "", dataLength = 0)
{
	static csgoClan[clanInfo];

	for (new i = 0; i < ArraySize(csgoClans); i++) {
		ArrayGetArray(csgoClans, i, csgoClan);

		if (csgoClan[CLAN_ID] != clanId) continue;

		if (info == CLAN_NAME) {
			copy(dataReturn, dataLength, csgoClan[info]);

			return 0;
		}

		return csgoClan[info];
	}

	return 0;
}

stock set_clan_info(clanId, info, value = 0, Float:money = 0.0, dataSet[] = "", dataLength = 0)
{
	static csgoClan[clanInfo];

	for (new i = 1; i < ArraySize(csgoClans); i++) {
		ArrayGetArray(csgoClans, i, csgoClan);

		if (csgoClan[CLAN_ID] != clanId) continue;

		if (info == CLAN_NAME) formatex(csgoClan[CLAN_NAME], dataLength, "%s", dataSet);
		else if(info == CLAN_MONEY) csgoClan[CLAN_MONEY] += money;
		else csgoClan[info] += value;

		ArraySetArray(csgoClans, i, csgoClan);

		save_clan(csgoClan[CLAN_ID]);

		break;
	}
}

stock explode(const string[], const character, output[][], const maxParts, const maxLength)
{
	new currentPart = 0, stringLength = strlen(string), currentLength = 0;

	do {
		currentLength += (1 + copyc(output[currentPart++], maxLength, string[currentLength], character));
	} while(currentLength < stringLength && currentPart < maxParts);
}