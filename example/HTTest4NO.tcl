set ID [lindex $argv 0]
logFile log$ID.log
puts "This is job number $ID"
# puts "received secondinput = [lindex $argv 1]"

set beamTempPts 15
set sidesHeated [lindex $argv 1]
if {$sidesHeated != 3 && $sidesHeated != 4} {
puts "sidesHeated got a value of $sidesHeated; can only be 3 or 4."
return -1
}
set protected [lindex $argv 2]
set composite [lindex $argv 3]
set tf [lindex $argv 4]
set tw [lindex $argv 5]	
set h [lindex $argv 6]
set b [lindex $argv 7]
set dp [lindex $argv 8]

set dps [lindex $argv 9]
set ts [lindex $argv 10]
set bs [lindex $argv 11]

set tFinal 1000
set dt 10
set hfire 35.0
set hamb 10.0

set f_elemx [expr max(4,int(($b - $tw)/0.025))]
if {fmod($f_elemx,2)} {
	set f_elemx [expr $f_elemx+1]
}
set f_elemy [expr max(4,int($tf/0.015))]
if {fmod($f_elemy,2)} {
	set f_elemy [expr $f_elemy+1]
}
set w_elemx [expr max(4,int($tw/0.015))]
if {fmod($w_elemx,2)} {
	set w_elemx [expr $w_elemx+1]
}
set w_elemy [expr max(8,int(($h-$tf)/0.025))]
if {fmod($w_elemy,4)} {
	if {![expr fmod($w_elemy + fmod($w_elemy,4),4)]} {
		set w_elemy [expr $w_elemy + fmod($w_elemy,4)]
	} else {
		set w_elemy [expr $w_elemy - fmod($w_elemy,4)]
	}
}
set p_elem 4

set s_elemy 8
if {$ts/$s_elemy > 25e-3} {
	set s_elemy 16
	if {$ts/$s_elemy > 25e-3} {
		set s_elemy 24
	}
}
set s_elemx [expr max(8,int(($bs-$b)/0.025))]

# Block centroids 
set f_x [expr 0.5*$b - 0.5*$tw]
set w_y [expr $h - 2*$tf]
set s_x [expr 0.5*($bs - $b)]
if {$composite && $s_x <= 0} {
puts "slab is less wide than the beam:\nBeam is $b m wide, while slab is $bs m wide.\nTerminating analysis."
return -1
}

set centrex1 [expr -0.5*$f_x-0.5*$tw] 
set centrey1 [expr -0.5*$h + 0.5*$tf]

set centrex2 0.0
set centrey2 [expr -0.5*$h + 0.5*$tf]

set centrex3 [expr 0.5*$f_x + 0.5*$tw] 
set centrey3 [expr -0.5*$h + 0.5*$tf]

set centrex4 0.0
set centrey4 0.0

set centrex5 [expr -0.5*$f_x-0.5*$tw] 
set centrey5 [expr  0.5*$h - 0.5*$tf]

set centrex6 0.0
set centrey6 [expr  0.5*$h - 0.5*$tf]

set centrex7 [expr 0.5*$f_x + 0.5*$tw] 
set centrey7 [expr 0.5*$h - 0.5*$tf]

if {$composite} {
	set centrex8 [expr -0.5*$b - 0.5*$s_x]
	set centrey8 [expr 0.5*$h + 0.5*$ts]

	set centrex9 [expr 0.5*$b + 0.5*$s_x]
	set centrey9 [expr 0.5*$h + 0.5*$ts]
	
	set centrex54 [expr -0.5*$f_x - 0.5*$tw] 
	set centrey54 [expr 0.5*$h + 0.5*$ts]

	set centrex64 0.0 
	set centrey64 [expr 0.5*$h + 0.5*$ts]

	set centrex74 [expr 0.5*$f_x + 0.5*$tw] 
	set centrey74 [expr 0.5*$h  + 0.5*$ts]
}

