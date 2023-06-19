
FUNCTION TAEM_spdbk {
	SET arbkb:PRESSED TO FALSE.
	SEt SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
}



//TAEM transition
FUNCTION TAEM_transition {
	PARAMETER tgt_dist.
	
	LOCAL nominal_condition IS ((tgt_dist <= 150) OR (SHIP:VELOCITY:SURFACE:MAG <= 850)).
	
	LOCAL high_energy_condition IS ((tgt_dist <= 200) AND (SHIP:VELOCITY:SURFACE:MAG > 1250)).
	
	IF (nominal_condition OR high_energy_condition) {
		RETURN TRUE.
	}
	
	RETURN FALSE.
	
}

//if we're close enough to the HAC entry point switch automatically
FUNCTION apch_transition {
	PARAMETER hac_entry_dist.
	
	IF hac_entry_dist < 15 {
		SET arbkb:PRESSED TO TRUE.
		SET guidb:PRESSED TO FALSE.
		SET sasb:PRESSED TO FALSE.
		WAIT 0.
		SET exitb:PRESSED TO TRUE.
	}


}



//calculate sign and value of bank angle 
// the bank angle value moves on a fixed profile of velocity
FUNCTION TAEM_roll_profile {
	PARAMETER delaz.
	PARAMETER hdot_err.
	PARAMETER sturn IS FALSE.
	
	//magnify delaz to bank harder
	LOCAL corr_delaz IS 4*ABS(delaz).

	
	LOCAL bank_vel_profile IS LIST(
								LIST(0,40),
								LIST(300,38),
								LIST(335,35),
								LIST(500,30)
								).
	
	LOCAL maxroll IS ABS(INTPLIN(bank_vel_profile,SHIP:VELOCITY:SURFACE:MAG)).
	
	//correct for the reference hdot error
	//a positive error means we need to bank more
	//it's an additive constant to the max bank
	LOCAL hdotgain IS 1/10.
	SET maxroll TO maxroll + hdot_err*hdotgain.
	
	IF (sturn) {
		//if doing an s-turn disregard delaz and bank at close to maximum roll
		RETURN MAx(0,maxroll).
	} ELSE {
		//bank proportionallyto delaz but enforce max bank constraint
		RETURN CLAMP(corr_delaz,0,maxroll).
	}
	
	
	
}


//use the full angle when doing the s-turn, if tracking the HAC instead ramp it down
//when the az error is small
FUNCTION TAEM_bank_angle {
	PARAMETER delaz.
	PARAMETER hdot_err.
	PARAMETER sturn IS FALSE.
	PARAMETER hac_side IS "".
	
	LOCAL bank_angle IS  TAEM_roll_profile(delaz,hdot_err,sturn).
	
	LOCAL signn is 1.

	IF (sturn) {
		//each guidance cycle spent in an s-turn increases the groundtrack to fly
		//the larger delaz is, the larger the increase in groundtrakc and energy dissipation
		//to avoid overshooting we ramp down the bank angle when delaz is great enough 
		//want to ramp it to zero and below so that delaz never gets too high 
		
		LOCAL bank_factor IS MIN(1, 1 - (ABS(delaz)/20 - 1)).
		
		RETURN s_turn_sign(hac_side)*bank_factor*bank_angle.
	} ELSE {
		RETURN SIGN(delaz)*bank_angle.
	}

	RETURN signn*ABS(bank_angle).
	
}

//TAEM s-turn direction logic
//the hac side also determines the direction of turn during the HAC
//we want the s-turn to be opposite in sign so that when it reverses we turn 
//in the same directon as the eventual HAc turn and thus the HAc interception angle is as small as possible 
FUNCTION s_turn_sign {
	PARAMETER hac_side.
	
	IF hac_side="left" {
		RETURN 1.
	} ELSE IF hac_side="right"{
		RETURN -1.
	} ELSE {
		//should never be entered
		RETURN 0.
	}
}



FUNCTION TAEM_pitch_profile {
	PARAMETEr ref_pitch.
	PARAMETER ref_roll.
	PARAMETER vel.
	PARAMETER hdot_err.
	
	LOCAL out_pitch IS ref_pitch.

	//correct pitch by a term proportional to the error in hdot
	//if positive error we must pitch down
	
	LOCAL hdotgain IS 1/25.
	SET out_pitch TO out_pitch - hdot_err*hdotgain.

	//clamp to reasonable values.
	RETURN CLAMP(out_pitch,0,20).
}

