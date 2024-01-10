//runway and hac functions 



//given runway coordinates, assumed to be centre, and length 
//finds the coordinates of the touchdown points and adds them to the lexicon
FUNCTION define_td_points {
	
	FROM {LOCAL k IS 0.} UNTIL k >= (ldgsiteslex:KEYS:LENGTH) STEP { SET k TO k+1.} DO{	
		LOCAL sitename IS ldgsiteslex:KEYS[k].
		
		LOCAL site IS ldgsiteslex[sitename].
		
		LOCAL rwyslex IS LEXICON().
		
		LOCAL rwydeflist IS LIST().
		
		IF (site:ISTYPE("LEXICON")) {
			rwydeflist:ADD(site). 
		} ELSE IF (site:ISTYPE("LIST")) {
			SET rwydeflist TO site.
		}
		
		FOR rwy IN rwydeflist {
			initialise_rwy_guid_pts(
				rwyslex,
				sitename,
				rwy["position"],
				rwy["length"],
				rwy["heading"],
				rwy["elevation"]
			).
		}
		
		SET ldgsiteslex[sitename] TO LEXICON("rwys", rwyslex).

	}

}


FUNCTION initialise_rwy_guid_pts {
	FUNCTION head2rwyno {
		PARAMETER head.
		RETURN FLOOR(head/10,0).
	}

	PARAMETER rwyslex.
	PARAMETER sitename.
	PARAMETER centre_pos.
	PARAMETEr len.
	PARAMETEr rwy_heading.
	PARAMETEr elevation.
	
	local head is rwy_heading.
	
	LOCAL rwyno IS head2rwyno(head).
		
	IF rwyslex:HASKEY(rwyno) {
		SET rwyno TO head2rwyno(fixangle(head + 10)).
	}

	rwyslex:ADD(
				rwyno, 
				LEXICON(
					"name", sitename + rwyno,
					"heading", head,
					"elevation", elevation,
					"end_pt", new_position(centre_pos, len/2000, fixangle(head - 180))
		)
	).
	
	//now get the touchdown point for the opposite side of the runway
	SET head TO fixangle(head + 180).
	
	SET rwyno TO head2rwyno(fixangle(rwyno * 10 + 180)).

	rwyslex:ADD(
				rwyno, 
				LEXICON(
					"name", sitename + rwyno,
					"heading", head,
					"elevation", elevation,
					"end_pt", new_position(centre_pos, len/2000, fixangle(head - 180))
		)
	).

}



//refresh the runway lexicon upon changing runway.
FUNCTION refresh_runway_lex {
	PARAMETER tgt_site.
	PARAMETER tgt_rwy_number.
	PARAMETER overhead_apch.
	
	LOCAL site IS ldgsiteslex[tgt_site].
	local siterwy is site["rwys"][tgt_rwy_number].

	RETURN LEXICON(
							"name",siterwy["name"],
							"position",siterwy["end_pt"],
							"elevation",siterwy["elevation"],
							"heading",siterwy["heading"],
							"overhead", overhead_apch
							
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
	LOCAL rwy_ship_bng IS bearingg(cur_pos, rwy["position"]).
	LOCAL ship_heading IS compass_for(cur_surfv,cur_pos).
	
	LOCAL ship_rwy_dist_mt IS greatcircledist(rwy["position"],cur_pos) * 1000.
	
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
			"rwy_rel_crs", vel_rwy_rel_angle,
			"rwy_dist", ship_rwy_dist_mt
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
	
	SET rwy["td_pt"] TO new_position(rwy["position"], taemg_out["xaim"]/1000, rwy_heading).
	
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


