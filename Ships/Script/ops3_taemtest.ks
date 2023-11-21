CLEARSCREEN.


RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	
RUNPATH("0:/Libraries/aerosim_library").	

RUNPATH("0:/Shuttle_OPS3/landing_sites").
RUNPATH("0:/Shuttle_OPS3/constants").

RUNPATH("0:/Shuttle_OPS3/src/ops3_entry_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_gui_utility.ks").
RUNPATH("0:/Shuttle_OPS3/src/ops3_apch_utility.ks").

RUNPATH("0:/Shuttle_OPS3/src/taem_guid.ks").

//RUNPATH("0:/Shuttle_OPS3/vessel_dir").
//RUNPATH("0:/Shuttle_OPS3/VESSELS/" + vessel_dir + "/pitch_profile").

GLOBAL quit_program IS FALSE.

//initialise touchdown points for all landing sites
define_td_points().

//after the td points but before anything that modifies the default button selections
make_main_entry_gui().



IF (DEFINED tgtrwy) {UNSET tgtrwy.}
GLOBAL tgtrwy IS refresh_runway_lex(select_tgt:VALUE).

//this must be called after the GUI and the tgtrwy lexicon have been initialised
select_random_rwy().
SET tgtrwy["heading"] TO ldgsiteslex[select_tgt:VALUE]["rwys"][select_rwy:VALUE]["heading"].
SET tgtrwy["td_pt"] TO ldgsiteslex[select_tgt:VALUE]["rwys"][select_rwy:VALUE]["td_pt"].




ops3_taem_test().



close_all_GUIs().




FUNCTION ops3_taem_test {
	SET CONFIG:IPU TO 1800.	
	
	until false{
		clearscreen.
		clearvecdraws().
		
		if (quit_program) {
			break.
		}
	
		
		LOCAL rwystate IS get_runway_rel_state(
			-SHIP:ORBIT:BODY:POSITION,
			SHIP:VELOCITY:SURFACE,
			tgtrwy
		).
		
		
		
		local taemg_in is LEXICON(
											"h", rwystate["h"],
											"hdot", rwystate["hdot"],
											"x", rwystate["x"], 
											"y", rwystate["y"], 
											"surfv", rwystate["surfv"],
											"surfv_h", rwystate["surfv_h"],
											"xdot", rwystate["xdot"], 
											"ydot", rwystate["ydot"], 
											"psd", rwystate["rwy_rel_crs"], 
											"mach", rwystate["mach"],
											"qbar", rwystate["qbar"],
											"phi",  rwystate["phi"],
											"theta", rwystate["theta"],
											"m", rwystate["mass"],
											"gamma", rwystate["fpa"],
											"ovhd", tgtrwy["overhead"],
											"rwid", tgtrwy["number"]
									).
									
							
		
		//call taem guidance here
		//LOCAL taemg_out is taemg_wrapper(
		//								taemg_in						
		//).
		//print 	taemg_out.	
		
		
		pos_arrow(tgtrwy["position"],"runwaypos", 5000, 0.1).
		pos_arrow(tgtrwy["td_pt"],"td_pt", 5000, 0.1).
		pos_arrow(tgtrwy["end_pt"],"end_pt" , 5000, 0.1).
		
		wait 0.5.
	}
	
}