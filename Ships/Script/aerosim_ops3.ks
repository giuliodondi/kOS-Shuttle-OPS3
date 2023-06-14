CLEARSCREEN.


RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	
RUNPATH("0:/Libraries/aerosim_library").	

RUNPATH("0:/Shuttle_OPS3/landing_sites").
RUNPATH("0:/Shuttle_OPS3/constants").


RUNPATH("0:/Shuttle_OPS3/src/entry_guid.ks").




//GLOBAL sim_input IS LEXICON(
//						"target", "Vandenberg",
//						"deorbit_apoapsis", 190,
//						"deorbit_periapsis", 10,
//						"deorbit_inclination", -103.5,
//						"entry_interf_eta", 150,
//						"entry_interf_dist", 9500,
//						"entry_interf_xrange", 1400,
//						"entry_interf_offset", "right"
//).


GLOBAL sim_input IS LEXICON(
						"target", "KSC",
						"deorbit_apoapsis", 220,
						"deorbit_periapsis", 10,
						"deorbit_inclination", 52.5,
						"entry_interf_eta", 130,
						"entry_interf_dist", 9500,
						"entry_interf_xrange", 1000,
						"entry_interf_offset", "right"
).

GLOBAL ICS IS generate_simulation_ics(sim_input).

GLOBAL sim_settings IS LEXICON(
					"deltat",2,
					"integrator","rk3",
					"log",FALSE
	).


IF NOT (DEFINED sim_end_conditions) {
	GLOBAL sim_end_conditions IS LEXICON(
							"altitude",30000,
							"surfvel",900,
							"range_bias",-70
	).
}


//given the deorbit and entry interface parameters, generates the simulation initial conditions
FUNCTION generate_simulation_ics {
	PARAMETER sim_input.
	
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
	
	LOCAL d IS dist2degrees(sim_input["entry_interf_dist"]).
	
	LOCAL y IS get_c_ab(d, x).
	
	LOCAL ei_vec IS rodrigues(tgt_vec_proj, norm_vec, y).
	
	//scale by entry interface altitude
	LOCAL h IS BODy:RADIUS + constants["interfalt"].
	SET ei_vec TO ei_vec:NORMALIZED * h.
	
	clearvecdraws().
	arrow_body(tgt_vec,"tgt_vec").
	arrow_body(norm_vec,"norm_vec").
	arrow_body(ei_vec,"ei_vec").


	print "x " + x + " d " + d + " y " + y at (0,8).
	print "dist " + greatcircledist( ei_vec , tgt_vec ) at (0,9).
	
	//conditions at entry interface
	
	
	LOCAL ei_vel IS orbit_velocity_altitude(sim_input["deorbit_apoapsis"], sim_input["deorbit_periapsis"], constants["interfalt"]).
	LOCAL ei_fpa IS orbit_gamma_altitude(sim_input["deorbit_apoapsis"], sim_input["deorbit_periapsis"], constants["interfalt"]).
	
	print "vel " + ei_vel + " gamma " + ei_fpa at (0,10).
	
	//now get velocity vector at the entry interface
	LOCAL ei_vel_vec IS VCRs(ei_vec, norm_vec):NORMALIZED.
	
	SET ei_vel_vec TO rodrigues(ei_vel_vec, norm_vec, ei_fpa):NORMALIZED * ei_vel.

	RETURN 	LEXICON(
					 "position",ei_vec,
	                 "velocity",ei_vel_vec
	).
}


FUNCTION orbit_velocity_altitude {
	PARAMETER ap.
	PARAMETER pe.
	PARAMETER h.
	
	LOCAL sma IS (ap*1000 + pe*1000 + 2*BODY:RADIUS)/2.
	
	LOCAL rad IS h + BODY:RADIUS.
	
	RETURN SQRT( BODY:MU * ( 2/rad - 1/sma  ) ).

}

