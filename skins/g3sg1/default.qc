// Start of QC script.

$modelname "v_g3sg1.mdl"
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
studio "template"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.g3sg1_Parent" -0.200000 4.000000 34.000000
$attachment 1 "v_weapon.g3sg1_Parent" 0.500000 4.700000 7.300000

// 24 hit box(es)
$hbox 0 "v_weapon.Bip01_L_Hand" -5.320000 -4.140000 -4.170000 24.620001 2.160000 2.830000
$hbox 0 "v_weapon.Bip01_R_Hand" -13.030169 -4.140000 -2.820000 24.600000 57.547207 4.150000
$hbox 0 "v_weapon.Bip01_L_Finger0" -2.140000 -1.070000 -1.230000 1.050000 1.680000 0.990000
$hbox 0 "v_weapon.Bip01_L_Finger01" -1.660000 -0.830000 -0.870000 0.000000 0.520000 0.620000
$hbox 0 "v_weapon.Bip01_L_Finger02" -1.600000 -0.790000 -0.700000 0.000000 0.400000 0.580000
$hbox 0 "v_weapon.Bip01_L_Finger1" -1.860000 -0.770000 -0.930000 0.000000 0.680000 0.550000
$hbox 0 "v_weapon.Bip01_L_Finger11" -1.380000 -0.470000 -0.630000 0.000000 0.570000 0.510000
$hbox 0 "v_weapon.Bip01_L_Finger2" -2.190000 -0.850000 -0.700000 0.000000 0.720000 0.660000
$hbox 0 "v_weapon.Bip01_L_Finger21" -1.300000 -0.650000 -0.540000 0.000000 0.490000 0.510000
$hbox 0 "v_weapon.Bip01_L_Finger3" -1.940000 -0.810000 -0.540000 0.000000 0.710000 0.710000
$hbox 0 "v_weapon.Bip01_L_Finger31" -1.170000 -0.630000 -0.490000 0.000000 0.410000 0.520000
$hbox 0 "v_weapon.Bip01_L_Finger4" -1.410000 -0.640000 -0.480000 0.000000 0.790000 0.820000
$hbox 0 "v_weapon.Bip01_R_Finger0" -2.190000 -1.110000 -0.970000 1.290000 1.700000 1.280000
$hbox 0 "v_weapon.Bip01_R_Finger01" -1.690000 -0.850000 -0.660000 0.000000 0.560000 0.890000
$hbox 0 "v_weapon.Bip01_R_Finger02" -1.620000 -0.760000 -0.610000 0.000000 0.460000 0.720000
$hbox 0 "v_weapon.Bip01_R_Finger1" -1.870000 -0.790000 -0.590000 0.000000 0.730000 0.970000
$hbox 0 "v_weapon.Bip01_R_Finger11" -1.380000 -0.500000 -0.550000 0.000000 0.600000 0.650000
$hbox 0 "v_weapon.Bip01_R_Finger2" -2.190000 -0.860000 -0.600000 0.000000 0.770000 0.730000
$hbox 0 "v_weapon.Bip01_R_Finger21" -1.300000 -0.670000 -0.540000 0.000000 0.530000 0.580000
$hbox 0 "v_weapon.Bip01_R_Finger3" -1.930000 -0.850000 -0.730000 0.000000 0.730000 0.530000
$hbox 0 "v_weapon.Bip01_R_Finger31" -1.170000 -0.660000 -0.540000 0.000000 0.460000 0.540000
$hbox 0 "v_weapon.Bip01_R_Finger4" -1.410000 -0.660000 -0.830000 0.000000 0.820000 0.420000
$hbox 0 "v_weapon.g3sg1_Parent" -1.590000 -3.160000 -16.070000 1.290000 9.390000 34.150002
$hbox 0 "v_weapon.g3sg1_Clip" -0.760000 -3.420000 -1.960000 0.620000 3.460000 1.850000

// 6 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "shoot" "shoot" fps 30 { event 5001 0 "32" }
$sequence "shoot2" "shoot2" fps 30 { event 5001 0 "32" }
$sequence "reload" "reload" fps 30 {
  { event 5004 13 "weapons/g3sg1_clipout.wav" }
  { event 5004 61 "weapons/g3sg1_clipin.wav" }
  { event 5004 76 "weapons/g3sg1_slide.wav" }
  { event 5004 80 "weapons/g3sg1_slideforward.wav" }
 }
$sequence "draw" "draw" fps 30 {
  { event 5004 0 "weapons/g3sg1_draw.wav" }
  { event 5004 4 "weapons/g3sg1_slide.wav" }
  { event 5004 8 "weapons/g3sg1_slideforward.wav" }
 }
$sequence "inspect" "inspect" fps 30

// End of QC script.
