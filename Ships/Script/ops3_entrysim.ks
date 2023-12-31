@LAZYGLOBAL OFF.
CLEARSCREEN.
SET CONFIG:IPU TO 1800. 


RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	
RUNPATH("0:/Libraries/aerosim_library").	

RUNPATH("0:/Shuttle_OPS3/landing_sites").
RUNPATH("0:/Shuttle_OPS3/parameters").

RUNPATH("0:/Shuttle_OPS3/src/ops3_entry_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").

RUNPATH("0:/Shuttle_OPS3/src/entry_guid.ks").

GLOBAL quit_program IS FALSE.

IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS LEXICON().

//initialise touchdown points for all landing sites
define_td_points().

make_main_ops3_gui().


make_entry_traj_GUI().

gLOBAL sim_input_target IS "".
gLOBAL tal_abort IS FALSE.
GLOBAL ICS IS generate_simulation_ics("edwards").

GLOBAL sim_settings IS LEXICON(
					"deltat",2,
					"integrator","rk3",
					"log",FALSE
	).


IF NOT (DEFINED sim_end_conditions) {
	GLOBAL sim_end_conditions IS LEXICON(
							"altitude",20000,
							"surfvel",500,
							"range_bias",0
	).
}



ops3_reentry_simulate().



close_all_GUIs().


FUNCTION generate_simulation_ics {
	PARAMETER name_.
	
	LOCAL ics_lex IS LEXICON().
	local standard is TRUE.
	
	if (name_ = "edwards") {
		SET ics_lex to LEXICON(
													"target", "Edwards",
													"deorbit_apoapsis", 260,
													"deorbit_periapsis", 0,
													"deorbit_inclination", 40,
													"entry_interf_dist", 6500,
													"entry_interf_xrange", 600,
													"entry_interf_offset", "right"
							).
		set standard to TRUE.
	} else if (name_ = "3a") {
		SET ics_lex to LEXICON(
													"target", "Vandenberg",
													"deorbit_apoapsis", 190,
													"deorbit_periapsis", 30,
													"deorbit_inclination", -104,
													"entry_interf_dist", 8500,
													"entry_interf_xrange", 1400,
													"entry_interf_offset", "right"
							).
		set standard to TRUE.
	} else if (name_ = "tal") {
		SET ics_lex to LEXICON(
													"target", "Istres",
													"deorbit_apoapsis", 115,
													"deorbit_periapsis", -1700,
													"deorbit_inclination", 52,
													"entry_interf_dist", 5000,
													"entry_interf_xrange", 600,
													"entry_interf_offset", "left"
							).
		set standard to FALSE.
		set tal_abort to TRUE.
	}
	
	SET sim_input_target TO ics_lex["target"].

	return calculate_simulation_ics(ics_lex, standard).
}


