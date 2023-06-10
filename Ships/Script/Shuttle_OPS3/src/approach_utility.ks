

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

FUNCTION define_hac_centre {
	PARAMETER rwy.
	PARAMETER params.
	PARAMETER dist_shift.

	LOCAL bng IS fixangle(rwy["heading"] - 180).
	
	LOCAL hac_angle IS ARCTAN2(params["hac_radius"] + dist_shift,params["final_dist"]).
	LOCAL hac_dist IS params["final_dist"]/COS(hac_angle).
	
	//find the hac centre
	IF rwy["hac_side"]="left" {
		SET bng TO fixangle(bng + hac_angle).
	} ELSE IF rwy["hac_side"]="right"  {
		SET bng TO fixangle(bng - hac_angle).
	}
	SET rwy["hac"] TO new_position(rwy["aiming_pt"],hac_dist,bng).
}


//called upon changing either the runway or the hac side
//defined the hac centre, the displaced final point (hac exit) and the reference up vector
//also sets the runway elevation
FUNCTION define_hac {
	PARAMETER cur_pos.
	PARAMETER rwy.
	PARAMETER params.
	
	LOCAL bng IS fixangle(rwy["heading"] - 180).
	
	//find the final approach aiming point, common for left and right
	SET rwy["aiming_pt"] TO  new_position(rwy["td_pt"],params["aiming_pt_dist"],bng).
	
	//find the hac exit point, common for left and right
	SET rwy["hac_exit"] TO new_position(rwy["aiming_pt"],params["final_dist"],bng).
	
	//shift artificially the hac centre 0.3km further away from centerline than they should be 
	define_hac_centre(rwy,params,0.1).
	
	//define the reference up vector, pointing up for a right hac and down for a left one
	SET rwy["upvec"] TO (pos2vec(rwy["hac"])):NORMALIZED.
	IF rwy["hac_side"]="right" { SET rwy["upvec"] TO -rwy["upvec"].}
	
	
	//initialise the hac entry point
	update_hac_entry_pt(cur_pos,rwy,params).
	
	//initialise the hac angle 
	
	LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	SET rwy["hac_angle"] TO signed_angle(exitvec,entryvec,rwy["upvec"],1).

	//clearvecdraws().
	//pos_arrow(rwy["position"],"runwaypos").
	//pos_arrow(rwy["td_pt"],"td_pt").
	//pos_arrow(rwy["aiming_pt"],"aiming_pt").
	//pos_arrow(rwy["hac"],"hac").
	//pos_arrow(rwy["hac_exit"],"hac_exit").
	//pos_arrow(rwy["hac_entry"],"hac_entry").

}



//moved closest_site function to navigation library so it could 
//be used by ops1 abort functions



//update the entry point to the HAC
//assumes a circular hac with radius corresponding to the hac radius at the old hac angle
FUNCTION update_hac_entry_pt {
	PARAMETER cur_pos.
	PARAMETER rwy.
	PARAMETER params.
	
	//now find the hac entry point given the hac position and the ship position relative to it
	//a left hac always entails the entry point is to the right of the ship bearing to the hac centre 
	//and for a right hac the reverse is true 
	
	LOCAL rho IS get_hac_radius(rwy["hac_angle"],params).
	
	//we need to make the entry point a geoposition,not a vector
	//find the bearing from the hac centre to the ship,
	//add or subtract 	the beta angle accordingly
	//then get the geoposition from the hac given that bearing and the hac radius
	
	LOCAL d IS greatcircledist(rwy["hac"],cur_pos).
	LOCAL alpha IS ARCSIN(LIMITARG(rho/d)).
	LOCAL beta IS 90 - alpha.
	
	//same calculations as the hac definition routine 
	LOCAL ship_bng IS bearingg(cur_pos,rwy["hac"]).
	LOCAL hac_entry_sign IS 1.
	IF rwy["hac_side"]="left" {SET hac_entry_sign TO -1.}
	LOCAL entry_bng IS fixangle(ship_bng + hac_entry_sign*beta).
	
	//the entry point 
	
	
	SET rwy["hac_entry"] TO  new_position(rwy["hac"],rho,entry_bng).
	
	//clearvecdraws().
	//pos_arrow(rwy["hac_exit"],"hac_exit").
	//pos_arrow(rwy["hac"],"hac").
	//pos_arrow(rwy["hac_entry"],"hac_entry").

}



