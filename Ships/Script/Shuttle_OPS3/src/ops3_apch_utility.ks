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
	
	
		LOCAL end_dist IS site["length"].
		LOCAL head IS site["heading"].
		
		site:ADD("rwys",LEXICON()).
		
		//convert in kilometres
		SET end_dist TO end_dist/1000.
		
		//multiply by a hard-coded value identifying the touchdown marks from the 
		//runway halfway point
		SET td_dist TO end_dist*0.39.
		
		SET site TO add_runway_tdpt(site,head,end_dist,td_dist).
		
		//now get the touchdown point for the opposite side of the runway
		SET head TO fixangle(head + 180).
		SET site TO add_runway_tdpt(site,head,end_dist,td_dist).
		
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
							"end_pt",LATLNG(0,0),
							"td_pt",LATLNG(0,0),
							"glideslope",0,
							"overhead",TRUE,	//default choice
							"aiming_pt",LATLNG(0,0),
							"acq_guid_pt",LATLNG(0,0),
							"hac",LATLNG(0,0)
	).
}

//simple wrapper to convert an altitude in metres to altitude above the landing site
FUNCTION runway_alt {
	PARAMETER altt.
	RETURN altt - tgtrwy["elevation"].
}
