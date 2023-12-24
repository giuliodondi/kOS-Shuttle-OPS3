RUNONCEPATH("0:/Libraries/misc_library").	
RUNONCEPATH("0:/Libraries/maths_library").	
RUNONCEPATH("0:/Libraries/navigation_library").
RUNONCEPATH("0:/Libraries/aerosim_library").

RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").

RUNPATH("0:/Shuttle_OPS3/vessel_dir").
RUNPATH("0:/Shuttle_OPS3/VESSELS/" + vessel_dir + "/aerosurfaces_control").

LOCAL dap IS dap_hdot_nz_controller_factory().

LOCAL aerosurfaces_control IS aerosurfaces_control_factory().

local engaged Is FALSE.

LOCAL steerdir IS SHIP:FACING.

ON (AG9) {
	IF engaged {
		SET engaged TO FALSE.
		UNLOCK STEERING.
	} ELSe {
		SET engaged TO TRUE.
		dap:reset_steering().
		LOCK STEERING TO steerdir.
	}
	PRESERVE.
}

ON (AG9) {
	IF (dap:mode = "atmo_pch_css") {
		SET dap:mode TO "atmo_hdot_auto".
		dap:reset_hdot_auto().
	} ELSe IF (dap:mode = "atmo_hdot_auto") {
		SET dap:mode TO "atmo_pch_css".
	} 
	PRESERVE.
}

clearscreen.

until false{
	//clearscreen.
	
	IF (SHIP:STATUS = "LANDEd") {
		UNLOCK STEERING.
	}
	
	SET dap:tgt_hdot tO dap:tgt_hdot + 8.0 *SHIP:CONTROL:PILOTPITCH.
	SET dap:tgt_roll tO dap:tgt_roll + 2.0 * SHIP:CONTROL:PILOTROLL.
	SET dap:tgt_yaw tO 5 * SHIP:CONTROL:PILOTYAW.
	
	SET steerdir TO dap:update().
	
	//speed_control(FALSE, aerosurfaces_control, 0).
	aerosurfaces_control["deflect"]().
	
	dap:print_debug(2).
	
	WAIT 0.15.
}