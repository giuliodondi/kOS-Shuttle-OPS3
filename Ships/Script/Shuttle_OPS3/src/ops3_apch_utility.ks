//runway and hac functions 



//given runway coordinates, assumed to be centre, and length 
//finds the coordinates of the touchdown points and adds them to the lexicon
FUNCTION define_td_points {
	
	FROM {LOCAL k IS 0.} UNTIL k >= (ldgsiteslex:KEYS:LENGTH) STEP { SET k TO k+1.} DO{	
		LOCAL sitename IS ldgsiteslex:KEYS[k].
		
		LOCAL site IS ldgsiteslex[sitename].
	
		LOCAL end_dist IS site["length"]/2.
		LOCAL head IS site["heading"].
		
		//convert in kilometres
		SET end_dist TO end_dist/1000.
		
		//multiply by a hard-coded value identifying the touchdown marks from the 
		//runway halfway point
		SET td_dist TO end_dist*0.8.
		
		LOCAL rwyslex IS LEXICON().
		
		LOCAL rwyno IS "".
		
		SET rwyno TO ROUND(head/10,0).

		rwyslex:ADD(
					rwyno, 
					LEXICON(
						"name", sitename + rwyno,
						"heading", head,
						"end_pt", new_position(site["position"],end_dist,fixangle(head - 180))
			)
		).
		
		//now get the touchdown point for the opposite side of the runway
		SET head TO fixangle(head + 180).
		
		SET rwyno TO ROUND(head/10,0).

		rwyslex:ADD(
					rwyno, 
					LEXICON(
						"name", sitename + rwyno,
						"heading", head,
						"end_pt", new_position(site["position"],end_dist,fixangle(head - 180))
			)
		).
		
		site:ADD("rwys", rwyslex).
		
		SET ldgsiteslex[ldgsiteslex:KEYS[k]] TO site.

	}

}



//refresh the runway lexicon upon changing runway.
FUNCTION refresh_runway_lex {
	PARAMETER tgt_site.
	PARAMETER tgt_rwy_number.
	
	LOCAL site IS ldgsiteslex[tgt_site].
	local siterwy is site["rwys"][tgt_rwy_number].

	RETURN LEXICON(
							"name",siterwy["name"],
							"position",site["position"],
							"elevation",site["elevation"],
							"heading",siterwy["heading"],
							"length",site["length"],
							"end_pt",siterwy["end_pt"],
							"glideslope",0,
							"overhead",is_apch_overhead(),
							"td_pt",LATLNG(0,0),
							"hac_centre",LATLNG(0,0),
							"hac_exit",LATLNG(0,0),
							"hac_tan",LATLNG(0,0)
							
	).
}

//simple wrapper to convert the position radius to altitude above the landing site in metres
FUNCTION pos_rwy_alt {
	PARAMETER cur_pos.
	PARAMETER rwy.
	
	LOCAL altt IS cur_pos:MAG - BODY:RADIUS.
	
	RETURN altt - tgtrwy["elevation"].
}

//convert several ksp quantities in the runway-relative frame for taem
FUNCTION get_runway_rel_state {
	PARAMETER cur_pos.
	PARAMETER cur_surfv.
	PARAMETER rwy.
	
	
	LOCAL rwy_heading IS rwy["heading"].
	LOCAL rwy_ship_bng IS bearingg(cur_pos, rwy["end_pt"]).
	LOCAL ship_heading IS compass_for(cur_surfv,cur_pos).
	
	LOCAL ship_rwy_dist_mt IS greatcircledist(rwy["end_pt"],cur_pos) * 1000.
	
	LOCAL pos_rwy_rel_angle IS unfixangle( rwy_ship_bng - rwy_heading).
	LOCAL vel_rwy_rel_angle IS unfixangle( ship_heading - rwy_heading).
	
	LOCAL cur_h IS pos_rwy_alt(cur_pos, rwy).
	
	LOCAL cur_surfv_h_vec IS VXCL(cur_pos, cur_surfv).
	//LOCAL cur_hdot_vec IS VXCL(cur_surfv_h_vec, cur_surfv).
	
	LOCAL cur_surfv_h IS cur_surfv_h_vec:MAG.
	LOCAL cur_hdot IS VDOT(cur_surfv, cur_pos:NORMALIZED).
	
	return LEXICON(
			"time", cur_time, 
			"dt", dt,
			"x", ship_rwy_dist_mt*COS(pos_rwy_rel_angle),
			"y", ship_rwy_dist_mt*SIN(pos_rwy_rel_angle),
			"h", cur_h,
			"xdot", cur_surfv_h*COS(vel_rwy_rel_angle),
			"ydot", cur_surfv_h*SIN(vel_rwy_rel_angle),
			"hdot", cur_hdot,
			"surfv", cur_surfv:MAG,
			"surfv_h", cur_surfv_h,
			"fpa", ARCTAN2(cur_hdot, cur_surfv_h),
			"rwy_rel_crs", vel_rwy_rel_angle,
			"rwy_dist", ship_rwy_dist_mt,
			"phi", get_roll_lvlh(),
			"theta", get_pitch_lvlh(),
			"mass", SHIP:MASS,
			"qbar", SHIP:Q,
			"mach", ADDONS:FAR:MACH
	).
}

//measure vertical load factor in Gs
FUNCTION get_current_nz {
	LOCAL aeroacc IS cur_aeroaccel_ld().
	return aeroacc["lift"] / 9.80665.

}

//use the taemg output to set guidance points 
FUNCTION build_taemg_guid_points {
	PARAMETEr taemg_out.
	PARAMETER rwy.
	
	LOCAL rwy_heading IS rwy["heading"].
	
	SET rwy["td_pt"] TO new_position(rwy["end_pt"], taemg_out["xaim"]/1000, rwy_heading).
	
	LOCAL hac_exit_az IS fixangle(rwy_heading + ARCTAN2(0, taemg_out["xhac"])).
	
	SET rwy["hac_exit"] TO new_position(rwy["td_pt"], ABS(taemg_out["xhac"]/1000), hac_exit_az).
	
	LOCAL hac_centre_az IS fixangle(rwy_heading + ARCTAN2(taemg_out["yhac"], taemg_out["xhac"])).
	
	LOCAL hac_centre_dist Is SQRT(taemg_out["xhac"]^2 + taemg_out["yhac"]^2).
	
	SET rwy["hac_centre"] TO new_position(rwy["td_pt"], hac_centre_dist/1000, hac_centre_az).
	
	LOCAL hac_tan_az IS fixangle(rwy_heading - taemg_out["ysgn"] * (90 + taemg_out["psha"])).

	SET rwy["hac_tan"] TO new_position(rwy["hac_centre"], taemg_out["rturn"]/1000, hac_tan_az).
}


//weight-on-wheels
FUNCTION measure_wow {
	RETURN (SHIP:STATUS = "LANDED").
}


