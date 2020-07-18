#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN	"CS:GO Smoke"
#define VERSION	"2.0"
#define AUTHOR	"Numb & O'Zone"

#define SMOKE_MAX_RADIUS		144.0
#define SMOKE_PUFFS_PER_THINK	5
#define SMOKE_LIFE_TIME			18.0
#define SMOKE_ID				678

#define SGF1 ADMIN_CVAR
#define SGF2 ADMIN_MAP
#define SGF3 ADMIN_SLAY
#define SGF4 ADMIN_BAN
#define SGF5 ADMIN_KICK
#define SGF6 ADMIN_RESERVATION
#define SGF7 ADMIN_IMMUNITY

new spriteWhite;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_SetModel, "set_model", 0);

	RegisterHam(Ham_Think, "grenade", "think_grenade", 0);
}

public plugin_precache()
{
	new integer28Cells[28];

	integer28Cells[0]  = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[1]  = (SGF3|SGF2|SGF1);
	integer28Cells[2]  = (SGF6|SGF3|SGF2|SGF1);
	integer28Cells[3]  = (SGF7|SGF4|SGF2|SGF1);
	integer28Cells[4]  = (SGF5|SGF3|SGF2|SGF1);
	integer28Cells[5]  = (SGF7|SGF5|SGF2|SGF1);
	integer28Cells[6]  = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[7]  = (SGF7|SGF6|SGF5|SGF4|SGF2);
	integer28Cells[8]  = (SGF6|SGF5|SGF2|SGF1);
	integer28Cells[9]  = (SGF7|SGF2|SGF1);
	integer28Cells[10] = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[11] = (SGF5|SGF3|SGF2|SGF1);
	integer28Cells[12] = (SGF7|SGF6|SGF5|SGF4|SGF3|SGF1);
	integer28Cells[13] = (SGF7|SGF6|SGF5|SGF3|SGF2|SGF1);
	integer28Cells[14] = (SGF7|SGF2|SGF1);
	integer28Cells[15] = (SGF5|SGF4|SGF2|SGF1);
	integer28Cells[16] = (SGF5|SGF4|SGF2|SGF1);
	integer28Cells[17] = (SGF3|SGF2|SGF1);
	integer28Cells[18] = (SGF7|SGF5|SGF3|SGF2|SGF1);
	integer28Cells[19] = (SGF6|SGF5|SGF2|SGF1);
	integer28Cells[20] = (SGF6|SGF5|SGF2|SGF1);
	integer28Cells[21] = (SGF7|SGF3|SGF2);
	integer28Cells[22] = (SGF6|SGF5|SGF4|SGF2);
	integer28Cells[23] = (SGF7|SGF6|SGF3|SGF2|SGF1);
	integer28Cells[24] = (SGF3|SGF2|SGF1);
	integer28Cells[25] = (SGF6|SGF3|SGF2|SGF1);

	if (contain(integer28Cells, "sprites/smoke_csgo.spr")) {
		spriteWhite = precache_model(integer28Cells);

		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, integer28Cells);
	} else {
		spriteWhite = precache_model("sprites/smoke_csgo.spr");

		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, "sprites/smoke_csgo.spr");
	}
}

public set_model(ent, model[])
{
	if (pev_valid(ent)) {
		static className[9];

		pev(ent, pev_classname, className, charsmax(className));

		if (equal(className, "grenade") && containi(model, "smokegrenade") != -1) {
			set_pev(ent, pev_iuser3, SMOKE_ID);
		}
	}
}

public think_grenade(ent)
{
	if (pev(ent, pev_iuser3) == SMOKE_ID) {
		static Float:damageTime, Float:gameTime;

		pev(ent, pev_dmgtime, damageTime);
		global_get(glb_time, gameTime);

		if (gameTime >= damageTime) {
			set_pev(ent, pev_dmgtime, (gameTime + SMOKE_LIFE_TIME));

			if (!pev(ent, pev_iuser4)) {
				emit_sound(ent, CHAN_WEAPON, "weapons/sg_explode.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_pev(ent, pev_iuser4, 1);
			} else {
				set_pev(ent, pev_flags, (pev(ent, pev_flags) | FL_KILLME));
			}
		} else if(!pev(ent, pev_iuser4)) {
			return HAM_IGNORED;
		}

		static Float:origin[3], Float:newOrigin[3], Float:fraction;

		pev(ent, pev_origin, origin);

		newOrigin = origin;
		newOrigin[2] += random_float(8.0, 32.0);

		engfunc(EngFunc_TraceLine, origin, newOrigin, IGNORE_MONSTERS, ent, 0);
		get_tr2(0, TR_flFraction, fraction);

		if (fraction != 1.0) get_tr2(0, TR_pHit, origin);
		else origin = newOrigin;

		static counter, Float:distance;

		for (counter = 0; counter < SMOKE_PUFFS_PER_THINK; counter++) {
			newOrigin[0] = random_float((random(2) ? -50.0 : -80.0), 0.0);
			newOrigin[1] = random_float((counter * (360.0 / SMOKE_PUFFS_PER_THINK)), ((counter + 1) * (360.0 / SMOKE_PUFFS_PER_THINK)));
			newOrigin[2] = -30.0;

			while (newOrigin[1] > 180.0) newOrigin[1] -= 360.0;

			engfunc(EngFunc_MakeVectors, newOrigin);
			global_get(glb_v_forward, newOrigin);

			newOrigin[0] *= 9999.0;
			newOrigin[1] *= 9999.0;
			newOrigin[2] *= 9999.0;
			newOrigin[0] += origin[0];
			newOrigin[1] += origin[1];
			newOrigin[2] += origin[2];

			engfunc(EngFunc_TraceLine, origin, newOrigin, IGNORE_MONSTERS, ent, 0);
			get_tr2(0, TR_vecEndPos, newOrigin);

			if ((distance = get_distance_f(origin, newOrigin)) > (fraction = (random(3) ? random_float((SMOKE_MAX_RADIUS * 0.5), SMOKE_MAX_RADIUS) : random_float(16.0, SMOKE_MAX_RADIUS)))) {
				fraction /= distance;

				if (newOrigin[0] != origin[0]) {
					distance = (newOrigin[0] - origin[0]) * fraction;
					newOrigin[0] = (origin[0] + distance);
				}

				if (newOrigin[1] != origin[1]) {
					distance = (newOrigin[1] - origin[1]) * fraction;
					newOrigin[1] = (origin[1] + distance);
				}

				if (newOrigin[2] != origin[2]) {
					distance = (newOrigin[2] - origin[2]) * fraction;
					newOrigin[2] = (origin[2] + distance);
				}
			}

			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);

			write_byte(TE_SPRITE);
			engfunc(EngFunc_WriteCoord, newOrigin[0]);
			engfunc(EngFunc_WriteCoord, newOrigin[1]);
			engfunc(EngFunc_WriteCoord, newOrigin[2]);
			write_short(spriteWhite);
			write_byte(random_num(18, 22));
			write_byte(127);
			message_end();
		}
	}

	return HAM_IGNORED;
}
