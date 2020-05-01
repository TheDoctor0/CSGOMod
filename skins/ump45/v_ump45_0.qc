// Start of QC script.

$modelname "v_ump45_0.mdl"
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
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "smd\briefing"
studio "smd\corporal"
studio "smd\exposure"
studio "smd\flame"
studio "smd\grandprix"
studio "smd\metal_flowers"
studio "smd\metal_flowers2"
studio "smd\primalsaber"
studio "smd\primalsaber2"
studio "smd\riot"
studio "smd\scaffold"
studio "smd\tread"
studio "smd\vertex"
studio "smd\witsend"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.ump45_Parent" 0.000000 4.200000 15.700000
$attachment 1 "v_weapon.ump45_Parent" -1.200000 4.100000 6.000000

// 18 hit box(es)
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.220000 -3.060000 -2.650000 10.520000 2.720000 2.200000
$hbox 0 "v_weapon.Bip01_R_Hand" -4.470000 -1.600000 -2.320000 4.287420 4.952876 8.686856
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.270000 -3.040000 -2.170000 10.550000 2.710000 2.610000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.500000 -1.640000 -1.990000 0.670000 1.130000 2.290000
$hbox 0 "v_weapon.ump45_Parent" -1.500000 -2.400000 -13.480000 1.250000 7.130000 15.710000
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.840000 -0.900000 -0.800000 1.040000 1.440000 1.090000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.410000 -0.670000 -0.520000 0.000000 0.480000 0.740000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.560000 -0.620000 -0.490000 0.000000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" -1.810000 -0.700000 -0.480000 0.000000 0.620000 0.610000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.620000 -0.690000 -0.570000 0.000000 0.630000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.200000 -0.530000 -0.650000 0.000000 0.670000 0.370000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.760000 -0.880000 -1.050000 1.080000 1.390000 0.800000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.380000 -0.690000 -0.730000 0.000000 0.420000 0.520000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.520000 -0.640000 -0.800000 0.000000 0.570000 0.440000
$hbox 0 "v_weapon.Bip01_L_Finger2" -1.810000 -0.700000 -0.580000 0.000000 0.590000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.630000 -0.670000 -0.460000 0.000000 0.600000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.180000 -0.510000 -0.380000 0.000000 0.650000 0.700000
$hbox 0 "v_weapon.ump45_Clip" -0.770000 -5.800000 -0.830000 0.740000 4.550000 1.050000

// 7 animation sequence(s)
$sequence "idle1" "idle1" fps 12
$sequence "reload" "reload" fps 22 {
  { event 5004 10 "weapons/ump45_clipout.wav" }
  { event 5004 34 "weapons/ump45_clipin.wav" }
  { event 5004 51 "weapons/ump45_boltslap.wav" }
  { event 5004 58 "weapons/ump45_boltrelease.wav" }
 }
$sequence "draw" "draw" fps 23 {
  { event 5004 0 "weapons/ump45_deploy.wav" }
  { event 5004 6 "weapons/ump45_boltslap.wav" }
  { event 5004 11 "weapons/ump45_boltrelease.wav" }
 }
$sequence "shoot1" "shoot1" fps 32 { event 5001 0 "21" }
$sequence "shoot2" "shoot2" fps 32 { event 5001 0 "21" }
$sequence "shoot3" "shoot3" fps 32 { event 5001 0 "21" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
