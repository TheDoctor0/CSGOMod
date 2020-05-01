// Start of QC script.

$modelname "v_galil_0.mdl"
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
$body "studio" "hands5"
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "smd\aquaterrace"
studio "smd\blacksand"
studio "smd\cerbrus"
studio "smd\chatterbox"
studio "smd\chatterbox2"
studio "smd\eco"
studio "smd\firefight"
studio "smd\octopus"
studio "smd\odyssy"
studio "smd\orangeddpat"
studio "smd\orangeddpat2"
studio "smd\revolution"
studio "smd\rocketpop"
studio "smd\sirius"
studio "smd\stonecold"
studio "smd\sugar_rush"
studio "smd\surge"
studio "smd\wastelandrebeld"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.galilar_parent" 0.000000 9.000000 58.000000
$attachment 1 "v_weapon.galilar_parent" 0.000000 9.000000 15.000000

// 38 hit box(es)
$hbox 0 "v_weapon.Bip01_L_Hand" -11.440000 -4.120000 -5.740000 1.420000 3.040000 5.850000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -26.450001 -7.790000 -5.510000 26.440001 6.950000 6.710000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -26.610001 -7.790000 -6.720000 26.430000 6.950000 5.520000
$hbox 0 "v_weapon.Bip01_L_Finger0" -4.470000 -2.250000 -2.720000 2.890000 3.330000 2.200000
$hbox 0 "v_weapon.Bip01_L_Finger1" -4.010000 -1.620000 -2.150000 0.000000 1.460000 1.220000
$hbox 0 "v_weapon.Bip01_L_Finger11" -3.090000 -1.040000 -1.350000 0.000000 1.170000 1.120000
$hbox 0 "v_weapon.Bip01_L_Finger12" -3.250000 -1.010000 -1.070000 0.000000 0.950000 1.070000
$hbox 0 "v_weapon.Bip01_L_Finger2" -4.980000 -1.910000 -1.560000 0.000000 1.450000 1.370000
$hbox 0 "v_weapon.Bip01_L_Finger21" -3.050000 -1.400000 -1.140000 0.230000 0.920000 1.140000
$hbox 0 "v_weapon.Bip01_L_Finger22" -2.790000 -1.050000 -1.090000 0.040000 1.040000 1.120000
$hbox 0 "v_weapon.Bip01_L_Finger3" -4.420000 -1.860000 -1.190000 0.000000 1.420000 1.490000
$hbox 0 "v_weapon.Bip01_L_Finger31" -2.620000 -1.360000 -1.070000 0.000000 0.830000 1.140000
$hbox 0 "v_weapon.Bip01_L_Finger32" -3.310000 -1.120000 -1.090000 0.000000 0.930000 1.040000
$hbox 0 "v_weapon.Bip01_L_Finger4" -3.190000 -1.620000 -1.040000 0.000000 1.350000 1.830000
$hbox 0 "v_weapon.Bip01_L_Finger41" -2.560000 -1.110000 -0.830000 0.000000 0.920000 1.280000
$hbox 0 "v_weapon.Bip01_L_Finger42" -2.940000 -0.810000 -0.920000 0.000000 0.930000 0.950000
$hbox 0 "v_weapon.Bip01_R_Hand" -27.770521 -4.140000 -5.920000 1.310000 120.152740 13.303423
$hbox 0 "v_weapon.Bip01_R_Finger0" -4.640000 -2.390000 -2.610000 3.370000 3.590000 3.140000
$hbox 0 "v_weapon.Bip01_R_Finger01" -3.770000 -1.980000 -1.810000 0.000000 1.050000 2.000000
$hbox 0 "v_weapon.Bip01_R_Finger1" -4.270000 -1.650000 -1.270000 0.000000 1.620000 2.140000
$hbox 0 "v_weapon.Bip01_R_Finger2" -5.270000 -2.060000 -1.340000 0.000000 1.240000 1.650000
$hbox 0 "v_weapon.Bip01_R_Finger3" -4.560000 -1.850000 -1.560000 0.000000 1.360000 1.130000
$hbox 0 "v_weapon.Bip01_R_Finger31" -2.620000 -1.370000 -1.220000 0.000000 0.860000 1.130000
$hbox 0 "v_weapon.Bip01_R_Finger32" -3.400000 -1.200000 -1.110000 0.000000 0.980000 1.150000
$hbox 0 "v_weapon.Bip01_R_Finger4" -3.250000 -1.540000 -1.770000 0.000000 1.410000 0.970000
$hbox 0 "v_weapon.Bip01_R_Finger41" -2.590000 -1.180000 -1.360000 0.000000 0.940000 0.900000
$hbox 0 "v_weapon.Bip01_R_Finger42" -3.000000 -0.910000 -1.010000 0.000000 1.000000 1.000000
$hbox 0 "v_weapon.Bip01_R_Finger02" -3.460000 -1.680000 -1.320000 0.000000 0.930000 1.580000
$hbox 0 "v_weapon.Bip01_R_Finger11" -3.130000 -1.110000 -1.200000 0.090000 1.240000 1.440000
$hbox 0 "v_weapon.Bip01_R_Finger12" -3.350000 -1.080000 -1.130000 0.000000 1.020000 1.150000
$hbox 0 "v_weapon.Bip01_R_Finger21" -3.220000 -1.490000 -1.190000 0.520000 0.880000 1.210000
$hbox 0 "v_weapon.Bip01_R_Finger22" -2.870000 -1.050000 -1.190000 0.150000 1.100000 1.170000
$hbox 0 "v_weapon.Bip01_L_Finger01" -3.690000 -1.700000 -1.940000 0.000000 1.140000 1.200000
$hbox 0 "v_weapon.Bip01_L_Finger02" -3.370000 -1.670000 -1.490000 0.000000 0.840000 1.250000
$hbox 0 "v_weapon.galilar_parent" -3.070000 -5.560000 -24.240000 3.050000 13.800000 58.160000
$hbox 0 "v_weapon.magazine" -0.830000 -12.040000 -2.780000 1.140000 7.450000 5.860000
$hbox 0 "v_weapon.latch" -0.520000 -5.770000 -0.790000 0.590000 0.000000 0.280000
$hbox 0 "v_weapon.bolt" -2.870000 -1.460000 -1.500000 0.000000 1.510000 1.470000

// 7 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "reload" "reload" fps 25 {
  { event 5004 10 "weapons/galil_clipout.wav" }
  { event 5004 25 "weapons/galil_clipin.wav" }
  { event 5004 42 "weapons/galil_boltpull.wav" }
  { event 5004 49 "weapons/galil_boltrelease.wav" }
 }
$sequence "draw" "draw" fps 24 {
  { event 5004 0 "weapons/galil_draw.wav" }
  { event 5004 4 "weapons/galil_boltpull.wav" }
  { event 5004 10 "weapons/galil_boltrelease.wav" }
 }
$sequence "fire1" "fire1" fps 40 { event 5001 0 "52" }
$sequence "fire2" "fire2" fps 40 { event 5001 0 "52" }
$sequence "fire3" "fire3" fps 40 { event 5001 0 "52" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
