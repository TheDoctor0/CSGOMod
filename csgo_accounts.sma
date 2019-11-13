#include <amxmodx>
#include <sqlx>
#include <fakemeta>
#include <csgomod>

#define PLUGIN "CS:GO Accounts"
#define VERSION "1.1"
#define AUTHOR "O'Zone"

#define TASK_PASSWORD   1945
#define TASK_LOAD       2491

enum _:playerInfo { STATUS, FAILS, PASSWORD[32], TEMP_PASSWORD[32], NAME[32], SAFE_NAME[64] };
enum _:status { NOT_REGISTERED, NOT_LOGGED, LOGGED, GUEST };
enum _:queries { UPDATE, INSERT, DELETE };

new const accountStatus[status][] = { "Niezarejestrowany", "Niezalogowany", "Zalogowany", "Gosc" };

new const commandAccount[][] = { "say /haslo", "say_team /haslo", "say /password", "say_team /password",
	"say /konto", "say_team /konto", "say /account", "say_team /account", "konto" };

new playerData[MAX_PLAYERS + 1][playerInfo], setinfo[16], Handle:sql, bool:sqlConnected, dataLoaded, autoLogin, loginMaxTime, passwordMaxFails, passwordMinLength;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof commandAccount; i++) register_clcmd(commandAccount[i], "account_menu");

	bind_pcvar_num(create_cvar("csgo_accounts_login_max_time", "60"), loginMaxTime);
	bind_pcvar_num(create_cvar("csgo_accounts_password_max_fails", "3"), passwordMaxFails);
	bind_pcvar_num(create_cvar("csgo_accounts_password_min_length", "5"), passwordMinLength);
	bind_pcvar_string(create_cvar("csgo_accounts_setinfo", "csgopass"), setinfo, charsmax(setinfo));

	register_clcmd("WPROWADZ_SWOJE_HASLO", "login_account");
	register_clcmd("WPROWADZ_WYBRANE_HASLO", "register_step_one");
	register_clcmd("POWTORZ_WYBRANE_HASLO", "register_step_two");
	register_clcmd("WPROWADZ_AKTUALNE_HASLO", "change_step_one");
	register_clcmd("WPROWADZ_NOWE_HASLO", "change_step_two");
	register_clcmd("POWTORZ_NOWE_HASLO", "change_step_three");
	register_clcmd("WPROWADZ_SWOJE_AKTUALNE_HASLO", "delete_account");

	register_concmd("joinclass", "check_account");
	register_concmd("jointeam", "check_account");
	register_concmd("chooseteam", "check_account");

	register_message(get_user_msgid("ShowMenu"), "message_show_menu");
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu");

	register_forward(FM_PlayerPreThink, "player_prethink");
}

public plugin_natives()
	register_native("csgo_check_account", "_csgo_check_account", 1);

public plugin_cfg()
	sql_init();

public plugin_end()
	SQL_FreeHandle(sql);

public client_connect(id)
{
	playerData[id][PASSWORD] = "";
	playerData[id][STATUS] = NOT_REGISTERED;
	playerData[id][FAILS] = 0;

	rem_bit(id, dataLoaded);
	rem_bit(id, autoLogin);

	if (is_user_bot(id) || is_user_hltv(id)) return;

	get_user_name(id, playerData[id][NAME], charsmax(playerData[][NAME]));

	mysql_escape_string(playerData[id][NAME], playerData[id][SAFE_NAME], charsmax(playerData[][SAFE_NAME]));

	set_task(0.1, "load_account", id + TASK_LOAD);
}

public client_disconnected(id)
{
	remove_task(id + TASK_PASSWORD);
	remove_task(id + TASK_LOAD);
	remove_task(id);
}

