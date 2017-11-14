// ========================================================================= CONFIG START =========================================================================

// Radius in units from smoke grenade where smoke can be created. Float number type is needed
#define SMOKE_MAX_RADIUS 144.0 // default: (144.0)

// Number of smoke puffs what will be created every 0.1sec from one grenade (the higher this value is - the higher is ability of getting svc_bad errors)
#define SMOKE_PUFFS_PER_THINK 3 // default: (5)

// How long smoke will stay on until it disappears (in seconds). NOTE: Counter-Strike default is 25.0
#define SMOKE_LIFE_TIME 18.0 // default (18.0)

// ========================================================================== CONFIG END ==========================================================================

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME	"CS:GO Smoke"
#define PLUGIN_VERSION	"1.5"
#define PLUGIN_AUTHOR	"Numb & O'Zone"

#define SGF1 ADMIN_CVAR
#define SGF2 ADMIN_MAP
#define SGF3 ADMIN_SLAY
#define SGF4 ADMIN_BAN
#define SGF5 ADMIN_KICK
#define SGF6 ADMIN_RESERVATION
#define SGF7 ADMIN_IMMUNITY

new g_iSpriteWhite;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_forward(FM_SetModel, "FM_SetModel_Pre", 0);
	
	RegisterHam(Ham_Think, "grenade", "Ham_Think_grenade_Pre", 0);
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
	
	if(contain(integer28Cells, "sprites/smoke_csgo.spr"))
	{
		g_iSpriteWhite = precache_model(integer28Cells);
		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, integer28Cells);
	}
	else
	{
		g_iSpriteWhite = precache_model("sprites/smoke_csgo.spr");
		force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, "sprites/smoke_csgo.spr");
	}
}

public FM_SetModel_Pre(iEnt, iModel[])
{
	if(pev_valid(iEnt))
	{
		static s_iClassName[9];
		pev(iEnt, pev_classname, s_iClassName, 8);
		
		if(equal(s_iClassName, "grenade") && equal(iModel, "models/w_smokegrenade.mdl")) set_pev(iEnt, pev_iuser3, 678);
	}
}

public Ham_Think_grenade_Pre(iEnt)
{
	if(pev(iEnt, pev_iuser3) == 678)
	{
		static Float:s_fDmgTime, Float:s_fGameTime;

		pev(iEnt, pev_dmgtime, s_fDmgTime);
		global_get(glb_time, s_fGameTime);
		
		if(s_fGameTime>=s_fDmgTime)
		{
			set_pev(iEnt, pev_dmgtime, (s_fGameTime+SMOKE_LIFE_TIME));
			if(!pev(iEnt, pev_iuser4))
			{
				emit_sound(iEnt, CHAN_WEAPON, "weapons/sg_explode.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_pev(iEnt, pev_iuser4, 1);
			}
			else set_pev(iEnt, pev_flags, (pev(iEnt, pev_flags)|FL_KILLME));
		}
		else if(!pev(iEnt, pev_iuser4)) return HAM_IGNORED;
		
		static Float:s_fOrigin[3], Float:s_fEndOrigin[3];

		pev(iEnt, pev_origin, s_fOrigin);
		s_fEndOrigin = s_fOrigin;
		s_fEndOrigin[2] += random_float(8.0, 32.0);
		
		static Float:s_fFraction;

		engfunc(EngFunc_TraceLine, s_fOrigin, s_fEndOrigin, IGNORE_MONSTERS, iEnt, 0);
		get_tr2(0, TR_flFraction, s_fFraction);
		
		if(s_fFraction!=1.0) get_tr2(0, TR_pHit, s_fOrigin);
		else s_fOrigin = s_fEndOrigin;
		
		static s_iLoopId, Float:s_fDistance;

		for(s_iLoopId = 0; s_iLoopId < SMOKE_PUFFS_PER_THINK; s_iLoopId++)
		{
			s_fEndOrigin[0] = random_float((random(2) ? -50.0 : -80.0), 0.0);
			s_fEndOrigin[1] = random_float((s_iLoopId*(360.0 / SMOKE_PUFFS_PER_THINK)), ((s_iLoopId + 1) * (360.0 / SMOKE_PUFFS_PER_THINK)));
			s_fEndOrigin[2] = -20.0;

			while(s_fEndOrigin[1] > 180.0) s_fEndOrigin[1] -= 360.0;
			
			engfunc(EngFunc_MakeVectors, s_fEndOrigin);
			global_get(glb_v_forward, s_fEndOrigin);

			s_fEndOrigin[0] *= 9999.0;
			s_fEndOrigin[1] *= 9999.0;
			s_fEndOrigin[2] *= 9999.0;
			s_fEndOrigin[0] += s_fOrigin[0];
			s_fEndOrigin[1] += s_fOrigin[1];
			s_fEndOrigin[2] += s_fOrigin[2];
			
			engfunc(EngFunc_TraceLine, s_fOrigin, s_fEndOrigin, IGNORE_MONSTERS, iEnt, 0);
			get_tr2(0, TR_vecEndPos, s_fEndOrigin);
			
			if((s_fDistance=get_distance_f(s_fOrigin, s_fEndOrigin)) > (s_fFraction = (random(3) ? random_float((SMOKE_MAX_RADIUS * 0.5), SMOKE_MAX_RADIUS) : random_float(16.0, SMOKE_MAX_RADIUS))))
			{
				s_fFraction /= s_fDistance;
				
				if(s_fEndOrigin[0]!=s_fOrigin[0])
				{
					s_fDistance = (s_fEndOrigin[0]-s_fOrigin[0])*s_fFraction;
					s_fEndOrigin[0] = (s_fOrigin[0]+s_fDistance);
				}
				if(s_fEndOrigin[1]!=s_fOrigin[1])
				{
					s_fDistance = (s_fEndOrigin[1]-s_fOrigin[1])*s_fFraction;
					s_fEndOrigin[1] = (s_fOrigin[1]+s_fDistance);
				}
				if(s_fEndOrigin[2]!=s_fOrigin[2])
				{
					s_fDistance = (s_fEndOrigin[2]-s_fOrigin[2])*s_fFraction;
					s_fEndOrigin[2] = (s_fOrigin[2]+s_fDistance);
				}
			}
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);

			write_byte(TE_SPRITE);
			engfunc(EngFunc_WriteCoord, s_fEndOrigin[0]);
			engfunc(EngFunc_WriteCoord, s_fEndOrigin[1]);
			engfunc(EngFunc_WriteCoord, s_fEndOrigin[2]);
			write_short(g_iSpriteWhite);
			write_byte(random_num(18, 22));
			write_byte(127);
			message_end();
		}
	}
	
	return HAM_IGNORED;
}
