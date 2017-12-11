#include <amxmodx>
#include <sqlx>
#include <cod>

#define PLUGIN "CS:GO Clans"
#define VERSION "1.0.0"
#define AUTHOR "O'Zone"

new const commandClan[][] = { "say /clan", "say_team /clan", "say /clans", "say_team /clans", "say /klany", "say_team /klany", "say /klan", "say_team /klan", "klan" };

enum _:clanInfo { CLAN_ID, CLAN_LEVEL, CLAN_HONOR, CLAN_HEALTH, CLAN_GRAVITY, CLAN_DAMAGE, CLAN_DROP, CLAN_KILLS, CLAN_MEMBERS, Trie:CLAN_STATUS, CLAN_NAME[64] };
enum _:statusInfo { STATUS_NONE, STATUS_MEMBER, STATUS_DEPUTY, STATUS_LEADER };

new cvarCreateLevel, cvarMembersStart, cvarLevelMax, cvarSkillMax, cvarChatPrefix, cvarLevelCost, cvarNextLevelCost, cvarSkillCost, 
	cvarNextSkillCost, cvarMembersPerLevel, cvarHealthPerLevel, cvarGravityPerLevel, cvarDamagePerLevel, cvarWeaponDropPerLevel;

new playerName[MAX_PLAYERS + 1][64], chosenName[MAX_PLAYERS + 1][64], clan[MAX_PLAYERS + 1], chosenId[MAX_PLAYERS + 1], Handle:sql, bool:sqlConnected, Array:codClans;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof commandClan; i++) register_clcmd(commandClan[i], "show_clan_menu");
	
	register_clcmd("PODAJ_NAZWE_KLANU", "create_clan_handle");
	register_clcmd("PODAJ_NOWA_NAZWE_KLANU", "change_name_handle");
	register_clcmd("WPISZ_ILOSC_HONORU", "deposit_honor_handle");

	bind_pcvar_num(create_cvar("cod_clans_create_level", "25"), cvarCreateLevel);
	bind_pcvar_num(create_cvar("cod_clans_members_start", "3"), cvarMembersStart);
	bind_pcvar_num(create_cvar("cod_clans_level_max", "10"), cvarLevelMax);
	bind_pcvar_num(create_cvar("cod_clans_skill_max", "10"), cvarSkillMax);
	bind_pcvar_num(create_cvar("cod_clans_chat_prefix", "0"), cvarChatPrefix);
	bind_pcvar_num(create_cvar("cod_clans_level_cost", "1000"), cvarLevelCost);
	bind_pcvar_num(create_cvar("cod_clans_next_level_cost", "1000"), cvarNextLevelCost);
	bind_pcvar_num(create_cvar("cod_clans_skill_cost", "500"), cvarSkillCost);
	bind_pcvar_num(create_cvar("cod_clans_next_skill_cost", "500"), cvarNextSkillCost);
	bind_pcvar_num(create_cvar("cod_clans_members_per_level", "1"), cvarMembersPerLevel);
	bind_pcvar_num(create_cvar("cod_clans_health_per_level", "1"), cvarHealthPerLevel);
	bind_pcvar_num(create_cvar("cod_clans_gravity_per_level", "20"), cvarGravityPerLevel);
	bind_pcvar_num(create_cvar("cod_clans_damage_per_level", "1"), cvarDamagePerLevel);
	bind_pcvar_num(create_cvar("cod_clans_weapondrop_per_level", "1"), cvarWeaponDropPerLevel);
	
	register_message(get_user_msgid("SayText"), "say_text");
	
	codClans = ArrayCreate(clanInfo);
}

public plugin_natives()
{
	register_native("cod_get_user_clan", "_cod_get_user_clan", 1);
	register_native("cod_get_clan_name", "_cod_get_clan_name", 1);
}

public plugin_cfg()
{
	new codClan[clanInfo];
	
	codClan[CLAN_NAME] = "Brak";
	
	ArrayPushArray(codClans, codClan);

	sql_init();
}

public plugin_end()
{
	SQL_FreeHandle(sql);

	ArrayDestroy(codClans);
}

public client_putinserver(id)
{
	if (is_user_bot(id) || is_user_hltv(id)) return;

	clan[id] = 0;

	get_user_name(id, playerName[id], charsmax(playerName));

	cod_sql_string(playerName[id], playerName[id], charsmax(playerName));

	set_task(0.1, "load_data", id);
}

public client_disconnected(id)
{
	remove_task(id);

	clan[id] = 0;
}

public cod_spawned(id, respawn)
{
	if (!clan[id]) return PLUGIN_CONTINUE;

	cod_add_user_gravity(id, -cvarGravityPerLevel * get_clan_info(clan[id], CLAN_GRAVITY) / 800.0, ROUND);
	
	return PLUGIN_CONTINUE;
}

public cod_damage_post(attacker, victim, weapon, Float:damage, damageBits, hitPlace)
{
	if (!clan[attacker]) return PLUGIN_CONTINUE;
	
	cod_inflict_damage(attacker, victim, damage * cvarGravityPerLevel * get_clan_info(clan[attacker], CLAN_DAMAGE) / 100.0, 0.0, damageBits);
	
	if (get_clan_info(clan[attacker], CLAN_DROP) && random_num(1, (cvarSkillMax * 1.6 - (get_clan_info(clan[attacker], CLAN_DROP) * cvarWeaponDropPerLevel)) == 1)) engclient_cmd(victim, "drop");
	
	return PLUGIN_CONTINUE;
}

public cod_killed(killer, victim, weaponId, hitPlace)
{
	if (!clan[killer]) return PLUGIN_CONTINUE;
	
	set_clan_info(clan[killer], CLAN_KILLS, get_clan_info(clan[killer], CLAN_KILLS) + 1);
	
	return PLUGIN_CONTINUE;
}