public message_show_menu(msgId, dest, id)
{
	new const Team_Select[] = "#Team_Select";
	static menuData[sizeof(Team_Select)];

	get_msg_arg_string(4, menuData, charsmax(menuData));

	if (equal(menuData, Team_Select) && get_bit(id, dataLoaded) && playerData[id][STATUS] < LOGGED && sql != Empty_Handle) {
		set_pdata_int(id, 205, 0, 5);

		set_task(0.1, "account_menu", id);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public message_vgui_menu(msgId, dest, id)
{
	if (get_msg_arg_int(1) == 2 && get_bit(id, dataLoaded) && playerData[id][STATUS] < LOGGED && sql != Empty_Handle) {
		set_task(0.1, "account_menu", id);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public player_prethink(id)
{
	if (is_user_connected(id) && get_bit(id, dataLoaded) && !is_user_bot(id) && !is_user_hltv(id) && !is_user_alive(id) && playerData[id][STATUS] < LOGGED) {
		static msgScreenFade;

		if (!msgScreenFade) msgScreenFade = get_user_msgid("ScreenFade");

		message_begin(MSG_ONE, msgScreenFade, {0, 0, 0}, id);
		write_short(1<<12);
		write_short(1<<12);
		write_short(0x0000);
		write_byte(0);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		message_end();
	}
}

public check_account(id)
{
	if (playerData[id][STATUS] < LOGGED) {
		account_menu(id);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public kick_player(id)
{
	id -= TASK_PASSWORD;

	if (is_user_connected(id)) server_cmd("kick #%d ^"Nie zalogowales sie w ciagu %is!^"", get_user_userid(id), loginMaxTime);
}

public account_menu(id)
{
	if (!is_user_connected(id) || !is_user_valid(id)) return PLUGIN_HANDLED;

	if (!get_bit(id, dataLoaded)) {
		remove_task(id);

		set_task(1.0, "account_menu", id);

		return PLUGIN_HANDLED;
	}

	if (!get_user_team(id) && playerData[id][STATUS] == LOGGED) {
		client_cmd(id, "chooseteam");
		engclient_cmd(id, "chooseteam");

		return PLUGIN_HANDLED;
	}

	if (playerData[id][STATUS] <= NOT_LOGGED && !task_exists(id + TASK_PASSWORD)) set_task(float(loginMaxTime), "kick_player", id + TASK_PASSWORD);

	static menuData[256];

	formatex(menuData, charsmax(menuData), "\rSYSTEM REJESTRACJI^n^n\rNick: \w[\y%s\w]^n\rStatus: \w[\y%s\w]", playerData[id][NAME], accountStatus[playerData[id][STATUS]]);

	if ((playerData[id][STATUS] == NOT_LOGGED || playerData[id][STATUS] == LOGGED) && !get_bit(id, autoLogin)) format(menuData, charsmax(menuData),"%s^n\wWpisz w konsoli \ysetinfo ^"_%s^" ^"twojehaslo^"^n\wSprawi to, ze twoje haslo bedzie ladowane \rautomatycznie\w.", menuData, setinfo);

	new menu = menu_create(menuData, "account_menu_handle"), callback = menu_makecallback("account_menu_callback");

	menu_additem(menu, "\yLogowanie", _, _, callback);
	menu_additem(menu, "\yRejestracja^n", _, _, callback);
	menu_additem(menu, "\yZmien \wHaslo", _, _, callback);
	menu_additem(menu, "\ySkasuj \wKonto^n", _, _, callback);
	menu_additem(menu, "\yZaloguj jako \wGosc \r(NIEZALECANE)^n", _, _, callback);

	if (playerData[id][STATUS] == LOGGED) menu_additem(menu, "\wWyjdz", _, _, callback);

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public account_menu_callback(id, menu, item)
{
	switch(item) {
		case 0: return playerData[id][STATUS] == NOT_LOGGED ? ITEM_ENABLED : ITEM_DISABLED;
		case 1: return (playerData[id][STATUS] == NOT_REGISTERED || playerData[id][STATUS] == GUEST) ? ITEM_ENABLED : ITEM_DISABLED;
		case 2, 3: return playerData[id][STATUS] == LOGGED ? ITEM_ENABLED : ITEM_DISABLED;
		case 4: return playerData[id][STATUS] == NOT_REGISTERED ? ITEM_ENABLED : ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public account_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT || item == 5) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch(item)
	{
		case 0: {
			client_print_color(id, id, "^x04[CS:GO]^x01 Wprowadz swoje^x04 haslo^x01, aby sie^x04 zalogowac.");

			set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
			show_hudmessage(id, "Wprowadz swoje haslo.");

			client_cmd(id, "messagemode WPROWADZ_SWOJE_HASLO");
		}
		case 1: {
			client_print_color(id, id, "^x04[CS:GO]^x01 Rozpoczales proces^x04 rejestracji^x01. Wprowadz wybrane^x04 haslo^x01.");

			set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
			show_hudmessage(id, "Wprowadz swoje haslo.");

			client_cmd(id, "messagemode WPROWADZ_WYBRANE_HASLO");

			remove_task(id + TASK_PASSWORD);
		}
		case 2: {
			client_print_color(id, id, "^x04[CS:GO]^x01 Wprowadz swoje^x04 aktualne haslo^x01 w celu potwierdzenia tozsamosci.");

			set_hudmessage(255, 128, 0, 0.22, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
			show_hudmessage(id, "Wprowadz swoje aktualne haslo.");

			client_cmd(id, "messagemode WPROWADZ_AKTUALNE_HASLO");
		}
		case 3: {
			client_print_color(id, id, "^x04[CS:GO]^x01 Wprowadz swoje^x04 aktualne haslo^x01 w celu potwierdzenia tozsamosci.");

			set_hudmessage(255, 128, 0, 0.22, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
			show_hudmessage(id, "Wprowadz swoje aktualne haslo.");

			client_cmd(id, "messagemode WPROWADZ_SWOJE_AKTUALNE_HASLO");
		}
		case 4: {
			client_print_color(id, id, "^x04[CS:GO]^x01 Zalogowales sie jako^x04 Gosc^x01. By zabezpieczyc swoj nick^x04 zarejestruj sie^x01.");

			set_hudmessage(0, 255, 0, -1.0, 0.9, 0, 0.0, 3.5, 0.0, 0.0);
			show_hudmessage(id, "Zostales pomyslnie zalogowany jako Gosc.");

			remove_task(id + TASK_PASSWORD);

			playerData[id][STATUS] = GUEST;

			client_cmd(id, "chooseteam");

			engclient_cmd(id, "chooseteam");
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public login_account(id)
{
	if (playerData[id][STATUS] != NOT_LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[32];

	read_args(password, charsmax(password));

	remove_quotes(password);

	if (!equal(playerData[id][PASSWORD], password)) {
		if (++playerData[id][FAILS] >= passwordMaxFails) server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));

		client_print_color(id, id, "^x04[CS:GO]^x01 Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/%i^x01)", playerData[id][FAILS], passwordMaxFails);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);

		show_hudmessage(id, "Podane haslo jest nieprawidlowe.");

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	playerData[id][STATUS] = LOGGED;

	playerData[id][FAILS] = 0;

	remove_task(id + TASK_PASSWORD);

	client_print_color(id, id, "^x04[CS:GO]^x01 Zostales pomyslnie^x04 zalogowany^x01. Zyczymy milej gry.");

	set_hudmessage(0, 255, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
	show_hudmessage(id, "Zostales pomyslnie zalogowany.");

	client_cmd(id, "chooseteam");
	engclient_cmd(id, "chooseteam");

	return PLUGIN_HANDLED;
}

public register_step_one(id)
{
	if ((playerData[id][STATUS] != NOT_REGISTERED && playerData[id][STATUS] != GUEST) || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[32];

	read_args(password, charsmax(password));
	remove_quotes(password);

	if (strlen(password) < passwordMinLength) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Haslo musi miec co najmniej^x04 %i znakow^x01.", passwordMinLength);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
		show_hudmessage(id, "Haslo musi miec co najmniej %i znakow.", passwordMinLength);

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	copy(playerData[id][TEMP_PASSWORD], charsmax(playerData[][TEMP_PASSWORD]), password);

	client_print_color(id, id, "^x04[CS:GO]^x01 Teraz powtorz wybrane^x04 haslo^x01.");

	set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
	show_hudmessage(id, "Powtorz wybrane haslo.");

	client_cmd(id, "messagemode POWTORZ_WYBRANE_HASLO");

	return PLUGIN_HANDLED;
}

public register_step_two(id)
{
	if ((playerData[id][STATUS] != NOT_REGISTERED && playerData[id][STATUS] != GUEST) || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[32];

	read_args(password, charsmax(password));
	remove_quotes(password);

	if (!equal(password, playerData[id][TEMP_PASSWORD])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Podane hasla^x04 roznia sie^x01 od siebie.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
		show_hudmessage(id, "Podane hasla roznia sie od siebie.");

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	new menuData[192];

	formatex(menuData, charsmax(menuData), "\rPOTWIERDZENIE REJESTRACJI^n^n\wTwoj Nick: \y[\r%s\y]^n\wTwoje Haslo: \y[\r%s\y]", playerData[id][NAME], playerData[id][TEMP_PASSWORD]);

	new menu = menu_create(menuData, "register_confirmation_handle");

	menu_additem(menu, "\rPotwierdz \wRejestracje");
	menu_additem(menu, "\yZmien \wHaslo^n");
	menu_additem(menu, "\wAnuluj \wRejestracje");

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public register_confirmation_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	switch(item) {
		case 0: {
			playerData[id][STATUS] = LOGGED;

			copy(playerData[id][PASSWORD], charsmax(playerData[][PASSWORD]), playerData[id][TEMP_PASSWORD]);

			account_query(id, INSERT);

			set_hudmessage(0, 255, 0, -1.0, 0.9, 0, 0.0, 3.5, 0.0, 0.0);
			show_hudmessage(id, "Zostales pomyslnie zarejestrowany i zalogowany.");

			client_print_color(id, id, "^x04[CS:GO]^x01 Twoj nick zostal pomyslnie^x04 zarejestrowany^x01.");
			client_print_color(id, id, "^x04[CS:GO]^x01 Wpisz w konsoli komende^x04 setinfo ^"_%s^" ^"%s^"^x01, aby twoje haslo bylo ladowane automatycznie.", setinfo, playerData[id][PASSWORD]);

			cmd_execute(id, "setinfo _%s %s", setinfo, playerData[id][PASSWORD]);
			cmd_execute(id, "writecfg %s", setinfo);

			client_cmd(id, "chooseteam");
			engclient_cmd(id, "chooseteam");
		} case 1: {
			client_print_color(id, id, "^x04[CS:GO]^x01 Rozpoczales proces^x04 rejestracji^x01. Wprowadz wybrane^x04 haslo^x01.");

			set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
			show_hudmessage(id, "Wprowadz wybrane haslo.");

			client_cmd(id, "messagemode WPROWADZ_WYBRANE_HASLO");
		} case 2: account_menu(id);
	}

	return PLUGIN_HANDLED;
}

public change_step_one(id)
{
	if (playerData[id][STATUS] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[32];

	read_args(password, charsmax(password));
	remove_quotes(password);

	if (!equal(playerData[id][PASSWORD], password)) {
		if (++playerData[id][FAILS] >= passwordMaxFails) server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));

		client_print_color(id, id, "^x04[CS:GO]^x01 Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/%i^x01)", playerData[id][FAILS], passwordMaxFails);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
		show_hudmessage(id, "Podane haslo jest nieprawidlowe.");

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	client_print_color(id, id, "^x04[CS:GO]^x01 Wprowadz swoje^x04 nowe haslo^x01.");

	set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
	show_hudmessage(id, "Wprowadz swoje nowe haslo.");

	client_cmd(id, "messagemode WPROWADZ_NOWE_HASLO");

	return PLUGIN_HANDLED;
}

public change_step_two(id)
{
	if (playerData[id][STATUS] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[32];

	read_args(password, charsmax(password));
	remove_quotes(password);

	if (equal(playerData[id][PASSWORD], password)) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nowe haslo jest^x04 takie samo^x01 jak aktualne.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
		show_hudmessage(id, "Nowe haslo jest takie samo jak aktualne.");

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	if (strlen(password) < passwordMinLength) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Nowe haslo musi miec co najmniej^x04 %i znakow^x01.", passwordMinLength);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
		show_hudmessage(id, "Nowe haslo musi miec co najmniej %i znakow.", passwordMinLength);

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	copy(playerData[id][TEMP_PASSWORD], charsmax(playerData[][TEMP_PASSWORD]), password);

	client_print_color(id, id, "^x04[CS:GO]^x01 Powtorz swoje nowe^x04 haslo^x01.");

	set_hudmessage(255, 128, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
	show_hudmessage(id, "Powtorz swoje nowe haslo.");

	client_cmd(id, "messagemode POWTORZ_NOWE_HASLO");

	return PLUGIN_HANDLED;
}

public change_step_three(id)
{
	if (playerData[id][STATUS] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[32];

	read_args(password, charsmax(password));
	remove_quotes(password);

	if (!equal(password, playerData[id][TEMP_PASSWORD])) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Podane hasla^x04 roznia sie^x01 od siebie.");

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
		show_hudmessage(id, "Podane hasla roznia sie od siebie.");

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	copy(playerData[id][PASSWORD], charsmax(playerData[][PASSWORD]), password);

	account_query(id, UPDATE);

	set_hudmessage(0, 255, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
	show_hudmessage(id, "Twoje haslo zostalo pomyslnie zmienione.");

	client_print_color(id, id, "^x04[CS:GO]^x01 Twoje haslo zostalo pomyslnie^x04 zmienione^x01.");
	client_print_color(id, id, "^x04[CS:GO]^x01 Wpisz w konsoli komende^x04 setinfo ^"_%s^" ^"%s^"^x01, aby twoje haslo bylo ladowane automatycznie.", setinfo, playerData[id][PASSWORD]);

	cmd_execute(id, "setinfo _%s %s", setinfo, playerData[id][PASSWORD]);
	cmd_execute(id, "writecfg %s", setinfo);

	return PLUGIN_HANDLED;
}

public delete_account(id)
{
	if (playerData[id][STATUS] != LOGGED || !get_bit(id, dataLoaded)) return PLUGIN_HANDLED;

	new password[32];

	read_args(password, charsmax(password));
	remove_quotes(password);

	if (!equal(playerData[id][PASSWORD], password)) {
		if (++playerData[id][FAILS] >= passwordMaxFails) server_cmd("kick #%d ^"Nieprawidlowe haslo!^"", get_user_userid(id));

		client_print_color(id, id, "^x04[CS:GO]^x01 Podane haslo jest^x04 nieprawidlowe^x01. (Bledne haslo^x04 %i/%i^x01)", playerData[id][FAILS], passwordMaxFails);

		set_hudmessage(255, 0, 0, 0.24, 0.07, 0, 0.0, 3.5, 0.0, 0.0);
		show_hudmessage(id, "Podane haslo jest nieprawidlowe.");

		account_menu(id);

		return PLUGIN_HANDLED;
	}

	new menuData[128];

	formatex(menuData, charsmax(menuData), "\wCzy na pewno chcesz \rusunac \wswoje konto?");

	new menu = menu_create(menuData, "delete_account_handle");

	menu_additem(menu, "\rTak");
	menu_additem(menu, "\wNie^n");
	menu_additem(menu, "\wWyjdz");

	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public delete_account_handle(id, menu, item)
{
	if (item == 0) {
		account_query(id, DELETE);

		console_print(id, "==================================");
		console_print(id, "==========SYSTEM REJESTRACJI==========");
		console_print(id, "              Skasowales konto o nicku: %s", playerData[id][NAME]);
		console_print(id, "==================================");

		server_cmd("kick #%d ^"Konto zostalo usuniete!^"", get_user_userid(id));
	}

	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], queryData[128], error[128], errorNum;

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

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `csgo_accounts` (`name` VARCHAR(64), `pass` VARCHAR(32), PRIMARY KEY(`name`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);

	sqlConnected = true;
}

public load_account(id)
{
	id -= TASK_LOAD;

	if (!sqlConnected) {
		set_task(1.0, "load_account", id + TASK_LOAD);

		return;
	}

	new queryData[128], tempId[1];

	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `csgo_accounts` WHERE name = ^"%s^"", playerData[id][SAFE_NAME]);
	SQL_ThreadQuery(sql, "load_account_handle", queryData, tempId, sizeof(tempId));
}

public load_account_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	new id = tempId[0];

	if (failState) {
		log_to_file("csgo-error.log", "[CS:GO Accounts] SQL Error: %s (%d)", error, errorNum);

		return;
	}

	if (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "pass"), playerData[id][PASSWORD], charsmax(playerData[][PASSWORD]));

		if (playerData[id][PASSWORD][0]) {
			new password[32], info[32];

			formatex(info, charsmax(info), "_%s", setinfo);

			cmd_execute(id, "exec %s.cfg", setinfo);

			get_user_info(id, info, password, charsmax(password));

			if (equal(playerData[id][PASSWORD], password)) {
				playerData[id][STATUS] = LOGGED;

				set_bit(id, autoLogin);
			} else {
				playerData[id][STATUS] = NOT_LOGGED;

				client_print_color(id, id, "^x04[CS:GO]^x01 Musisz sie^x03 zalogowac^x01, aby miec dostep do glownych funkcji!");

				account_menu(id);
			}

			cmd_execute(id, "exec config.cfg");
		}
	}

	set_bit(id, dataLoaded);
}

public account_query(id, type)
{
	if (!is_user_connected(id)) return;

	new queryData[128], password[32];

	mysql_escape_string(playerData[id][PASSWORD], password, charsmax(password));

	switch(type) {
		case INSERT: formatex(queryData, charsmax(queryData), "INSERT INTO `csgo_accounts` VALUES (^"%s^", '%s')", playerData[id][SAFE_NAME], password);
		case UPDATE: formatex(queryData, charsmax(queryData), "UPDATE `csgo_accounts` SET pass = '%s' WHERE name = ^"%s^"", password, playerData[id][SAFE_NAME]);
		case DELETE: formatex(queryData, charsmax(queryData), "DELETE FROM `csgo_accounts` WHERE name = ^"%s^"", playerData[id][SAFE_NAME]);
	}

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) log_to_file("csgo-error.log", "[CS:GO Accounts] Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("csgo-error.log", "[CS:GO Accounts] Query failed. [%d] %s", errorNum, error);
	}

	return PLUGIN_CONTINUE;
}

public _csgo_check_account(id)
{
	if (sql == Empty_Handle) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Wystapil^x03 blad^x01 podczas tworzenia polaczenia z baza danych!");

		return false;
	} else if (playerData[id][STATUS] < LOGGED) {
		client_print_color(id, id, "^x04[CS:GO]^x01 Musisz sie^x03 zalogowac^x01, aby miec dostep do glownych funkcji!");

		account_menu(id);

		return false;
	}

	return true;
}