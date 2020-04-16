#include <amxmodx>
#include <hamsandwich>

native cs_set_viewmodel_body(id, body);
native cs_get_viewmodel_body(id);

stock m_pActiveItem = 373;

#define SKINS 40

new skin[MAX_PLAYERS + 1];

public plugin_init()
{
	register_clcmd("say /next", "next");
}

public client_connect(id)
	skin[id] = 0;

public next(id)
{
	if (++skin[id] >= SKINS) skin[id] = 0;

	client_print_color(id, id, "Body: %i", skin[id]);

	cs_set_viewmodel_body(id, skin[id]);

	if (!is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}

	static weapon;

	weapon = get_pdata_cbase(id, m_pActiveItem);

	if (weapon){
		ExecuteHamB(Ham_Item_Deploy, weapon);
	}

	return PLUGIN_HANDLED;
}
