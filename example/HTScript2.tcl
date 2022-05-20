wipe
wipeHT 
set mode auto
set variables {ID composite slab protection_material tf tw h b dp dps ts bs plt FireExposure tFinal dt hfire hamb}
puts "argc = $argc"
puts "number of variables = [llength $variables]"
if {$mode == "auto"} { 
	if {$argc >= [llength $variables]} {
		lassign $argv {*}$variables
	} else {
		puts "Script requires [llength $variables] arguments. Only $argc arguments were given. Aborting analysis."
		return -1
	}
}
file mkdir log
logFile "log/log$ID.log"
puts "This is job number $ID"
foreach arg $variables {
	puts "$arg = [subst $$arg]"
}
# puts "received secondinput = [lindex $argv 1]"

# set sidesHeated [lindex $argv 1]
set sidesHeated 4
if {$sidesHeated != 3 && $sidesHeated != 4} {
	puts "sidesHeated got a value of $sidesHeated; can only be 3 or 4."
	return -1
}
if {$mode == "manual"} {
	set protection_material 1
	set tf 25e-3
	set tw 10e-3
	set h 400e-3
	set b 300e-3
	set dp 10e-3

	set dps 0.020
	set ts 150e-3
	set bs 600e-3

	set plt 0.0

	set composite FALSE
	set slab TRUE

	set FireExposure 1
	#1 for standard fire
	#2 for hydroCarbon fire
	#3 for FDS/user-defined fire

	set tFinal 1000
	set dt 10
	set hfire 35.0
	set hamb 10.0
}
set values "$tf $tw $b $dp $dps $ts"
set okay 1
set i 0

while {$okay && $i < [llength $values]} {
	set item [lindex $values $i]
	set okay [expr $item < 1 && $item >= 0]
	incr i
}

if {!$okay} {
	puts "one the dimensions {tf tw b dp dps ts} exceeds 1 m or is negative which is unreasonable. Continue anyway? {y/n}\n" 
	gets stdin continue
	if {$continue == "y" || $continue == "Y" } {
		puts "Continuing with the anlaysis.\n"
	} else { 
		puts "Received $continue. Aborting analysis.\n"
		return -1
	}
}


if {$dp == 0} {
	set protected FALSE
} else {
	set protected TRUE
}

if {$plt == 0} {
	set stiffened FALSE
} else {
	set stiffened TRUE
}

if {$composite && $stiffened} {
	puts "the section cannot be stiffened and composite at the same time."
	return -1
}

if {$slab && [expr $composite || $stiffened]} {
	if {$composite} {
		puts "Section cannot be a slab and composite at the same time. Aborting analysis."
	} else {
		puts "Section cannot be a slab and stiffened at the same time. Aborting analysis."
	}
	return -1
}

