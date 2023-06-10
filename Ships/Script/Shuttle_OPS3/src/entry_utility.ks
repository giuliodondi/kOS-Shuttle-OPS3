//misc functions


//prints the modified pitch profile to a global file
FUNCTION log_new_pitchprof {
	PARAMETER logname.
	
	IF EXISTS(logname) {DELETEPATH(logname).}
	
	LOCAL string IS "GLOBAL pitchprof_segments IS LIST(".
	
	FROM {local k is 0.} UNTIL k >= pitchprof_segments:LENGTH STEP {set k to k+1.} DO {
		LOCAL s IS pitchprof_segments[k].
		LOCAL addstring IS "LIST(" + s[0] + "," + s[1] + ")".
		IF k<(pitchprof_segments:LENGTH-1) {SET addstring TO addstring + ",".}
		SET string TO string + addstring.
	}
	
	SET string TO string + ").".
	
	LOG string TO logname.
}

//prints the PID gains to file
FUNCTION log_gains {
	PARAMETER gains_lex.
	PARAMETER logname.
	
	IF EXISTS(logname) {DELETEPATH(logname).}
	
	LOCAL string IS "GLOBAL gains IS LEXICON(".
	
	LOCAL keylist IS gains_lex:KEYS.
	LOCAL vallist IS gains_lex:VALUES.
	
	FROM {LOCAL k IS 0.} UNTIL k >= (keylist:LENGTH) STEP { SET k TO k+1.} DO{
		LOCAL addstring IS CHAR(34) + keylist[k] + CHAR(34) + "," + vallist[k].
		IF k<(keylist:LENGTH-1) {SET addstring TO addstring + ",".}
		SET string TO string + addstring.
	}
	SET string TO string + ").".

	LOG string TO logname.

}








//navigation and measurement functions

//reference velocity-fpa curve taken from descent guidance paper
FUNCTION FPA_reference {
	PARAMETER vel.
	
	//shallow
	LOCAL p1 IS  -8.396.
	LOCAL p2 IS 64340.
	LOCAL q1 IS -6347.
	
	RETURN (p1*vel + p2) / (vel + q1).
}



