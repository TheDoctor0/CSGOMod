#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <csgomod>

#define PLUGIN	"CS:GO No Distractions"
#define AUTHOR	"O'Zone"

#define Menu_BuyItem 10

new const shield[] = "shield", nightvision[] = "nightvision";

new textMsgId;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("menuselect 6", "menu_select_nightvision");
	register_clcmd("menuselect 8", "menu_select_shield");

	register_forward(FM_EmitSound, "sound_emit");
}

public sound_emit(ent, channel, const sound[])
    return equal(sound, "fans/fan3.wav") ? FMRES_SUPERCEDE : FMRES_IGNORED;

public menu_select_nightvision(id)
	menu_select(id, nightvision);

public menu_select_shield(id)
	menu_select(id, shield);

public menu_select(id, const type[])
{
	if (is_user_alive(id) && get_pdata_int(id, OFFSET_MENU) == Menu_BuyItem && cs_get_user_team(id) == CS_TEAM_CT) {
		new oldMenu, newMenu;

		player_menu_info(id, oldMenu, newMenu);

		if (newMenu != -1 || oldMenu > 0) {
			set_pdata_int(id, OFFSET_MENU, 0);
		} else {
			message_not_available(id, type);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public client_command(id)
{
	static command[11];

	read_argv(0, command, charsmax(command));

	if (equali(command, shield)) {
		message_not_available(id, shield);

		return PLUGIN_HANDLED;
	}

	if (equali(command, nightvision)) {
		message_not_available(id, nightvision);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public CS_InternalCommand(id, const command[])
{
	if (equali(command, shield)) {
		message_not_available(id, shield);

		return PLUGIN_HANDLED;
	}

	if (equali(command, nightvision)) {
		message_not_available(id, nightvision);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

stock message_not_available(id, const type[])
{
	if (!is_user_connected(id)) {
		return;
	}

	if (!textMsgId) {
		textMsgId = get_user_msgid("TextMsg");
	}

	message_begin(MSG_ONE_UNRELIABLE, textMsgId, .player=id);
	write_byte(print_center);
	write_string("#Weapon_Not_Available");

	if (equali(type, shield)) {
		write_string("#TactShield");
	} else {
		write_string("#NightVision");
	}

	message_end();
}