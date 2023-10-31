RUNONCEPATH("0:/Libraries/misc_library").	
RUNONCEPATH("0:/Libraries/maths_library").	
RUNONCEPATH("0:/Libraries/navigation_library").
RUNONCEPATH("0:/Libraries/aerosim_library").

RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").

LOCAL dap IS dap_controller_factory().

local engaged Is FALSE.

LOCAL steerdir IS SHIP:FACING.

ON (AG9) {
	IF engaged {
		SET engaged TO FALSE.
		UNLOCK STEERING.
	} ELSe {
		SET engaged TO TRUE.
		LOCK STEERING TO steerdir.
	}
	PRESERVE.
}

clearscreen.

until false{
	//clearscreen.
	
	dap:update_nz().
	
	SET steerdir TO dap:atmo_nz_css().
	
	dap:print_debug(2).
	
	WAIT 0.15.
}