if {$protected} {
	# bottom flange
	set centrex11 [expr -0.5*$f_x - 0.5*$tw] 
	set centrey11 [expr -0.5*$h - 0.5*$dp]

	set centrex12 [expr -0.5*$b - 0.5*$dp] 
	set centrey12 [expr -0.5*$h + 0.5*$tf]

	set centrex14 [expr -0.5*$f_x - 0.5*$tw] 
	set centrey14 [expr -0.5*$h + $tf + 0.5*$dp]

	set centrex21 0.0 
	set centrey21 [expr -0.5*$h - 0.5*$dp]

	set centrex31 [expr 0.5*$f_x + 0.5*$tw] 
	set centrey31 [expr -0.5*$h - 0.5*$dp]

	set centrex33 [expr 0.5*$b + 0.5*$dp] 
	set centrey33 [expr -0.5*$h + 0.5*$tf]

	set centrex34 [expr 0.5*$f_x + 0.5*$tw] 
	set centrey34 [expr -0.5*$h + $tf + 0.5*$dp]

	# web
	set centrex42 [expr -0.5*$tw - 0.5*$dp] 
	set centrey42 0.0

	set centrex43 [expr 0.5*$tw + 0.5*$dp] 
	set centrey43 0.0

	# top flange

	set centrex51 [expr -0.5*$f_x - 0.5*$tw] 
	set centrey51 [expr 0.5*$h - $tf - 0.5*$dp]

	set centrex52 [expr -0.5*$b - 0.5*$dp] 
	set centrey52 [expr 0.5*$h - 0.5*$tf]

	set centrex71 [expr 0.5*$f_x + 0.5*$tw] 
	set centrey71 [expr 0.5*$h - $tf - 0.5*$dp]

	set centrex73 [expr 0.5*$b + 0.5*$dp] 
	set centrey73 [expr 0.5*$h - 0.5*$tf]

	if {!$composite} {
		set centrex54 [expr -0.5*$f_x - 0.5*$tw] 
		set centrey54 [expr 0.5*$h + 0.5*$dp]

		set centrex64 0.0 
		set centrey64 [expr 0.5*$h + 0.5*$dp]

		set centrex74 [expr 0.5*$f_x + 0.5*$tw] 
		set centrey74 [expr 0.5*$h + 0.5*$dp]
	} elseif {$composite} {
		set centrex81 [expr -0.5*$b - 0.5*$s_x]
		set centrey81 [expr 0.5*$h - 0.5*$dps]

		set centrex91 [expr 0.5*$b + 0.5*$s_x]
		set centrey91 [expr 0.5*$h - 0.5*$dps]
	}
}
 
HeatTransfer 2D;       #HeatTransfer activates the HTModule. 2D ,or 2d, or 3D or 3d indicate the model dimension. 

#Defining HeatTransfer Material with Material tag 1.
HTMaterial CarbonSteelEC3 1;
HTMaterial SFRM 2 1;
HTMaterial ConcreteEC2 3 0.0;

#Creating entitities
HTEntity Block 1 $centrex1 $centrey1 $f_x $tf;
HTEntity Block 2 $centrex2 $centrey2 $tw  $tf;
HTEntity Block 3 $centrex3 $centrey3 $f_x $tf;
HTEntity Block 4 $centrex4 $centrey4 $tw  $w_y;
HTEntity Block 5 $centrex5 $centrey5 $f_x $tf;
HTEntity Block 6 $centrex6 $centrey6 $tw  $tf;
HTEntity Block 7 $centrex7 $centrey7 $f_x $tf;
if {$composite} {
	HTEntity Block 8 $centrex8 $centrey8 $s_x $ts;
	HTEntity Block 9 $centrex9 $centrey9 $s_x $ts;
	HTEntity Block 54 $centrex54 $centrey54 $f_x $ts;
	HTEntity Block 64 $centrex64 $centrey64 $tw $ts;
	HTEntity Block 74 $centrex74 $centrey74 $f_x $ts;
}