//new strategy to ensure the hac angle is a continuous variable
//find the hac vector corresponding to the stored hac angle
//calculate the signed angle bw provided hac entry vector and that one
//add the result to the stored hac angle
FUNCTION update_hac_angle {
	PARAMETER rwy.
	PARAMETER entryvec.
		
	LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	LOCAL old_entryvec IS rodrigues(exitvec,rwy["upvec"],rwy["hac_angle"]).
	LOCAL delta_hac_angle IS CLAMP(signed_angle(old_entryvec,entryvec,rwy["upvec"],-1),-10,10).
	
	SET rwy["hac_angle"] TO MAX(0,rwy["hac_angle"] + delta_hac_angle). 
	
	//LOCAL hac_gndtrk IS get_hac_groundtrack(hac_angle, vehicle_params).
	
	//calculate profile altitude
	//if we're off by hal a turn's worth of altitude assume that the angle is off by 360° and add another turn around the HAC
	//LOCAL profile_alt IS ( vehicle_params["final_dist"] + hac_gndtrk)*vehicle_params["glideslope"]["outer"].
	//SET profile_alt TO rwy["elevation"] +  profile_alt*1000.
	//LOCAL alt_tol IS get_hac_groundtrack(180,vehicle_params)*vehicle_params["glideslope"]["outer"]*1000.
	//IF ABS(profile_alt - simstate["altitude"])
	
	//RETURN hac_angle.
	
}

FUNCTION update_hac_spiral {
	PARAMETER new_radius.
	PARAMETER ship_hac_angle.
	PARAMETER params.
	
	SET params["hac_r2"] TO (new_radius - params["hac_radius"])/(ship_hac_angle^2).
}


//implement the conical HAC
FUNCTION get_hac_radius {
	PARAMETER hac_angle.
	PARAMETER params.
	
	RETURN params["hac_radius"] + params["hac_r2"]*hac_angle^2.
}


//implement the conical HAC, distance function is an approximation of the curve integral
FUNCTION get_hac_groundtrack {
	PARAMETER hac_angle.
	PARAMETER params.
	
	//RETURN params["hac_radius"]*hac_angle*CONSTANT:PI/180.
	
	
	RETURN (params["hac_radius"] + 0.344*params["hac_r2"]*hac_angle^2)*hac_angle*CONSTANT:PI/180.
}


//estimate total range to be flown around the hac and to touchdown
FUNCTION total_range_hac_landing {
	PARAMETER pred_pos.
	PARAMETER rwy.
	PARAMETEr params.
	
	LOCAL total_range IS 0.
	
	IF mode>=5{
		SET total_range TO greatcircledist(rwy["position"],pred_pos).
	} ELSE {
		SET total_range TO greatcircledist(rwy["position"],rwy["hac_exit"]) + get_hac_groundtrack(rwy["hac_angle"], params).
		
		IF mode = 3 {
			SET total_range TO total_range + greatcircledist(rwy["hac_entry"],pred_pos).
		}
	}

	RETURN total_range.
}


