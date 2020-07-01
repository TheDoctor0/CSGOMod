// Start of QC script.

$modelname "v_knife_bowie.mdl"
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

// 19 hit box(es)
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.560000 -3.100000 -2.670000 10.270000 2.770000 2.200000
$hbox 0 "v_weapon.Bip01_R_Hand" -0.420000 -1.650000 -2.370000 4.500000 1.210000 2.020000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.560000 -3.100000 -2.210000 10.300000 2.770000 2.670000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.680000 -1.650000 -1.990000 4.500000 1.180000 2.340000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.100000 -0.950000 -0.820000 1.850000 1.450000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.730000 -0.560000 1.430000 0.480000 0.760000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.670000 -0.510000 1.580000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.740000 -0.520000 1.850000 0.660000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.720000 -0.630000 1.630000 0.630000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.560000 -0.710000 1.190000 0.700000 0.370000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.110000 -0.910000 -1.050000 1.810000 1.430000 0.840000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.700000 -0.740000 1.400000 0.440000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.650000 -0.800000 1.570000 0.590000 0.470000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.720000 -0.600000 1.850000 0.620000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger3" 0.000000 -0.690000 -0.470000 1.640000 0.610000 0.600000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.540000 -0.410000 1.200000 0.670000 0.700000
$hbox 0 "v_weapon.Bip01_R_Finger02" 0.000000 -0.650000 -0.520000 1.370000 0.390000 0.620000
$hbox 0 "v_weapon.Bip01_L_Finger02" 0.000000 -0.670000 -0.600000 1.350000 0.340000 0.490000
$hbox 0 "v_weapon.knife" -0.540000 -5.830000 -1.700000 0.550000 12.590000 2.080000

// 11 animation sequence(s)
$sequence "idle" "idle" fps 25 loop
$sequence "slash1" "slash1" fps 32
$sequence "slash2" "slash2" fps 32
$sequence "draw" "draw" fps 25 { event 5004 1 "weapons/csgo/bowie_knife/draw.wav" }
$sequence "stab" "stab" fps 25
$sequence "stab_miss" "stab_miss" fps 25
$sequence "midslash1" "midslash1" fps 32
$sequence "midslash2" "midslash2" fps 32
$sequence "inspect_1" "inspect_1" fps 25 { event 5004 6 "weapons/csgo/bowie_knife/inspect1.wav" } { event 5004 112 "weapons/csgo/bowie_knife/inspect2.wav" }
$sequence "inspect_2" "inspect_2" fps 25 { event 5004 6 "weapons/csgo/bowie_knife/inspect1.wav" } { event 5004 112 "weapons/csgo/bowie_knife/inspect2.wav" }
$sequence "inspect_3" "inspect_3" fps 25 { event 5004 6 "weapons/csgo/bowie_knife/inspect1.wav" } { event 5004 112 "weapons/csgo/bowie_knife/inspect2.wav" }

// End of QC script.
