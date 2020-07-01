// Start of QC script.

$modelname "v_sg550_0.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "hands" "h_01"
$body "hands" "h_02"
$body "hands" "h_03"
$body "hands" "h_04"
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "smd\bloodsport"
studio "smd\blueprint"
studio "smd\cardiac"
studio "smd\cyrex"
studio "smd\destroyer"
studio "smd\fire"
studio "smd\greenmarine"
studio "smd\powercore"
studio "smd\practitoner"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.SCAR_Parent" 0.000000 10.750000 72.500000
$attachment 1 "v_weapon.SCAR_Parent" 0.000000 11.500000 12.500000

// 37 hit box(es)
$hbox 0 "v_weapon.Bip01_L_Hand" -11.260000 -4.140000 -5.000000 1.700000 3.010000 5.900000
$hbox 0 "v_weapon.Bip01_L_Finger0" -4.570000 -2.330000 -2.660000 2.780000 3.600000 2.100000
$hbox 0 "v_weapon.Bip01_L_Finger01" -3.560000 -1.800000 -1.880000 0.000000 1.130000 1.360000
$hbox 0 "v_weapon.Bip01_L_Finger02" -3.390000 -1.680000 -1.510000 0.000000 0.890000 1.260000
$hbox 0 "v_weapon.Bip01_L_Finger1" -3.960000 -1.630000 -2.020000 0.000000 1.510000 1.220000
$hbox 0 "v_weapon.Bip01_L_Finger11" -2.970000 -1.030000 -1.360000 0.000000 1.250000 1.130000
$hbox 0 "v_weapon.Bip01_L_Finger12" -3.270000 -0.940000 -1.090000 0.000000 0.950000 1.070000
$hbox 0 "v_weapon.Bip01_L_Finger2" -4.650000 -1.810000 -1.500000 0.000000 1.610000 1.430000
$hbox 0 "v_weapon.Bip01_L_Finger21" -2.810000 -1.420000 -1.150000 0.000000 1.090000 1.140000
$hbox 0 "v_weapon.Bip01_L_Finger22" -2.800000 -1.080000 -1.110000 0.060000 1.040000 1.120000
$hbox 0 "v_weapon.Bip01_L_Finger3" -4.130000 -1.750000 -1.210000 0.000000 1.550000 1.530000
$hbox 0 "v_weapon.Bip01_L_Finger31" -2.500000 -1.360000 -1.070000 0.000000 0.950000 1.150000
$hbox 0 "v_weapon.Bip01_L_Finger32" -3.320000 -1.130000 -1.090000 0.110000 0.930000 1.050000
$hbox 0 "v_weapon.Bip01_L_Finger4" -3.000000 -1.360000 -1.030000 0.000000 1.740000 1.750000
$hbox 0 "v_weapon.Bip01_L_Finger41" -2.520000 -1.070000 -0.840000 0.000000 0.930000 1.290000
$hbox 0 "v_weapon.Bip01_L_Finger42" -2.950000 -0.710000 -0.930000 0.000000 0.950000 0.950000
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -25.760000 -7.800000 -5.530000 26.450001 6.960000 6.720000
$hbox 0 "v_weapon.Bip01_R_Hand" -34.952015 -4.140000 -5.970000 1.110000 10.815645 29.963884
$hbox 0 "v_weapon.Bip01_R_Finger0" -4.630000 -2.410000 -2.110000 2.800000 3.650000 2.740000
$hbox 0 "v_weapon.Bip01_R_Finger01" -3.600000 -1.860000 -1.430000 0.000000 1.210000 1.950000
$hbox 0 "v_weapon.Bip01_R_Finger1" -3.980000 -1.700000 -1.280000 0.000000 1.570000 2.090000
$hbox 0 "v_weapon.Bip01_R_Finger2" -4.650000 -1.880000 -1.360000 0.000000 1.680000 1.570000
$hbox 0 "v_weapon.Bip01_R_Finger3" -4.130000 -1.820000 -1.600000 0.000000 1.610000 1.150000
$hbox 0 "v_weapon.Bip01_R_Finger4" -3.010000 -1.430000 -1.810000 0.000000 1.790000 0.970000
$hbox 0 "v_weapon.Bip01_R_ForeTwist" -25.740000 -7.800000 -6.720000 26.450001 6.960000 5.530000
$hbox 0 "v_weapon.Bip01_R_Finger02" -3.470000 -1.690000 -1.330000 0.000000 0.990000 1.590000
$hbox 0 "v_weapon.Bip01_R_Finger11" -2.970000 -1.100000 -1.200000 0.000000 1.330000 1.440000
$hbox 0 "v_weapon.Bip01_R_Finger12" -3.350000 -1.010000 -1.140000 0.000000 1.030000 1.160000
$hbox 0 "v_weapon.Bip01_R_Finger21" -2.830000 -1.500000 -1.210000 0.000000 1.160000 1.230000
$hbox 0 "v_weapon.Bip01_R_Finger22" -2.870000 -1.140000 -1.190000 0.080000 1.110000 1.180000
$hbox 0 "v_weapon.Bip01_R_Finger31" -2.500000 -1.430000 -1.220000 0.000000 1.030000 1.150000
$hbox 0 "v_weapon.Bip01_R_Finger32" -3.400000 -1.200000 -1.120000 0.110000 1.000000 1.160000
$hbox 0 "v_weapon.Bip01_R_Finger41" -2.530000 -1.140000 -1.360000 0.000000 0.990000 0.920000
$hbox 0 "v_weapon.Bip01_R_Finger42" -3.020000 -0.780000 -1.030000 0.000000 1.030000 1.000000
$hbox 0 "v_weapon.SCAR_Parent" -3.310000 -3.850000 -36.849998 3.240000 24.200001 73.269997
$hbox 0 "v_weapon.SCAR_Clip" -1.280000 -3.840000 -11.390000 1.130000 3.600000 2.930000
$hbox 0 "v_weapon.SCAR_Trigger" -0.630000 -2.020000 -3.540000 0.480000 1.280000 0.350000

// 6 animation sequence(s)
$sequence "idle" "idle" fps 16
$sequence "shoot1" "shoot1" fps 45 { event 5001 0 "62" }
$sequence "shoot2" "shoot2" fps 45 { event 5001 0 "62" }
$sequence "reload" "reload" fps 28 {
  { event 5004 18 "weapons/sg550_clipout.wav" }
  { event 5004 41 "weapons/sg550_clipin.wav" }
  { event 5004 62 "weapons/sg550_boltpull.wav" }
 }
$sequence "draw" "draw" fps 40 { event 5004 15 "weapons/sg550_boltpull.wav" } { event 5004 18 "weapons/sg550_boltrelease.wav" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
