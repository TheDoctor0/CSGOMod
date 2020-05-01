// Start of QC script.

$modelname "v_scout.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "hands1" "t_arms_01"
$body "hands2" "t_arms_02"
$body "hands3" "t_arms_03"
$body "hands4" "t_arms_04"
$body "hands5" "t_arms_05"
$body "scope" "scope"
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "template"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.ssg08_parent" -1.000000 2.000000 35.200001
$attachment 1 "v_weapon.ssg08_parent" 0.000000 2.400000 8.500000

// 28 hit box(es)
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.470000 -3.340000 -2.720000 7.980000 2.910000 3.150000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.460000 -3.340000 -3.140000 7.960000 2.910000 2.730000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.440000 -1.570000 -2.030000 0.430000 1.290000 2.370000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.870000 -0.850000 -0.970000 1.040000 1.480000 0.790000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.490000 -0.770000 -0.750000 0.000000 0.550000 0.620000
$hbox 0 "v_weapon.Bip01_L_Finger02" -1.440000 -0.670000 -0.640000 0.000000 0.460000 0.560000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.580000 -0.860000 -0.820000 0.000000 0.590000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger11" -1.220000 -0.610000 -0.620000 0.000000 0.580000 0.510000
$hbox 0 "v_weapon.Bip01_L_Finger2" -1.860000 -0.980000 -0.620000 0.000000 0.550000 0.490000
$hbox 0 "v_weapon.Bip01_L_Finger21" -1.008841 -0.690000 -0.630000 0.000000 0.510000 0.480000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.540000 -0.900000 -0.440000 0.000000 0.610000 0.580000
$hbox 0 "v_weapon.Bip01_L_Finger31" -0.920000 -0.660000 -0.510000 0.090000 0.540000 0.550000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.270000 -0.740000 -0.320000 0.000000 0.600000 0.770000
$hbox 0 "v_weapon.Bip01_R_Hand" -9.404148 -1.560000 -2.360000 0.410000 46.015659 3.282581
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.870000 -0.840000 -0.780000 1.030000 1.490000 0.990000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.500000 -0.750000 -0.610000 0.000000 0.580000 0.760000
$hbox 0 "v_weapon.Bip01_R_Finger02" -1.470000 -0.650000 -0.550000 0.000000 0.480000 0.640000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.580000 -0.870000 -0.510000 0.000000 0.600000 0.800000
$hbox 0 "v_weapon.Bip01_R_Finger11" -1.210000 -0.600000 -0.500000 0.000000 0.590000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger2" -1.860000 -0.970000 -0.480000 0.000000 0.570000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger21" -1.008844 -0.680000 -0.470000 0.000000 0.510000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.550000 -0.890000 -0.570000 0.000000 0.610000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger31" -0.930000 -0.640000 -0.550000 0.080000 0.540000 0.510000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.280000 -0.740000 -0.760000 0.000000 0.620000 0.310000
$hbox 0 "v_weapon.ssg08_parent" -1.930000 -5.710000 -13.960000 1.780000 6.120000 35.419998
$hbox 0 "v_weapon.weapon_Clip" -0.930000 -0.240000 -1.960000 0.320000 3.100000 2.700000
$hbox 0 "v_weapon.weapon_Slide" -0.820000 -0.620000 -0.560000 0.500000 0.560000 1.968504
$hbox 0 "v_weapon.weapon_bolt" -2.160000 -0.390000 -1.020000 0.680000 2.140000 6.600000

// 6 animation sequence(s)
$sequence "idle" "idle" fps 25
$sequence "shoot1" "shoot1" fps 35 {
  { event 5001 0 "31" }
  { event 5004 14 "weapons/scout_bolt.wav" }
  { event 5004 21 "weapons/scout_bolt2.wav" }
 }
$sequence "shoot2" "shoot2" fps 35 {
  { event 5001 0 "31" }
  { event 5004 14 "weapons/scout_bolt.wav" }
  { event 5004 21 "weapons/scout_bolt2.wav" }
 }
$sequence "reload" "reload" fps 45 {
  { event 5004 7 "weapons/scout_clipout.wav" }
  { event 5004 35 "weapons/scout_clipin.wav" }
  { event 5004 46 "weapons/boltpull1.wav" }
  { event 5004 62 "weapons/scout_bolt.wav" }
  { event 5004 70 "weapons/scout_bolt2.wav" }
 }
$sequence "draw" "draw" fps 26 {
  { event 5004 0 "weapons/scout_draw.wav" }
  { event 5004 6 "weapons/scout_bolt.wav" }
  { event 5004 12 "weapons/scout_bolt2.wav" }
 }
$sequence "inspect" "inspect" fps 25

// End of QC script.
