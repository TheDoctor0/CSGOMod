// Start of QC script.

$modelname "v_mac10.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000

//reference mesh(es)
$body "stoodio" "t_hand_ref1"
$body "stoodio" "t_hand_ref2"
$body "stoodio" "t_hand_ref3"
$body "stoodio" "t_hand_ref4"
$body "stoodio" "t_hand_ref5"
$body "attachments" "attachments"

$bodygroup "skins"
{
studio "template"
// end
}

// 2 attachment(s)
$attachment 0 "v_weapon.mac10_parent" 0.000000 6.000000 18.000000
$attachment 1 "v_weapon.mac10_parent" 1.400000 5.800000 0.000000

// 19 hit box(es)
$hbox 0 "v_weapon.Bip01_L_Hand" -9.281741 -3.065332 -4.051384 1.864923 3.022461 5.316101
$hbox 0 "v_weapon.Bip01_L_ForeTwist" -21.757431 -7.245332 -5.208922 23.043583 5.401845 5.273230
$hbox 0 "v_weapon.Bip01_R_Hand" -9.324613 -7.052408 -5.358972 44.908195 12.426539 15.022656
$hbox 0 "v_weapon.Bip01_L_Finger0" -3.644102 -1.757743 -2.808102 2.572307 3.343999 1.200410
$hbox 0 "v_weapon.Bip01_L_Finger01" -2.829538 -1.221846 -2.165025 0.000000 1.286154 0.578769
$hbox 0 "v_weapon.Bip01_L_Finger1" -3.072739 -0.857436 -1.479077 0.000000 1.822051 1.329025
$hbox 0 "v_weapon.Bip01_L_Finger2" -3.804605 -1.050359 -0.943179 0.000000 1.843487 1.521948
$hbox 0 "v_weapon.Bip01_L_Finger3" -3.215671 -1.050359 -0.621641 0.000000 1.757743 1.650564
$hbox 0 "v_weapon.Bip01_L_Finger4" -2.250768 -0.750256 -0.428718 0.000000 1.864923 1.907794
$hbox 0 "v_weapon.Bip01_R_Finger0" -3.686974 -1.822051 -1.200410 2.593743 3.386871 2.872410
$hbox 0 "v_weapon.Bip01_R_Finger01" -2.850973 -1.264718 -0.643077 0.000000 1.350461 2.229333
$hbox 0 "v_weapon.Bip01_R_Finger02" -2.743794 -1.028923 -0.557333 0.171487 1.178974 1.907794
$hbox 0 "v_weapon.Bip01_R_Finger1" -3.072747 -0.921743 -1.371897 0.000000 1.886358 1.521948
$hbox 0 "v_weapon.Bip01_R_Finger2" -3.804600 -1.114666 -1.457641 0.000000 1.907794 1.007487
$hbox 0 "v_weapon.Bip01_R_Finger3" -3.215686 -1.114666 -1.714871 0.000000 1.800615 0.578769
$hbox 0 "v_weapon.Bip01_R_Finger4" -2.250768 -0.814564 -1.972102 0.000000 1.907794 0.364410
$hbox 0 "v_weapon.mac10_parent" -2.336512 -4.160177 -10.203485 1.886358 10.203485 17.255894
$hbox 0 "v_weapon.mac10_clip" -1.178974 -9.045946 -1.564820 1.136102 10.546459 1.543384
$hbox 0 "v_weapon.mac10_bolt" -0.878872 -3.022461 -8.853023 1.393333 0.900307 1.114666

// 7 animation sequence(s)
$sequence "idle" "idle" fps 30
$sequence "reload" "reload" fps 24 {
  { event 5004 13 "weapons/mac10_clipout.wav" }
  { event 5004 33 "weapons/mac10_clipin.wav" }
  { event 5004 53 "weapons/mac10_boltpull.wav" }
  { event 5004 60 "weapons/mac10_boltforward.wav" }
 }
$sequence "draw" "draw" fps 27 {
  { event 5004 0 "items/cliprelease1.wav" }
  { event 5004 9 "weapons/mac10_boltpull.wav" }
  { event 5004 16 "weapons/mac10_boltforward.wav" }
 }
$sequence "shoot1" "shoot1" fps 42 { event 5001 0 "1" }
$sequence "shoot2" "shoot2" fps 42 { event 5001 0 "1" }
$sequence "shoot3" "shoot3" fps 42 { event 5001 0 "1" }
$sequence "inspect" "inspect" fps 30

// End of QC script.