//give nthe current mode, returns the ground-track distance between the predicted point and 
//the appropriate target point 
FUNCTION mode_dist {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.

	IF mode=3 {
		//distance to hac entry point 
		RETURN greatcircledist(rwy["hac_entry"],simstate["latlong"]).
	}
	ELSE IF mode=4 {
		//ground-track distance around the hac
		//find the theta angle
		LOCAL shipvec IS (simstate["latlong"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
		
		//find the groundtrack around the hac
		RETURN get_hac_groundtrack(rwy["hac_angle"],params).
		
	}
	ELSE IF mode=5 OR mode=6{
		RETURN greatcircledist(rwy["td_pt"],simstate["latlong"]).
	}

}

//profile altitude during mode5
FUNCTION final_profile_alt {
	PARAMETER dist.
	PARAMETER rwy.
	PARAMETER params.

	RETURN rwy["elevation"] + dist*vehicle_params["glideslope"]["outer"]*1000.

}



//implements cubic altitude profile
//correct for the height difference between cubic and ogs profiles at 0.5 km from the hac exit
//to ensure continuity between the profiles
FUNCTION hac_turn_cubic_prof {
	PARAMETER hac_gndtrk.
	PARAMETER rwy.
	PARAMETER params.
	LOCAL prof IS params["hac_h_cub0"] + hac_gndtrk*( params["hac_h_cub1"] + hac_gndtrk*( params["hac_h_cub2"] + hac_gndtrk*params["hac_h_cub3"] ) ).
	RETURN prof*1000.
}


//profile altitude during mode4
//the cubic coefficients are now frozen
//calculate the cubic profile altitude at the predicted postion
//based on current altitude and the cubic profile altitude at current position, calculate a gain factor to match them
//let the gain factor ramp down to zero as we approach the exit
FUNCTION hac_turn_profile_alt{
	PARAMETER ship_hac_gndtrk.
	PARAMETER pred_hac_gndtrk.
	PARAMETER rwy.
	PARAMETER params.
	
	print "hac_gndtrk : " + pred_hac_gndtrk at (0,16).
	
	LOCAL x0 IS 0.5.
	
	//altitude at the exit
	LOCAL final_alt IS final_profile_alt(params["final_dist"] + x0,rwy,params).
	
	//nominal uncorrected profile altitude at the predicted point 
	LOCAL nom_hac_prof_alt IS hac_turn_cubic_prof(pred_hac_gndtrk - x0, rwy, vehicle_params).
	
	//gain factor to match current altitude to nominal profile alt at the current point 
	LOCAL alt_corr_gain IS (SHIP:ALTITUDE-final_alt)/hac_turn_cubic_prof(ship_hac_gndtrk - x0, rwy, vehicle_params).
	
	//ramp down the gain as we approach the exit 
	LOCAL alt_corr_gain_rampdown IS MIN(1,pred_hac_gndtrk/20).
	
	print "hac_alt_corr_gain : " + alt_corr_gain at (1,9). 
	
	//now build the vertical profile value at the predicted point with the gain factors
	RETURN final_alt + nom_hac_prof_alt*(1 + (alt_corr_gain - 1)*alt_corr_gain_rampdown).
}


//profile altitude at hac entry
//update taem glideslope so that it intersects the outer glideslope halfway through the hac turn 
//update cubic coefficients to match altitudes and derivatives with the two glideslopes
//then return cubic altitude at the entry point
FUNCTION hac_entry_profile_alt {
	PARAMETER ship_hac_dist.
	PARAMETER rwy.
	PARAMETER params.
	
	LOCAL mode5_alt IS final_profile_alt(params["final_dist"],rwy,params).
	
	//find the groundtrack around the hac
	LOCAL hac_gndtrk IS get_hac_groundtrack(rwy["hac_angle"], params).
	
	LOCAL hbar IS (SHIP:ALTITUDE - mode5_alt)/1000. 
	
	SET params["glideslope"]["taem"] TO (hbar - params["glideslope"]["outer"]*hac_gndtrk*0.5)/(ship_hac_dist + hac_gndtrk*0.5).
	
	LOCAL hac_turn_alt IS 0.5*hac_gndtrk*(params["glideslope"]["taem"] + params["glideslope"]["outer"]).
	
	update_cubic_coef_hac_acq(hac_turn_alt, hac_gndtrk, rwy, params).
	
	RETURN mode5_alt + hac_turn_alt*1000.
}



//wrapper function to bunch together several operations so we don't clutter the TAEM loop
function taem_profile_alt {
	PARAMETER rwy.
	PARAMETER params.

	//update hac turn angle
	LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	update_hac_angle(rwy,entryvec).

	//Calculate distance from the current entry point 
	LOCAL ship_hac_dist IS greatcircledist(rwy["hac_entry"],SHIP:GEOPOSITION).
	
	LOCAL profile_alt IS hac_entry_profile_alt(ship_hac_dist, rwy, params).
	
	print "hac_angle : " + rwy["hac_angle"] at (0,15).
	print "profile_alt : " + profile_alt at (0,16).
	
	RETURN profile_alt.
	
}



//update cubic parameters so that:
//the cubic and first derivative match the taem glideslope at hac entry 
//the cubic and first derivative match the outer glideslope at hac exit
FUNCTION update_cubic_coef_hac_acq {
	PARAMETER hac_alt.
	PARAMETER hac_gndtrk.
	PARAMETER rwy.
	PARAMETER params.
	
	//SET params["hac_h_cub1"] TO params["glideslope"]["outer"].
	//SET params["hac_h_cub3"] TO - (2*hac_alt - hac_gndtrk*(params["glideslope"]["taem"] + params["hac_h_cub1"]))/(hac_gndtrk^3).
	//SET params["hac_h_cub2"] TO (params["glideslope"]["taem"] - params["hac_h_cub1"] - 3*params["hac_h_cub3"]*(hac_gndtrk^2) )/(2*hac_gndtrk).
	
	LOCAL x0 IS params["ogs_preacq_dist"].
	LOCAL red_gndtrk IS hac_gndtrk - x0.
	LOCAL delta_gs IS params["glideslope"]["taem"] - params["glideslope"]["outer"].
	
	SET params["hac_h_cub3"] TO ( 2*(hac_gndtrk*params["glideslope"]["outer"] - hac_alt) + delta_gs*red_gndtrk )/(red_gndtrk^3).
	SET params["hac_h_cub2"] TO (delta_gs - 3*params["hac_h_cub3"]*(hac_gndtrk^2 - x0^2))/(2*red_gndtrk).
	SET params["hac_h_cub1"] TO params["glideslope"]["outer"] - x0*(2*params["hac_h_cub2"] - 3*x0*params["hac_h_cub3"]).
	SET params["hac_h_cub0"] TO (x0^2)*(params["hac_h_cub2"] - 2*params["hac_h_cub3"]*x0).
	
	
}


			//guidance functions 
			










//continuously update the hac entrance point based on the ship tangent vector 
//define a guidance point on the tangent to the hac corresponding to the entry point
//and moved a fixed distance ahead 
//calculate the azimuth deviation between the predicted heading and that point
//compare the predicted altitude with the profile and get the deviation from the line
//bw the current position and the hac entry point

FUNCTION mode3 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	//Calculate distance from the current entry point 
	//if it's less than 1km we no longer update the entry point 
	LOCAL ship_hac_dist IS greatcircledist(rwy["hac_entry"],SHIP:GEOPOSITION).
	IF (ship_hac_dist>5) { update_hac_entry_pt(SHIP:GEOPOSITION,rwy,params). }

	//once we have the entry point find the theta angle and hac radius
	LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	update_hac_angle(rwy,entryvec).
	
	print "hac angle:  " + rwy["hac_angle"] at (1,1).
	
	
	// buld the vertical profile 
	
	//find the distance from the predicted ship position to the entry point
	LOCAL ship_hac_dist_pred IS greatcircledist(rwy["hac_entry"],simstate["latlong"]).

	// no special function here since we use the real entry pt distance to recalculate the cubic parameters 
	//and use the predicted entry pt distance for vertical guidance
	LOCAL hacentry_profilealt IS hac_entry_profile_alt(ship_hac_dist, rwy, vehicle_params).
	LOCAL profile_alt IS hacentry_profilealt + ship_hac_dist_pred*params["glideslope"]["taem"]*1000.
	
	print "profile alt:  " +  profile_alt at (1,2).	
	
	print "rwy[glideslope]:  " +  rwy["glideslope"] at (1,3).	
	
	print "hac_h_cub1:  " +  params["hac_h_cub1"] at (1,4).	
	print "hac_h_cub2:  " +  params["hac_h_cub2"] at (1,5).	
	print "hac_h_cub3:  " +  params["hac_h_cub3"] at (1,6).	
	
	print "glideslope taem:  " +  params["glideslope"]["taem"] at (1,7).	
	print "hac entry profile alt:  " +  hacentry_profilealt at (1,8).	
	
	//build the target point as described
	//first get the HAC position corresponding to the predicted point
	
	LOCAL hac_tangentaz IS bearingg(rwy["hac_entry"],rwy["hac"]).
	

	//move the current position on the HAC of the ship HAc radius
	//along the tangent direction by an arbtrary distance 
	IF rwy["hac_side"]="left" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz - 90).
	}
	ELSE IF rwy["hac_side"]="right" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz + 90).
	}

	//move the current position on the HAC of the ship HAc radius
	//along the tangent direction by an arbtrary distance 
	LOCAL x IS 2.
	SET rwy["acq_guid_pt"] TO new_position(rwy["hac_entry"],x,hac_tangentaz). 
	
	//find now the azimuth error 
	//negative deviation if the vessel azimuth is greater i.e. to the right
	//of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(rwy["acq_guid_pt"],simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).
	
	//limit az error
	SET hac_az_error TO SIGN(hac_az_error)*MIN(6,ABS(hac_az_error)).

	
	
	//clearvecdraws().
	//pos_arrow(simstate["latlong"]).
	//pos_arrow(rwy["hac_entry"]).

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
	
}



