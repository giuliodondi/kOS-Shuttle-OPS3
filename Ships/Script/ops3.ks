@LAZYGLOBAL OFF.

parameter mode_ is "nominal".
parameter force_tgt_select is "".

CLEARSCREEN.
SET CONFIG:IPU TO 1800. 


//determine mode flags
local nominal_flag is false.
local tal_flag is false.
local grtls_flag is false.
local cont_flag is false.
local ecal_flag is false.

if (mode_ = "nominal") {
	set nominal_flag to true.
} else if (mode_ = "tal") {
	set tal_flag to true.
} else if (mode_ = "grtls") {
	set grtls_flag to true.
} else if (mode_ = "cont") {
	set cont_flag to true.
	set grtls_flag to true.
} else if (mode_ = "ecal") {
	set ecal_flag to true.
	set cont_flag to true.
	set grtls_flag to true.
}

RUNPATH("0:/Shuttle_OPS3/parameters").

//hard-coded check to run the script only in atmosphere
// modification : do this only in the nominal case
// we might be in a weird situation at TAL and it's an irrelevant check for grtls and cont
If nominal_flag and (SHIP:ALTITUDE >= ops3_parameters["interfalt"]) {
	PRINT "Not yet below Entry Interface (" + round(ops3_parameters["interfalt"]/1000, 0) + "km),  aborting." .
} ELSE {

	RUNPATH("0:/Shuttle_OPS3/landing_sites").

	RUNPATH("0:/Libraries/misc_library").   
	RUNPATH("0:/Libraries/maths_library").  
	RUNPATH("0:/Libraries/navigation_library"). 
	RUNPATH("0:/Libraries/aerosim_library").    
	RUNPATH("0:/Libraries/vehicle_library").	

	RUNPATH("0:/Shuttle_OPS3/src/ops3_entry_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").
	RUNPATH("0:/Shuttle_OPS3/src/entry_guid.ks").
	RUNPATH("0:/Shuttle_OPS3/src/taem_guid.ks").
	RUNPATH("0:/Shuttle_OPS3/src/ops3_main_executive.ks").

	ops3_main_exec(
					nominal_flag,
					tal_flag, 
					grtls_flag,
					cont_flag,
					ecal_flag,
					force_tgt_select
	).
}
