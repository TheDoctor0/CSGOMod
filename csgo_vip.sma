#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <stripweapons>
#include <csgomod>

#define PLUGIN "CS:GO VIP & SVIP"
#define VERSION "1.4"
#define AUTHOR "O'Zone"

#define ADMIN_FLAG_X (1<<23)

new Array:VIPs, Array:SVIPs, bool:used[MAX_PLAYERS + 1], bool:disabled, roundNum = 0, VIP, SVIP, smallMaps;

new const commandVIPs[][] = { "vips", "say /vips", "say_team /vips", "say /vipy", "say_team /vipy" };
new const commandSVIPs[][] = { "svips", "say /svips", "say_team /svips", "say /svipy", "say_team /svipy" };
new const commandVIPMotd[][] = { "vip", "say /vip", "say_team /vip" };
new const commandSVIPMotd[][] = { "svip", "say /svip", "say_team /svip", "say /supervip", "say_team /supervip" };

new disallowedWeapons[] = { CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_M249, CSW_GALIL, CSW_AK47, CSW_M4A1, CSW_AWP,
	CSW_SG550, CSW_G3SG1, CSW_UMP45, CSW_MP5NAVY, CSW_FAMAS, CSW_SG552, CSW_TMP, CSW_P90, CSW_M3 };

enum { ammo_none, ammo_338magnum = 1, ammo_762nato, ammo_556natobox, ammo_556nato, ammo_buckshot, ammo_45acp,
	ammo_57mm, ammo_50ae, ammo_357sig, ammo_9mm, ammo_flashbang, ammo_hegrenade, ammo_smokegrenade, ammo_c4 };

new const maxBPAmmo[] = { 0, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1 };

