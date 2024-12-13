//misc functions


//orbit/deorbit functions 

FUNCTION shuttle_steep_ei_fpa {
	PARAMETER ei_vel.
	
	return 162.5208 - 0.03742578*ei_vel + 0.000002114297*ei_vel^2.
}

FUNCTION shuttle_ei_range {
	PARAMETER ei_fpa.
	PARAMETER ei_incl.
	
	LOCAL range_bias IS 800.
	
	//heuristic, 16km for every degree off from 40°
	LOCAL incl_corr IS (ei_incl - 40) * 16.
	
	return (ei_fpa/3 + 1.6638490566)*BODY:RADIUS/1000 - range_bias  + incl_corr.
}

//need to be both in kilometres
FUNCTION deorbit_ei_calc {
	PARAMETER ap.
	PARAMETER incl.
	PARAMETER ei_alt.
	
	LOCAL ei_incl IS ABS(incl).
	
	local ei_calc is lexicon(
					"ei_eta",0,
					"ei_vel",0,
					"ei_fpa",0,
					"ei_range",0,
					"ap",ap,
					"pe",0,
					"incl", ei_incl
	).
	
	LOCAL ei_h IS ei_alt*1000 + BODY:RADIUS.
	
	local pe_guess is 0.
	
	local fpa_error is 1.
	
	
	set iter_count to 0.
    UNTIL (abs(fpa_error) < 0.005) {
	
		set iter_count to iter_count + 1.
		
		LOCAL sma IS orbit_appe_sma(ap, pe_guess).
		LOCAL ecc IS orbit_appe_ecc(ap, pe_guess).
		
		set ei_calc["ei_eta"] to orbit_alt_eta(ei_h, sma, ecc).
		set ei_calc["ei_vel"] to orbit_alt_vel(ei_h, sma).
		set ei_calc["ei_fpa"] to -orbit_eta_fpa(ei_calc["ei_eta"], sma, ecc).
		
		local steep_fpa is shuttle_steep_ei_fpa(ei_calc["ei_vel"]).
		
		set fpa_error to steep_fpa - ei_calc["ei_fpa"].
		
		set pe_guess to pe_guess + fpa_error * 100.
	}
	
	set ei_calc["pe"] to pe_guess.
	set ei_calc["ei_range"] to shuttle_ei_range(ei_calc["ei_fpa"], ei_incl).
	
	return ei_calc.
}

function blank_reentry_state {
	RETURN LEXICON(
		"t", TIME:SECONDS - 10,
		"tgt_range", 0,
		"delaz", 0,
		"hls", 0,	
		"hdot", 0,
		"fpa", 0
	).
}

//measure stuff needed by entry guidance
//needs attitude as a list(cur_pitch, cur_roll).
FUNCTION get_reentry_state {
	PARAMETER cur_pos.
	PARAMETER cur_latlng.
	PARAMETER cur_surfv.
	PARAMETER rwy.
	parameter prev_entry_state.
	
	local new_t is TIME:SECONDS.
	
	local dt is new_t - prev_entry_state["t"].
	
	local hdot_ is vspd(cur_surfv,cur_pos).
	
	local hddot_ is 0.

	if (abs(dt) > 0) {
		set hddot_ to (hdot_ - prev_entry_state["hdot"])/dt.
	}
	
	//for entry simulation to work correctly these two must be calculated with geoposition
	LOCAL delaz IS az_error(cur_latlng, rwy["position"], cur_surfv).
	LOCAL tgt_range IS greatcircledist( rwy["position"] , cur_latlng ).
	
	local hls is pos_rwy_alt(cur_pos, rwy).
	
	LOCAL upvec IS -SHIP:ORBIT:BODY:POSITION:NORMALIZED.
	LOCAL surfv_h IS VXCL(cur_pos,cur_surfv).
	
	local fpa is ARCTAN2(hdot_, surfv_h:MAG).

	RETURN LEXICON(
		"t", TIME:SECONDS,
		"tgt_range", tgt_range,
		"delaz", delaz,
		"hls", hls,	
		"hdot", hdot_,
		"hddot", hddot_,
		"fpa", fpa
	).
}

//heuristic to check if we're in a tal abort 
FUNCTION is_tal_abort {

	LOCAL rmag IS (-SHIP:ORBIT:BODY:POSITION):MAG.
	LOCAL alt_ IS rmag - SHIP:ORBIT:BODY:RADIUS.
	
	LOCAL alt_condition IS (alt_ > 90000).
	
	LOCAL vsat IS SQRT(BODY:MU/rmag).
	
	LOCAL vel_condition IS (SHIP:VELOCITY:ORBIT:MAG < 0.97 * vsat).
	
	RETURN alt_condition AND vel_condition.
} 

//heuristic to check for a grtls condition 
FUNCTION is_grtls {
	LOCAL rmag IS (-SHIP:ORBIT:BODY:POSITION):MAG.
	LOCAL alt_ IS rmag - SHIP:ORBIT:BODY:RADIUS.
	
	LOCAL alt_condition IS  (alt_ > 55000).
	
	LOCAL vel_condition IS (SHIP:VELOCITY:SURFACE:MAG < 2500).
	
	RETURN alt_condition AND vel_condition.
}