//put the roll correctin in a separate function so it can be tied to the current roll instead of the roll ref value
FUNCTION TAEM_pitch_roll_cor {
	PARAMETER ref_pitch.
	PARAMETER cur_roll.
	
	//correct the pitch value by the roll angle to keep the vertical 
	//component of lift consistent
	//not too large a correction though
	LOCAL out_pitch IS ref_pitch/COS(ABS(cur_roll/2)).
	
	//clamp to reasonable values.
	RETURN CLAMP(out_pitch,1,20).
	
}


// determines if the s-turn is to be commanded or not
FUNCTION s_turn {
	PARAMETER tgt_range.
	PARAMETER delaz.
	PARAMETER tgtvel.
	PARAMETER srfvel.
	
	//disable the s-turn if we're too close
	//also disable it if delaz is too large
	IF (tgt_range < 25 OR delaz>45) {
		RETURN FALSE.
	}
	
	//trigger s-turn if the final vel is higher than target 
	IF (srfvel > tgtvel) {
		RETURN TRUE.
	} ELSE {
		RETURN FALSE.
	}
	
}





declare function simulate_TAEM {

	
	PARAMETER simsets.
	parameter simstate.
	PARAMETER tgt_rwy.
	PARAMETER vehicle_params.
	PARAMETER roll0.
	PARAMETER pitch0.
	PARAMETER hdot_ref.
	
	LOCAL initialpos IS simstate["latlong"].
	
	LOCAL pitch_prof IS 0.
	LOCAL roll_prof IS 0.
	
	//sample initial values for proper termination conditions check
	SET simstate["altitude"] TO bodyalt(simstate["position"]).
	SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).

	LOCAL pos0 IS simstate["latlong"].

	LOCAL tgtdist IS greatcircledist(tgt_rwy["hac_entry"],simstate["latlong"]).
	LOCAL tgtdistp IS 2*tgtdist.
	
	LOCAL next_simstate IS simstate.
	
	//putting the termination conditions here should save an if check per step
	//UNTIL ( greatcircledist(initialpos,simstate["latlong"]) >= greatcircledist(initialpos,tgt_rwy["hac_entry"]) )  {
	UNTIL ( (tgtdist<5) OR ( greatcircledist(next_simstate["latlong"],pos0) >= greatcircledist(tgt_rwy["hac_entry"],pos0) ) OR next_simstate["altitude"] < 5000 )  {
			
		SET simstate TO next_simstate.
			
		//if target distance is less than 1km we no longer update the entry point
		//probably not necessary, save computations and avoid problems with spiral hac
		//IF (tgtdist>1) {
		//	update_hac_entry_pt(simstate["latlong"], tgt_rwy, vehicle_params). 
		//}

		LOCAL hdot IS VDOT(simstate["position"]:NORMALIZED,simstate["surfvel"]).
		
		
		LOCAL delaz IS az_error(simstate["latlong"], tgt_rwy["hac_entry"], simstate["surfvel"]).
		
		LOCAL hdoterr IS hdot - hdot_ref.
			
		SET roll0 TO TAEM_roll_profile(delaz,hdoterr).
		SET pitch_prof TO TAEM_pitch_profile(pitch0,roll_prof,simstate["surfvel"]:MAG, hdoterr).
		SET roll_prof TO SIGN(delaz)*roll0.
		
		IF simsets["log"]= TRUE {
			
			
			SET loglex["time"] TO simstate["simtime"].
			SET loglex["alt"] TO simstate["altitude"]/1000.
			SET loglex["speed"] TO simstate["surfvel"]:MAG.
			SET loglex["hdot"] TO hdot.
			SET loglex["lat"] TO simstate["latlong"]:LAT.
			SET loglex["long"] TO simstate["latlong"]:LNG.
			SET loglex["pitch"] TO pitch_prof.
			SET loglex["roll"] TO roll_prof.
			SET loglex["az_err"] TO delaz.
			log_data(loglex).
		}
		
		SET next_simstate TO simsets["integrator"]:CALL(simsets["deltat"],simstate,LIST(pitch_prof,roll_prof)).
		
		SET next_simstate["altitude"] TO bodyalt(next_simstate["position"]).
		SET next_simstate["surfvel"] TO surfacevel(next_simstate["velocity"],next_simstate["position"]).
		SET next_simstate["latlong"] TO shift_pos(next_simstate["position"],next_simstate["simtime"]).
		

		//update distance from the current entry point 
		SET tgtdistp TO tgtdist.
		SET tgtdist TO greatcircledist(tgt_rwy["hac_entry"],next_simstate["latlong"]).
		
	}


	return simstate.
}


