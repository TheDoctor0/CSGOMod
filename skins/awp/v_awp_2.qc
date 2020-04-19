// Start of QC script.

$modelname "v_awp_2.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "hands" "hands1"
$body "hands" "hands2"
$body "hands" "hands3"
$body "hands" "hands4"
$body "scope" "scope"
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "smd\novritsch2"
studio "smd\oni_taiji"
studio "smd\phobos"
studio "smd\pitviper"
studio "smd\pixelcamo"
studio "smd\pixelgreen"
studio "smd\psychopath"
studio "smd\purplesnake"
studio "smd\railgun"
studio "smd\razer"
studio "smd\redblack"
studio "smd\reddragon"
studio "smd\redhot"
studio "smd\redline1"
studio "smd\redline2"
studio "smd\royaldice"
studio "smd\safarimesh"
studio "smd\safarimesh2"
studio "smd\sandstorm"
studio "smd\singularity"
studio "smd\smoke"
studio "smd\spinebreaker"
studio "smd\starkeeper"
studio "smd\starkeepersticker"
studio "smd\stickerbombsnow"
studio "smd\sunfade"
studio "smd\supra"
studio "smd\tactical"
studio "smd\tertroner"
studio "smd\tigris"
studio "smd\tokioghoul"
studio "smd\townstyle"
studio "smd\ultrajade"
studio "smd\unicorn"
studio "smd\unknow1"
studio "smd\unknow2"
studio "smd\unknow3"
studio "smd\ursa"
studio "smd\utsuho"
studio "smd\vector"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.awp_parent" 0.000000 3.300000 40.099998
$attachment 1 "v_weapon.awp_parent" 0.700000 3.500000 6.000000

// 20 hit box(es)
$hbox 0 "v_weapon.Bip01_R_Hand" -7.245938 -1.580000 -2.270000 0.260000 42.462330 4.497306
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.590000 -0.650000 -0.470000 0.000000 0.590000 0.850000
$hbox 0 "v_weapon.Bip01_R_Finger2" -2.030000 -0.800000 -0.480000 0.000000 0.450000 0.610000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.750000 -0.740000 -0.570000 0.000000 0.500000 0.440000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.230000 -0.610000 -0.650000 0.000000 0.510000 0.370000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.480000 -1.580000 -2.090000 0.550000 1.150000 2.250000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.690000 -0.860000 -1.010000 1.070000 1.410000 0.790000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.310000 -0.680000 -0.700000 0.000000 0.430000 0.480000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.620000 -0.600000 -0.740000 0.000000 0.580000 0.470000
$hbox 0 "v_weapon.Bip01_L_Finger2" -2.000000 -0.760000 -0.560000 0.000000 0.490000 0.540000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.750000 -0.720000 -0.440000 0.000000 0.480000 0.580000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.240000 -0.590000 -0.370000 0.000000 0.490000 0.680000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.100000 -3.010000 -2.130000 10.220000 2.680000 2.580000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.710000 -0.910000 -1.010000 1.210000 1.210000 1.150000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.400000 -0.750000 -0.710000 0.000000 0.400000 0.730000
$hbox 0 "v_weapon.Bip01_R_Finger02" -1.340000 -0.650000 -0.510000 0.000000 0.360000 0.580000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.030000 -3.000000 -2.590000 10.220000 2.670000 2.130000
$hbox 0 "v_weapon.awp_parent" -1.320000 -2.660000 -12.210000 1.420000 7.090000 39.880001
$hbox 0 "v_weapon.awp_bolt_action" -2.690000 -1.340000 -5.070000 0.340000 0.330000 1.150000
$hbox 0 "v_weapon.awp_clip" -0.550000 -0.800000 -1.640000 0.610000 3.030000 1.550000

// 7 animation sequence(s)
$sequence "idle" "idle" fps 25
$sequence "fire_1" "fire_1" fps 29 {
  { event 5001 0 "31" }
  { event 5004 20 "weapons/boltup.wav" }
  { event 5004 28 "weapons/boltdown.wav" }
 }
$sequence "fire_2" "fire_2" fps 29 {
  { event 5001 0 "31" }
  { event 5004 20 "weapons/boltup.wav" }
  { event 5004 28 "weapons/boltdown.wav" }
 }
$sequence "fire_3" "fire_3" fps 29 {
  { event 5001 0 "31" }
  { event 5004 20 "weapons/boltup.wav" }
  { event 5004 28 "weapons/boltdown.wav" }
 }
$sequence "reload" "reload" fps 45 {
  { event 5004 8 "weapons/awp_clipout.wav" }
  { event 5004 46 "weapons/awp_clipin.wav" }
  { event 5004 60 "weapons/boltpull1.wav" }
  { event 5004 81 "weapons/boltup.wav" }
  { event 5004 90 "weapons/boltdown.wav" }
 }
$sequence "draw" "draw" fps 28 {
  { event 5004 0 "weapons/awp_draw.wav" }
  { event 5004 10 "weapons/boltup.wav" }
  { event 5004 19 "weapons/boltdown.wav" }
 }
$sequence "inspect" "inspect" fps 30

// End of QC script.
