// Start of QC script.

$modelname "v_knife_talon.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "studio" "hand_01"
$body "studio" "hand_02"
$body "studio" "hand_03"
$body "studio" "hand_04"
$body "studio" "hand_05"

$bodygroup "skins"
{
// end
}

// 16 hit box(es)
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.560000 -3.060000 -2.180000 10.270000 2.740000 2.630000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.680000 -1.640000 -1.990000 4.490000 1.140000 2.300000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.520000 -3.070000 -2.670000 10.230000 2.740000 2.200000
$hbox 0 "v_weapon.Bip01_R_Hand" -0.380000 -1.620000 -2.330000 4.480000 1.190000 2.000000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.090000 -0.880000 -1.020000 1.770000 1.390000 0.810000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.690000 -0.730000 1.390000 0.440000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.650000 -0.800000 1.540000 0.560000 0.450000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.720000 -0.600000 1.820000 0.590000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger3" 0.000000 -0.690000 -0.470000 1.630000 0.590000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.530000 -0.390000 1.190000 0.650000 0.700000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.060000 -0.950000 -0.790000 1.850000 1.440000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.690000 -0.530000 1.420000 0.480000 0.760000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.640000 -0.510000 1.560000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.710000 -0.480000 1.820000 0.640000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.690000 -0.590000 1.620000 0.620000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.540000 -0.670000 1.160000 0.670000 0.370000

// 9 animation sequence(s)
$sequence "idle" "idle" fps 20 loop
$sequence "slash1" "slash1" fps 30
$sequence "slash2" "slash2" fps 30
$sequence "draw" "draw" fps 30 { event 5004 2 "weapons/csgo/knife_widow/widow_deploy_01.wav" }
$sequence "stab" "stab" fps 30
$sequence "stab_miss" "stab_miss" fps 30
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30
$sequence "inspect" "inspect" fps 30 {
  { event 5004 10 "weapons/csgo/knife_widow/widow_lookat2_start.wav" }
  { event 5004 27 "weapons/csgo/knife_widow/widow_lookat2_loop_02.wav" }
  { event 5004 35 "weapons/csgo/knife_widow/widow_lookat2_loop_03.wav" }
  { event 5004 43 "weapons/csgo/knife_widow/widow_lookat2_loop_04.wav" }
  { event 5004 51 "weapons/csgo/knife_widow/widow_lookat2_loop_05.wav" }
  { event 5004 65 "weapons/csgo/knife_widow/widow_lookat2_end.wav" }
 }

// End of QC script.