//turn around the HAC
//take the point on the hac radius corresponding to the predicted point and on the circle
//define a guidance point on the tangent to the hac on that point a fixed distance ahead 
//calculate the azimuth deviation between the predicted heading and that point

FUNCTION mode4 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	//find the theta angle
	LOCAL ship_pred_vec IS (simstate["latlong"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	update_hac_angle(rwy,ship_pred_vec).
	print "hac angle:  " + rwy["hac_angle"] at (1,1).
	
	//if close to the exit, redraw the hac centre without bias
	//IF rwy["hac_angle"] < 35 {
	//	define_hac_centre(rwy,params,0.1*rwy["hac_angle"]/10).
	//}
	
	
	//the hac angle is measured wrt the predicted point 
	//correct it to find the ship hac angle 
	LOCAL ship_vec IS (SHIP:GEOPOSITION:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	LOCAL ship_hac_angle IS rwy["hac_angle"] + signed_angle(ship_vec,ship_pred_vec,-rwy["upvec"],-1).
	print "ship_hac_angle:  " +  ship_hac_angle at (1,5).	
	

	//update the HAC spiral to be tangent to the current ship position 
	LOCAL new_radius IS greatcircledist(rwy["hac"],SHIP:GEOPOSITION).
	print "new_radius:  " +  new_radius at (1,6).
	
	update_hac_spiral(new_radius,ship_hac_angle,params).

	
	print "hac_r2 : " + params["hac_r2"] at (1,7). 
	
	//find the groundtrack around the hac at the ship current point
	LOCAL ship_hac_gndtrk IS get_hac_groundtrack(ship_hac_angle, params).
	
	//find the groundtrack around the hac at the predicted point
	LOCAL pred_hac_gndtrk IS get_hac_groundtrack(rwy["hac_angle"], params).
	
	//get vertical profile
	
	LOCAL profile_alt IS hac_turn_profile_alt(ship_hac_gndtrk, pred_hac_gndtrk, rwy, params).

	print "profile alt:  " +  profile_alt at (1,2).	
	

	//build the target point as described
	//first get the HAC position corresponding to the predicted point
	
	LOCAL hac_radius IS get_hac_radius(rwy["hac_angle"], params).
	
	print "hac_radius : " + hac_radius at (0,3).
	
	
	LOCAL hac_tangentaz IS bearingg(simstate["latlong"],rwy["hac"]).
	LOCAL hac_tangentpos IS new_position(rwy["hac"],hac_radius,hac_tangentaz). 
	
	//print "horiz err:  " + (greatcircledist(rwy["hac"],SHIP:GEOPOSITION) - hac_radius)*1000 AT (1,3).

	//move the current position on the HAC of the ship HAc radius
	//along the tangent direction by an arbtrary distance 
	IF rwy["hac_side"]="left" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz - 90).
	}
	ELSE IF rwy["hac_side"]="right" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz + 90).
	}
	LOCAL x IS 0.5.
	LOCAL guid_pt IS new_position(hac_tangentpos,x,hac_tangentaz). 
	
	//find now the azimuth error 
	//negative deviation if the vessel azimuth is greater i.e. to the right
	//of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(guid_pt,simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).



	//clearvecdraws().
	//pos_arrow(simstate["latlong"]).
	//pos_arrow(guid_pt).
	//pos_arrow(rwy["hac_exit"]).

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
	

}