FUNCTION orbit_eta_altitude {
	PARAMETER ap.
	PARAMETER pe.
	PARAMETER h.
	
	LOCAL sma IS (ap*1000 + pe*1000 + 2*BODY:RADIUS)/2.
	LOCAL ecc IS (ap*1000 - pe*1000) / (ap*1000 + pe*1000 + 2*BODY:RADIUS).
	
	LOCAL rad IS h + BODY:RADIUS.
	
	LOCAL eta_ IS (sma * (1 - ecc^2) / rad - 1) / ecc.
	
	RETURN ARCCOS(eta_).
}

FUNCTION orbit_gamma_altitude {
	PARAMETER ap.
	PARAMETER pe.
	PARAMETER h.

	LOCAL sma IS (ap*1000 + pe*1000 + 2*BODY:RADIUS)/2.
	LOCAL ecc IS (ap*1000 - pe*1000) / (ap*1000 + pe*1000 + 2*BODY:RADIUS).
	
	LOCAL eta_ IS orbit_eta_altitude(ap, pe, h).
	
	LOCAL gamma IS ecc * SIN(eta_) / (1 + ecc * COS(eta_) ).
	
	//assumed downwards
	RETURN -ARCTAN(gamma).
}


FUNCTION ops3_reentry_simulate {
	SET CONFIG:IPU TO 1800.					//	Required to run the script fast enough.
	if  (defined logname) {UNSET logname.}
	CLEARSCREEN.

	
	
	LOCAL tgt_rwy IS ldgsiteslex[sim_input["target"]].
		
	//Initialise log lexicon 
	GLOBAL loglex IS LEXICON(
										"step",1,
										"time",0,
										"alt",0,
										"speed",0,
										"hdot",0,
										"range",0,
										"lat",0,
										"long",0,
										"pitch",0,
										"roll",0,
										"tgt_range",0,
										"range_err",0,
										"az_err",0,
										"roll_ref",0,
										"l_d",0


	).
	
	log_data(loglex,"0:/Shuttle_OPS3/LOGS/sim_log_" + sim_input["target"] + "_" + sim_input["deorbit_inclination"] + "_" + sim_input["entry_interf_xrange"] , TRUE).
	
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
	
	//set equal to mm304 parameters
	LOCAL pitch_0 is entryg_constants["mm304alp0"].
	LOCAL pitch_prof IS pitch_0.
	
	LOCAL roll_0 IS entryg_constants["mm304phi0"].
	LOCAL roll_prof IS roll_0.
	
	
	//putting the termination conditions here should save an if check per step
	UNTIL (( next_simstate["altitude"]< tgtalt AND next_simstate["surfvel"]:MAG < sim_end_conditions["surfvel"] ) OR next_simstate["altitude"]>140000)  {
		SET step_c TO step_c + 1.
	
		SET simstate TO next_simstate.
		
		LOCAL hdot IS VDOT(simstate["position"]:NORMALIZED,simstate["surfvel"]).

		LOCAL delaz IS az_error(simstate["latlong"],tgtpos,simstate["surfvel"]).
		
		LOCAL tgt_range IS greatcircledist( tgtpos , simstate["latlong"] ).
		
		//should already be acceleration
		LOCAL aeroacc IS aeroaccel_ld(simstate["position"], simstate["surfvel"], LIST(pitch_prof,roll_prof)).
		
		local hls is simstate["altitude"] - tgt_rwy["elevation"].
		
		local ve is simstate["surfvel"]:MAG.
		local vi is simstate["velocity"]:MAG.
		
		LOCAL xlfac IS aeroacc["load"]:MAG.
		local lod is aeroacc["lift"]/aeroacc["drag"].
		
		//call entry guidance here
		LOCAL entryg_out is entryg_wrapper(
									lexicon(
											"iteration_dt", sim_settings["deltat"],
											"alpha", pitch_prof,      
											"delaz", delaz,      
											"drag", aeroacc["drag"],
											"egflg", 0,      
											"hls", hls,		
											"lod", lod,
											"hdot", hdot,  
											"roll", roll_prof,
											"tgt_range", tgt_range,
											"ve", ve,
											"vi", vi,	
											"xlfac", xlfac,
											"roll0", roll_0,    
											"alpha0", pitch_0
									)
		).
		
		SET pitch_prof TO entryg_out["alpha"].
		SET roll_prof TO entryg_out["roll"].
		
		//log stuff to file and terminal before integrating
		
		//this must be after anything using latlong
		SET simstate["latlong"] TO shift_pos(simstate["position"],simstate["simtime"]).
		
		
		SET loglex["step"] TO step_c.
		SET loglex["time"] TO simstate["simtime"].
		SET loglex["alt"] TO (hls)/1000.
		SET loglex["speed"] TO vi.
		SET loglex["hdot"] TO hdot.
		SET loglex["lat"] TO simstate["latlong"]:LAT.
		SET loglex["long"] TO simstate["latlong"]:LNG.
		SET loglex["range"] TO tgt_range.
		SET loglex["pitch"] TO pitch_prof.
		SET loglex["roll"] TO roll_prof.
		SET loglex["az_err"] TO delaz.
		SET loglex["l_d"] TO lod.
		log_data(loglex).
		
		PRINTPLACE("step : " + loglex["step"], 20,0,1).
		PRINTPLACE("alt : " + round(hls,0), 20,0,2).
		PRINTPLACE("ve : " + round(ve,0), 20,0,3).
		PRINTPLACE("vi : " + round(vi,0), 20,0,4).
		PRINTPLACE("hdot : " + round(hdot,1), 20,0,5).
		PRINTPLACE("tgt_range : " + round(tgt_range,0), 20,0,6).
		PRINTPLACE("delaz : " + round(delaz,2), 20,0,7).
		
		PRINTPLACE("xlfac : " + round(xlfac,3), 20,0,9).
		PRINTPLACE("drag : " + round(aeroacc["drag"],3), 20,0,10).
		PRINTPLACE("l/d : " + round(lod,3), 20,0,11).
		PRINTPLACE("drag_ref : " + round(entryg_out["drag_ref"],3), 20,0,12).
		
		PRINTPLACE("pitch : " + round(pitch_prof,1), 20,0,14).
		PRINTPLACE("roll : " + round(roll_prof,1), 20,0,15).
		PRINTPLACE("roll_ref : " + round(entryg_out["roll_ref"],1), 20,0,16).
		
		PRINTPLACE("phase : " + round(entryg_out["phase"],0), 20,0,18).
		
		
		
		//finally do the step and save quantities for termination condition
		SET next_simstate TO sim_settings["integrator"]:CALL(sim_settings["deltat"],simstate,LIST(pitch_prof,roll_prof)).
		
		SET next_simstate["altitude"] TO bodyalt(next_simstate["position"]).
		SET next_simstate["surfvel"] TO surfacevel(next_simstate["velocity"],next_simstate["position"]).
		
	}


}




//new approach, hopefully more robust
//simply calculate the angle between velocity vector and vector pointing to the target
FUNCTION az_error {
	PARAMETEr pos.
	PARAMETER tgt_pos.
	PARAMETER surfv.
	
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	IF tgt_pos:ISTYPE("geocoordinates") {
		SET tgt_pos TO pos2vec(tgt_pos).
	}

		
	//vector normal to vehicle vel and in the same plane as vehicle pos
	//defines the "plane of velocity"
	LOCAL n1 IS VXCL(surfv,pos):NORMALIZED.
	
	//vector pointing from vehicle pos to target, projected "in the plane of velocity"
	LOCAL dr IS VXCL(n1,tgt_pos - pos):NORMALIZED.
	
	//clamp to -180 +180 range
	RETURN signed_angle(
		surfv:NORMALIZED,
		dr,
		n1,
		0
	).

}




ops3_reentry_simulate().