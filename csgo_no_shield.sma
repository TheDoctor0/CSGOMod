#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define PLUGIN	"CS:GO No Shield"
#define VERSION	"2.0"
#define AUTHOR	"ConnorMcLeod & O'Zone"

#define cs_get_user_menu(%0)    get_pdata_int(%0, m_iMenuCode)
#define cs_set_user_menu(%0,%1) set_pdata_int(%0, m_iMenuCode, %1)

#define Menu_BuyItem 10

const m_iMenuCode = 205;

new const shield[] = "shield";

new textMsg;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("menuselect 8", "menu_select");

	register_forward(FM_PrecacheModel, "unprecache_models");
}

public unprecache_models(const model[])
{
	if (containi(model, shield) != -1) {
		forward_return(FMV_CELL, 0);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public menu_select(id)
{
	if (is_user_alive(id) && cs_get_user_menu(id) == Menu_BuyItem && cs_get_user_team(id) == CS_TEAM_CT) {
		new oldMenu, newMenu;

		player_menu_info(id, oldMenu, newMenu);

		if (newMenu != -1 || oldMenu > 0) {
			cs_set_user_menu(id, 0);
		} else {
			message_no_shield(id);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public client_command(id)
{
	static command[8];

	if (read_argv(0, command, charsmax(command)) == 6 && equali(command, shield)) {
		message_no_shield(id);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public CS_InternalCommand(id, const command[])
{
	if (equali(command, shield)) {
		message_no_shield(id);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

stock message_no_shield(id)
{
	if (!is_user_connected(id)) {
		return;
	}

	if (!textMsg) {
		textMsg = get_user_msgid("TextMsg");
	}

	message_begin(MSG_ONE_UNRELIABLE, textMsg, .player=id);
	write_byte(print_center);
	write_string("#Weapon_Not_Available");
	write_string("#TactShield");
	message_end();
}