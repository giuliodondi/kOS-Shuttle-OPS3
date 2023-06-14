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





//guidance functions 


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







