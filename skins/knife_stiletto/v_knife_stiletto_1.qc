// Start of QC script.

$modelname "v_knife_stiletto_1.mdl"
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
studio "smd\snek"
studio "smd\space"
studio "smd\stained"
studio "smd\tiger_tooth"
studio "smd\toxic"
studio "smd\ultraviolet"
studio "smd\urban_masked"
studio "smd\waves"
// end
}

// 19 hit box(es)
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.560000 -3.100000 -2.670000 10.270000 2.770000 2.200000
$hbox 0 "v_weapon.Bip01_R_Hand" -0.420000 -1.650000 -2.380000 4.500000 1.210000 2.020000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.560000 -3.100000 -2.210000 10.300000 2.770000 2.670000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.680000 -1.650000 -1.990000 4.500000 1.180000 2.340000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.100000 -0.940000 -0.820000 1.850000 1.450000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.730000 -0.560000 1.430000 0.480000 0.760000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.670000 -0.510000 1.580000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.740000 -0.520000 1.850000 0.660000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.720000 -0.630000 1.630000 0.630000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.560000 -0.710000 1.190000 0.700000 0.370000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.110000 -0.910000 -1.050000 1.810000 1.420000 0.840000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.700000 -0.740000 1.410000 0.440000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.650000 -0.800000 1.570000 0.590000 0.470000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.720000 -0.600000 1.850000 0.620000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger3" 0.000000 -0.690000 -0.470000 1.640000 0.610000 0.600000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.540000 -0.410000 1.200000 0.670000 0.700000
$hbox 0 "v_weapon.Bip01_R_Finger02" 0.000000 -0.650000 -0.520000 1.370000 0.390000 0.620000
$hbox 0 "v_weapon.Bip01_L_Finger02" 0.000000 -0.670000 -0.600000 1.350000 0.340000 0.490000
$hbox 0 "v_weapon.knife" -0.340000 -4.430000 -0.670000 0.820000 3.300000 1.000000

// 11 animation sequence(s)
$sequence "idle" "idle" fps 30 loop
$sequence "slash1" "slash1" fps 30
$sequence "slash2" "slash2" fps 30
$sequence "draw" "draw" fps 30 { event 5004 0 "weapons\csgo\knife\knife_deploy.wav" } { event 5004 1 "weapons\csgo\knife_stilleto\stilletto_draw_01.wav" }
$sequence "stab" "stab" fps 30
$sequence "stab_miss" "stab_miss" fps 30
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30
$sequence "inspect_1" "inspect_1" fps 27 {
  { event 5004 42 "weapons\csgo\knife_stilleto\stilletto_flip_01.wav" }
  { event 5004 63 "weapons\csgo\knife_stilleto\stilletto_flip_02.wav" }
  { event 5004 81 "weapons\csgo\knife_stilleto\stilletto_flip_03.wav" }
  { event 5004 97 "weapons\csgo\knife_stilleto\stilletto_flip_04.wav" }
 }
$sequence "inspect_2" "inspect_2" fps 30 { event 5004 2 "weapons\csgo\movement1.wav" } { event 5004 150 "weapons\csgo\movement3.wav" }
$sequence "inspect_3" "inspect_3" fps 27 {
  { event 5004 42 "weapons\csgo\knife_stilleto\stilletto_flip_01.wav" }
  { event 5004 63 "weapons\csgo\knife_stilleto\stilletto_flip_02.wav" }
  { event 5004 81 "weapons\csgo\knife_stilleto\stilletto_flip_03.wav" }
  { event 5004 97 "weapons\csgo\knife_stilleto\stilletto_flip_04.wav" }
 }

// End of QC script.
