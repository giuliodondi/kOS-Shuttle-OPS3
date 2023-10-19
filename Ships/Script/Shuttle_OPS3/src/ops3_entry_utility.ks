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
	set ei_calc["ei_range"] to shuttle_ei_range(ei_calc["ei_fpa"]).
	
	return ei_calc.
}






