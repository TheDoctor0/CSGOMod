// Start of QC script.

$modelname "v_knife_bayonet_0.mdl"
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
studio "template"
studio "smd\autotronic"
studio "smd\black_laminate"
studio "smd\blue_steel"
studio "smd\boreal_forest"
studio "smd\bright_water"
studio "smd\case_hardened"
studio "smd\crimson_web"
studio "smd\damascus_steel"
studio "smd\doppler_black_pearl"
studio "smd\doppler_phase_1"
studio "smd\doppler_phase_2"
studio "smd\doppler_phase_3"
studio "smd\doppler_phase_4"
studio "smd\doppler_ruby"
studio "smd\doppler_saphire"
studio "smd\fade"
studio "smd\forest_ddpat"
studio "smd\freehand"
studio "smd\gamma_doppler"
studio "smd\gamma_doppler_emerald"
studio "smd\lore"
// end
}

// 22 hit box(es)
$hbox 0 "v_weapon.Bip01_R_Hand" -0.390000 -1.560000 -2.350000 4.540000 1.360000 2.050000
$hbox 0 "v_weapon.Bip01_R_Finger0" -0.960000 -0.980000 -0.780000 1.760000 1.490000 1.240000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.800000 -0.610000 1.260000 0.570000 0.790000
$hbox 0 "v_weapon.Bip01_R_Finger02" -0.040000 -0.690000 -0.600000 1.430000 0.440000 0.650000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.670000 -0.530000 1.470000 0.550000 0.800000
$hbox 0 "v_weapon.Bip01_R_Finger11" 0.000000 -0.600000 -0.500000 1.240000 0.580000 0.570000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.890000 -0.460000 1.800000 0.570000 0.610000
$hbox 0 "v_weapon.Bip01_R_Finger21" 0.000000 -0.620000 -0.480000 1.008842 0.490000 0.550000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.810000 -0.570000 1.510000 0.570000 0.440000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.540000 -0.780000 1.080000 0.660000 0.290000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.560000 -3.110000 -2.690000 10.260000 2.760000 2.200000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.560000 -3.100000 -2.190000 10.260000 2.760000 2.680000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.400000 -1.550000 -2.060000 4.520000 1.370000 2.330000
$hbox 0 "v_weapon.Bip01_L_Finger0" -0.960000 -0.960000 -1.250000 1.740000 1.490000 0.800000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.790000 -0.790000 1.250000 0.580000 0.610000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.540000 -0.310000 1.090000 0.670000 0.760000
$hbox 0 "v_weapon.Bip01_L_Finger02" -0.030000 -0.700000 -0.650000 1.430000 0.430000 0.600000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.660000 -0.780000 1.460000 0.550000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger11" 0.000000 -0.590000 -0.560000 1.250000 0.590000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.900000 -0.610000 1.800000 0.580000 0.460000
$hbox 0 "v_weapon.Bip01_L_Finger21" 0.000000 -0.610000 -0.550000 1.008841 0.490000 0.470000
$hbox 0 "v_weapon.knife" -0.630000 -3.670000 -1.840000 0.650000 10.820000 1.230000

// 11 animation sequence(s)
$sequence "idle" "idle" fps 30 loop
$sequence "slash1" "slash1" fps 30
$sequence "slash2" "slash2" fps 30
$sequence "draw" "draw" fps 23
$sequence "backstab" "backstab" fps 30
$sequence "heavy_miss" "heavy_miss" fps 30
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30
$sequence "inspect_1" "inspect_1" fps 30
$sequence "inspect_2" "inspect_2" fps 30
$sequence "inspect_3" "inspect_3" fps 30

// End of QC script.
