// Start of QC script.

$modelname "v_knife_karambit_1.mdl"
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
studio "smd\hyperbeast"
studio "smd\hyperhorse"
studio "smd\knife_karambit_abyss"
studio "smd\knife_karambit_bluesteel"
studio "smd\knife_karambit_borealforest"
studio "smd\knife_karambit_case_harden"
studio "smd\knife_karambit_crimson_web"
studio "smd\knife_karambit_damascus_steel"
studio "smd\knife_karambit_doppler_phase1"
studio "smd\knife_karambit_doppler_phase2"
studio "smd\knife_karambit_doppler_phase3"
studio "smd\knife_karambit_flame"
studio "smd\knife_karambit_forest_ddpat"
studio "smd\knife_karambit_marble_fade"
studio "smd\knife_karambit_rust_coat"
studio "smd\knife_karambit_safari_mesh"
studio "smd\knife_karambit_scorched"
studio "smd\knife_karambit_slaughter"
studio "smd\knife_karambit_stained"
studio "smd\knife_karambit_steel_dark"
studio "smd\knife_karambit_steel_light"
studio "smd\knife_karambit_tiger_tooth"
studio "smd\knife_karambit_urban_masked"
studio "smd\lava"
studio "smd\lore"
studio "smd\luminousice"
studio "smd\marble_fade"
studio "smd\neuralnet"
studio "smd\night"
studio "smd\rust_coat"
studio "smd\safari_mesh"
studio "smd\scocherd"
studio "smd\slaughter_2"
studio "smd\slaughter"
studio "smd\solarattack"
studio "smd\stained"
studio "smd\tiger_tooth"
studio "smd\ultraviolet"
studio "smd\urban_masked"
// end
}

// 21 hit box(es)
$hbox 0 "v_weapon.Bip01_R_Hand" -0.390000 -1.560000 -2.350000 4.540000 1.360000 2.050000
$hbox 0 "v_weapon.Bip01_R_Finger0" -0.960000 -0.980000 -0.780000 1.760000 1.490000 1.240000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.800000 -0.610000 1.260000 0.580000 0.790000
$hbox 0 "v_weapon.Bip01_R_Finger02" -0.040000 -0.690000 -0.600000 1.430000 0.440000 0.650000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.670000 -0.530000 1.470000 0.550000 0.800000
$hbox 0 "v_weapon.Bip01_R_Finger11" 0.000000 -0.600000 -0.500000 1.240000 0.580000 0.570000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.890000 -0.460000 1.800000 0.570000 0.610000
$hbox 0 "v_weapon.Bip01_R_Finger21" 0.000000 -0.620000 -0.480000 1.008842 0.490000 0.550000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.810000 -0.580000 1.510000 0.570000 0.440000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.540000 -0.780000 1.090000 0.660000 0.290000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.560000 -3.110000 -2.690000 10.260000 2.760000 2.210000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.560000 -3.100000 -2.190000 10.260000 2.760000 2.670000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.400000 -1.550000 -2.050000 4.520000 1.370000 2.330000
$hbox 0 "v_weapon.Bip01_L_Finger0" -0.960000 -0.960000 -1.250000 1.740000 1.490000 0.800000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.790000 -0.790000 1.250000 0.580000 0.610000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.540000 -0.300000 1.080000 0.660000 0.760000
$hbox 0 "v_weapon.Bip01_L_Finger02" -0.030000 -0.700000 -0.650000 1.430000 0.430000 0.600000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.660000 -0.780000 1.460000 0.550000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger11" 0.000000 -0.590000 -0.560000 1.250000 0.590000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.900000 -0.610000 1.800000 0.580000 0.460000
$hbox 0 "v_weapon.Bip01_L_Finger21" 0.000000 -0.610000 -0.550000 1.008841 0.490000 0.470000

// 11 animation sequence(s)
$sequence "idle" "idle" fps 26 loop
$sequence "slash1" "slash1" fps 30
$sequence "slash2" "slash2" fps 30
$sequence "draw" "draw" fps 24 { event 5004 1 "weapons/csgo/knife/knife_deploy.wav" }
$sequence "backstab" "backstab" fps 30
$sequence "heavy_miss" "heavy_miss" fps 30
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30
$sequence "inspect_1" "inspect_1" fps 30
$sequence "inspect_2" "inspect_2" fps 30
$sequence "inspect_3" "inspect_3" fps 30

// End of QC script.
