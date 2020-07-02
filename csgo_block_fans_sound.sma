#include <amxmodx>
#include <fakemeta>

#define PLUGIN "CS:GO Block Fans Sound"
#define VERSION "2.0"
#define AUTHOR "O'Zone"

public plugin_init()
    register_forward(FM_EmitSound, "sound_emit");

public sound_emit(ent, channel, const sound[])
    return equal(sound, "fans/fan3.wav") ? FMRES_SUPERCEDE : FMRES_IGNORED;