//runway and hac functions 



//given runway coordinates, assumed to be centre, and length 
//finds the coordinates of the touchdown points and adds them to the lexicon
FUNCTION define_td_points {

	FUNCTION add_runway_tdpt {
		PARAMETER site.
		PARAMETER bng.
		PARAMETER end_dist.
		PARAMETER td_dist.

		LOCAL rwy_lexicon IS LEXICON(
											"heading",0,
											"end_pt",LATLNG(0,0),
											"td_pt",LATLNG(0,0)
								).
								
								
		LOCAL pos IS site["position"].
		
		local rwy_number IS "" + ROUND(bng/10,0).
		SET rwy_lexicon["heading"] TO bng.
		SET rwy_lexicon["end_pt"] TO new_position(pos,end_dist,fixangle(bng - 180)).
		SET rwy_lexicon["td_pt"] TO new_position(pos,td_dist,fixangle(bng - 180)).
		
		
		site["rwys"]:ADD(rwy_number,rwy_lexicon).
		
		RETURN site.
	}
	
	FROM {LOCAL k IS 0.} UNTIL k >= (ldgsiteslex:KEYS:LENGTH) STEP { SET k TO k+1.} DO{	
		LOCAL site IS ldgsiteslex[ldgsiteslex:KEYS[k]].
	
	
		LOCAL end_dist IS site["length"]/2.
		LOCAL head IS site["heading"].
		
		site:ADD("rwys",LEXICON()).
		
		//convert in kilometres
		SET end_dist TO end_dist/1000.
		
		//multiply by a hard-coded value identifying the touchdown marks from the 
		//runway halfway point
		SET td_dist TO end_dist*0.8.
		
		SET site TO add_runway_tdpt(site,head,end_dist,td_dist).
		
		//now get the touchdown point for the opposite side of the runway
		SET head TO fixangle(head + 180).
		SET site TO add_runway_tdpt(site,head,end_dist,td_dist).
		
		SET ldgsiteslex[ldgsiteslex:KEYS[k]] TO site.

	}

}



//refresh the runway lexicon upon changing runway.
FUNCTION refresh_runway_lex {
	PARAMETER tgt_rwy_number.
	
	local tgtsite is ldgsiteslex[tgt_rwy_number].

	RETURN LEXICON(
							"number",tgt_rwy_number,
							"position",tgtsite["position"],
							"elevation",tgtsite["elevation"],
							"heading",tgtsite["heading"],
							"length",tgtsite["length"],
							"end_pt",LATLNG(0,0),
							"td_pt",LATLNG(0,0),
							"glideslope",0,
							"overhead",TRUE,	//default choice
							"aiming_pt",LATLNG(0,0),
							"acq_guid_pt",LATLNG(0,0),
							"hac",LATLNG(0,0)
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

//get several vehicle-related quantities
FUNCTION get_vehicle_state {

	RETURN LEXICON(
					
	).

}
