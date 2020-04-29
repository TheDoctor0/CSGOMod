// Start of QC script.

$modelname "v_famas_0.mdl"
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
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "smd\afterimage"
studio "smd\ascii"
studio "smd\carthage"
studio "smd\deathspine"
studio "smd\djinn"
studio "smd\falcon_blue"
studio "smd\gold_legend"
studio "smd\imperial"
studio "smd\jungle_tiger"
studio "smd\mechaindustries"
studio "smd\neural"
studio "smd\owl"
studio "smd\pulse"
studio "smd\rollcage"
studio "smd\sergeant"
studio "smd\spitfire"
studio "smd\survivorz"
studio "smd\valence"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.famas_Parent" 0.000000 3.000000 18.500000
$attachment 1 "v_weapon.famas_Parent" 0.000000 3.000000 -7.000000

// 17 hit box(es)
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.220000 -3.060000 -2.660000 10.500000 2.730000 2.200000
$hbox 0 "v_weapon.Bip01_R_Hand" -4.490000 -1.610000 -2.310000 0.390000 6.312160 6.159877
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.270000 -3.050000 -2.180000 10.550000 2.730000 2.630000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.490000 -1.620000 -1.980000 0.680000 1.140000 2.290000
$hbox 0 "v_weapon.famas_Parent" -1.420000 -3.390000 -16.590000 1.420000 7.130000 18.540001
$hbox 0 "v_weapon.Bip01_R_Finger0" -1.840000 -0.900000 -0.790000 1.050000 1.430000 1.080000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.410000 -0.670000 -0.520000 0.000000 0.480000 0.750000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.550000 -0.620000 -0.490000 0.000000 0.630000 0.830000
$hbox 0 "v_weapon.Bip01_R_Finger2" -1.810000 -0.700000 -0.480000 0.000000 0.620000 0.610000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.610000 -0.680000 -0.570000 0.000000 0.610000 0.450000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.200000 -0.530000 -0.660000 0.000000 0.660000 0.370000
$hbox 0 "v_weapon.Bip01_L_Finger0" -1.760000 -0.880000 -1.050000 1.070000 1.400000 0.810000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.380000 -0.670000 -0.730000 0.000000 0.430000 0.510000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.530000 -0.640000 -0.790000 0.000000 0.570000 0.440000
$hbox 0 "v_weapon.Bip01_L_Finger2" -1.800000 -0.710000 -0.590000 0.000000 0.590000 0.560000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.630000 -0.670000 -0.460000 0.000000 0.600000 0.570000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.180000 -0.520000 -0.380000 0.000000 0.650000 0.700000

// 7 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "reload" "reload" fps 27 {
  { event 5004 14 "weapons/famas_clipout.wav" }
  { event 5004 35 "weapons/famas_clipin.wav" }
  { event 5004 47 "weapons/famas_boltback.wav" }
  { event 5004 60 "weapons/famas_forearm.wav" }
  { event 5004 63 "weapons/famas_boltforward.wav" }
 }
$sequence "draw" "draw" fps 30 {
  { event 5004 0 "weapons/famas_forearm.wav" }
  { event 5004 7 "weapons/famas_boltback.wav" }
  { event 5004 10 "weapons/famas_boltforward.wav" }
 }
$sequence "shoot1" "shoot1" fps 30 { event 5001 0 "22" }
$sequence "shoot2" "shoot2" fps 30 { event 5001 0 "22" }
$sequence "shoot3" "shoot3" fps 30 { event 5001 0 "22" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
