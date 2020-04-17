$modelname "v_knife.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures

$body "studio" "cs_arms_reference"
$body "studio" "knife_css"

$origin 0 -2 0

$sequence "idle" "idle" fps 30 loop
$sequence "slash1" "slash1" fps 30 
$sequence "slash2" "slash2" fps 30 
$sequence "draw" "draw" fps 30 
$sequence "stab" "stab" fps 30
$sequence "stab_miss" "stab_miss" fps 30 
$sequence "midslash1" "midslash1" fps 30
$sequence "midslash2" "midslash2" fps 30
$sequence "inspect_1" "inspect_1" fps 30
$sequence "inspect_2" "inspect_2" fps 30