if {$protected} {
	#bottom flange
	HTEntity Block 11 $centrex11 $centrey11 $f_x $dp;
	HTEntity Block 12 $centrex12 $centrey12 $dp $tf;
	HTEntity Block 14 $centrex14 $centrey14 $f_x $dp;

	HTEntity Block 21 $centrex21 $centrey21 $tw $dp;

	HTEntity Block 31 $centrex31 $centrey31 $f_x $dp;
	HTEntity Block 33 $centrex33 $centrey33 $dp $tf;
	HTEntity Block 34 $centrex34 $centrey34 $f_x $dp;
	# web
	HTEntity Block 42 $centrex42 $centrey42 $dp $w_y;
	HTEntity Block 43 $centrex43 $centrey43 $dp $w_y;

	#top flange
	HTEntity Block 51 $centrex51 $centrey51 $f_x $dp;
	HTEntity Block 52 $centrex52 $centrey52 $dp $tf;
	HTEntity Block 71 $centrex71 $centrey71 $f_x $dp;
	HTEntity Block 73 $centrex73 $centrey73 $dp $tf;
	
	if {!$composite} {
		HTEntity Block 54 $centrex54 $centrey54 $f_x $dp;
		HTEntity Block 64 $centrex64 $centrey64 $tw $dp;
		HTEntity Block 74 $centrex74 $centrey74 $f_x $dp;
	} elseif {$composite} {
		if {$dps > 1e-8} {
			HTEntity Block 81 $centrex81 $centrey81 $s_x $dps;
			HTEntity Block 91 $centrex91 $centrey91 $s_x $dps;
		}
	}
}

# HTMesh $meshTag $EntityTag $MaterialTag 
  HTMesh 1 		  1 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
  HTMesh 2 		  2 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy
  HTMesh 3 		  3 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
  HTMesh 4 		  4 		 1 -phaseChange 1 -NumCtrl $w_elemx $w_elemy
  HTMesh 5 		  5 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
  HTMesh 6 		  6 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy
  HTMesh 7 		  7 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
if {$composite} {
	HTMesh 8 		  8 		 3 -phaseChange 1 -NumCtrl $s_elemx $s_elemy
	HTMesh 9 		  9 		 3 -phaseChange 1 -NumCtrl $s_elemx $s_elemy
	HTMesh 54 		  54 		 3 -phaseChange 1 -NumCtrl $f_elemx $s_elemy
	HTMesh 64 		  64 		 3 -phaseChange 1 -NumCtrl $w_elemx $s_elemy
	HTMesh 74 		  74 		 3 -phaseChange 1 -NumCtrl $f_elemx $s_elemy
}
if {$protected} {  
	#bottom flange
	HTMesh 11 		  11 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
	HTMesh 12 		  12 		 2 -phaseChange 0 -NumCtrl $p_elem  $f_elemy
	HTMesh 14 		  14 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
	  
	HTMesh 21 		  21 		 2 -phaseChange 0 -NumCtrl $w_elemx $p_elem

	HTMesh 31 		  31 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
	HTMesh 33 		  33 		 2 -phaseChange 0 -NumCtrl $p_elem  $f_elemy
	HTMesh 34 		  34 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
	  
	#web
	HTMesh 42 		  42 		 2 -phaseChange 0 -NumCtrl $p_elem $w_elemy 
	HTMesh 43 		  43 		 2 -phaseChange 0 -NumCtrl $p_elem $w_elemy
	  
	#top flange
	HTMesh 51 		  51 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
	HTMesh 52 		  52 		 2 -phaseChange 0 -NumCtrl $p_elem  $f_elemy
	HTMesh 71 		  71 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
	HTMesh 73 		  73 		 2 -phaseChange 0 -NumCtrl $p_elem  $f_elemy
	if {!$composite} {
		HTMesh 54 		  54 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
		HTMesh 64 		  64 		 2 -phaseChange 0 -NumCtrl $w_elemx $p_elem
		HTMesh 74 		  74 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
	} elseif {$composite} {
		if {$dps > 1e-8} {
			HTMesh 81 		  81 		 2 -phaseChange 0 -NumCtrl $s_elemx $p_elem
			HTMesh 91 		  91 		 2 -phaseChange 0 -NumCtrl $s_elemx $p_elem
		}
	}	
}

HTMeshAll

set MasterFace12 1
HTNodeSet $MasterFace12 -Entity 1 -Face 3
set SlaveFace12 2
HTNodeSet $SlaveFace12 -Entity 2 -Face 2

set MasterFace32 3
HTNodeSet $MasterFace32 -Entity 3 -Face 2
set SlaveFace32 4
HTNodeSet $SlaveFace32 -Entity 2 -Face 3

