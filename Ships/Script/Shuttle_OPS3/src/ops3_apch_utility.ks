//runway and hac functions 



//given runway coordinates, assumed to be centre, and length 
//finds the coordinates of the touchdown points and adds them to the lexicon
FUNCTION define_td_points {

	FUNCTION add_runway_tdpt {
		PARAMETER site.
		PARAMETER bng.
		PARAMETER dist.

		LOCAL rwy_lexicon IS LEXICON(
											"heading",0,
											"td_pt",LATLNG(0,0)
								).
								
								
		LOCAL pos IS site["position"].
		
		local rwy_number IS "" + ROUND(bng/10,0).
		SET rwy_lexicon["heading"] TO bng.
		SET rwy_lexicon["td_pt"] TO new_position(pos,dist,fixangle(bng - 180)).
		
		
		site["rwys"]:ADD(rwy_number,rwy_lexicon).
		
		RETURN site.
	}
	
	FROM {LOCAL k IS 0.} UNTIL k >= (ldgsiteslex:KEYS:LENGTH) STEP { SET k TO k+1.} DO{	
		LOCAL site IS ldgsiteslex[ldgsiteslex:KEYS[k]].
	
	
		LOCAL dist IS site["length"].
		LOCAL head IS site["heading"].
		
		site:ADD("rwys",LEXICON()).
		
		//convert in kilometres
		SET dist TO dist/1000.
		
		//multiply by a hard-coded value identifying the touchdown marks from the 
		//runway halfway point
		SET dist TO dist*0.39.
		
		SET site TO add_runway_tdpt(site,head,dist).
		
		//now get the touchdown point for the opposite side of the runway
		SET head TO fixangle(head + 180).
		SET site TO add_runway_tdpt(site,head,dist).
		
		SET ldgsiteslex[ldgsiteslex:KEYS[k]] TO site.

	}

}



//refresh the runway lexicon upon changing runway.
FUNCTION refresh_runway_lex {
	PARAMETER tgtsite.

	RETURN LEXICON(
							"position",tgtsite["position"],
							"elevation",tgtsite["elevation"],
							"heading",tgtsite["heading"],
							"length",tgtsite["length"],
							"td_pt",LATLNG(0,0),
							"glideslope",0,
							"hac_side","left",	//placeholder choice
							"aiming_pt",LATLNG(0,0),
							"acq_guid_pt",LATLNG(0,0),
							"hac",LATLNG(0,0),
							"hac_entry",LATLNG(0,0),
							"hac_entry_angle",0,
							"hac_exit",LATLNG(0,0),
							"hac_angle",0,
							"upvec",V(0,0,0)

	).
}

//simple wrapper to convert an altitude in metres to altitude above the landing site
FUNCTION runway_alt {
	PARAMETER altt.
	RETURN altt - tgtrwy["elevation"].
}
