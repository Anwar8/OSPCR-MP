# Written by Mhd Anwar Orabi 2021
# BSE, The Hong Kong Polytechnic University
# Please do NOT delete any of the items in this template unless instructed to do so.

# All tcl files used with this software must include the ID as the first input, and MUST.
# Contain the log file as specified here.
set ID [lindex $argv 0]
logFile log$ID.log
puts "This is job number $ID"

# use set variableName [lindex $argv argumentNumber] to initialise your variables. 
# Note that input variable 0 must be the ID assigned previously. See example below for next variable:
set beamDepth [lindex $argv 1]

# If you are going to use an external file (earthquake record, temperature file, etc.), 
# then use the ID number to differentiate it for each case you're running.
# For example, for files called FDS946654.dat where 946654 is my ID number, you can use: 
set fileName "FDS$ID.dat"

# likewise, for your recorders use the ID number to differentiate the output of your different cases. 
HTRecorder -file "Beam$ID.dat" -NodeSet 5
	
# Your analysis must run up to time tFinal (which you specify)
set tFinal 100

# Delete one of these statements according to your analysis type (HT or structural)
set reachedTime [getHTTime]; # HT 
set reachedTime [getTime]; # Structural
# you must have this if statement BEFORE your "wipe" command, and it MUST be the last
# item in your tcl file. 
if {[expr $tFinal - $reachedTime] < 1e-3} {
	puts "Success"
} else {
	puts $reachedTime
	puts "Failure"
}

# place your "wipe" command here (wipeHT for HT, and wipe for structural analysis) - delete as approporiate
wipeHT
wipe