set MasterFace24 5
HTNodeSet $MasterFace24 -Entity 2 -Face 4
set SlaveFace24 6
HTNodeSet $SlaveFace24 -Entity 4 -Face 1

set MasterFace46 7
HTNodeSet $MasterFace46 -Entity 4 -Face 4
set SlaveFace46 8
HTNodeSet $SlaveFace46 -Entity 6 -Face 1

set MasterFace65 9
HTNodeSet $MasterFace65 -Entity 6 -Face 2
set SlaveFace65 10
HTNodeSet $SlaveFace65 -Entity 5 -Face 3

set MasterFace67 11
HTNodeSet $MasterFace67 -Entity 6 -Face 3
set SlaveFace67 12
HTNodeSet $SlaveFace67 -Entity 7 -Face 2

if {$composite} {
	set MasterFace749 45
	HTNodeSet $MasterFace749 -Entity 74   -Face 3
	set SlaveFace749 46
	HTNodeSet $SlaveFace749 -Entity 9 -Face 2
	
	set MasterFace548 47
	HTNodeSet $MasterFace548 -Entity 54 -Face 2
	set SlaveFace548 48
	HTNodeSet $SlaveFace548 -Entity 8 -Face 3
	
	set MasterFace554 35
	HTNodeSet $MasterFace554 -Entity 5 -Face 4
	set SlaveFace554 36
	HTNodeSet $SlaveFace554 -Entity 54 -Face 1

	set MasterFace664 37
	HTNodeSet $MasterFace664 -Entity 6 -Face 4   
	set SlaveFace664 38
	HTNodeSet $SlaveFace664 -Entity 64  -Face 1

	set MasterFace774 43  
	HTNodeSet $MasterFace774 -Entity 7 -Face 4
	set SlaveFace774  44 
	HTNodeSet $SlaveFace774 -Entity 74  -Face  1
	
	if {$protected && $dps > 1e-8} {
		set MasterFace919 49
		HTNodeSet $MasterFace919 -Entity 91  -Face 4
		set SlaveFace919 50
		HTNodeSet $SlaveFace919 -Entity 9 -Face 1
		
		set MasterFace818 51
		HTNodeSet $MasterFace818 -Entity 81 -Face 4
		set SlaveFace818 52
		HTNodeSet $SlaveFace818 -Entity 8 -Face 1
	}
}

if {$protected} {
	# bottom flange
	set MasterFace111 13
	HTNodeSet $MasterFace111 -Entity 11 -Face 4
	set SlaveFace111 14
	HTNodeSet $SlaveFace111 -Entity 1 -Face 1

	set MasterFace121 15
	HTNodeSet $MasterFace121 -Entity 12 -Face 3
	set SlaveFace121 16
	HTNodeSet $SlaveFace121 -Entity 1 -Face 2

	set MasterFace141 17
	HTNodeSet $MasterFace141 -Entity 14 -Face 1
	set SlaveFace141 18
	HTNodeSet $SlaveFace141 -Entity 1 -Face 4

	set MasterFace212 19
	HTNodeSet $MasterFace212 -Entity 21  -Face 4 
	set SlaveFace212 20
	HTNodeSet $SlaveFace212 -Entity 2 -Face 1 

	set MasterFace313  21
	HTNodeSet $MasterFace313  -Entity 31  -Face  4
	set SlaveFace313   22
	HTNodeSet $SlaveFace313  -Entity 3 -Face 1

	set MasterFace333  23
	HTNodeSet $MasterFace333  -Entity 33  -Face 2 
	set SlaveFace333   24
	HTNodeSet $SlaveFace333  -Entity 3 -Face 3

	set MasterFace343 25  
	HTNodeSet $MasterFace343  -Entity 34  -Face  1
	set SlaveFace343  26 
	HTNodeSet $SlaveFace343  -Entity 3 -Face 4

	#web
	set MasterFace424  27
	HTNodeSet $MasterFace424  -Entity 42  -Face  3
	set SlaveFace424   28
	HTNodeSet $SlaveFace424  -Entity 4 -Face 2

	set MasterFace434  29
	HTNodeSet $MasterFace434  -Entity 43  -Face 2 
	set SlaveFace434   30
	HTNodeSet $SlaveFace434  -Entity 4 -Face 3

	# top flange
	set MasterFace515 31
	HTNodeSet $MasterFace515 -Entity 51 -Face 4
	set SlaveFace515 32
	HTNodeSet $SlaveFace515 -Entity 5 -Face 1

	set MasterFace525 33
	HTNodeSet $MasterFace525 -Entity 52 -Face 3
	set SlaveFace525 34
	HTNodeSet $SlaveFace525 -Entity 5 -Face 2

	set MasterFace717  39
	HTNodeSet $MasterFace717  -Entity 71  -Face  4
	set SlaveFace717   40
	HTNodeSet $SlaveFace717  -Entity 7 -Face 1

	set MasterFace737  41
	HTNodeSet $MasterFace737  -Entity 73  -Face 2 
	set SlaveFace737   42
	HTNodeSet $SlaveFace737  -Entity 7 -Face 3

	if {!$composite} {
		set MasterFace545 35
		HTNodeSet $MasterFace545 -Entity 54 -Face 1
		set SlaveFace545 36
		HTNodeSet $SlaveFace545 -Entity 5 -Face 4

		set MasterFace646 37
		HTNodeSet $MasterFace646 -Entity 64  -Face 1 
		set SlaveFace646 38
		HTNodeSet $SlaveFace646 -Entity 6 -Face 4 

		set MasterFace747 43  
		HTNodeSet $MasterFace747  -Entity 74  -Face  1
		set SlaveFace747  44 
		HTNodeSet $SlaveFace747  -Entity 7 -Face 4
	}
}