//measure deviation from the predicted point t othe runway centreline
//the target point is on centreline ahead of the ship's abeam position by a fixed distance
//the glideslope value is controlled outside this function
FUNCTION mode5 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	//predicted point distance to touchdown.
	LOCAL dist IS greatcircledist(rwy["td_pt"],simstate["latlong"]).
	
	//abeam point on centeline
	LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	LOCAL abeam_dist IS dist*COS(rwy_az_error).
	
	//build the guidance point
	LOCAL runway_bng IS FIXANGLE(rwy["heading"] - 180).
	
	LOCAL x IS 0.5.
	LOCAL guid_pt IS new_position(rwy["td_pt"],abeam_dist - x,runway_bng). 
	
	//find the azimuth error between the predicted heading and the bearing to the guidance point
	//negative deviation if the vessel azimuth is greater i.e. to the right of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(guid_pt,simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).
	
	////first calculate the angular deviation given the current distance
	////the horizontal deviation is calculated relative to the touchdown point 
	//LOCAL guid_pt IS new_position(hac_tangentpos,x,hac_tangentaz). 
	//LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	//LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	
	
	//build the vertical profile
	SET dist TO greatcircledist(rwy["aiming_pt"] ,simstate["latlong"]).
	
	LOCAL profile_alt IS final_profile_alt(dist,rwy,params).
	print "profile alt:  " +  profile_alt at (1,2).	

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
}

