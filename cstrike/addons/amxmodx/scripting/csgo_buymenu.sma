#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <csgomod>

#define PLUGIN	"CS:GO Buy Menu"
#define AUTHOR	"O'Zone"

#define CSW_NIGHTVISION 0
#define CSW_DEFUSEKIT 2
#define CSW_SHIELD 33
#define CSW_MOLOTOV 34
#define CSW_ZEUS 35

new const weaponCommands[][] = { "nvgs", "p228", "defuser", "scout", "hegren", "xm1014", "", "mac10", "aug", "sgren",
	"elites", "fn57", "ump45", "sg550", "galil", "famas", "usp", "glock", "awp", "mp5", "m249", "m3", "m4a1", "tmp",
	"g3sg1", "flash", "deagle", "sg552", "ak47", "", "p90", "vest", "vesthelm", "shield", "molotov", "zeus"
};

new Float:cvarBuyTime, Float:roundStartTime, mapBuyBlock;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_float(get_cvar_pointer("mp_buytime"), cvarBuyTime);

	register_clcmd("buy" , "clcmd_buy");
	register_clcmd("shop" , "clcmd_buy");
	register_clcmd("client_buy_open" , "clcmd_client_buy_open");
	register_clcmd("buyequip" , "clcmd_buyequip");

	register_logevent("round_start", 2, "1=Round_Start");

	register_event("HLTV", "round_start", "a", "1=0", "2=0");

	register_forward(FM_KeyValue, "key_value", true);
}

public key_value(ent, keyValueId)
{
	if (pev_valid(ent)) {
		new className[32], keyName[32], keyValue[32];

		get_kvd(keyValueId, KV_ClassName, className, charsmax(className));
		get_kvd(keyValueId, KV_KeyName, keyName, charsmax(keyName));
		get_kvd(keyValueId, KV_Value, keyValue, charsmax(keyValue));

		if (equali(className, "info_map_parameters") && equali(keyName, "buying")) {
			if (str_to_num(keyValue) != 0) mapBuyBlock = str_to_num(keyValue);
		}
	}

	return FMRES_IGNORED;
}

public round_start()
    roundStartTime = get_gametime();

public clcmd_client_buy_open(id)
{
	if (csgo_get_menu(id) || !pev_valid(id) || !is_user_alive(id)) return PLUGIN_CONTINUE;

	static msgBuyClose;

	if (!msgBuyClose) msgBuyClose = get_user_msgid("BuyClose");

	message_begin(MSG_ONE, msgBuyClose, _, id),
	message_end();

	clcmd_buy(id);

	return PLUGIN_HANDLED;
}

public clcmd_buy(id)
{
	if (csgo_get_menu(id)) return PLUGIN_CONTINUE;

	if (!can_buy(id)) return PLUGIN_HANDLED;

	new menu = menu_create("\yBuy Item", "clcmd_buy_handle");

	menu_additem(menu, "\wHandgun");
	menu_additem(menu, "\wShotgun");
	menu_additem(menu, "\wSub-Machine Gun");
	menu_additem(menu, "\wRifle");
	menu_additem(menu, "\wMachine Gun^n");
	menu_additem(menu, "\wPrimary weapon ammo");
	menu_additem(menu, "\wSecondary weapon ammo^n");
	menu_additem(menu, "\wEquipment");

	menu_addblank(menu);
	menu_additem(menu, "\wExit");

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\w");
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	menu_setprop(menu, MPROP_PERPAGE, 0);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public clcmd_buy_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item > 7) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: clcmd_handgun(id);
		case 1: clcmd_shotgun(id);
		case 2: clcmd_submachinegun(id);
		case 3: clcmd_rifle(id);
		case 4: clcmd_machinegun(id);
		case 5: engclient_cmd(id, "primammo");
		case 6: engclient_cmd(id, "secammo");
		case 7: clcmd_equipment(id);
	}

	return PLUGIN_HANDLED;
}

public clcmd_buyequip(id)
{
	if (csgo_get_menu(id)) return PLUGIN_CONTINUE;

	if (!can_buy(id)) return PLUGIN_HANDLED;

	clcmd_equipment(id);

	return PLUGIN_HANDLED;
}