SetInitialT 293.15
HTConstants 1 $hfire 293.15 0.85 0.85
HTConstants 2 $hamb 293.15 0.85 0.85

# thermal load assignment 
set fileName "FDS$ID.dat"

# FireModel	UserDefined	1	-file	$fileName -type 1
FireModel standard 1
# FireModel hydroCarbon 1

HTPattern fire 1 model 1 {
	# coupling
    HTCoupleT -HTNodeSet $MasterFace12 $SlaveFace12;
	HTCoupleT -HTNodeSet $MasterFace32 $SlaveFace32;
	HTCoupleT -HTNodeSet $MasterFace24 $SlaveFace24;
	HTCoupleT -HTNodeSet $MasterFace46 $SlaveFace46;
	HTCoupleT -HTNodeSet $MasterFace65 $SlaveFace65;
	HTCoupleT -HTNodeSet $MasterFace67 $SlaveFace67;
	if {$composite} {
		HTCoupleT -HTNodeSet $MasterFace554 $SlaveFace554;
		HTCoupleT -HTNodeSet $MasterFace664 $SlaveFace664;
		HTCoupleT -HTNodeSet $MasterFace774 $SlaveFace774;
		HTCoupleT -HTNodeSet $MasterFace749 $SlaveFace749;
		HTCoupleT -HTNodeSet $MasterFace548 $SlaveFace548;
	}

	if {$protected} {
		# bottom flange
		HTCoupleT -HTNodeSet $MasterFace111 $SlaveFace111;
		HTCoupleT -HTNodeSet $MasterFace121 $SlaveFace121;
		HTCoupleT -HTNodeSet $MasterFace141 $SlaveFace141;
		HTCoupleT -HTNodeSet $MasterFace212 $SlaveFace212;
		HTCoupleT -HTNodeSet $MasterFace313 $SlaveFace313;
		HTCoupleT -HTNodeSet $MasterFace333 $SlaveFace333;
		HTCoupleT -HTNodeSet $MasterFace343 $SlaveFace343;
		# web
		HTCoupleT -HTNodeSet $MasterFace424 $SlaveFace424;
		HTCoupleT -HTNodeSet $MasterFace434 $SlaveFace434;
		# top flange
		HTCoupleT -HTNodeSet $MasterFace515 $SlaveFace515;
		HTCoupleT -HTNodeSet $MasterFace525 $SlaveFace525;
		HTCoupleT -HTNodeSet $MasterFace717 $SlaveFace717;
		HTCoupleT -HTNodeSet $MasterFace737 $SlaveFace737;
		if {!$composite} {
			HTCoupleT -HTNodeSet $MasterFace545 $SlaveFace545;
			HTCoupleT -HTNodeSet $MasterFace646 $SlaveFace646;
			HTCoupleT -HTNodeSet $MasterFace747 $SlaveFace747;
		} elseif {$composite && $dps > 1e-8} {
			HTCoupleT -HTNodeSet $MasterFace818 $SlaveFace818;
			HTCoupleT -HTNodeSet $MasterFace919 $SlaveFace919;
		}
	}
	
	# heat flux
	if {$protected} {
		# bottom flange
		HeatFluxBC -HTEntity 11 -face 1 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 12 -face 2 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 14 -face 4 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 21 -face 1 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 31 -face 1 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 33 -face 3 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 34 -face 4 -type -ConvecAndRad -HTConstants 1
		# web
		HeatFluxBC -HTEntity 42 -face 2 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 43 -face 3 -type -ConvecAndRad -HTConstants 1
		# top flange	
		HeatFluxBC -HTEntity 51 -face 1 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 52 -face 2 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 71 -face 1 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 73 -face 3 -type -ConvecAndRad -HTConstants 1
		if {$sidesHeated == 4 && !$composite} {
			HeatFluxBC -HTEntity 54 -face 4 -type -ConvecAndRad -HTConstants 1
			HeatFluxBC -HTEntity 64 -face 4 -type -ConvecAndRad -HTConstants 1
			HeatFluxBC -HTEntity 74 -face 4 -type -ConvecAndRad -HTConstants 1
		} elseif {$composite && $dps > 1e-8} {
			HeatFluxBC -HTEntity 91 -face 1 -type -ConvecAndRad -HTConstants 1
			HeatFluxBC -HTEntity 81 -face 1 -type -ConvecAndRad -HTConstants 1
		} elseif {$composite && $dps <= 1e-8} {
			HeatFluxBC -HTEntity 8 -face 1 -type -ConvecAndRad -HTConstants 1
			HeatFluxBC -HTEntity 9 -face 1 -type -ConvecAndRad -HTConstants 1
		}
	} else {
		HeatFluxBC -HTEntity 1 -face 1 2 4 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 2 -face 1 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 3 -face 1 3 4 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 4 -face 2 3 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 5 -face 1 2 4 -type -ConvecAndRad -HTConstants 1
		HeatFluxBC -HTEntity 6 -face 4 -type -ConvecAndRad -HTConstants 1
		if {$sidesHeated == 4 && !$composite} {
			HeatFluxBC -HTEntity 7 -face 1 3 4 -type -ConvecAndRad -HTConstants 1
		} elseif {$composite} {
			HeatFluxBC -HTEntity 8 -face 1 -type -ConvecAndRad -HTConstants 1
			HeatFluxBC -HTEntity 9 -face 1 -type -ConvecAndRad -HTConstants 1
		}
	}
}
if {$composite} {
	HTPattern AmbientBC 2 {
		HeatFluxBC -HTEntity 54 -face 4 -type -ConvecAndRad -HTConstants 2
		HeatFluxBC -HTEntity 64 -face 4 -type -ConvecAndRad -HTConstants 2
		HeatFluxBC -HTEntity 74 -face 4 -type -ConvecAndRad -HTConstants 2
		HeatFluxBC -HTEntity 8 -face 4 -type -ConvecAndRad -HTConstants 2
		HeatFluxBC -HTEntity 9 -face 4 -type -ConvecAndRad -HTConstants 2
	}
}

