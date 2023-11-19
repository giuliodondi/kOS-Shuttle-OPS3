RUNONCEPATH("0:/Libraries/misc_library").	
RUNONCEPATH("0:/Libraries/maths_library").	
RUNONCEPATH("0:/Libraries/navigation_library").
RUNONCEPATH("0:/Libraries/aerosim_library").

RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").

RUNPATH("0:/Shuttle_OPS3/vessel_dir").
RUNPATH("0:/Shuttle_OPS3/VESSELS/" + vessel_dir + "/aerosurfaces_control").

LOCAL dap IS dap_controller_factory().

LOCAL aerosurfaces_control IS aerosurfaces_control_factory().

local engaged Is FALSE.

LOCAL steerdir IS SHIP:FACING.

ON (AG9) {
	IF engaged {
		SET engaged TO FALSE.
		UNLOCK STEERING.
	} ELSe {
		SET engaged TO TRUE.
		dap:reset_nz_css().
		LOCK STEERING TO steerdir.
	}
	PRESERVE.
}

ON (AG8) {
	IF (dap:mode = "atmo_css") {
		SET dap:mode TO "atmo_nz_css".
	} ELSe IF (dap:mode = "atmo_nz_css") {
		SET dap:mode TO "atmo_css".
	} 
	PRESERVE.
}

clearscreen.

until false{
	//clearscreen.
	
	IF (SHIP:STATUS = "LANDEd") {
		UNLOCK STEERING.
	}
	
	dap:update_nz().
	
	SET steerdir TO dap:update().
	
	speed_control(FALSE, aerosurfaces_control, 0).
	aerosurfaces_control["deflect"]().
	
	dap:print_debug(2).
	
	WAIT 0.15.
}