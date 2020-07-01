// Start of QC script.

$modelname "v_xm1014_0.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "hand" "t_arms_01"
$body "hand" "t_arms_02"
$body "hand" "t_arms_03"
$body "hand" "t_arms_04"
$body "hand" "t_arms_05"
$body "studio" "attachments"

$bodygroup "skins"
{
studio "smd\blactie"
studio "smd\bonemachine"
studio "smd\heavenguard"
studio "smd\scumbria"
studio "smd\stelarvandalism"
studio "smd\tecluburner"
studio "smd\tranquility"
studio "smd\tranquility2"
studio "smd\wastelandrebel"
studio "smd\ziggy"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.xm1014_Parent" 0.000000 3.800000 26.000000
$attachment 1 "v_weapon.xm1014_Parent" 0.700000 3.200000 7.000000

// 18 hit box(es)
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.300000 -3.080000 -2.200000 10.560000 2.750000 2.650000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.500000 -1.640000 -1.990000 0.680000 1.160000 2.320000
$hbox 0 "v_weapon.Bip01_R_Hand" -4.490000 -3.490000 -2.380000 20.740000 5.796158 11.887161
$hbox 0 "v_weapon.xm1014_Parent" -4.576370 -5.223464 -11.130000 1.070000 5.060000 26.030001
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.790000 -0.900000 -1.050000 1.110000 1.420000 0.820000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.400000 -0.690000 -0.740000 0.000000 0.430000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.560000 -0.650000 -0.800000 0.000000 0.570000 0.460000
$hbox 0 "v_weapon.Bip01_L_Finger2" -1.840000 -0.720000 -0.600000 0.000000 0.610000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.640000 -0.690000 -0.470000 0.000000 0.600000 0.580000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.200000 -0.530000 -0.400000 0.000000 0.660000 0.700000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.830000 -0.920000 -0.800000 0.880000 1.440000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.420000 -0.730000 -0.550000 0.000000 0.480000 0.760000
$hbox 0 "v_weapon.Bip01_R_Finger02" -1.380000 -0.630000 -0.500000 0.000000 0.390000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.570000 -0.660000 -0.510000 0.000000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" -1.830000 -0.740000 -0.500000 0.000000 0.660000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.630000 -0.710000 -0.610000 0.000000 0.610000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.200000 -0.550000 -0.690000 0.000000 0.680000 0.380000
$hbox 0 "v_weapon.xm1014_Bolt" -0.590000 -0.410000 -2.220000 1.700000 0.850000 0.600000

// 8 animation sequence(s)
$sequence "idle" "idle" fps 24
$sequence "shoot1" "shoot1" fps 40 { event 5001 0 "21" }
$sequence "shoot2" "shoot2" fps 40 { event 5001 0 "21" }
$sequence "insert" "insert" fps 28 { event 5004 4 "weapons/m3_insertshell.wav" }
$sequence "after_reload" "after_reload" fps 30 { event 5004 0 "items/cliprelease2.wav" }
$sequence "start_reload" "start_reload" fps 30 { event 5004 0 "items/cliprelease1.wav" }
$sequence "draw" "draw" fps 30 { event 5004 0 "weapons/de_deploy.wav" }
$sequence "inspect" "inspect" fps 25

// End of QC script.