set MiddleWeb 1000
HTNodeSet $MiddleWeb -Locx 0.0 -Locy 0.0

set TopFlange 1001
HTNodeSet $TopFlange -Locx 0.0 -Locy [expr 0.5*$h - 0.5*$tf]

set BotFlange 1002
HTNodeSet $BotFlange -Locx 0.0 -Locy [expr -0.5*$h + 0.5*$tf]

if {$beamTempPts == 15} {
	#Web
	set T1 101
	HTNodeSet $T1 -Entity 4 -Locx 0.0 -Locy [expr -0.5*$w_y]
	set T2 102
	HTNodeSet $T2 -Entity 4 -Locx 0.0 -Locy [expr -0.25*$w_y]
	set T3 103
	HTNodeSet $T3 -Entity 4 -Locx 0.0 -Locy 0.0
	set T4 104
	HTNodeSet $T4 -Entity 4 -Locx 0.0 -Locy [expr 0.25*$w_y]
	set T5 105
	HTNodeSet $T5 -Entity 4 -Locx 0.0 -Locy [expr 0.5*$w_y]
	# puts "reached line 536. Put your break points and enter any random string."
	# gets stdin randomString
	# Bottom flange
	set ix [expr round($f_elemx*(0.5*$f_x - 0.25*$tw)/$f_x)]
	set f_quarter [expr 0.5*$tw + $ix*$f_x/$f_elemx]
	set err [expr $f_quarter - 0.25*$b]
	puts "The selected point is [expr $err*1000] mm farther from the web than the actual quarter point. \n"
	set T6 106
	HTNodeSet $T6 -Entity 1 -Locx [expr -0.5*$b] -Locy [expr -0.5*$h + 0.5*$tf]
	set T7 107
	HTNodeSet $T7 -Entity 1 -Locx [expr -$f_quarter] -Locy [expr -0.5*$h + 0.5*$tf]
	set T8 108
	HTNodeSet $T8 -Entity 2 -Locx 0.0 -Locy [expr -0.5*$h + 0.5*$tf]
	set T9 109
	HTNodeSet $T9 -Entity 3 -Locx [expr $f_quarter] -Locy [expr -0.5*$h + 0.5*$tf]
	set T10 110
	HTNodeSet $T10 -Entity 3 -Locx [expr 0.5*$b] -Locy [expr -0.5*$h + 0.5*$tf]
	
	# Top flange
	set T11 111
	HTNodeSet $T11 -Entity 5 -Locx [expr -0.5*$b] -Locy [expr 0.5*$h - 0.5*$tf]
	set T12 112
	HTNodeSet $T12 -Entity 5 -Locx [expr -$f_quarter] -Locy [expr 0.5*$h - 0.5*$tf]
	set T13 113
	HTNodeSet $T13 -Entity 6 -Locx 0.0 -Locy [expr 0.5*$h - 0.5*$tf]
	set T14 114
	HTNodeSet $T14 -Entity 7 -Locx [expr $f_quarter] -Locy [expr 0.5*$h - 0.5*$tf]
	set T15 115
	HTNodeSet $T15 -Entity 7 -Locx [expr 0.5*$b] -Locy [expr 0.5*$h - 0.5*$tf]
	
	# Beam thermal load 3D
	set beamTemp 116
	HTNodeSet $beamTemp -NodeSet $T1 $T2 $T3 $T4 $T5 $T6 $T7 $T8 $T9 $T10 $T11 $T12 $T13 $T14 $T15
	HTRecorder -file "Beam$ID.dat" -NodeSet $beamTemp
	
	# Slab thermal load
	if {$composite} {
		set sT1 201
		HTNodeSet $sT1 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h]
		set sT2 202
		HTNodeSet $sT2 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 1*$ts/8]
		set sT3 203
		HTNodeSet $sT3 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 2*$ts/8]
		set sT4 204
		HTNodeSet $sT4 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 3*$ts/8]
		set sT5 205
		HTNodeSet $sT5 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 4*$ts/8]
		set sT6 206
		HTNodeSet $sT6 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 5*$ts/8]
		set sT7 207
		HTNodeSet $sT7 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 6*$ts/8]
		set sT8 208
		HTNodeSet $sT8 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 7*$ts/8]
		set sT9 209
		HTNodeSet $sT9 -Entity 64 -Locx 0.0 -Locy [expr 0.5*$h + 8*$ts/8]
		
		set slabTemp 210
		HTNodeSet $slabTemp -NodeSet $sT1 $sT2 $sT3 $sT4 $sT5 $sT6 $sT7 $sT8 $sT9
		HTRecorder -file "Slab$ID.dat" -NodeSet $slabTemp
	}
}

HTAnalysis HeatTransfer TempIncr 0.1 1000 2 Newton
HTAnalyze [expr $tFinal/$dt] $dt
set reachedTime [getHTTime]
if {[expr $tFinal - $reachedTime] < 1e-3} {
	puts "Success"
} else {
	puts $reachedTime
	puts "Failure"
}
wipeHT