//identical to mode5 
//except the aiming point is now the touchdown point on the runway 
//and the vertical profile is now a 3° glideslope 
//plus the exponential function modelling the flare profile
FUNCTION mode6 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	//predicted point distance to touchdown.
	LOCAL dist IS greatcircledist(rwy["td_pt"],simstate["latlong"]).
	
	//abeam point on centeline
	LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	LOCAL abeam_dist IS dist*COS(rwy_az_error).
	
	//build the guidance point
	LOCAL runway_bng IS FIXANGLE(rwy["heading"] - 180).
	
	LOCAL x IS 0.5.
	LOCAL guid_pt IS new_position(rwy["td_pt"],abeam_dist - x,runway_bng). 
	
	//find the azimuth error between the predicted heading and the bearing to the guidance point
	//negative deviation if the vessel azimuth is greater i.e. to the right of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(guid_pt,simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).
	
	
	////first calculate the angular deviation given the current distance
	////the horizontal deviation is calculated relative to the touchdown point 
	//LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	//LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	
	//build the vertical profile

	//measure the predicted altitude above the site elevation
	LOCAL altt IS simstate["altitude"] - rwy["elevation"].
	IF altt > params["flare_alt"] {
		SET dist TO greatcircledist(rwy["aiming_pt"] ,simstate["latlong"]).
	}
	
	LOCAL profile_alt IS 0.
	
	
	IF altt > params["flare_alt"] {
		//use the outer glideslope 
		SET profile_alt TO final_profile_alt(dist,rwy,params).
	} ELSE {
		IF altt > params["postflare_alt"]  {
			//use the flare circle equation
			
			SET profile_alt TO rwy["elevation"] + params["flare_circle"]["alt"] - 
				SQRT( params["flare_circle"]["radius"]^2 - ( dist*1000 - params["flare_circle"]["dist"] )^2 ).
		
		} ELSE {
			//use the inner glideslope 
			SET profile_alt TO rwy["elevation"] + dist*params["glideslope"]["inner"]*1000.
		
		}
	}
	print "profile alt:  " +  profile_alt at (1,2).	

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
	

}


