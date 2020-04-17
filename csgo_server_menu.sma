#include <amxmodx>
#include <csgomod>

#define PLUGIN "CS:GO Server Menu"
#define VERSION "2.0"
#define AUTHOR "O'Zone"

new Array:titles, Array:commands;

new const menuCommands[][] = { "say /menu", "say_team /menu", "menu", "say /komendy", "say_team /komendy" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof menuCommands; i++) register_clcmd(menuCommands[i], "server_menu");
}

public plugin_cfg()
{
	titles = ArrayCreate(64, 1);
	commands = ArrayCreate(64, 1);

	new filePath[128];

	get_localinfo("amxx_configsdir", filePath, charsmax(filePath));
	format(filePath, charsmax(filePath), "%s/csgo_menu.ini", filePath);

	if (!file_exists(filePath)) set_fail_state("[CS:GO Menu] Brak pliku z zawartoscia menu serwera!");

	new content[128], title[64], command[64], file = fopen(filePath, "r");

	while (!feof(file)) {
		fgets(file, content, charsmax(content)); trim(content);

		if(content[0] == ';' || content[0] == '^0') continue;

		parse(content, title, charsmax(title), command, charsmax(command));

		ArrayPushString(titles, title);
		ArrayPushString(commands, command);
	}

	fclose(file);
}

public client_putinserver(id)
{
	client_cmd(id, "bind ^"v^" ^"menu^"");
	cmd_execute(id, "bind v menu");
}

public server_menu(id)
{
	new title[64], menu = menu_create("\yMenu \rSerwera\w:", "server_menu_handler");

	for (new i; i < ArraySize(titles); i++) {
		ArrayGetString(titles, i, title, charsmax(title));

		menu_additem(menu, title);
	}

	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public server_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new command[64];

	ArrayGetString(commands, item, command, charsmax(command));

	client_cmd(id, command);
	engclient_cmd(id, command);
	cmd_execute(id, command);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}
