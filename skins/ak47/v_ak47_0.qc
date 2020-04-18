// Start of QC script.

$modelname "v_ak47_0.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

// reference mesh(es)
$body "arms" "t_arms_01"
$body "arms" "t_arms_02"
$body "arms" "t_arms_03"
$body "arms" "t_arms_04"
$body "arms" "t_arms_05"

$bodygroup "skins"
{
studio "smd\ak47_alien_matrix"
studio "smd\ak47_ambient"
studio "smd\ak47_aquamarine"
studio "smd\ak47_arckos"
studio "smd\ak47_armageddon"
studio "smd\ak47_assimov"
studio "smd\ak47_assimovlime"
studio "smd\ak47_astronaut"
studio "smd\ak47_blackholy"
studio "smd\ak47_blacklaminate"
studio "smd\ak47_blizzard"
studio "smd\ak47_bloodsport"
studio "smd\ak47_bluelaminate"
studio "smd\ak47_blueline"
studio "smd\ak47_blueline2"
studio "smd\ak47_bluewolf"
studio "smd\ak47_breakthrough"
studio "smd\ak47_butterfly"
studio "smd\ak47_carbon"
studio "smd\ak47_carbonblue"
studio "smd\ak47_cartel"
studio "smd\ak47_cartel2"
studio "smd\ak47_cartelgold"
studio "smd\ak47_casehardened"
studio "smd\ak47_casehardened2"
studio "smd\ak47_challenger"
studio "smd\ak47_cosmic"
studio "smd\ak47_creep"
studio "smd\ak47_crossline"
studio "smd\ak47_cube"
studio "smd\ak47_cyberfire"
studio "smd\ak47_cyrex"
studio "smd\ak47_damascus"
studio "smd\ak47_deepventure"
studio "smd\ak47_dragonlore"
studio "smd\ak47_dragonlorewhite"
studio "smd\ak47_elitebuild"
studio "smd\ak47_emeraldpinstripe"
studio "smd\ak47_fireserpent"
studio "smd\ak47_firewalker"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.ak47_parent" 0.000000 3.400000 25.500000
$attachment 1 "v_weapon.ak47_parent" 1.000000 4.000000 7.500000

// 19 hit box(es)
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -10.300000 -3.120000 -2.210000 10.580000 2.780000 2.690000
$hbox 0 "v_weapon.Bip01_L_Hand" -4.500000 -1.650000 -2.000000 0.680000 1.200000 2.360000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -10.290000 -3.120000 -2.690000 10.580000 2.780000 2.210000
$hbox 0 "v_weapon.Bip01_R_Hand" -4.520000 -1.650000 -2.380000 3.942292 6.533010 9.660479
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
$hbox 0 "v_weapon.ak47_parent" -1.000000 -2.380000 -11.800000 0.930000 5.550000 25.940001

// 7 animation sequence(s)
$sequence "idle" "idle" fps 25
$sequence "reload" "reload" fps 25 {
  { event 5004 12 "weapons/ak47_clipout.wav" }
  { event 5004 28 "weapons/ak47_clipin.wav" }
  { event 5004 42 "weapons/ak47_boltpull.wav" }
 }
$sequence "draw" "draw" fps 25 { event 5004 0 "weapons/ak47_draw.wav" } { event 5004 10 "weapons/ak47_boltpull.wav" }
$sequence "shoot1" "shoot1" fps 25 { event 5001 0 "22" }
$sequence "shoot2" "shoot2" fps 25 { event 5001 0 "22" }
$sequence "shoot3" "shoot3" fps 25 { event 5001 0 "22" }
$sequence "inspect" "inspect" fps 25

// End of QC script.