//given the deorbit and entry interface parameters, generates the simulation initial conditions
FUNCTION calculate_simulation_ics {
	PARAMETER sim_input.
	PARAMETER standard.
	
	LOCAL tgt_pos IS ldgsiteslex[sim_input["target"]]["position"].
	
	LOCAL tgt_vec IS pos2vec(tgt_pos).
	
	//get the azimuth of the orbit at the launch site
	
	LOCAL orbaz IS get_orbit_azimuth(sim_input["deorbit_inclination"], tgt_pos:LAT, (sim_input["deorbit_inclination"] < 0)).
	
	LOCAL orbvec IS vector_pos_bearing(tgt_vec, orbaz).
	
	//normal vector to the orbital plane
	
	LOCAL norm_vec IS VCRS(orbvec, tgt_vec) : NORMALIZED * BODy:RADIUS.
	
	
	LOCAL x IS dist2degrees(sim_input["entry_interf_xrange"]).
	
	//rotate the orbital plane until the crossrange is within about 1 km of the parameter
	
	LOCAL tgt_vec_proj IS V(0,0,0).
	
	LOCAL rot_sign IS 1.
	
	IF sim_input["entry_interf_offset"] = "left" {
		SET rot_sign TO -1.
	}
	
	UNTIL FALSE {
	
		SET tgt_vec_proj TO VXCL(norm_vec, tgt_vec): NORMALIZED * BODy:RADIUS.
	
		LOCAL xrange_err IS x - VANG(tgt_vec, tgt_vec_proj).
		
		IF xrange_err < 0.01 {BREAK.}
		
		LOCAL rot IS xrange_err * 1.5.
		
		SET norm_vec TO rodrigues(norm_vec, V(0,1,0), rot_sign*rot).
		
		WAIT 0.
	}
	
	if (standard) {
		local ei_calc is deorbit_ei_calc(sim_input["deorbit_apoapsis"], parameters["interfalt"]/1000).




		LOCAL d IS dist2degrees(ei_calc["ei_range"]).

		LOCAL y IS get_c_ab(d, x).

		LOCAL ei_vec IS rodrigues(tgt_vec_proj, norm_vec, y).

		//scale by entry interface altitude
		LOCAL h IS BODy:RADIUS + parameters["interfalt"].
		SET ei_vec TO ei_vec:NORMALIZED * h.

		clearvecdraws().
		arrow_body(tgt_vec,"tgt_vec").
		arrow_body(norm_vec,"norm_vec").
		arrow_body(ei_vec,"ei_vec").


		print "x " + x + " d " + d + " y " + y at (0,8).

		//conditions at entry interface


		LOCAL ei_vel IS ei_calc["ei_vel"].
		LOCAL ei_fpa IS ei_calc["ei_fpa"].

		print "ap " + ei_calc["ap"] + " pe " + ei_calc["pe"] + " range " + ei_calc["ei_range"] at (0,9).
		print "vel " + ei_calc["ei_vel"] + " gamma " + ei_calc["ei_fpa"] at (0,10).

		//now get velocity vector at the entry interface
		LOCAL ei_vel_vec IS VCRs(ei_vec, norm_vec):NORMALIZED.

		SET ei_vel_vec TO rodrigues(ei_vel_vec, norm_vec, ei_calc["ei_fpa"]):NORMALIZED * ei_calc["ei_vel"].

		RETURN 	LEXICON(
						 "position",ei_vec,
						 "velocity",ei_vel_vec
		).
	} else {
		LOCAL d IS dist2degrees(sim_input["entry_interf_dist"]).
	
		LOCAL y IS get_c_ab(d, x).
		
		LOCAL ei_vec IS rodrigues(tgt_vec_proj, norm_vec, y).
		
		//scale by entry interface altitude
		LOCAL h IS BODy:RADIUS + parameters["interfalt"].
		SET ei_vec TO ei_vec:NORMALIZED * h.
		
		clearvecdraws().
		arrow_body(tgt_vec,"tgt_vec").
		arrow_body(norm_vec,"norm_vec").
		arrow_body(ei_vec,"ei_vec").


		print "x " + x + " d " + d + " y " + y at (0,8).
		print "dist " + greatcircledist( ei_vec , tgt_vec ) at (0,9).
		
		//conditions at entry interface
		
		LOCAL ei_sma IS orbit_appe_sma(sim_input["deorbit_apoapsis"], sim_input["deorbit_periapsis"]).
		LOCAL ei_ecc IS orbit_appe_ecc(sim_input["deorbit_apoapsis"], sim_input["deorbit_periapsis"]).
		
		print "sma " + ei_sma + " ecc " + ei_ecc at (0,10).
		
		LOCAL ei_vel IS orbit_alt_vel(parameters["interfalt"] + BODY:RADIUS, ei_sma).
		LOCAL ei_eta IS 180 + orbit_alt_eta(parameters["interfalt"] + BODY:RADIUS, ei_sma, ei_ecc).
		LOCAL ei_fpa IS orbit_eta_fpa(ei_eta, ei_sma, ei_ecc).
		
		print "vel " + ei_vel + " eta " + ei_eta + " gamma " + ei_fpa at (0,11).
		
		//now get velocity vector at the entry interface
		LOCAL ei_vel_vec IS VCRs(ei_vec, norm_vec):NORMALIZED.
		
		SET ei_vel_vec TO rodrigues(ei_vel_vec, norm_vec, ei_fpa):NORMALIZED * ei_vel.

		RETURN 	LEXICON(
						 "position",ei_vec,
						 "velocity",ei_vel_vec
		).
	}
}



