#include <amxmodx>

#define PLUGIN "CS:GO Server Menu"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

new Array:aTitles, Array:aCommands;

new const szMenuCommands[][] = { "say /menu", "say_team /menu", "menu", "say /komendy", "say_team /komendy" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof szMenuCommands; i++) register_clcmd(szMenuCommands[i], "Menu");
}

public plugin_cfg()
{
	aTitles = ArrayCreate(64, 1);
	aCommands = ArrayCreate(64, 1);

	new szFile[128];

	get_localinfo("amxx_configsdir", szFile, charsmax(szFile));
	format(szFile, charsmax(szFile), "%s/csgo_menu.ini", szFile);

	if (!file_exists(szFile)) set_fail_state("[Menu] Brak pliku z zawartoscia menu serwera!");

	new szContent[128], szTitle[64], szCommand[64], iOpen = fopen(szFile, "r");

	while (!feof(iOpen)) {
		fgets(iOpen, szContent, charsmax(szContent)); trim(szContent);

		if(szContent[0] == ';' || szContent[0] == '^0') continue;

		parse(szContent, szTitle, charsmax(szTitle), szCommand, charsmax(szCommand));

		ArrayPushString(aTitles, szTitle);
		ArrayPushString(aCommands, szCommand);
	}

	fclose(iOpen);
}

public client_putinserver(id)
{
	client_cmd(id, "bind ^"v^" ^"menu^"");

	cmd_execute(id, "bind v menu");
}

public Menu(id)
{
	new menu = menu_create("\yMenu \rSerwera\w:", "Menu_Handler"), szTitle[64];

	for (new i; i < ArraySize(aTitles); i++) {
		ArrayGetString(aTitles, i, szTitle, charsmax(szTitle));
		menu_additem(menu, szTitle);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public Menu_Handler(id, menu, item)
{
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new szCommand[64];

	ArrayGetString(aCommands, item, szCommand, charsmax(szCommand));

	client_cmd(id, szCommand);
	engclient_cmd(id, szCommand);
	cmd_execute(id, szCommand);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

stock cmd_execute(id, const szText[], any:...)
{
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(szText) + 2);
	write_byte(10);
	write_string(szText);
	message_end();

	#pragma unused szText

	new szMessage[256];

	format_args(szMessage, charsmax(szMessage), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(szMessage) + 2);
	write_byte(10);
	write_string(szMessage);
	message_end();
}