# meshing parameters
set f_elemx [expr max(4,int(($b - $tw)/0.025))]
if {fmod($f_elemx,2)} {
	set f_elemx [expr int($f_elemx+1)]
}
set f_elemy [expr max(4,int($tf/0.015))]
if {fmod($f_elemy,2)} {
	set f_elemy [expr int($f_elemy+1)]
}
set w_elemx [expr max(4,int($tw/0.015))]
if {fmod($w_elemx,2)} {
	set w_elemx [expr int($w_elemx+1)]
}
set w_elemy [expr max(8,int(($h-$tf)/0.025))]
if {fmod($w_elemy,4)} {
	if {![expr fmod($w_elemy + fmod($w_elemy,4),4)]} {
		set w_elemy [expr int($w_elemy + fmod($w_elemy,4))]
	} else {
		set w_elemy [expr int($w_elemy - fmod($w_elemy,4))]
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
if {$slab} {
	set s_elemx [expr max(20,int(($bs)/0.05))]
} else {
	set s_elemx [expr max(8,int(($bs-$b)/0.025))]
}
if {fmod($s_elemx,2)} {
	set s_elemx [expr int($s_elemx + 1)]
}

puts "flange mesh: dfx, dfy = $f_elemx, $f_elemy"
puts "web mesh: dwx, dwy = $w_elemx, $w_elemy"
puts "slab mesh: dsx, dsy = $s_elemx, $s_elemy"
puts "protection mesh: $p_elem"
# Block centroids 
set f_x [expr 0.5*$b - 0.5*$tw]
set w_y [expr $h - 2*$tf]
set s_x [expr 0.5*($bs - $b)]
if {$composite && $s_x <= 0} {
	puts "slab is less wide than the beam:\nBeam is $b m wide, while slab is $bs m wide.\nTerminating analysis."
	return -1
}

if {$slab} {
	set centrex1 0.0
	set centrey1 0.0
	if {$protected} {
		set centrex2 0.0
		set centrey2 [expr -0.5*$ts - 0.5*$dps]
	}
} else {
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
	} elseif {$stiffened} {
		set centrex100 [expr -$f_x-0.5*$tw - 0.5*$plt] 
		set centrey100 [expr -0.5*$h + 0.5*$tf]
		
		set centrex110 [expr -$f_x-0.5*$tw - 0.5*$plt] 
		set centrey110 0.0

		set centrex120 [expr -$f_x-0.5*$tw - 0.5*$plt] 
		set centrey120 [expr 0.5*$h - 0.5*$tf]	

		set centrex130 [expr $f_x+0.5*$tw+0.5*$plt] 
		set centrey130 [expr -0.5*$h + 0.5*$tf]
		
		set centrex140 [expr $f_x+0.5*$tw+0.5*$plt] 
		set centrey140 0.0

		set centrex150 [expr $f_x+0.5*$tw+0.5*$plt]
		set centrey150 [expr 0.5*$h - 0.5*$tf]
	}

	if {$protected} {
		# bottom flange
		set centrex11 [expr -0.5*$f_x - 0.5*$tw] 
		set centrey11 [expr -0.5*$h - 0.5*$dp]	
		
		set centrex21 0.0 
		set centrey21 [expr -0.5*$h - 0.5*$dp]

		set centrex31 [expr 0.5*$f_x + 0.5*$tw] 
		set centrey31 [expr -0.5*$h - 0.5*$dp]
		
		if {$stiffened} {
			#left stiffening plate
			set centrex1001 [expr -$f_x-0.5*$tw - 0.5*$plt]  
			set centrey1001 [expr -0.5*$h -0.5*$dp]
			
			set centrex1002 [expr -$f_x-0.5*$tw - $plt - 0.5*$dp] 
			set centrey1002 [expr -0.5*$h + 0.5*$tf]
			
			set centrex1102 [expr -$f_x-0.5*$tw - $plt - 0.5*$dp] 
			set centrey1102 0.0

			set centrex1202 [expr -$f_x-0.5*$tw - $plt - 0.5*$dp] 
			set centrey1202 [expr 0.5*$h - 0.5*$tf]	
			
			set centrex1204 [expr -$f_x-0.5*$tw - 0.5*$plt] 
			set centrey1204 [expr 0.5*$h + 0.5*$dp]

			#right stiffening plate
			set centrex1301 [expr $f_x+0.5*$tw+0.5*$plt] 
			set centrey1301 [expr -0.5*$h -0.5*$dp]
			
			set centrex1303 [expr $f_x+ 0.5*$tw + $plt + 0.5*$dp] 
			set centrey1303 [expr -0.5*$h + 0.5*$tf]
			
			set centrex1403 [expr $f_x+ 0.5*$tw + $plt + 0.5*$dp]
			set centrey1403 0.0

			set centrex1503 [expr $f_x+ 0.5*$tw + $plt + 0.5*$dp]
			set centrey1503 [expr 0.5*$h - 0.5*$tf]	

			set centrex1504 [expr $f_x+0.5*$tw+0.5*$plt]
			set centrey1504 [expr 0.5*$h + 0.5*$dp]	
		} elseif {!$stiffened} {
			set centrex12 [expr -0.5*$b - 0.5*$dp] 
			set centrey12 [expr -0.5*$h + 0.5*$tf]
			
			set centrex14 [expr -0.5*$f_x - 0.5*$tw] 
			set centrey14 [expr -0.5*$h + $tf + 0.5*$dp]
			
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
		}

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
}
HeatTransfer 2D;

#Defining HeatTransfer Material with Material tag 1.
HTMaterial CarbonSteelEC3 1;
HTMaterial SFRM 2 $protection_material;
HTMaterial ConcreteEC2 3 0.0;
puts "creating entities"
if {$slab} {
	HTEntity Block 1 $centrex1 $centrey1 $bs $ts;
	if {$protected} {
		HTEntity Block 2 $centrex2 $centrey2 $bs $dps;
	}
} else {
	#Creating entitities
	puts "first set"
	HTEntity Block 1 $centrex1 $centrey1 $f_x $tf;
	HTEntity Block 2 $centrex2 $centrey2 $tw  $tf;
	HTEntity Block 3 $centrex3 $centrey3 $f_x $tf;
	HTEntity Block 4 $centrex4 $centrey4 $tw  $w_y;
	HTEntity Block 5 $centrex5 $centrey5 $f_x $tf;
	HTEntity Block 6 $centrex6 $centrey6 $tw  $tf;
	HTEntity Block 7 $centrex7 $centrey7 $f_x $tf;
	puts "stiffened set"
	if {$stiffened} {
		#left stiffening plate
		HTEntity Block 100 $centrex100 $centrey100 $plt $tf;
		HTEntity Block 110 $centrex110 $centrey110 $plt $w_y;
		HTEntity Block 120 $centrex120 $centrey120 $plt $tf;

		#right stiffening plate
		HTEntity Block 130 $centrex130 $centrey130 $plt $tf;
		HTEntity Block 140 $centrex140 $centrey140 $plt $w_y;
		HTEntity Block 150 $centrex150 $centrey150 $plt $tf;
	}
	puts "composite set"
	if {$composite} {
		HTEntity Block 8 $centrex8 $centrey8 $s_x $ts;
		HTEntity Block 9 $centrex9 $centrey9 $s_x $ts;
		HTEntity Block 54 $centrex54 $centrey54 $f_x $ts;
		HTEntity Block 64 $centrex64 $centrey64 $tw $ts;
		HTEntity Block 74 $centrex74 $centrey74 $f_x $ts;
	}
	puts "protected set"
	if {$protected} {
	puts "protected set"
		if {!$stiffened} {
		puts "protected and unstiffened"
			HTEntity Block 14 $centrex14 $centrey14 $f_x $dp;
			HTEntity Block 12 $centrex12 $centrey12 $dp $tf;
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
		} elseif {$stiffened} {
		puts "protected and stiffened"
			#left stiffening plate
			HTEntity Block 1001 $centrex1001 $centrey1001 $plt $dp;
			HTEntity Block 1002 $centrex1002 $centrey1002 $dp $tf;
			HTEntity Block 1102 $centrex1102 $centrey1102 $dp $w_y;
			HTEntity Block 1202 $centrex1202 $centrey1202 $dp $tf;
			HTEntity Block 1204 $centrex1204 $centrey1204 $plt $dp;

			#right stiffening plate
			HTEntity Block 1301 $centrex1301 $centrey1301 $plt $dp;
			HTEntity Block 1303 $centrex1303 $centrey1303 $dp $tf;
			HTEntity Block 1403 $centrex1403 $centrey1403 $dp $w_y;
			HTEntity Block 1503 $centrex1503 $centrey1503 $dp $tf;
			HTEntity Block 1504 $centrex1504 $centrey1504 $plt $dp;
		}
		puts "bottom flange protection"
		#bottom flange
		HTEntity Block 11 $centrex11 $centrey11 $f_x $dp;
		HTEntity Block 21 $centrex21 $centrey21 $tw $dp;
		HTEntity Block 31 $centrex31 $centrey31 $f_x $dp;

		
		if {!$composite} {
		puts "non composite"
			#top flange
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
}
puts "creating mesh controls"
if {$slab} {
	HTMesh 1 		  1 		 3 -phaseChange 1 -NumCtrl $s_elemx $s_elemy
	if {$protected} {
		HTMesh 2 		  2		 3 -phaseChange 0 -NumCtrl $s_elemx $p_elem
	}
} else {
	# HTMesh $meshTag $EntityTag $MaterialTag 
	  HTMesh 1 		  1 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
	  HTMesh 2 		  2 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy
	  HTMesh 3 		  3 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
	  HTMesh 4 		  4 		 1 -phaseChange 1 -NumCtrl $w_elemx $w_elemy
	  HTMesh 5 		  5 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
	  HTMesh 6 		  6 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy
	  HTMesh 7 		  7 		 1 -phaseChange 1 -NumCtrl $f_elemx $f_elemy
	  
	  if {$stiffened} {
		HTMesh 100 		  100 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy
		HTMesh 110 		  110 		 1 -phaseChange 1 -NumCtrl $w_elemx $w_elemy
		HTMesh 120 		  120 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy

		HTMesh 130 		  130 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy
		HTMesh 140 		  140 		 1 -phaseChange 1 -NumCtrl $w_elemx $w_elemy
		HTMesh 150 		  150 		 1 -phaseChange 1 -NumCtrl $w_elemx $f_elemy
	  }
	  
	if {$composite} {
		HTMesh 8 		  8 		 3 -phaseChange 1 -NumCtrl $s_elemx $s_elemy
		HTMesh 9 		  9 		 3 -phaseChange 1 -NumCtrl $s_elemx $s_elemy
		HTMesh 54 		  54 		 3 -phaseChange 1 -NumCtrl $f_elemx $s_elemy
		HTMesh 64 		  64 		 3 -phaseChange 1 -NumCtrl $w_elemx $s_elemy
		HTMesh 74 		  74 		 3 -phaseChange 1 -NumCtrl $f_elemx $s_elemy
	}
	if {$protected} {  
		if {!$stiffened} {
			HTMesh 12 		  12 		 2 -phaseChange 0 -NumCtrl $p_elem  $f_elemy
			HTMesh 14 		  14 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
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
		} elseif {$stiffened} {
			HTMesh 1001 		  1001 		 2 -phaseChange 0 -NumCtrl $w_elemx $p_elem
			HTMesh 1002 		  1002 		 2 -phaseChange 0 -NumCtrl $p_elem $f_elemy
			HTMesh 1102 		  1102 		 2 -phaseChange 0 -NumCtrl $p_elem $w_elemy
			HTMesh 1202 		  1202 		 2 -phaseChange 0 -NumCtrl $p_elem $f_elemy	
			HTMesh 1204 		  1204 		 2 -phaseChange 0 -NumCtrl $w_elemx $p_elem

			HTMesh 1301 		  1301 		 2 -phaseChange 0 -NumCtrl $w_elemx $p_elem
			HTMesh 1303 		  1303 		 2 -phaseChange 0 -NumCtrl $p_elem $f_elemy
			HTMesh 1403 		  1403 		 2 -phaseChange 0 -NumCtrl $p_elem $w_elemy
			HTMesh 1503 		  1503 		 2 -phaseChange 0 -NumCtrl $p_elem $f_elemy	
			HTMesh 1504 		  1504 		 2 -phaseChange 0 -NumCtrl $w_elemx $p_elem
		}
		#bottom flange
		HTMesh 11 		  11 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem
		HTMesh 21 		  21 		 2 -phaseChange 0 -NumCtrl $w_elemx $p_elem
		HTMesh 31 		  31 		 2 -phaseChange 0 -NumCtrl $f_elemx $p_elem

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
}
puts "meshing"
HTMeshAll

puts "Creating constraint couple-faces"
if {$slab} {
	if {$protected} {
		set MasterFace21 1
		HTNodeSet $MasterFace21 -Entity 2 -Face 4
		set SlaveFace21 2
		HTNodeSet $SlaveFace21 -Entity 1 -Face 1
	}
} else {
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

	if {$stiffened} {
		#Left plate
		set MasterFace1001 13
		HTNodeSet $MasterFace1001 -Entity 100 -Face 3
		set SlaveFace1001 14
		HTNodeSet $SlaveFace1001 -Entity 1 -Face 2
		
		set MasterFace110100 15
		HTNodeSet $MasterFace110100 -Entity 110 -Face 1
		set SlaveFace110100 16
		HTNodeSet $SlaveFace110100 -Entity 100 -Face 4
		
		set MasterFace110120 17
		HTNodeSet $MasterFace110120 -Entity 110 -Face 4
		set SlaveFace110120 18
		HTNodeSet $SlaveFace110120 -Entity 120 -Face 1

		set MasterFace1205 19
		HTNodeSet $MasterFace1205 -Entity 120 -Face 3
		set SlaveFace1205 20
		HTNodeSet $SlaveFace1205 -Entity 5 -Face 2
		
		#Right plate
		set MasterFace1303 21
		HTNodeSet $MasterFace1303 -Entity 130 -Face 2
		set SlaveFace1303 22
		HTNodeSet $SlaveFace1303 -Entity 3 -Face 3
		
		set MasterFace140130 23
		HTNodeSet $MasterFace140130 -Entity 140 -Face 1
		set SlaveFace140130 24
		HTNodeSet $SlaveFace140130 -Entity 130 -Face 4
		
		set MasterFace140150 25
		HTNodeSet $MasterFace140150 -Entity 140 -Face 4
		set SlaveFace140150 26
		HTNodeSet $SlaveFace140150 -Entity 150 -Face 1
		
		set MasterFace1507 27
		HTNodeSet $MasterFace1507 -Entity 150 -Face 2
		set SlaveFace1507 28
		HTNodeSet $SlaveFace1507 -Entity 7 -Face 3
	}

	if {$composite} {
		set MasterFace749 29
		HTNodeSet $MasterFace749 -Entity 74   -Face 3
		set SlaveFace749 30
		HTNodeSet $SlaveFace749 -Entity 9 -Face 2
		
		set MasterFace548 31
		HTNodeSet $MasterFace548 -Entity 54 -Face 2
		set SlaveFace548 32
		HTNodeSet $SlaveFace548 -Entity 8 -Face 3
		
		set MasterFace554 33
		HTNodeSet $MasterFace554 -Entity 5 -Face 4
		set SlaveFace554 34
		HTNodeSet $SlaveFace554 -Entity 54 -Face 1

		set MasterFace664 35
		HTNodeSet $MasterFace664 -Entity 6 -Face 4   
		set SlaveFace664 36
		HTNodeSet $SlaveFace664 -Entity 64  -Face 1

		set MasterFace774 37  
		HTNodeSet $MasterFace774 -Entity 7 -Face 4
		set SlaveFace774  38 
		HTNodeSet $SlaveFace774 -Entity 74  -Face  1
		
		if {$protected && $dps > 1e-8} {
			set MasterFace919 39
			HTNodeSet $MasterFace919 -Entity 91  -Face 4
			set SlaveFace919 40
			HTNodeSet $SlaveFace919 -Entity 9 -Face 1
			
			set MasterFace818 41
			HTNodeSet $MasterFace818 -Entity 81 -Face 4
			set SlaveFace818 42
			HTNodeSet $SlaveFace818 -Entity 8 -Face 1
		}
	}

	if {$protected} {
		if {!$stiffened} {
			set MasterFace121 43
			HTNodeSet $MasterFace121 -Entity 12 -Face 3
			set SlaveFace121 44
			HTNodeSet $SlaveFace121 -Entity 1 -Face 2

			set MasterFace141 45
			HTNodeSet $MasterFace141 -Entity 14 -Face 1
			set SlaveFace141 46
			HTNodeSet $SlaveFace141 -Entity 1 -Face 4

			set MasterFace333  47
			HTNodeSet $MasterFace333  -Entity 33  -Face 2 
			set SlaveFace333   48
			HTNodeSet $SlaveFace333  -Entity 3 -Face 3

			set MasterFace343 49  
			HTNodeSet $MasterFace343  -Entity 34  -Face  1
			set SlaveFace343  50 
			HTNodeSet $SlaveFace343  -Entity 3 -Face 4	
			
			#web
			set MasterFace424  51
			HTNodeSet $MasterFace424  -Entity 42  -Face  3
			set SlaveFace424   52
			HTNodeSet $SlaveFace424  -Entity 4 -Face 2

			set MasterFace434  53
			HTNodeSet $MasterFace434  -Entity 43  -Face 2 
			set SlaveFace434   54
			HTNodeSet $SlaveFace434  -Entity 4 -Face 3
			
			# top flange
			set MasterFace515 55
			HTNodeSet $MasterFace515 -Entity 51 -Face 4
			set SlaveFace515 56
			HTNodeSet $SlaveFace515 -Entity 5 -Face 1

			set MasterFace525 57
			HTNodeSet $MasterFace525 -Entity 52 -Face 3
			set SlaveFace525 58
			HTNodeSet $SlaveFace525 -Entity 5 -Face 2
			
			set MasterFace717  59
			HTNodeSet $MasterFace717  -Entity 71  -Face  4
			set SlaveFace717   60
			HTNodeSet $SlaveFace717  -Entity 7 -Face 1

			set MasterFace737  61
			HTNodeSet $MasterFace737  -Entity 73  -Face 2 
			set SlaveFace737   62
			HTNodeSet $SlaveFace737  -Entity 7 -Face 3
		} elseif {$stiffened} {
			#left stiffening plate
			set MasterFace1001100 63
			HTNodeSet $MasterFace1001100 -Entity 1001 -Face 4
			set SlaveFace1001100 64
			HTNodeSet $SlaveFace1001100 -Entity 100 -Face 1
			
			set MasterFace1002100 65
			HTNodeSet $MasterFace1002100 -Entity 1002 -Face 3
			set SlaveFace1002100 66
			HTNodeSet $SlaveFace1002100 -Entity 100 -Face 2
			
			set MasterFace1102110 67
			HTNodeSet $MasterFace1102110 -Entity 1102 -Face 3
			set SlaveFace1102110 68
			HTNodeSet $SlaveFace1102110 -Entity 110 -Face 2
			
			set MasterFace1202120 69
			HTNodeSet $MasterFace1202120 -Entity 1202 -Face 3
			set SlaveFace1202120 70
			HTNodeSet $SlaveFace1202120 -Entity 120 -Face 2
			
			set MasterFace1204120 71
			HTNodeSet $MasterFace1204120 -Entity 1204 -Face 1
			set SlaveFace1204120 72
			HTNodeSet $SlaveFace1204120 -Entity 120 -Face 4
			
			#right stiffening plate
			set MasterFace1301130 73
			HTNodeSet $MasterFace1301130 -Entity 1301 -Face 4
			set SlaveFace1301130 74
			HTNodeSet $SlaveFace1301130 -Entity 130 -Face 1

			set MasterFace1303130 75
			HTNodeSet $MasterFace1303130 -Entity 1303 -Face 2
			set SlaveFace1303130 76
			HTNodeSet $SlaveFace1303130 -Entity 130 -Face 3

			set MasterFace1403140 77
			HTNodeSet $MasterFace1403140 -Entity 1403 -Face 2
			set SlaveFace1403140 78
			HTNodeSet $SlaveFace1403140 -Entity 140 -Face 3

			set MasterFace1503150 79
			HTNodeSet $MasterFace1503150 -Entity 1503 -Face 2
			set SlaveFace1503150 80
			HTNodeSet $SlaveFace1503150 -Entity 150 -Face 3

			set MasterFace1504150 81
			HTNodeSet $MasterFace1504150 -Entity 1504 -Face 1
			set SlaveFace1504150 82
			HTNodeSet $SlaveFace1504150 -Entity 150 -Face 4		
		}
		# bottom flange
		set MasterFace111 83
		HTNodeSet $MasterFace111 -Entity 11 -Face 4
		set SlaveFace111 84
		HTNodeSet $SlaveFace111 -Entity 1 -Face 1
		
		set MasterFace212 85
		HTNodeSet $MasterFace212 -Entity 21  -Face 4 
		set SlaveFace212 86
		HTNodeSet $SlaveFace212 -Entity 2 -Face 1 

		set MasterFace313  87
		HTNodeSet $MasterFace313  -Entity 31  -Face  4
		set SlaveFace313   88
		HTNodeSet $SlaveFace313  -Entity 3 -Face 1

		if {!$composite} {
			set MasterFace545 89
			HTNodeSet $MasterFace545 -Entity 54 -Face 1
			set SlaveFace545 90
			HTNodeSet $SlaveFace545 -Entity 5 -Face 4

			set MasterFace646 91
			HTNodeSet $MasterFace646 -Entity 64  -Face 1 
			set SlaveFace646 92
			HTNodeSet $SlaveFace646 -Entity 6 -Face 4 

			set MasterFace747 93  
			HTNodeSet $MasterFace747  -Entity 74  -Face  1
			set SlaveFace747  94 
			HTNodeSet $SlaveFace747  -Entity 7 -Face 4
		}
	}
}

SetInitialT 293.15
HTConstants 1 $hfire 293.15 0.85 0.85
HTConstants 2 $hamb 293.15 0.85 0.85

# thermal load assignment 
set fileName "FDS$ID.dat"

if {$FireExposure == 1} {
	FireModel standard 1
	puts "standard fire exposure."
	
} elseif {$FireExposure == 2} {
	FireModel hydroCarbon 1
	puts "Hydro carbon fire exposure." 
 
} elseif {$FireExposure == 3} {
	FireModel	UserDefined	1	-file	$fileName -type 1
	puts "User-defined fire exposure."
	
} else {
	puts "unknown fire exposure type. Aborting analysis." 
	return -1
	
}

HTPattern fire 1 model 1 {
	if {$slab} {
		if {$protected} {
			HTCoupleT -HTNodeSet $MasterFace21 $SlaveFace21;
			HeatFluxBC -HTEntity 2 -face 1 -type -ConvecAndRad -HTConstants 1
		} else {
			HeatFluxBC -HTEntity 1 -face 1 -type -ConvecAndRad -HTConstants 1
		}
	} else {
		# coupling
		HTCoupleT -HTNodeSet $MasterFace12 $SlaveFace12;
		HTCoupleT -HTNodeSet $MasterFace32 $SlaveFace32;
		HTCoupleT -HTNodeSet $MasterFace24 $SlaveFace24;
		HTCoupleT -HTNodeSet $MasterFace46 $SlaveFace46;
		HTCoupleT -HTNodeSet $MasterFace65 $SlaveFace65;
		HTCoupleT -HTNodeSet $MasterFace67 $SlaveFace67;
		if {$stiffened} {
			HTCoupleT -HTNodeSet $MasterFace1001 $SlaveFace1001;
			HTCoupleT -HTNodeSet $MasterFace110100 $SlaveFace110100;
			HTCoupleT -HTNodeSet $MasterFace110120 $SlaveFace110120;
			HTCoupleT -HTNodeSet $MasterFace1205 $SlaveFace1205;
			
			HTCoupleT -HTNodeSet $MasterFace1303 $SlaveFace1303;
			HTCoupleT -HTNodeSet $MasterFace140130 $SlaveFace140130;
			HTCoupleT -HTNodeSet $MasterFace140150 $SlaveFace140150;
			HTCoupleT -HTNodeSet $MasterFace1507 $SlaveFace1507;
		}
		if {$composite} {
			HTCoupleT -HTNodeSet $MasterFace554 $SlaveFace554;
			HTCoupleT -HTNodeSet $MasterFace664 $SlaveFace664;
			HTCoupleT -HTNodeSet $MasterFace774 $SlaveFace774;
			HTCoupleT -HTNodeSet $MasterFace749 $SlaveFace749;
			HTCoupleT -HTNodeSet $MasterFace548 $SlaveFace548;
		}

		if {$protected} {
			if {!$stiffened} {
				HTCoupleT -HTNodeSet $MasterFace121 $SlaveFace121;
				HTCoupleT -HTNodeSet $MasterFace141 $SlaveFace141;
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
			} elseif {$stiffened} {
				# left plate
				HTCoupleT -HTNodeSet $MasterFace1001100 $SlaveFace1001100;
				HTCoupleT -HTNodeSet $MasterFace1002100 $SlaveFace1002100;
				HTCoupleT -HTNodeSet $MasterFace1102110 $SlaveFace1102110;
				HTCoupleT -HTNodeSet $MasterFace1202120 $SlaveFace1202120;
				HTCoupleT -HTNodeSet $MasterFace1204120 $SlaveFace1204120;
				
				# right plate
				HTCoupleT -HTNodeSet $MasterFace1301130 $SlaveFace1301130;
				HTCoupleT -HTNodeSet $MasterFace1303130 $SlaveFace1303130;
				HTCoupleT -HTNodeSet $MasterFace1403140 $SlaveFace1403140;
				HTCoupleT -HTNodeSet $MasterFace1503150 $SlaveFace1503150;
				HTCoupleT -HTNodeSet $MasterFace1504150 $SlaveFace1504150;
			}
			# bottom flange
			HTCoupleT -HTNodeSet $MasterFace111 $SlaveFace111;
			HTCoupleT -HTNodeSet $MasterFace212 $SlaveFace212;
			HTCoupleT -HTNodeSet $MasterFace313 $SlaveFace313;
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
			HeatFluxBC -HTEntity 21 -face 1 -type -ConvecAndRad -HTConstants 1
			HeatFluxBC -HTEntity 31 -face 1 -type -ConvecAndRad -HTConstants 1
			if {!$stiffened} { 
				HeatFluxBC -HTEntity 12 -face 2 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 14 -face 4 -type -ConvecAndRad -HTConstants 1
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
			} elseif {$stiffened} {
				#left plate
				HeatFluxBC -HTEntity 1001 -face 1 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1002 -face 2 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1102 -face 2 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1202 -face 2 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1204 -face 4 -type -ConvecAndRad -HTConstants 1
				
				#right plate
				HeatFluxBC -HTEntity 1301 -face 1 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1303 -face 3 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1403 -face 3 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1503 -face 3 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 1504 -face 4 -type -ConvecAndRad -HTConstants 1
			}

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
			if {!$stiffened} {
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
			} elseif {$stiffened} {
				HeatFluxBC -HTEntity 1 -face 1 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 2 -face 1 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 3 -face 1 -type -ConvecAndRad -HTConstants 1
				
				HeatFluxBC -HTEntity 130 -face 1 3 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 140 -face 3 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 150 -face 3 4 -type -ConvecAndRad -HTConstants 1
				
				HeatFluxBC -HTEntity 7 -face 4 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 6 -face 4 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 5 -face 4 -type -ConvecAndRad -HTConstants 1
				
				HeatFluxBC -HTEntity 120 -face 2 4 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 110 -face 2 -type -ConvecAndRad -HTConstants 1
				HeatFluxBC -HTEntity 100 -face 2 1 -type -ConvecAndRad -HTConstants 1
			}
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
} elseif {$slab} {
HTPattern AmbientBC 2 {
		HeatFluxBC -HTEntity 1 -face 4 -type -ConvecAndRad -HTConstants 2
	}
}

puts "creating nodesets and recorders"
if {$slab} {
	set sT1 201
	HTNodeSet $sT1 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts]
	set sT2 202
	HTNodeSet $sT2 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 1*$ts/8]
	set sT3 203
	HTNodeSet $sT3 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 2*$ts/8]
	set sT4 204
	HTNodeSet $sT4 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 3*$ts/8]
	set sT5 205
	HTNodeSet $sT5 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 4*$ts/8]
	set sT6 206
	HTNodeSet $sT6 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 5*$ts/8]
	set sT7 207
	HTNodeSet $sT7 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 6*$ts/8]
	set sT8 208
	HTNodeSet $sT8 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 7*$ts/8]
	set sT9 209
	HTNodeSet $sT9 -Entity 1 -Locx 0.0 -Locy [expr -0.5*$ts + 8*$ts/8]
	
	set slabTemp 210
	HTNodeSet $slabTemp -NodeSet $sT1 $sT2 $sT3 $sT4 $sT5 $sT6 $sT7 $sT8 $sT9
	HTRecorder -file "Slab$ID.dat" -NodeSet $slabTemp
} else {

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
	if {!$stiffened} {
		HTRecorder -file "Beam$ID.dat" -NodeSet $beamTemp
	}
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

	if {$stiffened} {
		#left plate
		set lplT1 301
		HTNodeSet $lplT1 -Entity 110 -Locx [expr -$f_x-0.5*$tw - 0.5*$plt] -Locy [expr -0.5*$w_y]
		set lplT2 302
		HTNodeSet $lplT2 -Entity 110 -Locx [expr -$f_x-0.5*$tw - 0.5*$plt] -Locy [expr -0.25*$w_y]
		set lplT3 303
		HTNodeSet $lplT3 -Entity 110 -Locx [expr -$f_x-0.5*$tw - 0.5*$plt] -Locy 0.0
		set lplT4 304
		HTNodeSet $lplT4 -Entity 110 -Locx [expr -$f_x-0.5*$tw - 0.5*$plt] -Locy [expr 0.25*$w_y]
		set lplT5 305
		HTNodeSet $lplT5 -Entity 110 -Locx [expr -$f_x-0.5*$tw - 0.5*$plt] -Locy [expr 0.5*$w_y]
		
		set rplT1 306
		HTNodeSet $rplT1 -Entity 140 -Locx [expr $f_x+0.5*$tw+0.5*$plt] -Locy [expr -0.5*$w_y]
		set rplT2 307
		HTNodeSet $rplT2 -Entity 140 -Locx [expr $f_x+0.5*$tw+0.5*$plt] -Locy [expr -0.25*$w_y]
		set rplT3 308
		HTNodeSet $rplT3 -Entity 140 -Locx [expr $f_x+0.5*$tw+0.5*$plt] -Locy 0.0
		set rplT4 309
		HTNodeSet $rplT4 -Entity 140 -Locx [expr $f_x+0.5*$tw+0.5*$plt] -Locy [expr 0.25*$w_y]
		set rplT5 310
		HTNodeSet $rplT5 -Entity 140 -Locx [expr $f_x+0.5*$tw+0.5*$plt] -Locy [expr 0.5*$w_y]
		
		set StiffenedBeamTemp 311
		HTNodeSet $StiffenedBeamTemp -NodeSet $beamTemp $lplT1 $lplT2 $lplT3 $lplT4 $lplT5 $rplT1 $rplT2 $rplT3 $rplT4 $rplT5
		HTRecorder -file "Column$ID.dat" -NodeSet $StiffenedBeamTemp
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