#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fakemeta_util>
#include <xs>
#include <csgomod>

#define PLUGIN "CS:GO Weapon Physics"
#define AUTHOR "O'Zone & Nomexous"

new const persistent[][] = { "armoury_entity" };
new const spawnable[][] = { "weaponbox", "item_thighpack" };

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("HLTV", "restart", "a", "1=0", "2=0");

	register_forward(FM_TraceLine, "forward_traceline", 1);

	for (new i = 0; i < sizeof persistent; i++) {
		RegisterHam(Ham_Spawn, persistent[i], "spawn_persistent_item", 1);
		RegisterHam(Ham_Touch, persistent[i], "touch_item");
		RegisterHam(Ham_TakeDamage, persistent[i], "damage_item");
		RegisterHam(Ham_TraceAttack, persistent[i], "shoot_item");
	}

	for (new i = 0; i < sizeof spawnable; i++) {
		RegisterHam(Ham_Spawn, spawnable[i], "spawn_item", 1);
		RegisterHam(Ham_Touch, spawnable[i], "touch_item");
		RegisterHam(Ham_TakeDamage, spawnable[i], "damage_item");
		RegisterHam(Ham_TraceAttack, spawnable[i], "shoot_item");
	}
}

public restart()
{
	for (new i; i < sizeof persistent; i++) {
		new entity;

		while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", persistent[i]))) {
			static Float:origin[3], Float:angles[3];

			pev(entity, pev_vuser1, origin);
			pev(entity, pev_vuser2, angles);
			set_pev(entity, pev_angles, angles);
			set_pev(entity, pev_avelocity, Float:{0.0, 0.0, 0.0});
			engfunc(EngFunc_SetOrigin, entity, origin);
			engfunc(EngFunc_DropToFloor, entity);
		}
	}
}

public spawn_item(entity)
{
	if (!pev_valid(entity)) return HAM_IGNORED;

	static className[32];

	pev(entity, pev_classname, className, charsmax(className));

	set_pev(entity, pev_movetype, MOVETYPE_BOUNCE);
	set_pev(entity, pev_takedamage, DAMAGE_YES);
	set_pev(entity, pev_health, 100.0);

	return HAM_IGNORED;
}

public spawn_persistent_item(entity)
{
	if (!pev_valid(entity)) return HAM_IGNORED;

	set_pev(entity, pev_movetype, MOVETYPE_BOUNCE);
	set_pev(entity, pev_takedamage, DAMAGE_YES);
	set_pev(entity, pev_health, 100.0);

	new Float:origin[3], Float:angles[3];

	pev(entity, pev_origin, origin);
	pev(entity, pev_angles, angles);
	set_pev(entity, pev_vuser1, origin);
	set_pev(entity, pev_vuser2, angles);

	return HAM_IGNORED;
}

public damage_item(entity, inflictor, attacker, Float:damage, damagebits)
{
	if (pev(entity, pev_effects) & EF_NODRAW) return HAM_IGNORED;

	static Float:velocity[3], Float:entityOrigin[3], Float:inflictorOrigin[3], Float:temp[3];

	pev(entity, pev_velocity, velocity);
	pev(entity, pev_origin, entityOrigin);
	pev(inflictor, pev_origin, inflictorOrigin);

	xs_vec_sub(entityOrigin, inflictorOrigin, temp);
	xs_vec_normalize(temp, temp);
	xs_vec_mul_scalar(temp, damage, temp);
	xs_vec_mul_scalar(temp, 30.0, temp);
	xs_vec_add(velocity, temp, velocity);

	set_pev(entity, pev_velocity, velocity);

	static Float:avelocity[3];

	avelocity[1] = random_float(-1000.0, 1000.0);

	set_pev(entity, pev_avelocity, avelocity);

	SetHamParamFloat(4, 0.0);

	return HAM_HANDLED;
}

public shoot_item(entity, attacker, Float:damage, Float:direction[3], trace, damagebits)
{
	static Float:endpoint[3], Float:velocity[3];

	get_tr2(trace, TR_vecEndPos, endpoint);

	draw_spark(endpoint);

	pev(entity, pev_velocity, velocity);

	xs_vec_mul_scalar(direction, damage, direction);
	xs_vec_mul_scalar(direction, 15.0, direction);
	xs_vec_add(direction, velocity, velocity);
	set_pev(entity, pev_velocity, velocity);

	return HAM_IGNORED;
}

public touch_item(entity, touched)
{
	if (pev(touched, pev_solid) < SOLID_BBOX || is_user_alive(touched)) return HAM_IGNORED;

	if (fm_get_weaponbox_type(entity) == CSW_C4) {
		set_pev(entity, pev_movetype, MOVETYPE_TOSS);
	}

	if (!is_shootable_entity(entity)) return HAM_IGNORED;

	static Float:velocity[3];

	pev(entity, pev_velocity, velocity);

	if (xs_vec_len(velocity) > 700.0) {
		static Float:origin[3];

		pev(entity, pev_origin, origin);

		origin[0] += random_float(-10.0, 10.0);
		origin[1] += random_float(-10.0, 10.0);
		origin[2] += random_float(-10.0, 10.0);

		draw_spark(origin);

		xs_vec_mul_scalar(velocity, 0.4, velocity);
	} else {
		xs_vec_mul_scalar(velocity, 0.1, velocity);
	}

	set_pev(entity, pev_velocity, velocity);

	return HAM_IGNORED;
}

public forward_traceline(Float:start[3], Float:end[3], conditions, id, trace)
{
	if (!pev_valid(id) || !is_user_alive(id) || is_user_alive(get_tr2(trace, TR_pHit))) return FMRES_IGNORED;

	static Float:endPoint[3];

	get_tr2(trace, TR_vecEndPos, endPoint);

	new entity = 0, traceLine = 0;

	while ((entity = engfunc(EngFunc_FindEntityInSphere, entity, endPoint, 20.0))) {
		if (is_shootable_entity(entity)) {
			engfunc(EngFunc_TraceModel, start, end, HULL_POINT, entity, traceLine);

			if (pev_valid(get_tr2(traceLine, TR_pHit))) {
				get_tr2(traceLine, TR_vecEndPos, endPoint);
				set_tr2(trace, TR_vecEndPos, endPoint);

				set_tr2(trace, TR_pHit, entity);

				return FMRES_IGNORED;
			}
		}
	}

	return FMRES_IGNORED;
}

public is_shootable_entity(entity)
{
	static className[32];

	pev(entity, pev_classname, className, charsmax(className));

	if (equal(className, "weaponbox") && fm_get_weaponbox_type(entity) == CSW_C4) return false;

	for (new i; i < sizeof spawnable; i++) {
		if (equal(className, spawnable[i])) return true;
	}

	return false;
}

stock draw_spark(Float:origin[3])
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	message_end();
}
