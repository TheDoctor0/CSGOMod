// Start of QC script.

$modelname "v_elite.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "studio" "h1"
$body "studio" "h2"
$body "studio" "h3"
$body "studio" "h4"
$body "studio" "h5"
$body "attachments" "attachments"

$bodygroup "skins"
{
// end
}

// 4 attachment(s)
$attachment 0 "v_weapon.m9a1_L_parent" 0.000000 3.300000 8.700000
$attachment 1 "v_weapon.m9a1_R_parent" 0.000000 3.300000 8.700000
$attachment 2 "v_weapon.m9a1_L_parent" 0.000000 3.300000 2.000000
$attachment 3 "v_weapon.m9a1_R_parent" 0.000000 3.300000 2.000000

// 26 hit box(es)
$hbox 0 "v_weapon.Bip01_R_Hand" -6.432053 -5.334980 -2.330000 0.390000 1.280000 3.659230
$hbox 0 "v_weapon.m9a1_R_parent" -0.670000 -2.723249 -1.880000 0.650000 3.712946 8.480000
$hbox 0 "v_weapon.m9a1_R_magazine" -0.550000 -0.070000 -0.960000 0.510000 5.010000 0.940000
$hbox 0 "v_weapon.m9a1_R_slide" -0.660000 -1.690000 -0.660000 0.710000 0.240000 8.560000
$hbox 0 "v_weapon.Bip01_L_Hand" -6.543982 -5.934248 -2.991041 0.410000 1.270000 2.330000
$hbox 0 "v_weapon.m9a1_L_parent" -0.630000 -2.723248 -1.850000 0.670000 3.712945 8.510000
$hbox 0 "v_weapon.m9a1_L_magazine" -0.520000 -0.050000 -0.930000 0.550000 5.010000 0.970000
$hbox 0 "v_weapon.m9a1_L_slide" -0.650000 -1.700000 -0.630000 0.720000 0.210000 8.580000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.470000 -3.310000 -2.680000 7.980000 2.890000 3.130000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.420000 -3.300000 -3.110000 7.920000 2.870000 2.710000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.870000 -0.840000 -0.960000 1.010000 1.470000 0.760000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.480000 -0.730000 -0.730000 0.000000 0.550000 0.600000
$hbox 0 "v_weapon.Bip01_L_Finger02" -1.440000 -0.650000 -0.620000 0.000000 0.460000 0.530000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.580000 -0.840000 -0.800000 0.000000 0.580000 0.480000
$hbox 0 "v_weapon.Bip01_L_Finger11" -1.220000 -0.580000 -0.610000 0.000000 0.580000 0.490000
$hbox 0 "v_weapon.Bip01_L_Finger2" -1.850000 -0.960000 -0.600000 0.000000 0.540000 0.450000
$hbox 0 "v_weapon.Bip01_L_Finger21" -1.008841 -0.650000 -0.620000 0.000000 0.510000 0.450000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.250000 -0.710000 -0.310000 0.000000 0.590000 0.750000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.830000 -0.820000 -0.760000 1.030000 1.470000 0.970000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.460000 -0.730000 -0.580000 0.000000 0.550000 0.740000
$hbox 0 "v_weapon.Bip01_R_Finger02" -1.430000 -0.630000 -0.530000 0.000000 0.460000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.550000 -0.850000 -0.490000 0.000000 0.580000 0.780000
$hbox 0 "v_weapon.Bip01_R_Finger11" -1.180000 -0.580000 -0.480000 0.000000 0.580000 0.610000
$hbox 0 "v_weapon.Bip01_R_Finger2" -1.820000 -0.950000 -0.450000 0.000000 0.550000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger21" -1.008844 -0.650000 -0.450000 0.000000 0.490000 0.620000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.240000 -0.720000 -0.740000 0.000000 0.600000 0.290000

// 17 animation sequence(s)
$sequence "idle" "idle" fps 16
$sequence "idle_leftempty" "idle_leftempty" fps 16
$sequence "shoot_left1_1" "shoot_left1_1" fps 40 { event 5001 0 "11" }
$sequence "shoot_left2_1" "shoot_left2_1" fps 40 { event 5001 0 "11" }
$sequence "shoot_left1_2" "shoot_left1_2" fps 40 { event 5001 0 "11" }
$sequence "shoot_left2_2" "shoot_left2_2" fps 40 { event 5001 0 "11" }
$sequence "shoot_left1_3" "shoot_left1_3" fps 40 { event 5001 0 "11" }
$sequence "shoot_leftlast" "shoot_leftlast" fps 40 { event 5001 0 "11" }
$sequence "shoot_right1_1" "shoot_right1_1" fps 40 { event 5011 0 "11" }
$sequence "shoot_right2_1" "shoot_right2_1" fps 40 { event 5011 0 "11" }
$sequence "shoot_right1_2" "shoot_right1_2" fps 40 { event 5011 0 "11" }
$sequence "shoot_right2_2" "shoot_right2_2" fps 40 { event 5011 0 "11" }
$sequence "shoot_right1_3" "shoot_right1_3" fps 40 { event 5011 0 "11" }
$sequence "shoot_rightlast" "shoot_rightlast" fps 40 { event 5011 0 "11" }
$sequence "reload" "reload" fps 22 {
  { event 5004 5 "weapons/elite_clipout.wav" }
  { event 5004 7 "weapons/elite_clipout.wav" }
  { event 5004 40 "weapons/elite_leftclipin.wav" }
  { event 5004 66 "weapons/elite_rightclipin.wav" }
  { event 5004 80 "weapons/elite_sliderelease.wav" }
  { event 5004 85 "weapons/elite_sliderelease.wav" }
 }
$sequence "draw" "draw" fps 35 {
  { event 5004 1 "weapons/elite_deploy.wav" }
  { event 5004 14 "weapons/elite_hammer.wav" }
  { event 5004 16 "weapons/elite_hammer.wav" }
 }
$sequence "inspect" "inspect" fps 25

// End of QC script.
