@LAZYGLOBAL OFF.
CLEARSCREEN.
SET CONFIG:IPU TO 1800. 

RUNPATH("0:/Shuttle_OPS3/parameters").

//hard-coded check to run the script only in atmosphere
If (SHIP:ALTITUDE >= parameters["interfalt"]) {
	PRINT "Not yet below Entry Interface (122km),  aborting." .
} ELSE {

	RUNPATH("0:/Shuttle_OPS3/landing_sites").

	RUNPATH("0:/Libraries/misc_library").   
	RUNPATH("0:/Libraries/maths_library").  
	RUNPATH("0:/Libraries/navigation_library"). 
	RUNPATH("0:/Libraries/aerosim_library").    

	RUNPATH("0:/Shuttle_OPS3/src/ops3_entry_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/entry_guid.ks").
	RUNPATH("0:/Shuttle_OPS3/src/taem_guid.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_main_executive.ks").

	ops3_main_exec().
}
