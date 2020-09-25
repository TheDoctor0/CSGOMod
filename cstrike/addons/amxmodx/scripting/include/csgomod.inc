#if defined _csgomod_included
  #endinput
#endif
#define _csgomod_included

#if !defined client_print_color || !defined MAX_NAME_LENGTH
    #error THIS VERSION IS NOT SUPPORTED! PLEASE USE AMXX 1.8.3+!
#endif

#define VERSION	"2.1.5"
#define CHAT_PREFIX "^4[CS:GO]^1"
#define CONSOLE_PREFIX "[CS:GO]"

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

#define OFFSET_ITEM_LINUX  4
#define OFFSET_PLAYER_LINUX  5
#define OFFSET_LAST_EVENT_CHECK 38
#define OFFSET_PLAYER 41
#define OFFSET_NEXT 42
#define OFFSET_ID 43
#define OFFSET_EMPTY_SOUND 44
#define OFFSET_PRIMARY_ATTACK 46
#define OFFSET_SECONDARY_ATTACK 47
#define OFFSET_WEAPON_IDLE 48
#define OFFSET_CLIP 51
#define OFFSET_CLIENT_CLIP 52
#define OFFSET_SHELL 57
#define OFFSET_SHOTS_FIRED 64
#define OFFSET_SILENCER 74
#define OFFSET_EJECT 111
#define OFFSET_MENU 205
#define OFFSET_BUTTON_PRESSED 246
#define OFFSET_ITEM_SLOT 367
#define OFFSET_ACTIVE_ITEM 373
#define OFFSET_AMMO 376
#define OFFSET_C4 385

#define SAVE_NAME 0
#define SAVE_STEAM_ID 1

#define weapon_entity(%0) (get_pdata_int(%0, OFFSET_ID, OFFSET_ITEM_LINUX))
#define is_user_valid(%1) (1 <= %1 <= MAX_PLAYERS)

/**
 * Checks if player is logged in his account.
 *
 * @note Account menu will be diplayed for player if not logged in.
 *
 * @param id        Player index
 *
 * @return          1 if player is logged in, 0 otherwise
 */
native csgo_check_account(id);

/**
 * Returns account balance (euro) for player.
 *
 * @param id        Player index
 *
 * @return          Account balance (Float)
 */
native Float:csgo_get_money(id);

/**
 * Adds value to player's account balance.
 *
 * @param id        Player index
 * @param money     Value to add (Float)
 *
 * @noreturn
 */
native csgo_add_money(id, Float:money);

/**
 * Sets player's account balance to given value.
 *
 * @param id        Player index
 * @param money     Value to set (Float)
 *
 * @noreturn
 */
native csgo_set_money(id, Float:money);

/**
 * Returns id of current player operation.
 *
 * @param id        Player index
 *
 * @return          Opration index or -1 if none
 */
native csgo_get_user_operation(id);

/**
 * Retrieves status text of current player operation.
 *
 * @note Format: "x/x (x.x%)" or command info if none.
 *
 * @param id        Player index
 * @param data      Buffer to copy text to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native csgo_get_user_operation_text(id, data[], legth);

/**
 * Returns progress of current player operation.
 *
 * @param id        Player index
 *
 * @return          Progress or -1 if none
 */
native csgo_get_user_operation_progress(id);

/**
 * Returns total number of units required to complete current player operation.
 *
 * @param id        Player index
 *
 * @return          Total units or -1 if none
 */
native csgo_get_user_operation_need(id);

/**
 * Returns player buymenu type.
 *
 * @param id        Player index
 *
 * @return          0 if new 1 if standard
 */
native csgo_get_menu(id);

/**
 * Returns player skin id for current weapon.
 *
 * @param id        Player index
 *
 * @return          Skin index -1 if none
 */
native csgo_get_skin(id);

/**
 * Returns player skin id for given weapon.
 *
 * @param id        Player index
 * @param weapon    Weapon index
 *
 * @return          Skin index -1 if none
 */
