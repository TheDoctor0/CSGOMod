// Start of QC script.

$modelname "v_knife_m9_bayonet.mdl"
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
// end
}

// 18 hit box(es)
$hbox 0 "v_weapon.Bip01_L_Hand" -0.620000 -1.500000 -2.100000 4.560000 1.230000 2.360000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.120000 -0.840000 -1.090000 2.020000 1.440000 0.860000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.690000 -0.760000 1.440000 0.550000 0.520000
$hbox 0 "v_weapon.Bip01_L_Finger02" 0.000000 -0.710000 -0.650000 1.400000 0.390000 0.550000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.720000 -0.800000 1.590000 0.540000 0.520000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.840000 -0.620000 1.860000 0.630000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger3" 0.000000 -0.690000 -0.440000 1.650000 0.600000 0.650000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.520000 -0.380000 1.200000 0.680000 0.780000
$hbox 0 "v_weapon.Bip01_R_Hand" -0.440000 -1.500000 -2.360000 4.560000 1.230000 2.100000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.120000 -0.840000 -0.860000 2.020000 1.440000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.680000 -0.520000 1.440000 0.550000 0.760000
$hbox 0 "v_weapon.Bip01_R_Finger02" 0.000000 -0.690000 -0.550000 1.400000 0.400000 0.650000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.720000 -0.520000 1.590000 0.540000 0.800000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.840000 -0.530000 1.860000 0.630000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.690000 -0.650000 1.650000 0.600000 0.440000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.520000 -0.780000 1.200000 0.680000 0.380000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.580000 -3.120000 -2.210000 10.280000 2.780000 2.690000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.580000 -3.120000 -2.690000 10.280000 2.780000 2.210000

// 11 animation sequence(s)
$sequence "idle" "idle" fps 30 loop
$sequence "slash1" "slash1" fps 30
$sequence "slash2" "slash2" fps 30
$sequence "draw" "draw" fps 30 { event 5004 1 "weapons/csgo/knife/knife_deploy.wav" }
$sequence "stab" "stab" fps 30
$sequence "stab_miss" "stab_miss" fps 30
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30
$sequence "inspect_1" "inspect_1" fps 38 { event 5004 1 "weapons/csgo/knife/movement1.wav" } { event 5004 155 "weapons/csgo/knife/movement2.wav" }
$sequence "inspect_2" "inspect_2" fps 38 { event 5004 1 "weapons/csgo/knife/movement1.wav" } { event 5004 155 "weapons/csgo/knife/movement2.wav" }
$sequence "inspect_3" "inspect_3" fps 38 { event 5004 1 "weapons/csgo/knife/movement1.wav" } { event 5004 155 "weapons/csgo/knife/movement2.wav" }

// End of QC script.
