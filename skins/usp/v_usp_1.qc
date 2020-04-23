// Start of QC script.

$modelname "v_usp_1.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "hands" "t_arms_01"
$body "hands" "t_arms_02"
$body "hands" "t_arms_03"
$body "hands" "t_arms_04"
$body "hands" "t_arms_05"
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "smd\vexter"
studio "smd\vexterblue"
studio "smd\vextergreen"
studio "smd\vexterorange"
studio "smd\vexterpink"
studio "smd\vexterpurple"
studio "smd\vexterred"
studio "smd\warmachine"
studio "smd\winters_bite"
// end
}

// 3 attachment(s)
$attachment 0 "v_weapon.223_parent" 0.000000 -1.#INF00 8.200000
$attachment 1 "v_weapon.223_parent" 0.000000 3.300000 3.200000
$attachment 2 "v_weapon.223_parent" 0.000000 3.000000 8.200000

// 22 hit box(es)
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.300000 -3.120000 -2.210000 10.580000 2.780000 2.690000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.500000 -1.650000 -2.000000 0.680000 1.200000 2.360000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.290000 -3.120000 -2.690000 10.580000 2.780000 2.210000
$hbox 0 "v_weapon.Bip01_R_Hand" -4.520000 -1.650000 -2.380000 2.587557 1.230000 9.234007
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.830000 -0.930000 -1.060000 1.110000 1.440000 0.840000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.420000 -0.720000 -0.750000 0.000000 0.450000 0.540000
$hbox 0 "v_weapon.Bip01_L_Finger02" -1.350000 -0.670000 -0.600000 0.000000 0.350000 0.500000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.580000 -0.650000 -0.810000 0.000000 0.600000 0.490000
$hbox 0 "v_weapon.Bip01_L_Finger2" -1.860000 -0.720000 -0.600000 0.000000 0.640000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.650000 -0.700000 -0.480000 0.000000 0.620000 0.610000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.200000 -0.540000 -0.410000 0.000000 0.690000 0.700000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.850000 -0.960000 -0.840000 1.120000 1.460000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.440000 -0.740000 -0.570000 0.000000 0.480000 0.780000
$hbox 0 "v_weapon.Bip01_R_Finger02" -1.390000 -0.670000 -0.530000 0.000000 0.390000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.590000 -0.680000 -0.510000 0.000000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" -1.860000 -0.750000 -0.540000 0.000000 0.670000 0.630000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.650000 -0.730000 -0.640000 0.000000 0.640000 0.460000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.200000 -0.570000 -0.720000 0.000000 0.710000 0.380000
$hbox 0 "v_weapon.223_parent" -0.720000 -2.890000 -1.810000 0.750000 3.540000 8.237796
$hbox 0 "v_weapon.Slide" -0.570000 -0.900000 -1.250000 0.630000 1.280000 7.590000
$hbox 0 "v_weapon.Clip" -0.580000 -0.940000 -0.790000 0.620000 4.400000 1.530000
$hbox 0 "v_weapon.silencer" -0.850000 -7.770000 -0.850000 0.850000 0.800000 0.850000

// 18 animation sequence(s)
$sequence "idle1" "idle1" fps 25
$sequence "shoot1" "shoot1" fps 25 { event 5001 0 "11" }
$sequence "shoot2" "shoot2" fps 25 { event 5001 0 "11" }
$sequence "shoot3" "shoot3" fps 25 { event 5001 0 "11" }
$sequence "shoot_empty" "shoot_empty" fps 32 { event 5001 0 "11" }
$sequence "reload" "reload" fps 19 {
  { event 5004 8 "weapons/usp_clipout.wav" }
  { event 5004 14 "weapons/usp_clipin.wav" }
  { event 5004 34 "weapons/usp_sliderelease.wav" }
  { event 5004 38 "weapons/usp_sliderelease2.wav" }
 }
$sequence "draw" "draw" fps 25 { event 5004 1 "weapons/de_deploy.wav" } { event 5004 9 "weapons/usp_slideback.wav" }
$sequence "add_silencer" "add_silencer" fps 35 {
  { event 5004 13 "weapons/usp_silencer_movement1.wav" }
  { event 5004 28 "weapons/usp_silencer_on.wav" }
  { event 5004 33 "weapons/usp_silencer_screw1.wav" }
  { event 5004 46 "weapons/usp_silencer_screw2.wav" }
  { event 5004 58 "weapons/usp_silencer_screw3.wav" }
  { event 5004 68 "weapons/usp_silencer_screw4.wav" }
  { event 5004 78 "weapons/usp_silencer_screw5.wav" }
  { event 5004 101 "weapons/usp_silencer_movement3.wav" }
 }
$sequence "idle1_unsil" "idle1_unsil" fps 25
$sequence "shoot1_unsil" "shoot1_unsil" fps 25 { event 5021 0 "21" }
$sequence "shoot2_unsil" "shoot2_unsil" fps 25 { event 5021 0 "21" }
$sequence "shoot3_unsil" "shoot3_unsil" fps 25 { event 5021 0 "21" }
$sequence "shoot_empty_unsil" "shoot_empty_unsil" fps 25 { event 5021 0 "21" }
$sequence "reload_unsil" "reload_unsil" fps 19 {
  { event 5004 8 "weapons/usp_clipout.wav" }
  { event 5004 14 "weapons/usp_clipin.wav" }
  { event 5004 34 "weapons/usp_sliderelease.wav" }
  { event 5004 38 "weapons/usp_sliderelease2.wav" }
 }
$sequence "draw_unsil" "draw_unsil" fps 25 { event 5004 1 "weapons/de_deploy.wav" } { event 5004 9 "weapons/usp_slideback.wav" }
$sequence "detach_silencer" "detach_silencer" fps 35 {
  { event 5004 6 "weapons/usp_silencer_movement1.wav" }
  { event 5004 22 "weapons/usp_silencer_off.wav" }
  { event 5004 35 "weapons/usp_silencer_screw1.wav" }
  { event 5004 44 "weapons/usp_silencer_screw2.wav" }
  { event 5004 53 "weapons/usp_silencer_screw3.wav" }
  { event 5004 61 "weapons/usp_silencer_screw4.wav" }
  { event 5004 71 "weapons/usp_silencer_screw5.wav" }
  { event 5004 76 "weapons/usp_silencer_silencer_off_end.wav" }
  { event 5004 96 "weapons/usp_silencer_movement3.wav" }
 }
$sequence "inspect" "inspect" fps 25
$sequence "inspect_unsil" "inspect_unsil" fps 25

// End of QC script.
