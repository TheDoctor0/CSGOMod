// Start of QC script.

$modelname "v_deagle.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition -2.000000 0.000000 1.000000

//reference mesh(es)
$body "studio" "hands1"
$body "studio" "hands2"
$body "studio" "hands3"
$body "studio" "hands4"

$body "attachments" "attachments"

$bodygroup "skins"
{
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.deagle_parent" 0.000000 8.000000 23.000000
$attachment 1 "v_weapon.deagle_parent" 0.000000 9.000000 5.000000

// 37 hit box(es)
$hbox 0 "v_weapon.Bip01_L_Hand" -11.250000 -4.130000 -4.990000 1.660000 2.990000 5.880000
$hbox 0 "v_weapon.Bip01_L_Finger0" -4.560000 -2.320000 -2.650000 2.740000 3.590000 2.090000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -25.740000 -7.790000 -5.510000 26.430000 6.940000 6.710000
$hbox 0 "v_weapon.Bip01_R_Hand" -26.365955 -4.110000 -5.960000 1.110000 118.752586 6.114070
$hbox 0 "v_weapon.Bip01_R_Finger0" -4.600000 -2.390000 -2.080000 2.790000 3.640000 2.740000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -25.709999 -7.780000 -6.690000 26.420000 6.940000 5.510000
$hbox 0 "v_weapon.Bip01_L_Finger01" -3.560000 -1.780000 -1.840000 0.000000 1.120000 1.350000
$hbox 0 "v_weapon.Bip01_L_Finger02" -3.380000 -1.670000 -1.480000 0.000000 0.860000 1.250000
$hbox 0 "v_weapon.Bip01_L_Finger1" -3.950000 -1.620000 -1.980000 0.000000 1.470000 1.220000
$hbox 0 "v_weapon.Bip01_L_Finger2" -4.630000 -1.770000 -1.480000 0.000000 1.580000 1.410000
$hbox 0 "v_weapon.Bip01_L_Finger3" -4.110000 -1.730000 -1.190000 0.000000 1.520000 1.510000
$hbox 0 "v_weapon.Bip01_L_Finger4" -2.990000 -1.340000 -1.000000 0.000000 1.720000 1.730000
$hbox 0 "v_weapon.Bip01_L_Finger41" -2.500000 -1.060000 -0.820000 0.000000 0.920000 1.290000
$hbox 0 "v_weapon.Bip01_R_Finger01" -3.570000 -1.850000 -1.390000 0.000000 1.210000 1.950000
$hbox 0 "v_weapon.Bip01_R_Finger02" -3.450000 -1.690000 -1.300000 0.000000 0.960000 1.580000
$hbox 0 "v_weapon.Bip01_R_Finger1" -3.960000 -1.690000 -1.250000 0.000000 1.570000 2.090000
$hbox 0 "v_weapon.Bip01_R_Finger2" -4.610000 -1.840000 -1.360000 0.000000 1.670000 1.550000
$hbox 0 "v_weapon.Bip01_R_Finger3" -4.100000 -1.790000 -1.600000 0.000000 1.610000 1.110000
$hbox 0 "v_weapon.Bip01_R_Finger4" -2.970000 -1.390000 -1.810000 0.000000 1.780000 0.940000
$hbox 0 "v_weapon.Bip01_R_Finger41" -2.510000 -1.130000 -1.340000 0.000000 0.980000 0.900000
$hbox 0 "v_weapon.Bip01_L_Finger11" -2.960000 -1.030000 -1.330000 0.000000 1.220000 1.130000
$hbox 0 "v_weapon.Bip01_L_Finger21" -2.790000 -1.420000 -1.150000 0.000000 1.070000 1.130000
$hbox 0 "v_weapon.Bip01_L_Finger31" -2.480000 -1.330000 -1.060000 0.000000 0.930000 1.140000
$hbox 0 "v_weapon.Bip01_L_Finger42" -2.940000 -0.680000 -0.920000 0.000000 0.940000 0.950000
$hbox 0 "v_weapon.Bip01_R_Finger11" -2.960000 -1.070000 -1.190000 0.000000 1.330000 1.440000
$hbox 0 "v_weapon.Bip01_R_Finger21" -2.790000 -1.470000 -1.200000 0.000000 1.160000 1.220000
$hbox 0 "v_weapon.Bip01_R_Finger31" -2.460000 -1.390000 -1.220000 0.000000 1.030000 1.120000
$hbox 0 "v_weapon.Bip01_R_Finger42" -3.010000 -0.780000 -1.010000 0.000000 1.030000 0.970000
$hbox 0 "v_weapon.Bip01_L_Finger12" -3.270000 -0.940000 -1.060000 0.000000 0.910000 1.070000
$hbox 0 "v_weapon.Bip01_L_Finger22" -2.790000 -1.070000 -1.110000 0.060000 1.020000 1.110000
$hbox 0 "v_weapon.Bip01_L_Finger32" -3.310000 -1.120000 -1.090000 0.100000 0.920000 1.030000
$hbox 0 "v_weapon.Bip01_R_Finger12" -3.350000 -0.970000 -1.110000 0.000000 1.030000 1.160000
$hbox 0 "v_weapon.Bip01_R_Finger22" -2.830000 -1.110000 -1.180000 0.080000 1.110000 1.170000
$hbox 0 "v_weapon.Bip01_R_Finger32" -3.360000 -1.160000 -1.110000 0.110000 0.990000 1.130000
$hbox 0 "v_weapon.deagle_parent" -1.560000 -5.468095 -6.400000 1.490000 9.740000 21.809999
$hbox 0 "v_weapon.deagle_clip" -1.000000 -0.110000 -1.690000 1.150000 10.710000 3.470000
$hbox 0 "v_weapon.deagle_slide" -1.510000 -1.470000 -4.690000 1.630000 3.340000 17.760000

// 7 animation sequence(s)
$sequence "idle" "idle" fps 30 loop
$sequence "shoot1" "shoot1" fps 23 { event 5001 0 "21" }
$sequence "shoot2" "shoot2" fps 23 { event 5001 0 "21" }
$sequence "shoot_empty" "shoot_empty" fps 25 { event 5001 0 "41" }
$sequence "reload" "reload" fps 24 {
  { event 5004 5 "weapons/de_clipout.wav" }
  { event 5004 16 "weapons/de_clipin.wav" }
  { event 5004 31 "weapons/p228_slidepull.wav" }
  { event 5004 36 "weapons/de_slideforward.wav" }
 }
$sequence "draw" "draw" fps 29 { event 5004 0 "weapons/de_deploy.wav" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