public show_clan_menu(id, sound)
{	
	if (!is_user_connected(id) || !cod_check_account(id)) return PLUGIN_HANDLED;
	
	if (!sound) client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new codClan[clanInfo], menuData[128], menu, callback = menu_makecallback("show_clan_menu_callback");
	
	if (clan[id]) {
		ArrayGetArray(codClans, get_clan_id(clan[id]), codClan);
		
		formatex(menuData, charsmax(menuData), "\yMenu \rKlanu^n\wAktualny Klan:\y %s^n\wStan: \y%i/%i %s \w| \y%i Honoru\w", codClan[CLAN_NAME], codClan[CLAN_MEMBERS], codClan[CLAN_LEVEL] * cvarMembersPerLevel + cvarMembersStart, codClan[CLAN_MEMBERS] > 1 ? "Czlonkow" : "Czlonek", codClan[CLAN_HONOR]);
		
		menu = menu_create(menuData, "show_clan_menu_handle");

		menu_additem(menu, "\wZarzadzaj \yKlanem", "1", _, callback);
		menu_additem(menu, "\wOpusc \yKlan", "2", _, callback);
		menu_additem(menu, "\wCzlonkowie \yOnline", "3", _, callback);
		menu_additem(menu, "\wWplac \yHonor", "4", _, callback);
		menu_additem(menu, "\wLista \yWplacajacych", "5", _, callback);
	} else {
		menu = menu_create("\yMenu \rKlanu^n\wAktualny Klan:\y Brak", "show_clan_menu_handle");

		formatex(menuData, charsmax(menuData), "\wStworz \yKlan \r(Wymagany %i Poziom)", cvarCreateLevel);

		menu_additem(menu, menuData, "0", _, callback);

		menu_additem(menu, "\wZloz \yPodanie", "7", _, callback);
	}

	menu_additem(menu, "\wTop15 \yKlanow", "6", _, callback);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public show_clan_menu_callback(id, menu, item)
{
	new itemData[2], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);

	switch (str_to_num(itemData)) {
		case 0: return cod_get_user_highest_level(id) >= cvarCreateLevel ? ITEM_ENABLED : ITEM_DISABLED;
		case 1: return get_user_status(id) > STATUS_MEMBER ? ITEM_ENABLED : ITEM_DISABLED;
		case 2, 3, 4, 5: return clan[id] ? ITEM_ENABLED : ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public show_clan_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	new itemData[2], itemAccess, menuCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, menuCallback);
	
	switch (str_to_num(itemData)) {
		case 0: {
			if (clan[id]) {
				cod_print_chat(id, "Nie mozesz utworzyc klanu, jesli w jakims jestes!");

				return PLUGIN_HANDLED;
			}
			
			if (cod_get_user_highest_level(id) < cvarCreateLevel) {
				cod_print_chat(id, "Nie masz wystarczajacego poziomu by stworzyc klan (Wymagany^x03 %i^x01)!", cvarCreateLevel);

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
		case 4: {
			client_cmd(id, "messagemode WPISZ_ILOSC_HONORU");

			client_print(id, print_center, "Wpisz ilosc Honoru, ktora chcesz wplacic");

			cod_print_chat(id, "Wpisz ilosc Honoru, ktora chcesz wplacic.");
		}
		case 5: depositors_list(id);
		case 6: clans_top15(id);
		case 7: application_menu(id);
	}
	
	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public create_clan_handle(id)
{
	if (!is_user_connected(id) || !cod_check_account(id) || clan[id]) return PLUGIN_HANDLED;
		
	client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);
	
	if (cod_get_user_level(id) < cvarCreateLevel) {
		cod_print_chat(id, "Nie masz wystarczajaco wysokiego poziomu (Wymagany: %i)!", cvarCreateLevel);

		return PLUGIN_HANDLED;
	}
	
	new clanName[64];
	
	read_args(clanName, charsmax(clanName));
	remove_quotes(clanName);
	trim(clanName);
	
	if (equal(clanName, "")) {
		cod_print_chat(id, "Nie wpisales nazwy klanu.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	if (strlen(clanName) < 3) {
		cod_print_chat(id, "Nazwa klanu musi miec co najmniej 3 znaki.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}
	
	if (check_clan_name(clanName)) {
		cod_print_chat(id, "Klan z taka nazwa juz istnieje.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	create_clan(id, clanName);
	
	cod_print_chat(id, "Pomyslnie zalozyles klan^x03 %s^01.", clanName);
	
	return PLUGIN_HANDLED;
}

public leave_confim_menu(id)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \ropuscic \wklan?", "leave_confim_menu_handle");
	
	menu_additem(menu, "Tak");
	menu_additem(menu, "Nie^n");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public leave_confim_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	switch (item) {
		case 0: {
			if (get_user_status(id) == STATUS_LEADER) {
				cod_print_chat(id, "Oddaj przywodctwo klanu jednemu z czlonkow zanim go upuscisz.");

				show_clan_menu(id, 1);

				return PLUGIN_HANDLED;
			}

			set_user_clan(id);
			
			cod_print_chat(id, "Opusciles swoj klan.");
			
			show_clan_menu(id, 1);
		}
		case 1: show_clan_menu(id, 1);
	}

	return PLUGIN_HANDLED;
}

public members_online_menu(id)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new clanName[64], playersAvailable = 0;
	
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
	
	if (!playersAvailable) cod_print_chat(id, "Na serwerze nie ma zadnego czlonka twojego klanu!");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public members_online_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	menu_destroy(menu);
	
	members_online_menu(id);
	
	return PLUGIN_HANDLED;
}

public leader_menu(id)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new menu = menu_create("\yZarzadzaj \rKlanem", "leader_menu_handle"), callback = menu_makecallback("leader_menu_callback");

	menu_additem(menu, "\wRozwiaz \yKlan", _, _, callback);
	menu_additem(menu, "\wUlepsz \yUmiejetnosci", _, _, callback);
	menu_additem(menu, "\wZapros \yGracza", _, _, callback);
	menu_additem(menu, "\wZarzadzaj \yCzlonkami", _, _, callback);
	menu_additem(menu, "\wRozpatrz \yPodania", _, _, callback);
	menu_additem(menu, "\wZmien \yNazwe Klanu^n", _, _, callback);
	menu_additem(menu, "\wWroc", _, _, callback);
		
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public leader_menu_callback(id, menu, item)
{
	switch (item) {
		case 1: get_user_status(id) == STATUS_LEADER ? ITEM_ENABLED : ITEM_DISABLED;
		case 2: if (((get_clan_info(clan[id], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[id], CLAN_MEMBERS)) return ITEM_DISABLED;
		case 4: if (((get_clan_info(clan[id], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[id], CLAN_MEMBERS) || !get_applications_count(clan[id])) return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public leader_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	switch (item) {
		case 0: disband_menu(id);
		case 1: skills_menu(id);
		case 2: invite_menu(id);
		case 3: members_menu(id);
		case 4: applications_menu(id);
		case 5: client_cmd(id, "messagemode PODAJ_NOWA_NAZWE_KLANU");
		case 6: show_clan_menu(id, 1);
	}

	return PLUGIN_HANDLED;
}

public disband_menu(id)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \rrozwiazac\w klan?", "disband_menu_handle");
	
	menu_additem(menu, "Tak", "0");
	menu_additem(menu, "Nie^n", "1");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public disband_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	switch (item) {
		case 0: {
			cod_print_chat(id, "Rozwiazales swoj klan.");
			
			remove_clan(id);
			
			show_clan_menu(id, 1);
		}
		case 1: show_clan_menu(id, 1);
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public skills_menu(id)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new codClan[clanInfo], menuData[128];

	ArrayGetArray(codClans, get_clan_id(clan[id]), codClan);
	
	formatex(menuData, charsmax(menuData), "\yMenu \rUmiejetnosci^n\wHonor Klanu: \y%i", codClan[CLAN_HONOR]);

	new menu = menu_create(menuData, "skills_menu_handle");
	
	formatex(menuData, charsmax(menuData), "Poziom Klanu \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_LEVEL], cvarLevelMax, cvarLevelCost + cvarNextLevelCost * codClan[CLAN_LEVEL]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Zycie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_HEALTH], cvarSkillMax, cvarSkillCost + cvarNextSkillCost * codClan[CLAN_HEALTH]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Grawitacja \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_GRAVITY], cvarSkillMax, cvarSkillCost + cvarNextSkillCost * codClan[CLAN_GRAVITY]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Obrazenia \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_DAMAGE], cvarSkillMax, cvarSkillCost + cvarNextSkillCost * codClan[CLAN_DAMAGE]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Obezwladnienie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_DROP], cvarSkillMax, cvarSkillCost + cvarNextSkillCost * codClan[CLAN_DROP]);
	menu_additem(menu, menuData);
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public skills_menu_handle(id, menu, item)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new codClan[clanInfo], upgradedSkill;

	ArrayGetArray(codClans, get_clan_id(clan[id]), codClan);

	menu_destroy(menu);
	
	switch (item) {
		case 0: {
			if (codClan[CLAN_LEVEL] == cvarLevelMax) {
				cod_print_chat(id, "Twoj klan ma juz maksymalny Poziom.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (cvarLevelCost + cvarNextLevelCost * codClan[CLAN_LEVEL]);
			
			if (remainingHonor < 0) {
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_LEVEL;
			
			codClan[CLAN_LEVEL]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles klan na^x03 %i Poziom^x01!", codClan[CLAN_LEVEL]);
		}
		case 1: {
			if (codClan[CLAN_HEALTH] == cvarSkillMax) {
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (cvarSkillCost + cvarNextSkillCost * codClan[CLAN_HEALTH]);
			
			if (remainingHonor < 0) {
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_HEALTH;
			
			codClan[CLAN_HEALTH]++;
			codClan[CLAN_HONOR] = remainingHonor;

			cod_set_user_bonus_health(id, cod_get_user_bonus_health(id) + get_clan_info(clan[id], CLAN_HEALTH) * cvarHealthPerLevel);
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Predkosc^x01 na^x03 %i^x01 poziom!", codClan[CLAN_HEALTH]);
		}
		case 2: {
			if (codClan[CLAN_GRAVITY] == cvarSkillMax) {
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (cvarSkillCost + cvarNextSkillCost * codClan[CLAN_GRAVITY]);
			
			if (remainingHonor < 0) {
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_GRAVITY;
			
			codClan[CLAN_GRAVITY]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Grawitacja^x01 na^x03 %i^x01 poziom!", codClan[CLAN_GRAVITY]);
		}
		case 3: {
			if (codClan[CLAN_DAMAGE] == cvarSkillMax) {
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (cvarSkillCost + cvarNextSkillCost * codClan[CLAN_DAMAGE]);
			
			if (remainingHonor < 0) {
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_DAMAGE;
			
			codClan[CLAN_DAMAGE]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Obrazenia^x01 na^x03 %i^x01 poziom!", codClan[CLAN_DAMAGE]);
		}
		case 4: {
			if (codClan[CLAN_DROP] == cvarSkillMax) {
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (cvarSkillCost + cvarNextSkillCost * codClan[CLAN_DROP]);
			
			if (remainingHonor < 0) {
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_DROP;
			
			codClan[CLAN_DROP]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Obezwladnienie^x01 na^x03 %i^x01 poziom!", codClan[CLAN_DROP]);
		}
	}
	
	ArraySetArray(codClans, get_clan_id(clan[id]), codClan);

	save_clan(get_clan_id(clan[id]));
	
	new name[32];
	
	get_user_name(id, name, charsmax(name));
	
	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(id) || player == id || clan[player] != clan[id]) continue;

		cod_set_user_bonus_health(player, cod_get_user_bonus_health(player) + get_clan_info(clan[player], CLAN_HEALTH) * cvarHealthPerLevel);

		cod_print_chat(player, "^x03 %s^x01 ulepszyl klan na^x03 %i Poziom^x01!", name, codClan[upgradedSkill]);
	}
	
	skills_menu(id);
	
	return PLUGIN_HANDLED;
}

public invite_menu(id)
{	
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new userName[64], userId[6], playersAvailable = 0;
	
	new menu = menu_create("\yWybierz \rGracza \ydo zaproszenia:", "invite_menu_handle");
	
	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(id) || player == id || clan[player]) continue;

		playersAvailable++;
		
		get_user_name(player, userName, charsmax(userName));

		num_to_str(player, userId, charsmax(userId));

		menu_additem(menu, userName, userId);
	}	
	
	if (!playersAvailable) cod_print_chat(id, "Na serwerze nie ma gracza, ktorego moglbys zaprosic!");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public invite_menu_handle(id, menu, item)
{
	if (!is_user_connected(id)  || !clan[id]) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new userName[64], itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), userName, charsmax(userName), itemCallback);
	
	new player = str_to_num(itemData);

	if (!is_user_connected(player)) {
		cod_print_chat(id, "Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	} 
	
	invite_confirm_menu(id, player);

	cod_print_chat(id, "Zaprosiles^x03 %s^x01 do do twojego klanu.", userName);
	
	show_clan_menu(id, 1);
	
	return PLUGIN_HANDLED;
}

public invite_confirm_menu(id, player)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
		
	client_cmd(player, "spk %s", codSounds[SOUND_SELECT]);
	
	new menuData[128], clanName[64], userName[64], userId[6];
	
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
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT || item) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	new player = str_to_num(itemData);
	
	if (!is_user_connected(id)) {
		cod_print_chat(id, "Gracza, ktory cie zaprosil nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	client_cmd(player, "spk %s", codSounds[SOUND_SELECT]);
	
	if (clan[id]) {
		cod_print_chat(id, "Nie mozesz dolaczyc do klanu, jesli nalezysz do innego.");

		return PLUGIN_HANDLED;
	}
	
	if (((get_clan_info(clan[player], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[player], CLAN_MEMBERS)) {
		cod_print_chat(id, "Niestety, w tym klanie nie ma juz wolnego miejsca.");

		return PLUGIN_HANDLED;
	}

	new clanName[64];

	get_clan_info(clan[player], CLAN_NAME, clanName, charsmax(clanName));
	
	set_user_clan(id, clan[player]);
	
	cod_print_chat(id, "Dolaczyles do klanu^x03 %s^01.", clanName);
	
	return PLUGIN_HANDLED;
}

public change_name_handle(id)
{
	if (!is_user_connected(id) || !cod_check_account(id) || get_user_status(id) != STATUS_LEADER) return PLUGIN_HANDLED;
		
	client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);
	
	new clanName[64];
	
	read_args(clanName, charsmax(clanName));
	remove_quotes(clanName);
	trim(clanName);
	
	if (equal(clanName, "")) {
		cod_print_chat(id, "Nie wpisano nowej nazwy klanu.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	if (strlen(clanName) < 3) {
		cod_print_chat(id, "Nazwa klanu musi miec co najmniej 3 znaki.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}
	
	if (check_clan_name(clanName)) {
		cod_print_chat(id, "Klan z taka nazwa juz istnieje.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	set_clan_info(clan[id], CLAN_NAME, _, clanName, charsmax(clanName));
	
	cod_print_chat(id, "Zmieniles nazwe klanu na^x03 %s^x01.", clanName);
	
	return PLUGIN_CONTINUE;
}

public members_menu(id)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;

	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_members` WHERE clan = '%i' ORDER BY flag DESC", clan[id]);

	SQL_ThreadQuery(sql, "members_menu_handle", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public members_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = tempId[0];
	
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemData[64], userName[64], status, menu = menu_create("\yZarzadzaj \rCzlonkami:^n\wWybierz \yczlonka\w, aby pokazac mozliwe opcje.", "member_menu_handle");
	
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
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	new itemData[64], userName[64], tempFlag[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	menu_destroy(menu);

	strtok(itemData, userName, charsmax(userName), tempFlag, charsmax(tempFlag), '#');
	
	new flag = str_to_num(tempFlag), userId = get_user_index(userName);

	if (userId == id) {
		cod_print_chat(id, "Nie mozesz zarzadzac soba!");

		members_menu(id);

		return PLUGIN_HANDLED;
	}
	
	if (clan[userId]) chosenId[id] = get_user_userid(userId);

	if (flag == STATUS_LEADER) {
		cod_print_chat(id, "Nie mozna zarzadzac przywodca klanu!");

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
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
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

					cod_print_chat(player,  "Zostales mianowany przywodca klanu!");
				}
				case STATUS_DEPUTY: {
					set_user_status(player, STATUS_DEPUTY);

					cod_print_chat(player,  "^x01 Zostales zastepca przywodcy klanu!");		
				}
				case STATUS_MEMBER: {
					set_user_status(player, STATUS_MEMBER);

					cod_print_chat(player,  "^x01 Zostales zdegradowany do rangi czlonka klanu.");
				}
				case STATUS_NONE: {
					set_user_clan(player);

					cod_print_chat(player,  "Zostales wyrzucony z klanu.");
				}
			}

			playerOnline = true;

			continue;
		}
		
		switch (status) {
			case STATUS_LEADER: cod_print_chat(player, "^x03 %s^01 zostal nowym przywodca klanu.", chosenName[id]);
			case STATUS_DEPUTY: cod_print_chat(player, "^x03 %s^x01 zostal zastepca przywodcy klanu.", chosenName[id]);
			case STATUS_MEMBER: cod_print_chat(player, "^x03 %s^x01 zostal zdegradowany do rangi czlonka klanu.", chosenName[id]);
			case STATUS_NONE: cod_print_chat(player, "^x03 %s^01 zostal wyrzucony z klanu.", chosenName[id]);
		}
	}
	
	if (!playerOnline) {
		save_member(id, status, _, chosenName[id]);
		
		if (status == STATUS_NONE) set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) - 1);

		if (status == STATUS_LEADER) set_user_status(id, STATUS_DEPUTY);
	}
	
	show_clan_menu(id, 1);
	
	return PLUGIN_HANDLED;
}

public applications_menu(id)
{
	if (!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;

	new queryData[256], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.name, (SELECT level FROM `cod_mod` WHERE name = a.name ORDER BY level DESC LIMIT 1) as level, (SELECT honor FROM `cod_honor` WHERE name = a.name) as honor FROM `cod_clans_applications` a WHERE clan = '%i'", clan[id]);

	SQL_ThreadQuery(sql, "applications_menu_handle", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public applications_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = tempId[0];
	
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], userName[64], level, honor, usersCount = 0, menu = menu_create("\yRozpatrywanie \rPodan:^n\wWybierz \rpodanie\w, aby je \yzatwierdzic\w lub \yodrzucic\w.", "applications_confirm_menu");
	
	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), userName, charsmax(userName));

		level = SQL_ReadResult(query, SQL_FieldNameToNum(query, "level"));
		honor = SQL_ReadResult(query, SQL_FieldNameToNum(query, "honor"));
		
		formatex(itemName, charsmax(itemName), "\w%s \y(Najwyzszy poziom: \r%i\y | Honor: \r%i\y)", userName, level, honor);
		
		menu_additem(menu, itemName, userName);

		SQL_NextRow(query);

		usersCount++;
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");
	
	if (!usersCount) {
		menu_destroy(menu);

		cod_print_chat(id, "Nie ma zadnych niezatwierdzonych podan do klanu!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public applications_confirm_menu(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	new menuData[128], userName[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, userName, charsmax(userName), _, _, itemCallback);
	
	menu_destroy(menu);

	formatex(menuData, charsmax(menuData), "\wCo chcesz zrobic z podaniem gracza \y%s \w?", userName);
	
	new menu = menu_create(menuData, "applications_confirm_handle");
	
	menu_additem(menu, "Przymij", userName);
	menu_additem(menu, "Odrzuc");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public applications_confirm_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT || item) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new userName[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, userName, charsmax(userName), _, _, itemCallback);
	
	menu_destroy(menu);

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	switch (item) {
		case 0: {
			if (check_user_clan(userName)) {
				cod_print_chat(id, "Gracz dolaczyl juz do innego klanu!");

				show_clan_menu(id, 1);

				return PLUGIN_HANDLED;
			}

			if (((get_clan_info(clan[id], CLAN_LEVEL) * cvarMembersPerLevel) + cvarMembersStart) <= get_clan_info(clan[id], CLAN_MEMBERS)) {
				cod_print_chat(id, "Klan osiagnal maksymalna na ten moment liczbe czlonkow!");

				return PLUGIN_HANDLED;
			}

			accept_application(id, userName);

			cod_print_chat(id, "Zaakceptowales podanie gracza^x03 %s^01 o dolaczenie do klanu.", userName);
		}
		case 1: {
			remove_application(id, userName);

			cod_print_chat(id, "Odrzuciles podanie gracza^x03 %s^01 o dolaczenie do klanu.", userName);
		}
	}
	
	return PLUGIN_HANDLED;
}

public deposit_honor_handle(id)
{
	if (!is_user_connected(id) || !clan[id] || !cod_check_account(id)) return PLUGIN_HANDLED;

	client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);
	
	new honorData[16], honorAmount;
	
	read_args(honorData, charsmax(honorData));
	remove_quotes(honorData);

	honorAmount = str_to_num(honorData);
	
	if (honorAmount <= 0) { 
		cod_print_chat(id, "Nie mozesz wplacic mniej niz^x03 1 honoru^x01!");

		return PLUGIN_HANDLED;
	}
	
	if (cod_get_user_honor(id) < honorAmount) { 
		cod_print_chat(id, "Nie masz tyle^x03 honoru^x01!");

		return PLUGIN_HANDLED;
	}

	cod_add_user_honor(id, -honorAmount);
	
	set_clan_info(clan[id], CLAN_HONOR, get_clan_info(clan[id], CLAN_HONOR) + honorAmount);

	add_deposited_honor(id, honorAmount);
	
	cod_print_chat(id, "Wplaciles^x03 %i^x01 Honoru na rzecz klanu.", honorAmount);
	cod_print_chat(id, "Aktualnie twoj klan ma^x03 %i^x01 Honoru.", get_clan_info(clan[id], CLAN_HONOR));
	
	return PLUGIN_HANDLED;
}

public depositors_list(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, honor FROM `cod_clans_members` WHERE clan = '%i' AND honor > 0 ORDER BY honor DESC", clan[id]);

	SQL_ThreadQuery(sql, "show_depositors_list", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public show_depositors_list(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = tempId[0];
	
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	static motdData[2048], playerName[64], motdLength, rank, honor;

	rank = 0;
	
	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1s %-22.22s %12s^n", "#", "Nick", "Honor");
	
	while (SQL_MoreResults(query)) {
		rank++;
		
		SQL_ReadResult(query, 0, playerName, charsmax(playerName));
		replace_all(playerName, charsmax(playerName), "<", "");
		replace_all(playerName,charsmax(playerName), ">", "");
		
		honor = SQL_ReadResult(query, 1);
		
		if (rank >= 10) motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %5d^n", rank, playerName, honor);
		else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %6d^n", rank, playerName, honor);

		SQL_NextRow(query);
	}
	
	show_motd(id, motdData, "Lista Wplacajacych");
	
	return PLUGIN_HANDLED;
}

public clans_top15(id)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT name, members, honor, kills, level, health, gravity, weapondrop, damage FROM `cod_clans` ORDER BY kills DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_clans_top15", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public show_clans_top15(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = tempId[0];
	
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	static motdData[2048], clanName[64], motdLength, rank, members, honor, kills, level, health, gravity, drop, damage;

	rank = 0;
	
	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1s %-22.22s %4s %8s %6s %8s %9s %12s %11s^n", "#", "Nazwa", "Czlonkowie", "Poziom", "Zabicia", "Honor", "Zycie", "Grawitacja", "Obezwladnienie", "Obrazenia");
	
	while (SQL_MoreResults(query)) {
		rank++;
		
		SQL_ReadResult(query, 0, clanName, charsmax(clanName));
		replace_all(clanName, charsmax(clanName), "<", "");
		replace_all(clanName,charsmax(clanName), ">", "");
		
		members = SQL_ReadResult(query, 1);
		honor = SQL_ReadResult(query, 2);
		kills = SQL_ReadResult(query, 3);
		level = SQL_ReadResult(query, 4);
		health = SQL_ReadResult(query, 5);
		gravity = SQL_ReadResult(query, 6);
		drop = SQL_ReadResult(query, 7);
		damage = SQL_ReadResult(query, 8);
		
		if (rank >= 10) motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %5d %8d %10d %8d %7d %10d %14d^n", rank, clanName, members, level, kills, honor, health, gravity, drop, damage);
		else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %6d %8d %10d %8d %7d %10d %14d^n", rank, clanName, members, level, kills, honor, health, gravity, drop, damage);

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
		new tempMessage[192], message[192], chatPrefix[64], steamId[33], playerName[32];
		
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

public application_menu(id)
{
	if (!is_user_connected(id) || clan[id]) return PLUGIN_HANDLED;

	new queryData[256], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.id, a.name as 'clan', b.name FROM `cod_clans` a JOIN `cod_clans_members` b ON a.id = b.clan WHERE flag = '3' ORDER BY a.kills DESC");

	SQL_ThreadQuery(sql, "application_menu_handle", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public application_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = tempId[0];
	
	if (!is_user_connected(id)) return PLUGIN_HANDLED;

	new itemName[128], itemData[64], clanName[64], userName[64], clanId, clansCount = 0, menu = menu_create("\yZlozenie \rPodania:^n\wWybierz \rklan\w, do ktorego chcesz zlozyc \ypodanie\w.", "application_handle");
	
	while (SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan"), clanName, charsmax(clanName));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), userName, charsmax(userName));

		clanId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
		
		formatex(itemName, charsmax(itemName), "%s \y(Lider: \r%s\y)", clanName, userName);
		formatex(itemData, charsmax(itemData), "%s#%i", clanName, clanId);
		
		menu_additem(menu, itemName, itemData);

		SQL_NextRow(query);

		clansCount++;
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");
	
	if (!clansCount) {
		menu_destroy(menu);

		cod_print_chat(id, "Nie ma klanu, do ktorego moglbys zlozyc podanie!");
	} else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public application_handle(id, menu, item)
{
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	if (clan[id]) {
		cod_print_chat(id, "Nie mozesz zlozyc podania, jesli jestes juz w klanie!");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	new itemData[64], clanName[64], tempClanId[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	menu_destroy(menu);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');

	if (check_applications(id, str_to_num(tempClanId))) {
		cod_print_chat(id, "Juz zlozyles podanie do tego klanu, poczekaj na jego rozpatrzenie!");

		show_clan_menu(id, 1);

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
	if (!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if (item == MENU_EXIT || item) {
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new itemData[64], clanName[64], tempClanId[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	menu_destroy(menu);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');
	
	new clanId = str_to_num(tempClanId);

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	if (clan[id]) {
		cod_print_chat(id, "Nie mozesz zlozyc podania, jesli jestes juz w klanie!");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	add_application(id, clanId);

	cod_print_chat(id, "Zlozyles podanie do klanu^x03 %s^01.", clanName);
	
	return PLUGIN_HANDLED;
}

stock set_user_clan(id, playerClan = 0, owner = 0)
{
	if (!is_user_connected(id)) return;
	
	if (playerClan == 0) {
		set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) - 1);

		TrieDeleteKey(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id]);
		
		save_member(id, STATUS_NONE);
		
		clan[id] = 0;
	} else {
		clan[id] = playerClan;
		
		set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) + 1);

		TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], owner ? STATUS_LEADER : STATUS_MEMBER);
		
		save_member(id, owner ? STATUS_LEADER : STATUS_MEMBER, 1);
	}
}

stock set_user_status(id, status)
{
	if (!is_user_connected(id) || !clan[id]) return;

	TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);
	
	save_member(id, status);
}

stock get_user_status(id)
{
	if (!is_user_connected(id) || !clan[id]) return STATUS_NONE;
	
	new status;

	TrieGetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);
	
	return status;
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], queryData[512], error[128], errorNum;
	
	get_cvar_string("cod_sql_host", host, charsmax(host));
	get_cvar_string("cod_sql_user", user, charsmax(user));
	get_cvar_string("cod_sql_pass", pass, charsmax(pass));
	get_cvar_string("cod_sql_db", db, charsmax(db));
	
	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s", error);

		set_task(3.0, "sql_init");
		
		return;
	}

	sqlConnected = true;
	
	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `cod_clans` (`id` INT NOT NULL AUTO_INCREMENT, `name` varchar(64) NOT NULL, ");
	add(queryData, charsmax(queryData), "`members` INT NOT NULL, `honor` INT NOT NULL, `kills` INT NOT NULL, `level` INT NOT NULL, `health` INT NOT NULL, ");
	add(queryData, charsmax(queryData), "`gravity` INT NOT NULL, `damage` INT NOT NULL, `weapondrop` INT NOT NULL, PRIMARY KEY (`id`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `cod_clans_members` (`name` varchar(64) NOT NULL, `clan` INT NOT NULL, `flag` INT NOT NULL, `honor` INT NOT NULL, PRIMARY KEY (`name`));");
	
	query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `cod_clans_applications` (`name` varchar(64) NOT NULL, `clan` INT NOT NULL, PRIMARY KEY (`name`, `clan`));");
	
	query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) {
		if (failState == TQUERY_CONNECT_FAILED) log_to_file("cod_mod.log", "[CoD Clans] Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("cod_mod.log", "[CoD Clans] Query failed. [%d] %s", errorNum, error);
	}
	
	return PLUGIN_CONTINUE;
}

public save_clan(clan)
{
	static queryData[512], safeClanName[64], codClan[clanInfo];
	
	ArrayGetArray(codClans, clan, codClan);

	cod_sql_string(codClan[CLAN_NAME], safeClanName, charsmax(safeClanName));
	
	formatex(queryData, charsmax(queryData), "UPDATE `cod_clans` SET name = '%s', level = '%i', honor = '%i', kills = '%i', members = '%i', health = '%i', gravity = '%i', weapondrop = '%i', damage = '%i' WHERE name = '%s'", 
	safeClanName, codClan[CLAN_LEVEL], codClan[CLAN_HONOR], codClan[CLAN_KILLS], codClan[CLAN_MEMBERS], codClan[CLAN_HEALTH], codClan[CLAN_GRAVITY], codClan[CLAN_DROP], codClan[CLAN_DAMAGE], safeClanName);
	
	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public load_data(id)
{
	if (!sqlConnected) {
		set_task(1.0, "load_data", id);

		return;
	}

	new queryData[192], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.flag, b.* FROM `cod_clans_members` a JOIN `cod_clans` b ON a.clan = b.id WHERE a.name = '%s'", playerName[id]);
	SQL_ThreadQuery(sql, "load_data_handle", queryData, tempId, sizeof(tempId));
}

public load_data_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if (failState) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new id = tempId[0];
	
	if (SQL_MoreResults(query)) {
		new codClan[clanInfo];

		codClan[CLAN_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));

		if (!check_clan_loaded(codClan[CLAN_ID]))
		{
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), codClan[CLAN_NAME], charsmax(codClan[CLAN_NAME]));

			codClan[CLAN_LEVEL] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "level"));
			codClan[CLAN_HONOR] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "honor"));
			codClan[CLAN_HEALTH] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "health"));
			codClan[CLAN_GRAVITY] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "gravity"));
			codClan[CLAN_DROP] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "weapondrop"));
			codClan[CLAN_DAMAGE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "damage"));
			codClan[CLAN_KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "kills"));
			codClan[CLAN_MEMBERS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "members"));
			codClan[CLAN_STATUS] = _:TrieCreate();

			ArrayPushArray(codClans, codClan);
		}
		
		clan[id] = codClan[CLAN_ID];

		new status = SQL_ReadResult(query, SQL_FieldNameToNum(query, "flag"));

		cod_set_user_bonus_health(id, cod_get_user_bonus_health(id) + get_clan_info(clan[id], CLAN_HEALTH) * cvarHealthPerLevel);

		TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);
	} else {
		new queryData[128];

		formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO `cod_clans_members` (`name`) VALUES ('%s');", playerName[id]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}
}

public _cod_get_user_clan(id)
	return clan[id];

public _cod_get_clan_name(clanId, dataReturn[], dataLength)
{
	param_convert(2);

	get_clan_info(clanId, CLAN_NAME, dataReturn, dataLength);
}

stock save_member(id, status = 0, change = 0, const name[] = "")
{
	new queryData[128], safeName[64];

	if (strlen(name)) cod_sql_string(name, safeName, charsmax(safeName));
	else copy(safeName, charsmax(safeName), playerName[id]);

	if (status) {
		if (change) formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET clan = '%i', flag = '%i' WHERE name = '%s'", clan[id], status, safeName);
		else formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET flag = '%i' WHERE name = '%s'", status, safeName);
	} else formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET clan = '0', flag = '0', honor = '0' WHERE name = '%s'", safeName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if (change) remove_applications(id, safeName);
}

stock add_deposited_honor(id, honor)
{
	new queryData[128];

	formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET honor = honor + %d WHERE name = '%s'", honor, playerName[id]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock add_application(id, clanId)
{
	new queryData[128], userName[32];

	formatex(queryData, charsmax(queryData), "INSERT INTO `cod_clans_applications` (`name`, `clan`) VALUES ('%s', '%i');", playerName[id], clanId);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	get_user_name(id, userName, charsmax(userName));

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		if (!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i) || clan[i] != clanId || get_user_status(i) <= STATUS_MEMBER) continue;

		cod_print_chat(i, "^x03%s^x01 zlozyl podanie do klanu!", userName);
	}
}

stock check_applications(id, clanId)
{
	new queryData[128], error[128], errorNum, bool:foundApplication;
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_applications` WHERE `name` = '%s' AND clan = '%i'", playerName[id], clanId);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s", error);
		
		return false;
	}
	
	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	if (SQL_NumResults(query)) foundApplication = true;

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
	
	return foundApplication;
}

stock accept_application(id, const userName[])
{
	new player = get_user_index(userName);

	if (is_user_connected(player)) {
		new clanName[64];

		get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));

		set_user_clan(player, clan[id]);

		cod_print_chat(player, "Zostales przyjety do klanu^x03 %s^x01!", clanName);
	} else {
		set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) + 1);

		save_member(id, STATUS_MEMBER, 1, userName);
	}

	remove_applications(id, userName);
}

stock remove_application(id, const name[] = "")
{
	new player = get_user_index(name);

	if (is_user_connected(player)) {
		new clanName[64], userName[32];

		get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));
		get_user_name(id, userName, charsmax(userName));

		cod_print_chat(player, "^x03%s^x01 odrzucil twoje podanie do klanu^x03 %s^x01!", userName, clanName);
	}

	new queryData[128], safeName[64];

	if (strlen(name)) cod_sql_string(name, safeName, charsmax(safeName));
	else copy(safeName, charsmax(safeName), playerName[id]);

	formatex(queryData, charsmax(queryData), "DELETE FROM `cod_clans_applications` WHERE name = '%s' AND clan = '%i'", safeName, clan[id]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock remove_applications(id, const name[] = "")
{
	new queryData[128], safeName[64];

	if (strlen(name)) cod_sql_string(name, safeName, charsmax(safeName));
	else copy(safeName, charsmax(safeName), playerName[id]);

	formatex(queryData, charsmax(queryData), "DELETE FROM `cod_clans_applications` WHERE name = '%s'", safeName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock get_applications_count(clan)
{
	new queryData[128],error[128], errorNum, applicationsCount = 0;
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_applications` WHERE `clan` = '%i'", clan);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s", error);
		
		return 0;
	}
	
	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	while (SQL_MoreResults(query)) {
		applicationsCount++;

		SQL_NextRow(query);
	}

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
	
	return applicationsCount;
}

stock check_clan_name(const clanName[])
{
	new queryData[128], safeClanName[64], error[128], errorNum, bool:foundClan;

	cod_sql_string(clanName, safeClanName, charsmax(safeClanName));
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans` WHERE `name` = '%s'", safeClanName);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s", error);
		
		return false;
	}
	
	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	if (SQL_NumResults(query)) foundClan = true;

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
	
	return foundClan;
}

stock check_user_clan(const userName[])
{
	new queryData[128], safeUserName[64], error[128], errorNum, bool:foundClan;

	cod_sql_string(userName, safeUserName, charsmax(safeUserName));
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_members` WHERE `name` = '%s' AND clan > 0", userName);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s", error);
		
		return false;
	}
	
	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	if (SQL_NumResults(query)) foundClan = true;

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
	
	return foundClan;
}

stock create_clan(id, const clanName[])
{
	new codClan[clanInfo], queryData[128], safeClanName[64], error[128], errorNum;

	cod_sql_string(clanName, safeClanName, charsmax(safeClanName));
	
	formatex(queryData, charsmax(queryData), "INSERT INTO `cod_clans` (`name`) VALUES ('%s');", safeClanName);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s", error);
		
		return;
	}

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "SELECT id FROM `cod_clans` WHERE name = '%s';", safeClanName);
	
	connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if (errorNum) {
		log_to_file("cod_mod.log", "[CoD Clans] SQL Error: %s", error);
		
		return;
	}

	query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	if (SQL_NumResults(query)) clan[id] = SQL_ReadResult(query, 0);

	copy(codClan[CLAN_NAME], charsmax(codClan[CLAN_NAME]), clanName);
	codClan[CLAN_STATUS] = _:TrieCreate();
	codClan[CLAN_ID] = clan[id];
	
	ArrayPushArray(codClans, codClan);

	set_user_clan(id, clan[id], 1);
	set_user_status(id, STATUS_LEADER);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

stock remove_clan(id)
{
	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (!is_user_connected(player) || is_user_hltv(player) || is_user_bot(id) || player == id) continue;

		if (clan[player] == clan[id]) {
			clan[player] = 0;
		
			cod_print_chat(player, "Twoj klan zostal rozwiazany.");
		}
	}

	ArrayDeleteItem(codClans, get_clan_id(clan[id]));

	clan[id] = 0;

	new queryData[128];
			
	formatex(queryData, charsmax(queryData), "DELETE FROM `cod_clans` WHERE id = '%i'", clan[id]);
	SQL_ThreadQuery(sql, "ignore_handle", queryData);
	
	formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET flag = '0', clan = '0' WHERE clan = '%i'", clan[id]);
	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock check_clan_loaded(clan)
{
	static codClan[clanInfo];
	
	for (new i = 1; i < ArraySize(codClans); i++) {
		ArrayGetArray(codClans, i, codClan);
		
		if (clan == codClan[CLAN_ID]) return true;
	}
	
	return false;
}

stock get_clan_id(clan)
{
	static codClan[clanInfo];
	
	for (new i = 1; i < ArraySize(codClans); i++) {
		ArrayGetArray(codClans, i, codClan);
		
		if (clan == codClan[CLAN_ID]) return i;
	}
	
	return 0;
}

stock get_clan_info(clan, info, dataReturn[] = "", dataLength = 0)
{
	static codClan[clanInfo];

	for (new i = 0; i < ArraySize(codClans); i++) {
		ArrayGetArray(codClans, i, codClan);
		
		if (codClan[CLAN_ID] != clan) continue;
	
		if (info == CLAN_NAME) {
			copy(dataReturn, dataLength, codClan[info]);
		
			return 0;
		}

		return codClan[info];
	}

	return 0;
}

stock set_clan_info(clan, info, value = 0, dataSet[] = "", dataLength = 0)
{
	static codClan[clanInfo];

	for (new i = 1; i < ArraySize(codClans); i++) {
		ArrayGetArray(codClans, i, codClan);

		if (codClan[CLAN_ID] != clan) continue;

		if (info == CLAN_NAME) formatex(codClan[info], dataLength, dataSet);
		else codClan[info] = value;

		ArraySetArray(codClans, i, codClan);

		save_clan(i);

		break;
	}
}