//determines if the conditions are right for the reference pitch value (pitch of highest velocity point in 
//the pitch profile) to be set to the pitch slider value
FUNCTION update_ref_pitch {
	PARAMETER new_ref_pitch.
	
	IF ((NOT is_auto_steering()) AND (SHIP:VELOCITY:SURFACE:MAG >= pitchprof_segments[pitchprof_segments:LENGTH-1][0]) AND (new_ref_pitch >=  pitchprof_segments[pitchprof_segments:LENGTH-2][1]) ) {
		RETURN TRUE.
	}
	RETURN FALSE.
	
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



FUNCTION abeam {
	//this is the B spherical angle
	PARAMETER az_err.
	//this is the c side
	PARAMETER _range.
	
	LOCAL p2 IS 180/((SHIP:ORBIT:BODY:RADIUS/1000)*CONSTANT:PI).

	RETURN get_a_cBB(_range*p2,ABS(az_err))/p2.
}

FUNCTION cross_error {
	PARAMETEr pos.
	PARAMETER tgt_pos.
	PARAMETER surfv.
	PARAMETER  _range. //this is the c side
	
	//this is the B spherical angle
	LOCAL az_err IS az_error(pos,tgt_pos,surfv).
	
	LOCAL p2 IS 180/((SHIP:ORBIT:BODY:RADIUS/1000)*CONSTANT:PI).
	
	RETURN get_b_cBB(_range*p2,az_err)/p2.
	
}




//guidance functions 


//estimate range to be flown around the hac and to the runway
FUNCTION estimate_range_hac_landing {
	PARAMETER rwy.
	PARAMETEr params.

	LOCAL range_bias IS rwy["length"]/2 +  params["aiming_pt_dist"] + params["final_dist"] + get_hac_groundtrack(rwy["hac_angle"], params).

}


//check the pitch profile for negative values
FUNCTION check_pitch_prof {
	
	FROM {local k is 0.} UNTIL k = pitchprof_segments:LENGTH STEP {set k to k+1.} DO {
		IF ( (pitchprof_segments[k][0] < 0 ) OR (pitchprof_segments[k][1] < 0 ) ) {
			RETURN FALSE.
		}
	}
	RETURN TRUE.
}



//wrapper for updating both pitch and roll functions 
//gather the calls here so that the simulation function remains agnostic about these functions 
FUNCTION pitchroll_profiles_entry {
	PARAMETER ref_att.
	PARAMETER cur_att.
	PARAMETER simstate.
	PARAMETER hddot.
	PARAMETER delaz.
	PARAMETER first_reversal_done.
	
	LOCAL roll_ref IS ref_att[0].
	LOCAL pitch_ref IS ref_att[1].
	
	LOCAL roll_cur IS cur_att[0].
	LOCAL pitch_cur IS cur_att[1].
	
	LOCAL roll_sign IS 1.
	
	IF (roll_cur = 0) {
		SET roll_sign TO SIGN(delaz).
	} ELSE {
		SET roll_sign TO roll_reversal(SIGN(roll_cur),delaz,roll_ref,first_reversal_done).
	}
		
	LOCAL roll_prof IS roll_sign*roll_profile(simstate,roll_ref,hddot,delaz).

	LOCAL pitch_prof IS pitch_profile(pitch_ref,simstate["surfvel"]:MAG).

	RETURN LIST(roll_prof, pitch_prof).
}


//new version which expects a global list of vel-pitch points 
// and builds the profile by linear interpolation
//if vel is higher than the highest velocity point it will update the reference 
//pitch to the alpha0 input value
FUNCTION pitch_profile {
	PARAMETER alpha0.
	PARAMETER vel IS 0.
	
	LOCAL out IS alpha0.

	IF (vel >= pitchprof_segments[pitchprof_segments:LENGTH-1][0] ) {
		SET out TO pitchprof_segments[pitchprof_segments:LENGTH-1][1].
	} ELSE {
		SET out TO INTPLIN(pitchprof_segments,vel).
	}

	RETURN out.
}




//alternative pitch modulation logic based on range error
//create a profile of acceptable range error values vs velocity
//if the range error is outside this band , increase or decrease pitch to adjust drag 
//the pitch delta is scaled to the current pitch times a gain
FUNCTION pitch_modulation {
	PARAMETER range_err.
	PARAMETER pitchv.
	
	
	LOCAL range_err_profile IS LIST(
								LIST(250,3),
								LIST(8000,40)
								).
	
	LOCAL range_band IS INTPLIN(range_err_profile,SHIP:VELOCITY:SURFACE:MAG).
	
	LOCAL pitch_corr IS 0.
	
	//the pitch correction should have the same sign as the range error
	//i.e. negative if we're short and positive if we're long
	//the correction is scaled to be between 0 and 1 when the range error is between 0.5x and 1.5x the range_band
	// maximum +- 3 degrees either way
	IF ABS(range_err) > range_band {
		SET pitch_corr TO SIGN(range_err) * MIN(3, CLAMP((ABS(range_err/range_band) - 1),0,1) * pitchv *  gains["pchmod"]).
	}
		
	RETURN pitchv + pitch_corr.
}



//if not re-entering in RSS all the parameters in this function need to be changed
FUNCTION roll_profile {
	PARAMETER state.
	PARAMETER roll0.
	PARAMETER hddot.
	PARAMETER delaz.
	
	//prebank command
	IF state["altitude"]>constants["firstrollalt"] {
		RETURN ABS(constants["prebank_angle"]).
	}
	
	//let the base roll value decrease linearly with velocity
	//LOCAL newroll IS MIN(roll0,(roll0/gains["Roll_ramp"])*(state["surfvel"]:MAG + 2500 - 500)/(2500 - 250)).
	
	LOCAL newroll IS roll0 + gains["Roll_ramp"] * (state["surfvel"]:MAG - 4000).

	
	//modulate the base roll based on vertical speed 
	//to try and dampen altitude oscillations
	//not too much since it reduces range a lot
	//this effect decays with velocity
	LOCAL refvel IS 6000.
	LOCAL gain IS gains["Khdot"]*(state["surfvel"]:MAG/refvel)^3.
	SET newroll TO newroll + gain*hddot.
	
	
	//heuristic minimum roll taken from the training manuals
	//min value to still ensure proper lateral guidance even in low-energy situations
	//only enable it if the reference roll is too small
	//update: use it in every case
	LOCAL roll_min IS constants["delaz_roll_factor"]*ABS(delaz).
	
	RETURN clamp(newroll,roll_min,85).
}




//determine the sign of the roll given the az error and its variation
FUNCTION roll_reversal {
	PARAMETER cur_sign.
	PARAMETER delaz.
	PARAMETER roll_ref.
	PARAMETER first_reversal_done.
	
	//lower bandwidth before first roll reversa, higher afterwards
	LOCAL bandwidth IS 10.5.
	IF first_reversal_done {
		SET bandwidth TO 17.5.
	}
	
	//the 0.9 factor is to compensate for slow roll reversal and tendency to overshoot
	
	//the logic for low energy guidance is to bank towards the target at minimum bank angle but then
	//to disable the roll reversals and fly at zero bank
	//do this by clamping the delaz bandwidth using the roll ref value which is small or even zero in low energy cases
	//divide by 2 because of the same heuristic used for the min bank angle, only the other way around
	LOCAL red_bandwidth IS 0.9*MIN(bandwidth,roll_ref/constants["delaz_roll_factor"]).
	
	//the default output is simply set to the current roll sign
	LOCAL out_s IS cur_sign.
	
	IF ABS(delaz) > red_bandwidth {
		//if we're out of the error band we command a reversal
		//we set the bank sign to the same sign as the error.
		//recall that the error is + if the tgt is to our right
		//and - if it's to the left 
		//and the same convention is used for bank angles 
		SET out_s TO SIGN(delaz).
	} 
	RETURN out_s.
}


declare function simulate_reentry {

	
	PARAMETER simsets.
	parameter simstate.
	PARAMETER tgt_rwy.
	PARAMETER end_conditions.
	PARAMETER roll0.
	PARAMETER pitch0.
	PARAMETER pitchroll_profiles.
	PARAMETER plot_traj IS FALSE.
	
	LOCAL tgtpos IS tgt_rwy["position"].
	LOCAL tgtalt IS tgt_rwy["elevation"] + end_conditions["altitude"].

	//sample initial values for proper termination conditions check
	SET simstate["altitude"] TO bodyalt(simstate["position"]).
	SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).

	LOCAL hdotp IS 0.
	LOCAL hddot IS 0.
	
	LOCAL pitch_prof IS pitch_profile(pitchprof_segments[pitchprof_segments:LENGTH-1][1],simstate["surfvel"]:MAG).
	LOCAL roll_prof IS 0.
	
	
	LOCAL poslist IS LIST().
	
	LOCAL next_simstate IS simstate.
	
	LOCAL first_reversal_done IS FALSE.

	
	//putting the termination conditions here should save an if check per step
	UNTIL (( next_simstate["altitude"]< tgtalt AND next_simstate["surfvel"]:MAG < end_conditions["surfvel"] ) OR next_simstate["altitude"]>140000)  {
	
		SET simstate TO next_simstate.
		
		LOCAL hdot IS VDOT(simstate["position"]:NORMALIZED,simstate["surfvel"]).
		SET hddot TO (hdot - hdotp)/simsets["deltat"].
		SET hdotp TO hdot.

	
		LOCAL delaz IS az_error(simstate["latlong"],tgtpos,simstate["surfvel"]).
		
		
		
		LOCAL out IS pitchroll_profiles(LIST(roll0,pitch0),LIST(roll_prof,pitch_prof),simstate,hddot,delaz,first_reversal_done).
		
		LOCAL roll_prof_p IS roll_prof.
		SET roll_prof TO out[0].
		SET pitch_prof TO out[1].
		
		IF ( NOT first_reversal_done AND roll_prof_p*roll_prof < 0 AND roll_prof*delaz > 0 ) {
			
			SET first_reversal_done TO TRUE.
		}

		SET simstate["latlong"] TO shift_pos(simstate["position"],simstate["simtime"]).
		
		IF plot_traj {
			poslist:ADD( simstate["latlong"]:ALTITUDEPOSITION(simstate["altitude"]) ).
		}
		
		IF simsets["log"]= TRUE {
		
			LOCAL tgt_range IS greatcircledist( tgtpos , simstate["latlong"] ).
			
			LOCAL outforce IS aeroforce_ld(simstate["position"], simstate["velocity"], LIST(pitch_prof,roll_prof)).
			
			
			SET loglex["time"] TO simstate["simtime"].
			SET loglex["alt"] TO simstate["altitude"]/1000.
			SET loglex["speed"] TO simstate["surfvel"]:MAG.
			SET loglex["hdot"] TO hdot.
			SET loglex["lat"] TO simstate["latlong"]:LAT.
			SET loglex["long"] TO simstate["latlong"]:LNG.
			SET loglex["range"] TO tgt_range.
			SET loglex["pitch"] TO pitch_prof.
			SET loglex["roll"] TO roll_prof.
			SET loglex["az_err"] TO delaz.
			SET loglex["l_d"] TO outforce["lift"] / outforce["drag"].
			log_data(loglex).
		}
		
		SET next_simstate TO simsets["integrator"]:CALL(simsets["deltat"],simstate,LIST(pitch_prof,roll_prof)).
		
		SET next_simstate["altitude"] TO bodyalt(next_simstate["position"]).
		SET next_simstate["surfvel"] TO surfacevel(next_simstate["velocity"],next_simstate["position"]).

	}
	
	IF plot_traj {
		SET simstate["poslist"] TO poslist.
	}
	

	return simstate.
}