//logic to determine when to switch modes
//given the current mode, do the appropriate test and increment if required
//overhauled - simplified logic to switch modes 3 and 4 based on distance
FUNCTION mode_switch {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	PARAMETER switch_mode IS FALSE.
	
	IF mode=3 {
		LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
		LOCAL predvec IS (simstate["latlong"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
		LOCAL entry_angle IS VANG(predvec,entryvec).
		IF (entry_angle < 2 OR mode_dist(simstate,tgtrwy,params) < 0.1) {
			SET switch_mode TO TRUE.
		}	
	} ELSE IF mode=4 {	
		IF (rwy["hac_angle"] < 14 OR mode_dist(simstate,tgtrwy,params) < params["ogs_preacq_dist"]) {
			SET switch_mode TO TRUE.
			//override the previously calculated glideslope value
			SET rwy["glideslope"] TO params["glideslope"]["outer"].
			
		}
	} ELSE IF mode=5 {
		//measure the predicted altitude above the site elevation
		LOCAL altt IS simstate["altitude"] - rwy["elevation"].
		
		//below the flare threshold switch
		
		IF altt<=params["preflare_alt"]{
			SET switch_mode TO TRUE.
			
			//gear and brakes trigger
			WHEN ALT:RADAR<200 THEN {
				GEAR ON.
			}
		}
	
	} ELSE IF mode=6 {
		//transition below 50m
		IF ALT:RADAR <= 50{
			SET fbwb:PRESSED to FALSE.
			SET switch_mode TO TRUE.
		}
	} ELSE IF mode=7 {
		IF SHIP:STATUS = "LANDED" {
			SET fbwb:PRESSED to FALSE.
			SET switch_mode TO TRUE.
		}
	}
	
	IF switch_mode {
		SET mode TO mode + 1.
		CLEARSCREEN.
	}
	RETURN mode.

}






//given the outer and inner glideslope and the radius 
//find the centre of the flare circle, the flare altitudes and the middle glideslope
FUNCTION define_flare_circle {
	PARAMETEr params.
	
	//all calculations in metres
	LOCAL xp IS params["aiming_pt_dist"]*1000.
	//coordinates of the glideslopes intersection pt
	LOCAL xpp IS  (params["glideslope"]["outer"]*xp)/(  params["glideslope"]["outer"] -  params["glideslope"]["inner"] ).
	LOCAL ypp IS xpp*params["glideslope"]["inner"].
	
	LOCAL ogs IS ARCTAN(params["glideslope"]["outer"]).
	LOCAL igs IS  ARCTAN(params["glideslope"]["inner"]).
	
	//half-angle described by the glideslope straight lines
	LOCAL beta IS 90 - 0.5*( ogs - igs ).

	
	
	LOCAL gamma IS beta - igs .
	LOCAL s2 IS params["flare_circle"]["radius"]/SIN(beta).
	LOCAL s3 IS s2*COS(beta).
	
	
	//flare and post-flare altitudes
	SET params["flare_alt"] TO ypp + s3*SIN(ogs).
	SET params["postflare_alt"] TO ypp - s3*SIN(igs).
	//centre of circle
	SET params["flare_circle"]["dist"] TO xpp - s2*COS(gamma).
	SET params["flare_circle"]["alt"] TO ypp + s2*SIN(gamma).
	
	//at the intersection between the flare circle and the outer glideslope
	//the derivative of the circle profile is nearly linear 
	//which means the pitch increase will also be linear 
	//to describe the rising cue in mode 6 we use a lower glideslope 
	//called the middle gs, with angular coeff. corresponding to the second derivative 
	//of the circle equation at the tangent point

	
	////first find the x coordinate of the tangent point 
	//LOCAL xtg_out IS xp + params["flare_alt"]/ TAN( params["glideslope"]["outer"]).
	//print xtg_out.
	////calculate the 2nd derivative 
	//LOCAL curv_tg IS  (params["flare_circle"]["radius"]^2)/( params["flare_circle"]["radius"]^2 - (xtg_out - params["flare_circle"]["dist"])^2 )^(1.5).
	//SET params["glideslope"]["middle"] TO ARCTAN( curv_tg).
	//
	////calculate now the pre-flare altitude 
	////we define it as the altitude where the vertical deviation between the outer and middle glideslopes
	////equals the altitude deadband for the diamond cue on the hud.
	////we use the hard-coded value of 300 metres
	
	SET params["preflare_alt"] TO params["flare_alt"] + 30.

}



FUNCTION update_nz {
	Parameter pos.
	Parameter surfvel.
	Parameter attitude.
	
	LOCAL g0 IS 9.80665.
	
	//sample lift force
	LOCAL outlex IS aeroforce_ld(pos, surfvel, attitude).

	return outlex["lift"]/(g0*ship:mass).
}


FUNCTION update_g_force {
	PARAMETER nz.
	
	LOCAL g0 IS 9.80665.
	LOCAL cur_t IS TIME:SECONDS.
	LOCAL cur_hdot IS SHIP:VERTICALSPEED.
	SET nz["dt"] TO cur_t - nz["cur_t"].
	
	IF nz["dt"]>0 {
		SET nz["cur_nz"] TO (cur_hdot- nz["cur_hdot"])/(g0*nz["dt"]) + 1.
	}
	SET nz["cur_hdot"] TO cur_hdot.
	SET nz["cur_t"] TO cur_t.

	RETURN nz.
}
