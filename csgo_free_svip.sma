#include <amxmodx>

#define PLUGIN "Free SVIP"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_RELOAD 8402

#define ADMIN_FLAG_X (1<<23)

native csgo_get_user_svip(id);
native csgo_set_user_svip(id);

forward amxbans_sql_initialized(info, db);

new freeSVIP;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	bind_pcvar_num(create_cvar("csgo_free_svip", "1"), freeSVIP);
}

public client_authorized(id)
{
	if (!is_user_hltv(id) && freeSVIP) {
		set_user_flags(id, get_user_flags(id) | ADMIN_FLAG_X);
			
		if (!csgo_get_user_svip(id)) csgo_set_user_svip(id);
	}
}

public amxbans_sql_initialized(info, db)
	if (freeSVIP) set_task(1.0, "SetVIP", TASK_RELOAD);

public SetVIP()
{
	for (new id = 1; id <= MAX_PLAYERS; id++) {
		if (is_user_connected(id) && !is_user_hltv(id)) {
			set_user_flags(id, get_user_flags(id) | ADMIN_FLAG_X);
			
			if (!csgo_get_user_svip(id)) csgo_set_user_svip(id);
		}
	}
}