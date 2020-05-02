// Start of QC script.

$modelname "v_aug.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "weapon" "hands_01"
$body "weapon" "hands_02"
$body "weapon" "hands_03"
$body "weapon" "hands_04"
$body "weapon" "hands_05"
$body "weapon" "scope_01"
$body "weapon" "scope_02"
$body "weapon" "scope_03"
$body "attachments" "attachments_01"
$body "attachments" "attachments_02"

$bodygroup "skins"
{
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.aug_Parent" 0.000000 9.110000 44.209999
$attachment 1 "v_weapon.aug_Bolt" 4.000000 0.450000 -26.209999

// 37 hit box(es)
$hbox 0 "v_weapon.Bip01_L_Hand" -1.700000 -4.140000 -5.000000 11.260000 3.010000 5.900000
$hbox 0 "v_weapon.Bip01_L_Finger0" -2.780000 -2.330000 -2.660000 4.570000 3.600000 2.100000
$hbox 0 "v_weapon.Bip01_L_Finger01" 0.000000 -1.790000 -1.880000 3.560000 1.130000 1.360000
$hbox 0 "v_weapon.Bip01_L_Finger1" 0.000000 -1.630000 -2.020000 3.960000 1.510000 1.220000
$hbox 0 "v_weapon.Bip01_L_Finger2" 0.000000 -1.810000 -1.500000 4.650000 1.610000 1.430000
$hbox 0 "v_weapon.Bip01_L_Finger3" 0.000000 -1.750000 -1.210000 4.130000 1.550000 1.530000
$hbox 0 "v_weapon.Bip01_L_Finger4" 0.000000 -1.360000 -1.030000 3.000000 1.740000 1.750000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -26.450001 -7.800000 -5.530000 25.760000 6.960000 6.720000
$hbox 0 "v_weapon.Bip01_R_Hand" -1.110000 -4.140000 -5.970000 27.415302 119.983757 6.005975
$hbox 0 "v_weapon.Bip01_R_Finger0" -2.800000 -2.410000 -2.110000 4.630000 3.650000 2.740000
$hbox 0 "v_weapon.Bip01_R_Finger01" 0.000000 -1.860000 -1.430000 3.600000 1.210000 1.950000
$hbox 0 "v_weapon.Bip01_R_Finger1" 0.000000 -1.700000 -1.280000 3.980000 1.570000 2.090000
$hbox 0 "v_weapon.Bip01_R_Finger2" 0.000000 -1.880000 -1.360000 4.650000 1.680000 1.570000
$hbox 0 "v_weapon.Bip01_R_Finger3" 0.000000 -1.820000 -1.600000 4.130000 1.610000 1.150000
$hbox 0 "v_weapon.Bip01_R_Finger4" 0.000000 -1.430000 -1.810000 3.010000 1.790000 0.970000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -26.450001 -7.800000 -6.720000 25.740000 6.960000 5.530000
$hbox 0 "v_weapon.Bip01_R_Finger02" 0.000000 -1.690000 -1.330000 3.470000 0.990000 1.590000
$hbox 0 "v_weapon.Bip01_R_Finger11" 0.000000 -1.100000 -1.200000 2.970000 1.330000 1.440000
$hbox 0 "v_weapon.Bip01_R_Finger12" 0.000000 -1.010000 -1.140000 3.350000 1.030000 1.160000
$hbox 0 "v_weapon.Bip01_R_Finger21" 0.000000 -1.500000 -1.210000 2.830000 1.160000 1.230000
$hbox 0 "v_weapon.Bip01_R_Finger22" -0.080000 -1.140000 -1.190000 2.870000 1.110000 1.180000
$hbox 0 "v_weapon.Bip01_R_Finger31" 0.000000 -1.430000 -1.220000 2.500000 1.030000 1.150000
$hbox 0 "v_weapon.Bip01_R_Finger32" -0.110000 -1.200000 -1.120000 3.400000 1.000000 1.160000
$hbox 0 "v_weapon.Bip01_R_Finger41" 0.000000 -1.140000 -1.360000 2.530000 0.990000 0.920000
$hbox 0 "v_weapon.Bip01_R_Finger42" 0.000000 -0.780000 -1.030000 3.020000 1.030000 1.000000
$hbox 0 "v_weapon.Bip01_L_Finger02" 0.000000 -1.680000 -1.510000 3.390000 0.890000 1.260000
$hbox 0 "v_weapon.Bip01_L_Finger11" 0.000000 -1.030000 -1.360000 2.970000 1.250000 1.130000
$hbox 0 "v_weapon.Bip01_L_Finger12" 0.000000 -0.940000 -1.090000 3.270000 0.950000 1.070000
$hbox 0 "v_weapon.Bip01_L_Finger21" 0.000000 -1.420000 -1.150000 2.810000 1.090000 1.140000
$hbox 0 "v_weapon.Bip01_L_Finger22" -0.060000 -1.080000 -1.110000 2.800000 1.040000 1.120000
$hbox 0 "v_weapon.Bip01_L_Finger31" 0.000000 -1.360000 -1.070000 2.500000 0.950000 1.150000
$hbox 0 "v_weapon.Bip01_L_Finger32" -0.110000 -1.130000 -1.090000 3.320000 0.930000 1.050000
$hbox 0 "v_weapon.Bip01_L_Finger41" 0.000000 -1.070000 -0.840000 2.520000 0.930000 1.290000
$hbox 0 "v_weapon.Bip01_L_Finger42" 0.000000 -0.710000 -0.930000 2.950000 0.950000 0.950000
$hbox 0 "v_weapon.aug_Parent" -3.760000 -5.600000 -32.119999 3.620000 18.530001 45.540001
$hbox 0 "v_weapon.aug_Clip" -1.250000 -12.420000 -3.620000 1.250000 9.410000 6.800000
$hbox 0 "v_weapon.aug_Bolt" -0.210000 -0.580000 -1.110000 3.540000 2.950000 1.640000

// 7 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "reload" "reload" fps 28 {
  { event 5004 12 "weapons/aug_clipout.wav" }
  { event 5004 35 "weapons/aug_clipin.wav" }
  { event 5004 49 "weapons/aug_boltslap.wav" }
  { event 5004 62 "weapons/aug_boltpull.wav" }
  { event 5004 67 "weapons/aug_boltrelease.wav" }
 }
$sequence "draw" "draw" fps 28 {
  { event 5004 0 "weapons/aug_forearm.wav" }
  { event 5004 5 "weapons/aug_boltpull.wav" }
  { event 5004 10 "weapons/aug_boltrelease.wav" }
 }
$sequence "shoot1" "shoot1" fps 30 { event 5001 0 "42" }
$sequence "shoot2" "shoot2" fps 30 { event 5001 0 "42" }
$sequence "shoot3" "shoot3" fps 30 { event 5001 0 "42" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
