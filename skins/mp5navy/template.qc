// Start of QC script.

$modelname "v_mp5navy.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

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
$attachment 0 "v_weapon.mp7_parent" 0.000000 2.500000 9.000000
$attachment 1 "v_weapon.mp7_parent" 0.000000 3.000000 0.000000

// 18 hit box(es)
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.290000 -3.070000 -2.190000 10.550000 2.740000 2.640000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.460000 -1.650000 -1.990000 0.680000 1.150000 2.320000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.240000 -3.080000 -2.690000 10.530000 2.750000 2.200000
$hbox 0 "v_weapon.Bip01_R_Hand" -4.510000 -1.620000 -2.340000 11.205424 4.343000 6.837805
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.790000 -0.920000 -1.020000 1.100000 1.410000 0.810000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.370000 -0.690000 -0.720000 0.000000 0.440000 0.520000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.540000 -0.650000 -0.800000 0.000000 0.560000 0.490000
$hbox 0 "v_weapon.Bip01_L_Finger2" -1.820000 -0.710000 -0.590000 0.000000 0.600000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.620000 -0.690000 -0.470000 0.000000 0.570000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.180000 -0.540000 -0.380000 0.000000 0.650000 0.670000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.850000 -0.920000 -0.790000 1.070000 1.460000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.430000 -0.690000 -0.520000 0.000000 0.480000 0.780000
$hbox 0 "v_weapon.Bip01_R_Finger02" -1.390000 -0.620000 -0.480000 0.000000 0.390000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.580000 -0.630000 -0.500000 0.000000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" -1.810000 -0.700000 -0.500000 0.000000 0.670000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.640000 -0.680000 -0.590000 0.000000 0.640000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.200000 -0.530000 -0.690000 0.000000 0.700000 0.380000
$hbox 0 "v_weapon.mp7_parent" -0.860000 -2.640000 -5.900000 0.840000 5.310000 9.710000

// 7 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "reload" "reload" fps 30 {
  { event 5004 10 "weapons/mp5_clipout.wav" }
  { event 5004 33 "weapons/mp5_clipin.wav" }
  { event 5004 51 "weapons/mp5_slideback.wav" }
  { event 5004 57 "weapons/mp5_slideforward.wav" }
 }
$sequence "draw" "draw" fps 30 {
  { event 5004 0 "weapons/mp5_draw.wav" }
  { event 5004 7 "weapons/mp5_slideback.wav" }
  { event 5004 12 "weapons/mp5_slideforward.wav" }
 }
$sequence "shoot1" "shoot1" fps 30 { event 5001 0 "21" }
$sequence "shoot2" "shoot2" fps 30 { event 5001 0 "21" }
$sequence "shoot3" "shoot3" fps 30 { event 5001 0 "21" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
