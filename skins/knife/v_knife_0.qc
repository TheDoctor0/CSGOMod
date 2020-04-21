// Start of QC script.

$modelname "v_knife_0.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "studio" "leet-1"
$body "studio" "leet-2"
$body "studio" "leet-3"
$body "studio" "leet-4"

$bodygroup "skins"
{
studio "smd\blue_steel"
studio "smd\boreal_forest"
studio "smd\case_hardened"
studio "smd\crimson_web"
studio "smd\fade"
studio "smd\forest_ddpat"
studio "smd\night_stripe"
studio "smd\safari_mesh"
studio "smd\scorched"
studio "smd\slaughter"
studio "smd\stained"
studio "smd\urban_masked"
// end
}

// 12 hit box(es)
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.470000 -3.330000 -2.140000 9.510000 2.560000 2.250000
$hbox 0 "v_weapon.Bip01_R_Hand" -0.530000 -1.530000 -2.210000 3.799523 1.050000 1.630000
$hbox 0 "v_weapon.Bip01_R_Finger0" 0.000000 -0.720000 -0.620000 1.263882 0.610000 0.810000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.770000 -0.530000 1.730000 0.310000 0.520000
$hbox 0 "v_weapon.Bip01_R_Finger1" -0.240000 -0.720000 -0.600000 1.433453 0.350000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" -0.290000 -0.610000 -0.850000 0.970000 0.410000 0.230000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.470000 -3.330000 -2.250000 9.510000 2.560000 2.140000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.530000 -1.530000 -1.630000 3.799559 1.050000 2.210000
$hbox 0 "v_weapon.Bip01_L_Finger0" 0.000000 -0.720000 -0.810000 1.263886 0.610000 0.620000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.770000 -0.520000 1.730000 0.310000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger1" -0.240000 -0.720000 -0.450000 1.433428 0.350000 0.600000
$hbox 0 "v_weapon.Bip01_L_Finger4" -0.290000 -0.610000 -0.230000 0.970000 0.410000 0.850000

// 10 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "slash1" "slash1" fps 30
$sequence "slash2" "slash2" fps 30
$sequence "draw" "draw" fps 30
$sequence "stab" "stab" fps 30
$sequence "stab_miss" "stab_miss" fps 30
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30
$sequence "inspect_1" "inspect_1" fps 30
$sequence "inspect_2" "inspect_2" fps 30

// End of QC script.