native csgo_get_weapon_skin(id, weapon);

/**
 * Retrieves name of skin with given id.
 *
 * @param id        Player index (for multilang purpose)
 * @param skin      Skin index
 * @param data      Buffer to copy text to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native csgo_get_skin_name(id, skin, data[], length);

/**
 * Retrieves name of skin for current player weapon.
 *
 * @param id        Player index
 * @param data      Buffer to copy text to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native csgo_get_current_skin_name(id, data[], length);

/**
 * Retrieves player clan id.
 *
 * @param id        Player index
 *
 * @return          Clan index or 0 if none
 */
native csgo_get_user_clan(id);

/**
 * Retrieves clan name for given player.
 *
 * @param clan      Player index
 * @param data      Buffer to copy name to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native csgo_get_user_clan_name(id, data[], length);

/**
 * Retrieves clan name for given clan id.
 *
 * @param clan      Clan index
 * @param data      Buffer to copy name to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native csgo_get_clan_name(clan, data[], length);

/**
 * Retrieves members count for clan with given id.
 *
 * @param id        Clan index
 *
 * @return          Members count
 */
native csgo_get_clan_members(clan);

/**
 * Retrieves player rank id.
 *
 * @param id        Player index
 *
 * @return          Rank index
 */
native csgo_get_rank(id);

/**
 * Retrieves rank name for given rank id.
 *
 * @param rank      Rank index
 * @param data      Buffer to copy name to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native csgo_get_rank_name(rank, data[], length);

/**
 * Retrieves current player rank name.
 *
 * @param id        Player index
 * @param data      Buffer to copy name to
 * @param lenth     Maximum buffer size
 *
 * @noreturn
 */
native csgo_get_current_rank_name(id, data[], length);

/**
 * Retrieves StatTrak for given player weapon.
 *
 * @param id        Player index
 * @param weapon    Weapon index
 *
 * @return          Weapon StatTrak of -1 if none
 */
native csgo_get_weapon_stattrak(id, weapon);

/**
 * Checks if player has VIP account.
 *
 * @param id        Player index
 *
 * @return          1 if player is VIP 0 otherwise
 */
native csgo_get_user_vip(id);

/**
 * Checks if player has SVIP account.
 *
 * @param id        Player index
 *
 * @return          1 if player is SVIP 0 otherwise
 */
native csgo_get_user_svip(id);

/**
 * Checks if player has zeus.
 *
 * @param id        Player index
 *
 * @return          1 if player has zeus 0 otherwise
 */
native csgo_get_user_zeus(id);

/**
 * Checks if player has molotov.
 *
 * @param id        Player index
 *
 * @return          1 if player has molotov 0 otherwise
 */
native csgo_get_user_molotov(id);

/**
 * Multiforward called when player has logged in.
 *
 * @param id        Player index
 *
 * @noreturn
 */
forward csgo_user_login(id);

/**
 * Multiforward called when a player is registering.
 *
 * @param id        Player index
 *
 * @noreturn
 */
forward csgo_user_register(id);

/**
 * Multiforward called when a player is assisting other player.
 *
 * @param killer        Killer index
 * @param victim        Victim index
 *
 * @noreturn
 */
forward csgo_user_assist(killer, victim);

/**
 * Multiforward called on data reset.
 *
 * @noreturn
 */
forward csgo_reset_data();

stock mysql_escape_string(const source[], dest[], length)
{
	copy(dest, length, source);

	replace_all(dest, length, "\\", "\\\\");
	replace_all(dest, length, "\0", "\\0");
	replace_all(dest, length, "\n", "\\n");
	replace_all(dest, length, "\r", "\\r");
	replace_all(dest, length, "\x1a", "\Z");
	replace_all(dest, length, "'", "\'");
	replace_all(dest, length, "`", "\`");
	replace_all(dest, length, "^"", "\^"");
}

stock cmd_execute(id, const text[], any:...)
{
	if (!is_user_connected(id)) return;

	#pragma unused text

	new message[256];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}
