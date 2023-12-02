CLEARSCREEN.


RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	
RUNPATH("0:/Libraries/aerosim_library").	

RUNPATH("0:/Shuttle_OPS3/landing_sites").
RUNPATH("0:/Shuttle_OPS3/constants").

RUNPATH("0:/Shuttle_OPS3/src/ops3_entry_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").

RUNPATH("0:/Shuttle_OPS3/src/taem_guid.ks").

RUNPATH("0:/Shuttle_OPS3/vessel_dir").
RUNPATH("0:/Shuttle_OPS3/VESSELS/" + vessel_dir + "/aerosurfaces_control").

GLOBAL quit_program IS FALSE.

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//initialise touchdown points for all landing sites
define_td_points().

//after the td points but before anything that modifies the default button selections
make_main_entry_gui().

make_hud_gui().

ops3_taem_test().



close_all_GUIs().




FUNCTION ops3_taem_test {
	SET CONFIG:IPU TO 1800.	
	
	
	LOCAL dap IS dap_controller_factory().
	
	SET dap:mode TO "atmo_pch_css".
	
	LOCAL aerosurfaces_control IS aerosurfaces_control_factory().
	
	aerosurfaces_control["set_aoa_feedback"](50).
	
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
	
	//Initialise log lexicon 
	GLOBAL loglex IS LEXICON(
							"iphase",1,
							"time",0,
							"alt",0,
							"speed",0,
							"mach",0,
							"hdot",0,
							"lat",0,
							"long",0,
							"x",0,
							"y",0,
							
							"rpred", 0,
							"herror", 0,
							"psha", 0,
							"dpsac", 0,
							
							"nzc", 0,
							"nztotal", 0,
							"phic_at", 0,
							"dsbc_at", 0,
							
							"eow",0,
							"es",0,
							"en",0,
							"emep",0
	).
	
	until false{
		clearscreen.
		clearvecdraws().
		
		if (quit_program) {
			break.
		}
		
		IF (SHIP:STATUS = "LANDEd") {
			UNLOCK STEERING.
		}
	
		
		LOCAL rwystate IS get_runway_rel_state(
			-SHIP:ORBIT:BODY:POSITION,
			SHIP:VELOCITY:SURFACE,
			tgtrwy
		).
		
		
		
		local taemg_in is LEXICON(
											"h", rwystate["h"],
											"hdot", rwystate["hdot"],
											"x", rwystate["x"], 
											"y", rwystate["y"], 
											"surfv", rwystate["surfv"],
											"surfv_h", rwystate["surfv_h"],
											"xdot", rwystate["xdot"], 
											"ydot", rwystate["ydot"], 
											"psd", rwystate["rwy_rel_crs"], 
											"mach", rwystate["mach"],
											"qbar", rwystate["qbar"],
											"phi",  rwystate["phi"],
											"theta", rwystate["theta"],
											"m", rwystate["mass"],
											"gamma", rwystate["fpa"],
											"ovhd", tgtrwy["overhead"],
											"rwid", tgtrwy["name"]
									).
									
							
		
		//call taem guidance here
		LOCAL taemg_out is taemg_wrapper(
										taemg_in						
		).
		
		build_hac_points(taemg_out, tgtrwy).
		
		IF EXISTS("0:/taemg_internal.txt") {
			DELETEPATH("0:/taemg_internal.txt").
		}
		
		log taemg_internal:dump() to "0:/taemg_internal.txt".
		
		print 	taemg_out.	
		
		
		pos_arrow(tgtrwy["position"],"runwaypos", 5000, 0.1).
		pos_arrow(tgtrwy["td_pt"],"td_pt", 5000, 0.1).
		pos_arrow(tgtrwy["end_pt"],"end_pt" , 5000, 0.1).
		pos_arrow(tgtrwy["hac_exit"],"hac_exit" , 5000, 0.1).
		pos_arrow(tgtrwy["hac_centre"],"hac_centre" , 5000, 0.1).
		pos_arrow(tgtrwy["hac_tan"],"hac_tan" , 5000, 0.1).
		
		LOCAL lvlh_pch IS get_pitch_lvlh().
		LOCAL lvlh_rll IS get_roll_lvlh().
		LOCAL cur_nz IS get_current_nz().
		
		LOCAL deltas IS LIST(
									taemg_out["phic_at"] - lvlh_rll, 
									taemg_out["nztotal"] -  cur_nz
		).
		
		
		SET steerdir TO dap:update().
		
		flaptrim_control(TRUE, aerosurfaces_control).
		SET aerosurfaces_control["spdbk_defl"] TO taemg_out["dsbc_at"].
		aerosurfaces_control["deflect"]().
		
		update_hud_gui(
			"ACQ",
			"AUTO",
			diamond_deviation_taem(deltas),
			rwystate["h"] / 1000,
			taemg_out["rpred"] / 1000,
			rwystate["rwy_rel_crs"],
			ADDONS:FAR:MACH,
			lvlh_pch,
			lvlh_rll,
		    aerosurfaces_control["spdbk_defl"],
			aerosurfaces_control["flap_defl"],
			cur_nz
		).
		
		GLOBAL loglex IS LEXICON(
							"iphase",1,
							"time",0,
							"alt",0,
							"speed",0,
							"mach",0,
							"hdot",0,
							"lat",0,
							"long",0,
							
							"x",0,
							"y",0,
							
							"rpred", 0,
							"herror", 0,
							"psha", 0,
							"dpsac", 0,
							
							"nzc", 0,
							"nztotal", 0,
							"phic_at", 0,
							"dsbc_at", 0,
							
							"eow",0,
							"es",0,
							"en",0,
							"emep",0
		).
		
		SET loglex["time"] TO TIME:SECONDS.
		SET loglex["alt"] TO taemg_in["h"].
		SET loglex["speed"] TO taemg_in["surfv"]. 
		SET loglex["mach"] TO taemg_in["mach"]. 
		SET loglex["hdot"] TO taemg_in["hdot"].
		SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
		SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
		
		SET loglex["x"] TO taemg_in["x"].
		SET loglex["y"] TO taemg_in["y"].
		
		SET loglex["rpred"] TO taemg_out["rpred"].
		SET loglex["herror"] TO taemg_out["herror"].
		SET loglex["psha"] TO taemg_out["psha"].
		SET loglex["dpsac"] TO taemg_out["dpsac"].
		
		SET loglex["nzc"] TO taemg_out["nzc"].
		SET loglex["nztotal"] TO taemg_out["nztotal"].
		SET loglex["phic_at"] TO taemg_out["phic_at"].
		SET loglex["dsbc_at"] TO taemg_out["dsbc_at"].
		
		SET loglex["eow"] TO taemg_out["eow"].
		SET loglex["es"] TO taemg_out["es"].
		SET loglex["en"] TO taemg_out["en"].
		SET loglex["emep"] TO taemg_out["emep"].
		
		log_data(loglex,"0:/Shuttle_OPS3/LOGS/taem_log").
	
		
		wait 0.15.
	}
	
}