public clcmd_handgun(id)
{
	if (!can_buy(id)) return PLUGIN_HANDLED;

	new menuData[128], skinName[64], itemData[3], skin, menu = menu_create("\yBuy Handgun\R$ Cost    \rSkin\y^n(Secondary weapon)", "clcmd_buy_weapon_handle");

	if ((skin = csgo_get_weapon_skin(id, CSW_GLOCK18)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\w9X19mm Sidearm\R\y400   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\w9X19mm Sidearm\R\y400");
	}

	num_to_str(CSW_GLOCK18, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	if ((skin = csgo_get_weapon_skin(id, CSW_USP)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wK&M .45 Tactical\R^t\y500   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wK&M .45 Tactical\R^t\y500");
	}

	num_to_str(CSW_USP, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	if ((skin = csgo_get_weapon_skin(id, CSW_P228)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\w228 Compact\R\y600   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\w228 Compact\R\y600");
	}

	num_to_str(CSW_P228, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	if ((skin = csgo_get_weapon_skin(id, CSW_DEAGLE)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wNight Hawk .50C\R\y650   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wNight Hawk .50C\R\y650");
	}

	num_to_str(CSW_DEAGLE, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	if (cs_get_user_team(id) == CS_TEAM_T) {
		if ((skin = csgo_get_weapon_skin(id, CSW_ELITE)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\w.40 Dual Elites\R\y800   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\w.40 Dual Elites\R\y800");
		}

		num_to_str(CSW_ELITE, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);
	} else {
		if ((skin = csgo_get_weapon_skin(id, CSW_FIVESEVEN)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wES Five-Seven\R\y750   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wES Five-Seven\R\y750");
		}

		num_to_str(CSW_FIVESEVEN, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Exit");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\w");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public clcmd_shotgun(id)
{
	if (!can_buy(id)) return PLUGIN_HANDLED;

	new menuData[128], skinName[64], itemData[3], skin, menu = menu_create("\yBuy Shotgun\R$ Cost    \rSkin\y^n(Primary weapon)", "clcmd_buy_weapon_handle");

	if ((skin = csgo_get_weapon_skin(id, CSW_M3)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wLeone 12 Gauge Super\R\y1700   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wLeone 12 Gauge Super\R\y1700");
	}

	num_to_str(CSW_M3, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	if ((skin = csgo_get_weapon_skin(id, CSW_XM1014)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wLeone YG1265 Auto Shotgun\R^t\y3000   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wLeone YG1265 Auto Shotgun\R^t\y3000");
	}

	num_to_str(CSW_XM1014, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	menu_setprop(menu, MPROP_EXITNAME, "Exit");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\w");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public clcmd_submachinegun(id)
{
	if (!can_buy(id)) return PLUGIN_HANDLED;

	new menuData[128], skinName[64], itemData[3], skin, menu = menu_create("\yBuy Sub-Machine Gun\R$ Cost    \rSkin\y^n(Primary weapon)", "clcmd_buy_weapon_handle");

	if (cs_get_user_team(id) == CS_TEAM_T) {
		if ((skin = csgo_get_weapon_skin(id, CSW_MAC10)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wIngram MAC-10\R^t\y1400   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wIngram MAC-10\R^t\y1400");
		}

		num_to_str(CSW_MAC10, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);
	} else {
		if ((skin = csgo_get_weapon_skin(id, CSW_TMP)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wSchmidt Machine Pistol\R^t\y1250   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wSchmidt Machine Pistol\R^t\y1250");
		}

		num_to_str(CSW_TMP, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);
	}

	if ((skin = csgo_get_weapon_skin(id, CSW_MP5NAVY)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wK&M Sub-Machine Gun\R\y1500   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wK&M Sub-Machine Gun\R\y1500");
	}

	num_to_str(CSW_MP5NAVY, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	if ((skin = csgo_get_weapon_skin(id, CSW_UMP45)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wK&M UMP45\R\y1700   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wK&M UMP45\R\y1700");
	}

	num_to_str(CSW_UMP45, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	if ((skin = csgo_get_weapon_skin(id, CSW_P90)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wES C90\R^t\y2350   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wES C90\R^t\y2350");
	}

	num_to_str(CSW_P90, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	menu_setprop(menu, MPROP_EXITNAME, "Exit");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\w");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public clcmd_rifle(id)
{
	if (!can_buy(id)) return PLUGIN_HANDLED;

	new menuData[128], skinName[64], itemData[3], skin, menu = menu_create("\yBuy Rifle\R$  Cost    \rSkin\y^n(Primary weapon)", "clcmd_buy_weapon_handle");

	if (cs_get_user_team(id) == CS_TEAM_T) {
		if ((skin = csgo_get_weapon_skin(id, CSW_GALIL)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wIDF Defender\R\y2000   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wIDF Defender\R\y2000");
		}

		num_to_str(CSW_GALIL, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_AK47)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wCV-47\R^t\y2500   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wCV-47\R^t\y2500");
		}

		num_to_str(CSW_AK47, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_SCOUT)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wSchmidt Scout\R\y2750   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wSchmidt Scout\R\y2750");
		}

		num_to_str(CSW_SCOUT, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_SG552)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wKrieg 552 Commando\R\y3500   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wKrieg 552 Commando\R\y3500");
		}

		num_to_str(CSW_SG552, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_AWP)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wMagnum Sniper Rifle\R\y4750   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wMagnum Sniper Rifle\R\y4750");
		}

		num_to_str(CSW_AWP, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_G3SG1)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wD3/AU-1 Semi-Auto Sniper Rifle \y5000   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wD3/AU-1 Semi-Auto Sniper Rifle \y5000");
		}

		num_to_str(CSW_G3SG1, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);
	} else {
		if ((skin = csgo_get_weapon_skin(id, CSW_FAMAS)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wClarion 5.56\R^t\y2250   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wClarion 5.56\R^t\y2250");
		}

		num_to_str(CSW_FAMAS, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_SCOUT)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wSchmidt Scout\R^t\y2750   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wSchmidt Scout\R^t\y2750");
		}

		num_to_str(CSW_SCOUT, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_M4A1)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wMaveric M4A1 Carabine\R\y3100   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wMaveric M4A1 Carabine\R\y3100");
		}

		num_to_str(CSW_M4A1, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_AUG)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wBullpup\R\y3500   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wBullpup\R\y3500");
		}

		num_to_str(CSW_AUG, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_SG550)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wKrieg 550 Commando\R^t\y4200   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wKrieg 550 Commando\R^t\y4200");
		}

		num_to_str(CSW_SG550, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);

		if ((skin = csgo_get_weapon_skin(id, CSW_AWP)) > -1) {
			csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

			formatex(menuData, charsmax(menuData), "\wMagnum Sniper Rifle\R^t\y4750   \r%s", skinName);
		} else {
			formatex(menuData, charsmax(menuData), "\wMagnum Sniper Rifle\R^t\y4750");
		}

		num_to_str(CSW_AWP, itemData, charsmax(itemData));
		menu_additem(menu, menuData, itemData);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Exit");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\w");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public clcmd_machinegun(id)
{
	if (!can_buy(id)) return PLUGIN_HANDLED;

	new menuData[128], skinName[64], itemData[3], skin, menu = menu_create("\yBuy Machine Gun\R$  Cost    \rSkin\y^n(Primary weapon)", "clcmd_buy_weapon_handle");

	if ((skin = csgo_get_weapon_skin(id, CSW_M249)) > -1) {
		csgo_get_skin_name(id, skin, skinName, charsmax(skinName));

		formatex(menuData, charsmax(menuData), "\wES M249 Para\R\y5750   \r%s", skinName);
	} else {
		formatex(menuData, charsmax(menuData), "\wES M249 Para\R\y5750");
	}

	num_to_str(CSW_M249, itemData, charsmax(itemData));
	menu_additem(menu, menuData, itemData);

	menu_setprop(menu, MPROP_EXITNAME, "Exit");
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\w");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public clcmd_equipment(id)
{
	if (!can_buy(id)) return PLUGIN_HANDLED;

	new menuData[64], itemData[3], menu = menu_create("\yBuy Equipment\R$  Cost", "clcmd_buy_weapon_handle");

	num_to_str(CSW_VEST, itemData, charsmax(itemData));
	menu_additem(menu, "\wKevlar Vest\R\y650", itemData);

	num_to_str(CSW_VESTHELM, itemData, charsmax(itemData));
	menu_additem(menu, "\wKevlar Vest & Helmet\R\y1000", itemData);

	num_to_str(CSW_FLASHBANG, itemData, charsmax(itemData));
	menu_additem(menu, "\wFlashbang\R\y200", itemData);

	num_to_str(CSW_HEGRENADE, itemData, charsmax(itemData));
	menu_additem(menu, "\wHE Grenade\R^t^t\y300", itemData);

	num_to_str(CSW_SMOKEGRENADE, itemData, charsmax(itemData));
	menu_additem(menu, "\wSmoke Grenade\R\y300", itemData);

	if (cvar_exists("csgo_molotov_enabled") && get_cvar_num("csgo_molotov_enabled")) {
		num_to_str(CSW_MOLOTOV, itemData, charsmax(itemData));

		formatex(menuData, charsmax(menuData), "\wMolotov\R^t^t\y%i", get_cvar_num("csgo_molotov_price"));

		menu_additem(menu, menuData, itemData);
	} else {
		num_to_str(CSW_NIGHTVISION, itemData, charsmax(itemData));
		menu_additem(menu, "\wNightVision Goggles\R^t\y1250", itemData);
	}

	if (cs_get_user_team(id) == CS_TEAM_CT) {
		num_to_str(CSW_DEFUSEKIT, itemData, charsmax(itemData));
		menu_additem(menu, "\wDefuse Kit                              ^t\y200", itemData);
	}

	if (cvar_exists("csgo_zeus_enabled") && get_cvar_num("csgo_zeus_enabled")) {
		num_to_str(CSW_ZEUS, itemData, charsmax(itemData));

		formatex(menuData, charsmax(menuData), "\wZeus\R\y%i", get_cvar_num("csgo_zeus_price"));

		menu_additem(menu, menuData, itemData);
	} else if(cs_get_user_team(id) == CS_TEAM_CT) {
		num_to_str(CSW_SHIELD, itemData, charsmax(itemData));
		menu_additem(menu, "\wTactical Shield\R\y2200", itemData);
	}

	if (cs_get_user_team(id) == CS_TEAM_CT) {
		menu_addblank(menu);
		menu_additem(menu, "\wExit");

		menu_setprop(menu, MPROP_PERPAGE, 0);
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	} else {
		menu_setprop(menu, MPROP_EXITNAME, "Exit");
	}

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\w");

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public clcmd_buy_weapon_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	if (item == MENU_EXIT || item == 9) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	new itemData[3], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	engclient_cmd(id, weaponCommands[str_to_num(itemData)]);

	return PLUGIN_HANDLED;
}

stock can_buy(id)
{
	if (!pev_valid(id) || !is_user_alive(id) || !cs_get_user_buyzone(id)) return false;

	new Float:buyTime;

	static msgText;

	if (!msgText) msgText = get_user_msgid("TextMsg");

	if (cvarBuyTime != -1.0 && !(get_gametime() < roundStartTime + (buyTime = cvarBuyTime * 60.0))) {
		new buyTimeText[8];

		num_to_str(floatround(buyTime), buyTimeText, charsmax(buyTimeText));

		message_begin(MSG_ONE, msgText, _, id);
		write_byte(print_center);
		write_string("#Cant_buy");
		write_string(buyTimeText);
		message_end();

		return false;
	}

	if ((mapBuyBlock == 1 && cs_get_user_team(id) == CS_TEAM_CT) || (mapBuyBlock == 2 && cs_get_user_team(id) == CS_TEAM_T) || mapBuyBlock == 3) {
		message_begin(MSG_ONE, msgText, _, id);
		write_byte(print_center);

		if (cs_get_user_team(id) == CS_TEAM_T) write_string("#Cstrike_TitlesTXT_Terrorist_cant_buy");
		else if (cs_get_user_team(id) == CS_TEAM_CT) write_string("#Cstrike_TitlesTXT_CT_cant_buy");

		message_end();

		return false;
	}

	return true;
}
