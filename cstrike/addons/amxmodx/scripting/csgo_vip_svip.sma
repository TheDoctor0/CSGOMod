#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <csgomod>

#define PLUGIN	"CS:GO VIP and SVIP"
#define AUTHOR	"O'Zone"

#define ADMIN_FLAG_X (1<<23)

new Array:VIPs, Array:SVIPs, bool:used[MAX_PLAYERS + 1], bool:disabled, roundNum = 0,
	VIP, SVIP, smallMaps, prefixEnabled, freeType, freeEnabled, freeFrom, freeTo;

new const commandVIPs[][] = { "vips", "say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };
new const commandSVIPs[][] = { "svips", "say /svips", "say_team /svips", "say /svipy", "say_team /svipy" };
new const commandVIPMotd[][] = { "vip", "say /vip", "say_team /vip" };
new const commandSVIPMotd[][] = { "svip", "say /svip", "say_team /svip", "say /supervip", "say_team /supervip" };

new const zeusWeaponName[] = "weapon_p228";

new disallowedWeapons[] = { CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL, CSW_AK47, CSW_M4A1, CSW_AWP,
	CSW_SG550, CSW_G3SG1, CSW_UMP45, CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

enum { ammo_none, ammo_338magnum = 1, ammo_762nato, ammo_556natobox, ammo_556nato, ammo_buckshot, ammo_45acp,
	ammo_57mm, ammo_50ae, ammo_357sig, ammo_9mm, ammo_flashbang, ammo_hegrenade, ammo_smokegrenade, ammo_c4 };

new const maxBPAmmo[] = { 0, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1 };
new const weaponSlots[] = { -1, 2, -1, 1, 4, 1, 5, 1, 1, 4, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 4, 2, 1, 1, 3, 1 };

enum _:{ PRIMARY = 1, SECONDARY, KNIFE, GRENADES, C4 };
enum _:{ FREE_NONE, FREE_HOURS, FREE_ALWAYS };
enum _:{ FREE_VIP, FREE_SVIP };

forward amxbans_admin_connect(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(register_cvar("csgo_vip_svip_small_maps", "0"), smallMaps);
	bind_pcvar_num(register_cvar("csgo_vip_svip_prefix_enabled", "1"), prefixEnabled);
	bind_pcvar_num(register_cvar("csgo_vip_svip_free_enabled", "0"), freeEnabled);
	bind_pcvar_num(register_cvar("csgo_vip_svip_free_type", "0"), freeType);
	bind_pcvar_num(register_cvar("csgo_vip_svip_free_from", "23"), freeFrom);
	bind_pcvar_num(register_cvar("csgo_vip_svip_free_to", "9"), freeTo);

	for (new i; i < sizeof commandVIPs; i++) register_clcmd(commandVIPs[i], "show_vips");
	for (new i; i < sizeof commandSVIPs; i++) register_clcmd(commandSVIPs[i], "show_svips");
	for (new i; i < sizeof commandVIPMotd; i++) register_clcmd(commandVIPMotd[i], "show_vipmotd");
	for (new i; i < sizeof commandSVIPMotd; i++) register_clcmd(commandSVIPMotd[i], "show_svipmotd");

	register_clcmd("say_team", "handle_say");

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);

	register_event("TextMsg", "restart_round", "a", "2&#Game_C", "2&#Game_w");

	register_event("HLTV", "new_round", "a", "1=0", "2=0");
	register_event("DeathMsg", "player_death", "a");

	register_message(get_user_msgid("SayText"), "say_text");
	register_message(get_user_msgid("ScoreAttrib"), "handle_status");
	register_message(get_user_msgid("AmmoX"), "handle_ammo");

	VIPs = ArrayCreate(32, 32);
	SVIPs = ArrayCreate(32, 32);
}

public plugin_natives()
{
	register_native("csgo_set_user_vip", "_csgo_set_user_vip", 1);
	register_native("csgo_get_user_vip", "_csgo_get_user_vip", 1);
	register_native("csgo_set_user_svip", "_csgo_set_user_svip", 1);
	register_native("csgo_get_user_svip", "_csgo_get_user_svip", 1);
}

public plugin_cfg()
	if (!smallMaps) check_map();

public plugin_end()
{
	ArrayDestroy(VIPs);
	ArrayDestroy(SVIPs);
}

public amxbans_admin_connect(id)
	client_authorized_post(id);

public client_authorized(id)
	client_authorized_post(id);

public client_authorized_post(id)
{
	rem_bit(id, VIP);
	rem_bit(id, SVIP);

	new currentTime[3], hour, bool:freeVip = freeEnabled == FREE_ALWAYS;

	if (!freeVip && freeEnabled == FREE_HOURS) {
		get_time("%H", currentTime, charsmax(currentTime));

		hour = str_to_num(currentTime);

		if (freeFrom >= freeTo && (hour >= freeFrom || hour < freeTo)) {
			freeVip = true;
		} else if (freeFrom < freeTo && (hour >= freeFrom && hour < freeTo)) {
			freeVip = true;
		}
	}

	if (get_user_flags(id) & ADMIN_LEVEL_H || get_user_flags(id) & ADMIN_FLAG_X || freeVip) {
		set_bit(id, VIP);

		new playerName[32], tempName[32], size = ArraySize(VIPs), bool:found;

		get_user_name(id, playerName, charsmax(playerName));

		for (new i = 0; i < size; i++) {
			ArrayGetString(VIPs, i, tempName, charsmax(tempName));

			if (equal(playerName, tempName)) found = true;
		}

		if (!found) ArrayPushString(VIPs, playerName);

		if (get_user_flags(id) & ADMIN_FLAG_X || freeType == FREE_SVIP) {
			set_bit(id, SVIP);

			new playerName[32], tempName[32], size = ArraySize(SVIPs);

			get_user_name(id, playerName, charsmax(playerName));

			for (new i = 0; i < size; i++) {
				ArrayGetString(SVIPs, i, tempName, charsmax(tempName));

				if (equal(playerName, tempName)) return PLUGIN_CONTINUE;
			}

			ArrayPushString(SVIPs, playerName);
		}
	}

	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if (get_bit(id, VIP)) {
		rem_bit(id, VIP);

		new playerName[32], tempName[32], size = ArraySize(VIPs);

		get_user_name(id, playerName, charsmax(playerName));

		for (new i = 0; i < size; i++) {
			ArrayGetString(VIPs, i, tempName, charsmax(tempName));

			if (equal(playerName, tempName)) {
				ArrayDeleteItem(VIPs, i);

				break;
			}
		}
	}

	if (get_bit(id, SVIP)) {
		rem_bit(id, SVIP);

		new playerName[32], tempName[32], size = ArraySize(SVIPs);

		get_user_name(id, playerName, charsmax(playerName));

		for (new i = 0; i < size; i++) {
			ArrayGetString(SVIPs, i, tempName, charsmax(tempName));

			if (equal(playerName, tempName)) {
				ArrayDeleteItem(SVIPs, i);

				break;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if (get_bit(id, VIP)) {
		new playerName[32], newName[32], tempName[32], size = ArraySize(VIPs);

		get_user_info(id, "name", newName,charsmax(newName));
		get_user_name(id, playerName, charsmax(playerName));

		if (playerName[0] && !equal(playerName, newName)) {
			ArrayPushString(VIPs, newName);

			for (new i = 0; i < size; i++) {
				ArrayGetString(VIPs, i, tempName, charsmax(tempName));

				if (equal(playerName, tempName)) {
					ArrayDeleteItem(VIPs, i);

					break;
				}
			}
		}
	}

	if (get_bit(id, SVIP)) {
		new playerName[32], newName[32], tempName[32], size = ArraySize(SVIPs);

		get_user_info(id, "name", newName,charsmax(newName));
		get_user_name(id, playerName, charsmax(playerName));

		if (playerName[0] && !equal(playerName, newName)) {
			ArrayPushString(SVIPs, newName);

			for (new i = 0; i < size; i++) {
				ArrayGetString(SVIPs, i, tempName, charsmax(tempName));

				if (equal(playerName, tempName)) {
					ArrayDeleteItem(SVIPs, i);

					break;
				}
			}
		}
	}
}

public show_vipmotd(id)
{
	new motdTitle[32], motdFile[32];

	formatex(motdTitle, charsmax(motdTitle), "%L", id, "CSGO_VIP_VIP_MOTD_TITLE");
	formatex(motdFile, charsmax(motdFile), "%L", id, "CSGO_VIP_VIP_MOTD_FILE");

	show_motd(id, motdFile, motdTitle);
}

public show_svipmotd(id)
{
	new motdTitle[32], motdFile[32];

	formatex(motdTitle, charsmax(motdTitle), "%L", id, "CSGO_VIP_SVIP_MOTD_TITLE");
	formatex(motdFile, charsmax(motdFile), "%L", id, "CSGO_VIP_SVIP_MOTD_FILE");

	show_motd(id, motdFile, motdTitle);
}

public new_round()
	++roundNum;

public restart_round()
	roundNum = 0;

public csgo_user_login(id)
	player_spawn(id);

public player_spawn(id)
{
	if (disabled || !csgo_check_account(id)) return PLUGIN_CONTINUE;

	remove_task(id);
	client_authorized_post(id);

	if (!is_user_alive(id) || !pev_valid(id) || !get_bit(id, VIP)) return PLUGIN_CONTINUE;

	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);

	if (roundNum >= 2) {
		strip_weapons(id, SECONDARY);

		if (csgo_get_user_zeus(id)) {
			give_item(id, zeusWeaponName);
		}

		give_item(id, "weapon_deagle");
		give_item(id, "ammo_50ae");
		give_item(id, "weapon_hegrenade");

		if (get_bit(id, SVIP)) {
			give_item(id, "weapon_flashbang");
			give_item(id, "weapon_flashbang");
			give_item(id, "weapon_smokegrenade");
		}

		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
	} else {
		vip_menu_pistol(id);
	}

	if (roundNum >= 3) vip_menu(id);

	return PLUGIN_CONTINUE;
}

public vip_menu(id)
{
	used[id] = false;

	set_task(15.0, "close_vip_menu", id);

	new menu, title[64];

	formatex(title, charsmax(title), "%L", id, get_bit(id, SVIP) ? "CSGO_VIP_MENU_WEAPONS_SVIP" : "CSGO_VIP_MENU_WEAPONS_VIP");
	menu = menu_create(title, "vip_menu_handle");

	formatex(title, charsmax(title), "%L", id, "CSGO_VIP_MENU_M4A1");
	menu_additem(menu, title);

	formatex(title, charsmax(title), "%L", id, "CSGO_VIP_MENU_AK47");
	menu_additem(menu, title);

	if (get_bit(id, SVIP)) {
		formatex(title, charsmax(title), "%L", id, "CSGO_VIP_MENU_AWP");
		menu_additem(menu, title);
	}

	formatex(title, charsmax(title), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, title);

	menu_display(id, menu);
}

public vip_menu_handle(id, menu, item)
{
	if (!pev_valid(id) || !is_user_alive(id) || used[id] || item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	used[id] = true;

	switch (item) {
		case 0: {
			strip_weapons(id, SECONDARY);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			if (csgo_get_user_zeus(id)) {
				give_item(id, zeusWeaponName);
			}

			strip_weapons(id, PRIMARY);

			give_item(id, "weapon_m4a1");
			give_item(id, "ammo_556nato");

			client_print(id, print_center, "%L", id, "CSGO_VIP_M4A1");
		} case 1: {
			strip_weapons(id, SECONDARY);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			if (csgo_get_user_zeus(id)) {
				give_item(id, zeusWeaponName);
			}

			strip_weapons(id, PRIMARY);

			give_item(id, "weapon_ak47");
			give_item(id, "ammo_762nato");

			client_print(id, print_center, "%L", id, "CSGO_VIP_AK47");
		} case 2: {
			strip_weapons(id, SECONDARY);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			if (csgo_get_user_zeus(id)) {
				give_item(id, zeusWeaponName);
			}

			strip_weapons(id, PRIMARY);

			give_item(id, "weapon_awp");
			give_item(id, "ammo_338magnum");

			client_print(id, print_center, "%L", id, "CSGO_VIP_AWP");
		}
	}

	remove_task(id);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public close_vip_menu(id)
{
	if (used[id] || !is_user_alive(id) || !pev_valid(id)) return PLUGIN_CONTINUE;

	if (!check_weapons(id)) {
		if (get_bit(id, SVIP)) {
			client_print_color(id, id, "^4[SVIP]^1 %L", id, "CSGO_VIP_RANDOM_WEAPONS_SVIP");
		} else {
			client_print_color(id, id, "^4[VIP]^1 %L", id, "CSGO_VIP_RANDOM_WEAPONS_VIP");
		}

		used[id] = true;

		new random = random_num(0, get_bit(id, SVIP) ? 2 : 1);

		switch (random) {
			case 0: {
				strip_weapons(id, SECONDARY);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				if (csgo_get_user_zeus(id)) {
					give_item(id, zeusWeaponName);
				}

				strip_weapons(id, PRIMARY);

				give_item(id, "weapon_m4a1");
				give_item(id, "ammo_556nato");

				client_print(id, print_center, "%L", id, "CSGO_VIP_M4A1");
			} case 1: {
				strip_weapons(id, SECONDARY);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				if (csgo_get_user_zeus(id)) {
					give_item(id, zeusWeaponName);
				}

				strip_weapons(id, PRIMARY);

				give_item(id, "weapon_ak47");
				give_item(id, "ammo_762nato");

				client_print(id, print_center, "%L", id, "CSGO_VIP_AK47");
			} case 2: {
				strip_weapons(id, SECONDARY);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				if (csgo_get_user_zeus(id)) {
					give_item(id, zeusWeaponName);
				}

				strip_weapons(id, PRIMARY);

				give_item(id, "weapon_awp");
				give_item(id, "ammo_338magnum");

				client_print(id, print_center, "%L", id, "CSGO_VIP_AWP");
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public vip_menu_pistol(id)
{
	used[id] = false;

	set_task(15.0, "close_vip_menu_pistol", id);

	new menu, title[64];

	formatex(title, charsmax(title), "%L", id, get_bit(id, SVIP) ? "CSGO_VIP_MENU_PISTOL_SVIP" : "CSGO_VIP_MENU_PISTOL_VIP");
	menu = menu_create(title, "vip_menu_pistol_handle");

	formatex(title, charsmax(title), "%L", id, "CSGO_VIP_MENU_DEAGLE");
	menu_additem(menu, title);

	formatex(title, charsmax(title), "%L", id, "CSGO_VIP_MENU_USP");
	menu_additem(menu, title);

	formatex(title, charsmax(title), "%L", id, "CSGO_VIP_MENU_GLOCK");
	menu_additem(menu, title);

	formatex(title, charsmax(title), "%L", id, "CSGO_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, title);

	menu_display(id, menu);
}

public vip_menu_pistol_handle(id, menu, item)
{
	if (!pev_valid(id) || !is_user_alive(id) || used[id] || item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	used[id] = true;

	switch (item) {
		case 0: {
			strip_weapons(id, SECONDARY);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			if (csgo_get_user_zeus(id)) {
				give_item(id, zeusWeaponName);
			}

			client_print(id, print_center, "%L", id, "CSGO_VIP_DEAGLE");
		} case 1: {
			strip_weapons(id, SECONDARY);

			give_item(id, "weapon_usp");
			give_item(id, "ammo_45acp");

			if (csgo_get_user_zeus(id)) {
				give_item(id, zeusWeaponName);
			}

			client_print(id, print_center, "%L", id, "CSGO_VIP_USP");
		} case 2: {
			strip_weapons(id, SECONDARY);

			give_item(id, "weapon_glock18");
			give_item(id, "ammo_9mm");

			if (csgo_get_user_zeus(id)) {
				give_item(id, zeusWeaponName);
			}

			client_print(id, print_center, "%L", id, "CSGO_VIP_GLOCK");
		}
	}

	remove_task(id);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public close_vip_menu_pistol(id)
{
	if (used[id] || !is_user_alive(id) || !pev_valid(id)) return PLUGIN_CONTINUE;

	if (!check_weapons(id)) {
		if (get_bit(id, SVIP)) {
			client_print_color(id, id, "^4[SVIP]^1 %L", id, "CSGO_VIP_RANDOM_PISTOL_SVIP");
		} else {
			client_print_color(id, id, "^4[VIP]^1 %L", id, "CSGO_VIP_RANDOM_PISTOL_VIP");
		}

		used[id] = true;

		new random = random_num(0, 2);

		switch (random) {
			case 0: {
				strip_weapons(id, SECONDARY);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				if (csgo_get_user_zeus(id)) {
					give_item(id, zeusWeaponName);
				}

				client_print(id, print_center, "%L", id, "CSGO_VIP_DEAGLE");
			} case 1: {
				strip_weapons(id, SECONDARY);

				give_item(id, "weapon_usp");
				give_item(id, "ammo_45acp");

				if (csgo_get_user_zeus(id)) {
					give_item(id, zeusWeaponName);
				}

				client_print(id, print_center, "%L", id, "CSGO_VIP_USP");
			} case 2: {
				strip_weapons(id, SECONDARY);

				give_item(id, "weapon_glock18");
				give_item(id, "ammo_9mm");

				if (csgo_get_user_zeus(id)) {
					give_item(id, zeusWeaponName);
				}

				client_print(id, print_center, "%L", id, "CSGO_VIP_GLOCK");
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public player_death()
{
	new killer = read_data(1), victim = read_data(2), headShot = read_data(3);

	if (get_bit(killer, VIP) && is_user_alive(killer) && get_user_team(killer) != get_user_team(victim) && !disabled) {
		if (headShot) {
			set_dhudmessage(38, 218, 116, 0.50, 0.35, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(killer, "%L", killer, "CSGO_VIP_KILL_HS");

			set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) + 15 : min(get_user_health(killer) + 15, 100));

			cs_set_user_money(killer, cs_get_user_money(killer) + 350);
		} else  {
			set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(killer, "%L", killer, "CSGO_VIP_KILL");

			set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) + 10 : min(get_user_health(killer) + 10, 100));

			cs_set_user_money(killer, cs_get_user_money(killer) + 200);
		}
	}
}

public show_vips(id)
{
	new playerName[32], tempMessage[190], message[190], size = ArraySize(VIPs);

	for (new i = 0; i < size; i++) {
		ArrayGetString(VIPs, i, playerName, charsmax(playerName));

		add(tempMessage, charsmax(tempMessage), playerName);

		if (i == size - 1) add(tempMessage, charsmax(tempMessage), ".");
		else add(tempMessage, charsmax(tempMessage), ", ");
	}

	formatex(message, charsmax(message), tempMessage);

	client_print_color(id, id, "^4%s", message);

	return PLUGIN_CONTINUE;
}

public show_svips(id)
{
	new playerName[32], tempMessage[190], message[190], size = ArraySize(SVIPs);

	for (new i = 0; i < size; i++) {
		ArrayGetString(SVIPs, i, playerName, charsmax(playerName));

		add(tempMessage, charsmax(tempMessage), playerName);

		if (i == size - 1) add(tempMessage, charsmax(tempMessage), ".");
		else add(tempMessage, charsmax(tempMessage), ", ");
	}

	formatex(message, charsmax(message), tempMessage);

	client_print_color(id, id, "^4%s", message);

	return PLUGIN_CONTINUE;
}

public handle_status()
{
	new id = get_msg_arg_int(1);

	if (is_user_alive(id) && (get_bit(id, VIP) || get_bit(id, SVIP))) {
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | 4);
	}
}

public handle_say(id)
{
	if (get_bit(id, VIP)) {
		new text[190], message[190];

		read_args(text, charsmax(text));
		remove_quotes(text);

		if (text[0] == '*' && text[1]) {
			new playerName[32];

			get_user_name(id, playerName, charsmax(playerName));

			formatex(message, charsmax(message), "^4(VIP CHAT) ^3%s: ^4%s", playerName, text[1]);

			for (new i = 1; i <= MAX_PLAYERS; i++) {
				if (is_user_connected(i) && get_bit(i, VIP)) client_print_color(i, i, "^4%s", message);
			}

			return PLUGIN_HANDLED_MAIN;
		}
	}

	return PLUGIN_CONTINUE;
}

public say_text(msgId,msgDest,msgEnt)
{
	new id = get_msg_arg_int(1);

	if (prefixEnabled && is_user_connected(id) && get_bit(id, VIP)) {
		new tempMessage[192], message[192], chatPrefix[16], playerName[32];

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

		formatex(chatPrefix, charsmax(chatPrefix), "%s", get_bit(id, SVIP) ? "^4[SVIP]" : "^4[VIP]");

		if (!equal(tempMessage, "#Cstrike_Chat_All")) {
			add(message, charsmax(message), chatPrefix);
			add(message, charsmax(message), " ");
			add(message, charsmax(message), tempMessage);
		} else {
	        get_user_name(id, playerName, charsmax(playerName));

	        get_msg_arg_string(4, tempMessage, charsmax(tempMessage));
	        set_msg_arg_string(4, "");

	        add(message, charsmax(message), chatPrefix);
	        add(message, charsmax(message), "^3 ");
	        add(message, charsmax(message), playerName);
	        add(message, charsmax(message), "^1 : ");
	        add(message, charsmax(message), tempMessage);
		}

		set_msg_arg_string(2, message);
	}

	return PLUGIN_CONTINUE;
}

public handle_ammo(iMsgId, iMsgDest, id)
{
	new ammoID = get_msg_arg_int(1);

	if (is_user_alive(id) && ammoID && ammoID <= ammo_9mm && get_bit(id, SVIP)) {
		new ammo = maxBPAmmo[ammoID];

		if (get_msg_arg_int(2) < ammo && pev_valid(id) == VALID_PDATA) {
			set_msg_arg_int(2, ARG_BYTE, ammo);
			set_pdata_int(id, OFFSET_AMMO + ammoID, ammo, OFFSET_PLAYER_LINUX);
		}
	}
}

stock strip_weapons(id, type, bool:switchIfActive = true)
{
	new result;

	if (is_user_alive(id)) {
		new entity, weapon;

		while ((weapon = get_weapon_from_slot(id, type, entity)) > 0) {
			result = ham_strip_user_weapon(id, weapon, type, switchIfActive);
		}
	}

	return result;
}

stock get_weapon_from_slot(id, slot, &entity)
{
	if (!( 1 <= slot <= 5 ) || pev_valid(id) != VALID_PDATA) return 0;

	entity = get_pdata_cbase(id, OFFSET_ITEM_SLOT + slot, OFFSET_PLAYER_LINUX);

	return (entity > 0) ? get_pdata_int(entity, OFFSET_ID, OFFSET_ITEM_LINUX) : 0;
}

stock ham_strip_user_weapon(id, weaponId, slot = 0, bool:switchIfActive = true)
{
	new weapon;

	if (!slot) {
		slot = weaponSlots[weaponId];
	}

	if (pev_valid(id) != VALID_PDATA) return 0;

	weapon = get_pdata_cbase(id, OFFSET_ITEM_SLOT + slot, OFFSET_PLAYER_LINUX);

	while (weapon > 0) {
		if (get_pdata_int(weapon, OFFSET_ID, OFFSET_ITEM_LINUX) == weaponId) {
			break;
		}

		weapon = get_pdata_cbase(weapon, OFFSET_NEXT, OFFSET_ITEM_LINUX);
	}

	if (weapon > 0) {
		if (switchIfActive && get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_PLAYER_LINUX) == weapon) {
			ExecuteHamB(Ham_Weapon_RetireWeapon, weapon);
		}

		if (ExecuteHamB(Ham_RemovePlayerItem, id, weapon)) {
			user_has_weapon(id, weaponId, 0);
			ExecuteHamB(Ham_Item_Kill, weapon);

			return 1;
		}
	}

	return 0;
}

stock bool:check_weapons(id)
{
	new weapons[32], weapon, weaponsNum;

	weapon = get_user_weapons(id, weapons, weaponsNum);

	for (new i = 0; i < sizeof(disallowedWeapons); i++) {
		if (weapon & (1<<disallowedWeapons[i])) return true;
	}

	return false;
}

stock check_map()
{
	new mapPrefixes[][] = {
		"aim_",
		"awp_",
		"awp4one",
		"fy_" ,
		"cs_deagle5" ,
		"fun_allinone",
		"1hp_he",
		"css_india"
	};

	new mapName[32];

	get_mapname(mapName, charsmax(mapName));

	for (new i = 0; i < sizeof(mapPrefixes); i++) {
		if (containi(mapName, mapPrefixes[i]) != -1) disabled = true;
	}
}



public _csgo_get_user_vip(id)
	return get_bit(id, VIP);

public _csgo_get_user_svip(id)
	return get_bit(id, SVIP);

public _csgo_set_user_vip(id)
{
	if (get_user_flags(id) & ADMIN_LEVEL_H && !get_bit(id, VIP)) client_authorized_post(id);

	return PLUGIN_CONTINUE;
}

public _csgo_set_user_svip(id)
{
	if (get_user_flags(id) & ADMIN_FLAG_X && !get_bit(id, SVIP)) client_authorized_post(id);

	return PLUGIN_CONTINUE;
}
