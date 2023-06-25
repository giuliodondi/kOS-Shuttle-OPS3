//misc functions


//orbit/deorbit functions 

FUNCTION shuttle_steep_ei_fpa {
	PARAMETER ei_vel.
	
	return 162.2908 - 0.03742578*ei_vel + 0.000002114297*ei_vel^2.
}

FUNCTION shuttle_ei_range {
	PARAMETER ei_fpa.
	
	return (ei_fpa/3 + 1.7638490566)*BODY:RADIUS/1000.
}

//need to be both in kilometres
FUNCTION deorbit_ei_calc {
	PARAMETER ap.
	PARAMETER ei_alt.
	
	local ei_calc is lexicon(
					"ei_eta",0,
					"ei_vel",0,
					"ei_fpa",0,
					"ei_range",0,
					"ap",ap,
					"pe",0
	).
	
	LOCAL ei_h IS ei_alt*1000 + BODY:RADIUS.
	
	local pe_guess is 0.
	
	local fpa_error is 1.
	
	
	set iter_count to 0.
    UNTIL (abs(fpa_error) < 0.005) {
	
		set iter_count to iter_count + 1.
		
		LOCAL sma IS (ap*1000 + pe_guess*1000 + 2*BODY:RADIUS)/2.
		LOCAL ecc IS (ap*1000 - pe_guess*1000) / (ap*1000 + pe_guess*1000 + 2*BODY:RADIUS).
		
		set ei_calc["ei_eta"] to orbit_alt_eta(ei_h, sma, ecc).
		set ei_calc["ei_vel"] to orbit_alt_vel(ei_h, sma).
		set ei_calc["ei_fpa"] to -orbit_alt_fpa(ei_h, sma, ecc).
		
		local steep_fpa is shuttle_steep_ei_fpa(ei_calc["ei_vel"]).
		
		set fpa_error to steep_fpa - ei_calc["ei_fpa"].
		
		set pe_guess to pe_guess + fpa_error * 100.
	}
	
	set ei_calc["pe"] to pe_guess.
	set ei_calc["ei_range"] to shuttle_ei_range(ei_calc["ei_fpa"]).
	
	return ei_calc.
}


//guidance

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





