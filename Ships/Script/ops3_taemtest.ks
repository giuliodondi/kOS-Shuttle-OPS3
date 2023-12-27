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
	
	
	LOCAL dap IS dap_hdot_nz_controller_factory().
	
	SET dap:mode TO "atmo_pch_css".

	dap:set_taem_pid_gains().
	
	LOCAL aerosurfaces_control IS aerosurfaces_control_factory().
	
	aerosurfaces_control["set_aoa_feedback"](50).
	
	LOCAL steerdir IS SHIP:FACING.
	
	dap:reset_steering().
	LOCK STEERING TO steerdir.
	SAS OFF.
	
	LOCAL css_flag Is TRUE.

	ON (AG9) {
		IF (dap:mode = "atmo_pch_css") {
			SET dap:mode TO "atmo_hdot_auto".
			dap:reset_hdot_auto().
		} ELSe IF (dap:mode = "atmo_hdot_auto") {
			SET dap:mode TO "atmo_pch_css".
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
	
	
	
	local control_loop is loop_executor_factory(
		0.1,
		{
			
			SET steerdir TO dap:update().
		
			flaptrim_control(TRUE, aerosurfaces_control).
			aerosurfaces_control:deflect().
			
		}
	).
	
	//initialise with just the a/L end flag
	LOCAL taemg_out is LEXICON("al_end", FALSE).
	//initialise as empty 
	LOCAL rwystate IS get_runway_rel_state(
			-SHIP:ORBIT:BODY:POSITION,
			SHIP:VELOCITY:SURFACE,
			tgtrwy
		).
	
	
	LOCAL last_iter Is TIMe:SECONDS.
	until false{
		clearvecdraws().
		
		if (quit_program OR taemg_out["al_end"]) {
			break.
		}
		
		
	
		
		set rwystate to get_runway_rel_state(
			-SHIP:ORBIT:BODY:POSITION,
			SHIP:VELOCITY:SURFACE,
			tgtrwy,
			rwystate
		).
		
		LOCAL cur_iter IS TIMe:SECONDS.
		
		
		local taemg_in is LEXICON(
											"dtg", rwystate["dt"],
											"wow", measure_wow(),
											"h", rwystate["h"],
											"hdot", rwystate["hdot"],
											"hddot", rwystate["hddot"],
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
									
		SET last_iter TO cur_iter.
		
		//call taem guidance here
		SET taemg_out TO taemg_wrapper(
										taemg_in						
		).
		
		build_taemg_guid_points(taemg_out, tgtrwy).
		
		SET aerosurfaces_control["spdbk_defl"] TO taemg_out["dsbc_at"].
		SET dap:tgt_hdot tO taemg_out["hdrefc"].
		SET dap:tgt_roll tO taemg_out["phic_at"].
		SET dap:tgt_yaw tO taemg_out["betac_at"].

		IF (RCS) and (rwystate["mach"] < 0.9) {
			RCS OFF.
		}

		if (NOT GEAR) and (taemg_out["geardown"]) {
			GEAR ON.
		}
		
		if (NOT BRAKES) and (taemg_out["brakeson"]) {
			BRAKES ON.
		}

		if (taemg_in["wow"]) {
			set dap:pitch_channel_engaged to FALSE.
			set aerosurfaces_control:flap_engaged to FALSE.
		}
		
		
		LOCAL lvlh_pch IS get_pitch_lvlh().
		LOCAL lvlh_rll IS get_roll_lvlh().
		LOCAL cur_nz IS get_current_nz().
		
		LOCAL deltas IS LIST(
									taemg_out["phic_at"] - lvlh_rll, 
									taemg_out["hdrefc"] -  taemg_in["hdot"]
		).

		if (taemg_out["itran"]) {
			hud_decluttering(taemg_out["guid_id"]).
			//at flare transition, change gains 
			if (taemg_out["guid_id"] >= 34) {
				dap:set_landing_pid_gains().
			}
		}
		
		update_hud_gui(
			taemg_out["guid_id"],
			css_flag,
			diamond_deviation_taem(deltas),
			rwystate["h"],
			taemg_out["rpred"] / 1000,
			rwystate["rwy_rel_crs"],
			lvlh_pch,
			lvlh_rll,
		    aerosurfaces_control["spdbk_defl"],
			aerosurfaces_control["flap_defl"],
			cur_nz
		).
		
		
		//GLOBAL loglex IS LEXICON(
		//					"iphase",1,
		//					"time",0,
		//					"alt",0,
		//					"speed",0,
		//					"mach",0,
		//					"hdot",0,
		//					"lat",0,
		//					"long",0,
		//					"psd", 0,
		//					
		//					"x",0,
		//					"y",0,
		//					
		//					"rpred", 0,
		//					"herror", 0,
		//					"psha", 0,
		//					"dpsac", 0,
		//					
		//					"nzc", 0,
		//					"nztotal", 0,
		//					"phic_at", 0,
		//					"dsbc_at", 0,
		//					
		//					"eow",0,
		//					"es",0,
		//					"en",0,
		//					"emep",0
		//).
		//
		//SET loglex["iphase"] TO taemg_out["iphase"].
		//SET loglex["time"] TO TIME:SECONDS.
		//SET loglex["alt"] TO taemg_in["h"].
		//SET loglex["speed"] TO taemg_in["surfv"]. 
		//SET loglex["mach"] TO taemg_in["mach"]. 
		//SET loglex["hdot"] TO taemg_in["hdot"].
		//SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
		//SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
		//SET loglex["psd"] TO taemg_in["psd"].
		//
		//SET loglex["x"] TO taemg_in["x"].
		//SET loglex["y"] TO taemg_in["y"].
		//
		//SET loglex["rpred"] TO taemg_out["rpred"].
		//SET loglex["herror"] TO taemg_out["herror"].
		//SET loglex["hdref"] TO taemg_out["hdref"].
		//SET loglex["psha"] TO taemg_out["psha"].
		//SET loglex["dpsac"] TO taemg_out["dpsac"].
		//
		//SET loglex["dnzc"] TO taemg_out["dnzc"].
		//SET loglex["nzc"] TO taemg_out["nzc"].
		//SET loglex["nztotal"] TO taemg_out["nztotal"].
		//SET loglex["phic_at"] TO taemg_out["phic_at"].
		//SET loglex["dsbc_at"] TO taemg_out["dsbc_at"].
		//
		//SET loglex["eow"] TO taemg_out["eow"].
		//SET loglex["es"] TO taemg_out["es"].
		//SET loglex["en"] TO taemg_out["en"].
		//SET loglex["emep"] TO taemg_out["emep"].
		//
		//log_data(loglex,"0:/Shuttle_OPS3/LOGS/taem_log", TRUE).
		
		dap:print_debug(2).
		
		WAIt 0.
	}
	
	
	control_loop:stop_execution().
	clearscreen.
}