forward amxbans_admin_connect(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(register_cvar("csgo_vip_small_maps", "0"), smallMaps);

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

	if (get_user_flags(id) & ADMIN_LEVEL_H || get_user_flags(id) & ADMIN_FLAG_X) {
		set_bit(id, VIP);

		new playerName[32], tempName[32], size = ArraySize(VIPs), bool:found;

		get_user_name(id, playerName, charsmax(playerName));

		for (new i = 0; i < size; i++) {
			ArrayGetString(VIPs, i, tempName, charsmax(tempName));

			if (equal(playerName, tempName)) found = true;
		}

		if (!found) ArrayPushString(VIPs, playerName);

		if (get_user_flags(id) & ADMIN_FLAG_X) {
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
	show_motd(id, "vip.txt", "Informacje o VIPie");

public show_svipmotd(id)
	show_motd(id, "svip.txt", "Informacje o SuperVIPie");

public new_round()
	++roundNum;

public restart_round()
	roundNum = 0;

public csgo_user_login(id)
	player_spawn(id);

public player_spawn(id)
{
	remove_task(id);

	if (!is_user_alive(id) || !get_bit(id, VIP) || disabled || !csgo_check_account(id)) return PLUGIN_CONTINUE;

	if (get_user_team(id) == 2) cs_set_user_defuse(id, 1);

	if (roundNum >= 2) {
		StripWeapons(id, Secondary);

		give_item(id, "weapon_deagle");
		give_item(id, "ammo_50ae");

		new weaponID = find_ent_by_owner(-1, "weapon_deagle", id);

		if (weaponID) cs_set_weapon_ammo(weaponID, 7);

		cs_set_user_bpammo(id, CSW_DEAGLE, 35);

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

	new menu;

	if (get_bit(id, SVIP)) {
		menu = menu_create("\wMenu \ySuperVIP\w: Wybierz \rZestaw\w", "vip_menu_handle");

		menu_additem(menu, "\yM4A1 + Deagle");
		menu_additem(menu, "\yAK47 + Deagle");
		menu_additem(menu, "\yAWP + Deagle");
	} else {
		menu = menu_create("\wMenu \yVIP\w: Wybierz \rZestaw\w", "vip_menu_handle");

		menu_additem(menu, "\yM4A1 + Deagle");
		menu_additem(menu, "\yAK47 + Deagle");
	}

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);
}

public vip_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	used[id] = true;

	switch (item) {
		case 0: {
			StripWeapons(id, Secondary);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			cs_set_user_bpammo(id, CSW_DEAGLE, 35);

			StripWeapons(id, Primary);

			give_item(id, "weapon_m4a1");
			give_item(id, "ammo_556nato");

			cs_set_user_bpammo(id, CSW_M4A1, 90);

			client_print(id, print_center, "Dostales M4A1 + Deagle!");
		} case 1: {
			StripWeapons(id, Secondary);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			cs_set_user_bpammo(id, CSW_DEAGLE, 35);

			StripWeapons(id, Primary);

			give_item(id, "weapon_ak47");
			give_item(id, "ammo_762nato");

			cs_set_user_bpammo(id, CSW_AK47, 90);

			client_print(id, print_center, "Dostales AK47 + Deagle!");
		} case 2: {
			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			cs_set_user_bpammo(id, CSW_DEAGLE, 35);

			StripWeapons(id, Primary);

			give_item(id, "weapon_awp");
			give_item(id,"ammo_338magnum");

			cs_set_user_bpammo(id, CSW_AWP, 30);

			client_print(id, print_center, "Dostales AWP + Deagle!");
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public close_vip_menu(id)
{
	if (used[id] || !is_user_alive(id)) return PLUGIN_CONTINUE;

	if (!check_weapons(id)) {
		client_print_color(id, id, "^x04[%sVIP]^x01 Zestaw zostal ci przydzielony losowo.", get_bit(id, SVIP) ? "S" : "");

		new random = random_num(0, get_bit(id, SVIP) ? 2 : 1);

		switch (random) {
			case 0: {
				StripWeapons(id, Secondary);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				cs_set_user_bpammo(id, CSW_DEAGLE, 35);

				StripWeapons(id, Primary);

				give_item(id, "weapon_m4a1");
				give_item(id, "ammo_556nato");

				cs_set_user_bpammo(id, CSW_M4A1, 90);

				client_print(id, print_center, "Dostales M4A1 + Deagle!");
			} case 1: {
				StripWeapons(id, Secondary);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				cs_set_user_bpammo(id, CSW_DEAGLE, 35);

				StripWeapons(id, Primary);

				give_item(id, "weapon_ak47");
				give_item(id, "ammo_762nato");

				cs_set_user_bpammo(id, CSW_AK47, 90);

				client_print(id, print_center, "Dostales AK47 + Deagle!");
			} case 2: {
				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				cs_set_user_bpammo(id, CSW_DEAGLE, 35);

				StripWeapons(id, Primary);

				give_item(id, "weapon_awp");
				give_item(id, "ammo_338magnum");

				cs_set_user_bpammo(id, CSW_AWP, 30);

				client_print(id, print_center, "Dostales AWP + Deagle!");
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public vip_menu_pistol(id)
{
	used[id] = false;

	set_task(15.0, "close_vip_menu_pistol", id);

	new menu;

	if (get_bit(id, SVIP)) menu = menu_create("\wMenu \ySuperVIP\w: Wybierz \rPistolet\w", "vip_menu_pistol_handle");
	else menu = menu_create("\wMenu \yVIP\w: Wybierz \rPistolet\w", "vip_menu_pistol_handle");

	menu_additem(menu, "\yDeagle");
	menu_additem(menu, "\yUSP");
	menu_additem(menu, "\yGlock");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");

	menu_display(id, menu);
}

public vip_menu_pistol_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	used[id] = true;

	switch (item) {
		case 0: {
			StripWeapons(id, Secondary);

			give_item(id, "weapon_deagle");
			give_item(id, "ammo_50ae");

			cs_set_user_bpammo(id, CSW_DEAGLE, 35);

			client_print(id, print_center, "Dostales Deagle!");
		} case 1: {
			StripWeapons(id, Secondary);

			give_item(id, "weapon_usp");
			give_item(id, "ammo_45acp");

			cs_set_user_bpammo(id, CSW_USP, 100);

			client_print(id, print_center, "Dostales USP!");
		} case 2: {
			StripWeapons(id, Secondary);

			give_item(id, "weapon_glock18");
			give_item(id, "ammo_9mm");

			cs_set_user_bpammo(id, CSW_GLOCK18, 120);

			client_print(id, print_center, "Dostales Glocka!");
		}
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public close_vip_menu_pistol(id)
{
	if (used[id] || !is_user_alive(id)) return PLUGIN_CONTINUE;

	if (!check_weapons(id)) {
		client_print_color(id, id, "^x04[%sVIP]^x01 Pistolet zostal ci przydzielony losowo.", get_bit(id, SVIP) ? "S" : "");

		new random = random_num(0, 2);

		switch (random) {
			case 0: {
				StripWeapons(id, Secondary);

				give_item(id, "weapon_deagle");
				give_item(id, "ammo_50ae");

				cs_set_user_bpammo(id, CSW_DEAGLE, 35);

				client_print(id, print_center, "Dostales Deagle!");
			} case 1: {
				StripWeapons(id, Secondary);

				give_item(id, "weapon_usp");
				give_item(id, "ammo_45acp");

				cs_set_user_bpammo(id, CSW_USP, 100);

				client_print(id, print_center, "Dostales USP!");
			} case 2: {
				StripWeapons(id, Secondary);

				give_item(id, "weapon_glock18");
				give_item(id, "ammo_9mm");

				cs_set_user_bpammo(id, CSW_GLOCK18, 120);

				client_print(id, print_center, "Dostales Glocka!");
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
			show_dhudmessage(killer, "HeadShot! +15 HP");

			set_user_health(killer, get_user_health(killer) > 100 ? get_user_health(killer) + 15 : min(get_user_health(killer) + 15, 100));

			cs_set_user_money(killer, cs_get_user_money(killer) + 350);
		} else  {
			set_dhudmessage(255, 212, 0, 0.50, 0.31, 0, 0.0, 1.0, 0.0, 0.0);
			show_dhudmessage(killer, "Zabiles! +10 HP");

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

	client_print_color(id, id, "^x04%s", message);

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

	client_print_color(id, id, "^x04%s", message);

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

			formatex(message, charsmax(message), "^x04(VIP CHAT) ^x03%s : ^x04%s", playerName, text[1]);

			for (new i = 1; i <= MAX_PLAYERS; i++) {
				if (is_user_connected(i) && get_bit(i, VIP)) client_print_color(i, i, "^x04%s", message);
			}

			return PLUGIN_HANDLED_MAIN;
		}
	}

	return PLUGIN_CONTINUE;
}

public say_text(msgId,msgDest,msgEnt)
{
	new id = get_msg_arg_int(1);

	if (is_user_connected(id) && get_bit(id, VIP)) {
		new tempMessage[192], message[192], chatPrefix[16], playerName[32];

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

		if (get_bit(id, SVIP)) formatex(chatPrefix, charsmax(chatPrefix), "^x04[SVIP]");
		else formatex(chatPrefix, charsmax(chatPrefix), "^x04[VIP]");

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

public handle_ammo(iMsgId, iMsgDest, id)
{
	new ammoID = get_msg_arg_int(1);

	if (is_user_alive(id) && ammoID && ammoID <= ammo_9mm && get_bit(id, SVIP)) {
		new ammo = maxBPAmmo[ammoID];

		if (get_msg_arg_int(2) < ammo) {
			set_msg_arg_int(2, ARG_BYTE, ammo);
			set_pdata_int(id, 376 + ammoID, ammo, 5);
		}
	}
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