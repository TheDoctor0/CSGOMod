#include <amxmodx>
#include <shop_sms>

#define PLUGIN "Sklep-SMS: Usluga CS:GO Euro"
#define AUTHOR "O'Zone"

native csgo_add_money(id, Float:amount);

new const service_id[MAX_ID] = "euro";

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_cfg()
	ss_register_service(service_id);

public plugin_natives()
	set_native_filter("native_filter");

public ss_service_bought(id, amount)
	csgo_add_money(id, float(amount));

public native_filter(const native_name[], index, trap) 
{
	if(trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR);

		pause_plugin();

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
