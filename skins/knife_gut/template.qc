// Start of QC script.

$modelname "v_knife_gut.mdl"
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
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.580000 -3.120000 -2.210000 10.300000 2.780000 2.690000
$hbox 0 "v_weapon.Bip01_L_Hand" -0.680000 -1.650000 -2.000000 4.500000 1.200000 2.360000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.580000 -3.120000 -2.690000 10.290000 2.780000 2.210000
$hbox 0 "v_weapon.Bip01_R_Hand" -0.440000 -1.650000 -2.380000 4.520000 1.230000 2.030000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.120000 -0.960000 -0.840000 1.850000 1.460000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -0.740000 -0.570000 1.440000 0.480000 0.780000
$hbox 0 "v_weapon.Bip01_R_Finger02" 0.000000 -0.670000 -0.530000 1.390000 0.390000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -0.680000 -0.510000 1.590000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -0.750000 -0.540000 1.860000 0.670000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -0.730000 -0.640000 1.650000 0.640000 0.460000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -0.570000 -0.720000 1.200000 0.710000 0.380000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.110000 -0.930000 -1.060000 1.830000 1.440000 0.840000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -0.720000 -0.750000 1.420000 0.450000 0.540000
$hbox 0 "v_weapon.Bip01_L_Finger02" 0.000000 -0.670000 -0.600000 1.350000 0.350000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -0.650000 -0.810000 1.580000 0.600000 0.490000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -0.720000 -0.600000 1.860000 0.640000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger3" 0.000000 -0.700000 -0.480000 1.650000 0.620000 0.610000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -0.540000 -0.410000 1.200000 0.690000 0.700000
$hbox 0 "v_weapon.knife" -0.670000 -5.660000 -1.270000 0.680000 8.940000 1.740000

// 8 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "slash1" "slash1" fps 30
$sequence "slash2" "slash2" fps 30
$sequence "draw" "draw" fps 30
$sequence "stab" "stab" fps 30
$sequence "stab_miss" "stab_miss" fps 30
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30

// End of QC script.