FUNCTION ops3_reentry_simulate {

	
	
	LOCAL tgt_rwy IS ldgsiteslex[sim_input_target].
		
	//Initialise log lexicon 
	GLOBAL loglex IS LEXICON(
										"step",1,
										"time",0,
										"alt",0,
										"vel",0,
										"surfv",0,
										"hdot",0,
										"range",0,
										"az_err",0,
										"lat",0,
										"long",0,
										"pitch",0,
										"roll",0,
										"unl_roll",0,
										"roll_ref",0,
										"l_d",0,
										"drag",0,
										"drag_ref",0,
										"hdot_ref",0,
										"entry_phase",1

	).
	
	
	log_data(loglex,"0:/Shuttle_OPS3/LOGS/sim_log_" + sim_input_target, TRUE).
	
	//define the delegate to the integrator function, saves an if check per integration step
	IF sim_settings["integrator"]= "rk2" {
		SET sim_settings["integrator"] TO rk2@.
	}
	ELSE IF sim_settings["integrator"]= "rk3" {
		SET sim_settings["integrator"] TO rk3@.
	}
	ELSE IF sim_settings["integrator"]= "rk4" {
		SET sim_settings["integrator"] TO rk4@.
	}
	

	LOCAL simstate IS blank_simstate(ICS).
	
	
	LOCAL tgtpos IS tgt_rwy["position"].
	LOCAL tgtalt IS tgt_rwy["elevation"] + sim_end_conditions["altitude"].
	
	//sample initial values for proper termination conditions check
	SET simstate["altitude"] TO bodyalt(simstate["position"]).
	SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).
	
	LOCAL next_simstate IS simstate.

	local step_c is 0.
	
	LOCAL pitch_prof IS 0.
	LOCAL roll_prof IS 0.
	
	
	//putting the termination conditions here should save an if check per step
	UNTIL (( next_simstate["altitude"]< tgtalt AND next_simstate["surfvel"]:MAG < sim_end_conditions["surfvel"] ) OR next_simstate["altitude"]>140000)  {
		SET step_c TO step_c + 1.
	
		SET simstate TO next_simstate.
		
		local ve is simstate["surfvel"].
		local vi is simstate["velocity"].
		
		local entry_state IS get_reentry_state(
			simstate["position"],
			simstate["latlong"],
            ve,
            tgt_rwy
		). 
		
		//should already be acceleration
		LOCAL aerolex IS LEXICON(
								"drag", 0,
								"load", 0,
								"lod", 0
		).
		LOCAL aeroacc IS aeroaccel_ld(simstate["position"], ve, LIST(pitch_prof,roll_prof)).
			
		//drag forces are alyways in imperial
		set aerolex["drag"] to aeroacc["drag"]*mt2ft.
		set aerolex["xlfac"] to aeroacc["load"]:MAG*mt2ft.
		set aerolex["lod"] to aeroacc["lift"]/aeroacc["drag"].
		
		
		//call entry guidance here
		LOCAL entryg_out is entryg_wrapper(
									lexicon(
											"iteration_dt", sim_settings["deltat"],
											"tgtsite", sim_input_target,
											"tgt_range", entry_state["tgt_range"],
											"delaz", entry_state["delaz"],   
											"ve", ve:MAG,
											"vi", vi:MAG,
											"hls", entry_state["hls"],	
											"hdot", entry_state["hdot"],  
											"alpha", pitch_prof,      
											"roll", roll_prof,  
											"drag", aerolex["drag"],
											"xlfac", aerolex["xlfac"],     	
											"lod", aerolex["lod"],
											"egflg", 0, 
											"ital", tal_abort,
											"debug", TRUE
									)
		).
		
		SET pitch_prof TO entryg_out["alpcmd"].
		//simulate roll lag
		LOCAL del_rol IS entryg_out["rolcmd"] - roll_prof.
		SET roll_prof TO roll_prof + SIGN(del_rol)* MIN(20, ABS(del_rol)).
		
		//log stuff to file and terminal before integrating
		
		//this must be after anything using latlong
		SET simstate["latlong"] TO shift_pos(simstate["position"],simstate["simtime"]).
		
		
		SET loglex["step"] TO step_c.
		SET loglex["time"] TO simstate["simtime"].
		SET loglex["alt"] TO (entry_state["hls"])/1000.
		SET loglex["vel"] TO vi:MAG.
		SET loglex["surfv"] TO ve:MAG.
		SET loglex["hdot"] TO entry_state["hdot"].
		SET loglex["lat"] TO simstate["latlong"]:LAT.
		SET loglex["long"] TO simstate["latlong"]:LNG.
		SET loglex["range"] TO entry_state["tgt_range"].
		SET loglex["az_err"] TO entry_state["delaz"].
		SET loglex["pitch"] TO pitch_prof.
		SET loglex["roll"] TO roll_prof.
		SET loglex["unl_roll"] TO entryg_out["unl_roll"].
		SET loglex["roll_ref"] TO entryg_out["roll_ref"].
		SET loglex["l_d"] TO aerolex["lod"].
		SET loglex["entry_phase"] TO entryg_out["islect"].
		SET loglex["drag"] TO aerolex["drag"].
		SET loglex["drag_ref"] TO entryg_out["drag_ref"].
		SET loglex["hdot_ref"] TO entryg_out["hdot_ref"].
		log_data(loglex,"0:/Shuttle_OPS3/LOGS/sim_log_" + sim_input_target).
		
		PRINTPLACE("step : " + loglex["step"], 20,0,1).
		PRINTPLACE("alt : " + round(entry_state["hls"],0), 20,0,2).
		PRINTPLACE("ve : " + round(ve:MAG,0), 20,0,3).
		PRINTPLACE("vi : " + round(vi:MAG,0), 20,0,4).
		PRINTPLACE("hdot : " + round(entry_state["hdot"],1), 20,0,5).
		PRINTPLACE("tgt_range : " + round(entry_state["tgt_range"],0), 20,0,6).
		PRINTPLACE("delaz : " + round(entry_state["delaz"],2), 20,0,7).

		
		local gui_data is lexicon(
								"iter", step_c,
								"range",entry_state["tgt_range"],
								"ve",ve:MAG,
								"xlfac",aerolex["xlfac"],
								"lod",aerolex["lod"],
								"drag",aerolex["drag"],
								"drag_ref",entryg_out["drag_ref"],
								"phase",entryg_out["islect"],
								"hdot_ref",entryg_out["hdot_ref"],
								"pitch_cmd",entryg_out["alpcmd"],
								"roll_cmd",entryg_out["rolcmd"],
								"roll_ref",entryg_out["roll_ref"],
								"pitch_mod",entryg_out["pitch_mod"],
								"roll_rev",entryg_out["roll_rev"]
		).
		update_entry_traj_disp(gui_data).
		
		if (entryg_out["eg_end"]) {
			print "entry guidance switched to taem" at (0, 20).
			BREAK.
		}
		
		if (quit_program) {
			print "entry guidance aborted" at (0, 20).
			BREAK.
		}
		
		
		
		//finally do the step and save quantities for termination condition
		SET next_simstate TO sim_settings["integrator"]:CALL(sim_settings["deltat"],simstate,LIST(pitch_prof,roll_prof)).
		
		SET next_simstate["altitude"] TO bodyalt(next_simstate["position"]).
		SET next_simstate["surfvel"] TO surfacevel(next_simstate["velocity"],next_simstate["position"]).
		
	}


}

