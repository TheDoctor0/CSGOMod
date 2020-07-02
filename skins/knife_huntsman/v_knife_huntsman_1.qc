// Start of QC script.

$modelname "v_knife_huntsman_1.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "studio" "t_arms_01"
$body "studio" "t_arms_02"
$body "studio" "t_arms_03"
$body "studio" "t_arms_04"
$body "studio" "t_arms_05"

$bodygroup "skins"
{
studio "smd\gamma_doppler_phase_1"
studio "smd\gamma_doppler_phase_2"
studio "smd\gamma_doppler_phase_3"
studio "smd\gamma_doppler_phase_4"
studio "smd\hyperbeast"
studio "smd\knife_huntsman_case_hardened"
studio "smd\knife_huntsman_crimson_web"
studio "smd\knife_huntsman_fade"
studio "smd\knife_huntsman_fade2"
studio "smd\knife_huntsman_night"
studio "smd\knife_huntsman_safari_mesh"
studio "smd\knife_huntsman_slaughter"
studio "smd\knife_huntsman_stained"
studio "smd\marble_fade"
studio "smd\musgravite_doppler"
studio "smd\night"
studio "smd\purple"
studio "smd\rhodonite_phase_1"
studio "smd\ruby"
studio "smd\rust_coat"
studio "smd\safarimesh"
studio "smd\sapphire"
studio "smd\scorched"
studio "smd\slaughter"
studio "smd\stained"
studio "smd\stickerbomb"
studio "smd\tiger_tooth"
studio "smd\tiger_tooth_2"
studio "smd\ultraviolet"
studio "smd\urban_masked"
// end
}

// 23 hit box(es)
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.570000 -3.110000 -2.200000 10.250000 2.770000 2.680000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.550000 -1.370000 -2.020000 4.500000 1.290000 2.320000
$hbox 0 "v_weapon.Bip01_L_Finger0" -0.820000 -0.870000 -1.250000 2.060000 1.410000 0.710000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.800000 -0.830000 1.440000 0.630000 0.600000
$hbox 0 "v_weapon.Bip01_L_Finger02" 0.000000 -0.690000 -0.640000 1.420000 0.460000 0.580000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.740000 -0.790000 1.580000 0.520000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.850000 -0.620000 1.870000 0.580000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.580000 -0.300000 1.250000 0.620000 0.790000
$hbox 0 "v_weapon.Bip01_L_Finger11" 0.000000 -0.600000 -0.610000 1.130000 0.570000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger21" 0.000000 -0.650000 -0.620000 1.040000 0.460000 0.480000
$hbox 0 "v_weapon.Bip01_L_Finger31" -0.010000 -0.640000 -0.500000 1.030000 0.530000 0.570000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.570000 -3.110000 -2.680000 10.250000 2.770000 2.200000
$hbox 0 "v_weapon.Bip01_R_Hand" -0.560000 -1.360000 -2.310000 4.510000 1.290000 2.030000
$hbox 0 "v_weapon.Bip01_R_Finger0" -0.820000 -0.870000 -0.710000 2.060000 1.410000 1.250000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.800000 -0.610000 1.430000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.740000 -0.500000 1.570000 0.530000 0.790000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.840000 -0.490000 1.860000 0.570000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.800000 -0.570000 1.530000 0.600000 0.440000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.580000 -0.780000 1.250000 0.610000 0.300000
$hbox 0 "v_weapon.Bip01_R_Finger02" 0.000000 -0.670000 -0.600000 1.440000 0.470000 0.640000
$hbox 0 "v_weapon.Bip01_R_Finger11" -0.010000 -0.590000 -0.490000 1.120000 0.580000 0.610000
$hbox 0 "v_weapon.Bip01_R_Finger21" 0.000000 -0.650000 -0.480000 1.030000 0.460000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger31" -0.020000 -0.650000 -0.560000 1.030000 0.530000 0.500000

// 11 animation sequence(s)
$sequence "idle" "idle" fps 26 loop
$sequence "slash1" "slash1" fps 26
$sequence "slash2" "slash2" fps 26
$sequence "draw" "draw" fps 26
$sequence "stab" "stab" fps 26
$sequence "stab_miss" "stab_miss" fps 26
$sequence "midslash1" "midslash1" fps 26
$sequence "midslash2" "midslash2" fps 26
$sequence "inspect" "inspect" fps 26
$sequence "inspect2" "inspect2" fps 26
$sequence "inspect3" "inspect3" fps 26

// End of QC script.
