SET CONFIG:IPU TO 1800.	

RUNONCEPATH("0:/Libraries/misc_library").	
RUNONCEPATH("0:/Libraries/maths_library").	
RUNONCEPATH("0:/Libraries/navigation_library").
RUNONCEPATH("0:/Libraries/aerosim_library").

RUNPATH("0:/Shuttle_OPS3/src/ops3_control_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").

RUNPATH("0:/Shuttle_OPS3/vessel_dir").
RUNPATH("0:/Shuttle_OPS3/VESSELS/" + vessel_dir + "/aerosurfaces_control").

LOCAL dap IS dap_hdot_nz_controller_factory().

LOCAL aerosurfaces_control IS aerosurfaces_control_factory().

local engaged Is FALSE.

LOCAL steerdir IS SHIP:FACING.


ON (AG9) {
	IF (dap:mode = "atmo_pch_css") {
		SET dap:mode TO "atmo_hdot_auto".
		dap:reset_hdot_auto().
	} ELSe IF (dap:mode = "atmo_hdot_auto") {
		SET dap:mode TO "atmo_pch_css".
	} 
	PRESERVE.
}

clearscreen.

dap:reset_steering().
LOCK STEERING TO steerdir.
SAS OFF.

local rwy is build_alt_profile().

local control_loop is loop_executor_factory(
		0.2,
		{
			IF (SHIP:STATUS = "LANDEd") {
				UNLOCK STEERING.
			}
			
			SET steerdir TO dap:update().
		
			flaptrim_control(TRUE, aerosurfaces_control).
			aerosurfaces_control["deflect"]().
			
		}
	).

until false{
	clearscreen.
	clearvecdraws().
	
	IF (SHIP:STATUS = "LANDEd") {
		UNLOCK STEERING.
	}
	
	local guid is path_guid(rwy).
	
	
	
	pos_arrow(rwy["td_pt"],"td_pt", 5000, 0.1).
	
	SET dap:tgt_hdot tO guid["hdot_at"].
	SET dap:tgt_roll tO guid["phi_at"].
	SET dap:tgt_yaw tO 5 * SHIP:CONTROL:PILOTYAW.
	
	//speed_control(FALSE, aerosurfaces_control, 0).
	aerosurfaces_control["deflect"]().
	
	dap:print_debug(2).
	
	WAIT 0.23.
}


function build_alt_profile {
	
	
	local cur_pos is -SHIP:ORBIT:BODY:POSITION.
	
	local initial_alt_bias is 1000.
	local initial_hdg_bias is 15.
	
	local prof_alt is ship:altitude - initial_alt_bias.
	
	local tggs is TAN(24).
	
	local prof_x is prof_alt / tggs.
	
	LOCAL ship_heading IS compass_for(SHIP:VELOCITY:SURFACE, cur_pos).
	
	local path_hdg is ship_heading + initial_hdg_bias.
	
	local td_pos is new_position(cur_pos, 3, ship_heading).
	set td_pos to new_position(td_pos, prof_x/1000, path_hdg).
	
	return lexicon(
		"td_pt", td_pos,
		"hdg", path_hdg,
		"tggs", tggs
	).
}

function path_guid {
	parameter rwy.
	
	local cur_pos is -SHIP:ORBIT:BODY:POSITION.
	local cur_surfv is SHIP:VELOCITY:SURFACE.
	local cur_h is SHIP:ALTITUDE.
	
	LOCAL rwy_heading IS rwy["hdg"].
	LOCAL rwy_ship_bng IS bearingg(cur_pos, rwy["td_pt"]).
	LOCAL ship_heading IS compass_for(cur_surfv,cur_pos).

	LOCAL pos_rwy_rel_angle IS unfixangle( rwy_ship_bng - rwy_heading).
	LOCAL vel_rwy_rel_angle IS unfixangle( ship_heading - rwy_heading).
	
	LOCAL ship_rwy_dist_mt IS greatcircledist(rwy["td_pt"],cur_pos) * 1000.
	
	LOCAL cur_surfv_h_vec IS VXCL(cur_pos, cur_surfv).
	
	LOCAL cur_surfv_h IS cur_surfv_h_vec:MAG.
	LOCAL cur_hdot IS VDOT(cur_surfv, cur_pos:NORMALIZED).
	
	local x_ is ship_rwy_dist_mt*COS(pos_rwy_rel_angle).
	local y_ is ship_rwy_dist_mt*SIN(pos_rwy_rel_angle).
	
	local xdot is cur_surfv_h*COS(vel_rwy_rel_angle).
	local ydot is cur_surfv_h*SIN(vel_rwy_rel_angle).
	
	
	//mimic taem phase 3
	local rpred is SQRT(x_^2 + y_^2).
	
	local href is - x_ * rwy["tggs"].
	local hdref is - cur_surfv_h * rwy["tggs"].
	
	local herr is href - cur_h.
	
	set hdref to hdref + clamp(0.05 * herr, -30, 30).

	
	local yerrc is -0.075 * midval(y_, -300, 300) * 3.2.
	local phic is yerrc - 0.5 * ydot  * 3.2.
	
	local philimit is phic.
	if (abs(phic) > 350) {
		set philimit to 35.
	}
	
	local phi is clamp( phic, -philimit, philimit).
	
	local line is 21.
	
	print "rpred " + round(rpred,0) + "    " at (0,line). 
	print "x " + round(x_,0) + "    " at (0,line+ 1). 
	print "y " + round(y_,0) + "    " at (0,line + 2). 
	
	print "href " + round(href,0) + "    " at (0,line + 4). 
	print "herr " + round(herr,0) + "    " at (0,line + 5). 
	
	
	return lexicon(
		"hdot_at", hdref,
		"phi_at", phi
	).

}