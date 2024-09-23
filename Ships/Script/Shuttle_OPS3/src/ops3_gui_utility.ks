@LAZYGLOBAL OFF.

close_all_GUIs().

GLOBAL guitextgreen IS RGB(20/255,255/255,21/255).
GLOBAL guitextred IS RGB(255/255,21/255,20/255).
global trajbgblack IS RGB(5/255,8/255,8/255).

GLOBAL guitextgreenhex IS "14ff15".
GLOBAL guitextredhex IS "ff1514".
GLOBAL guitextyellowhex IS "fff600".

//global and initialised by the gui toggle
GLOBAL loglex IS LEXICON().


						//DEORBIT GUI FUNCTIONS 
						
GLOBAL main_deorb_gui_width IS 300.
GLOBAL main_deorb_gui_height IS 320.

GLOBAL deorbit_target_selected IS FALSE.

FUNCTION make_global_deorbit_GUI {
	//create the GUI.
	GLOBAL main_deorbit_gui is gui(main_deorb_gui_width,main_deorb_gui_height).
	SET main_deorbit_gui:X TO 200.
	SET main_deorbit_gui:Y TO 670.
	SET main_deorbit_gui:STYLe:WIDTH TO main_deorb_gui_width.
	SET main_deorbit_gui:STYLe:HEIGHT TO main_deorb_gui_height.
	SET main_deorbit_gui:STYLE:ALIGN TO "center".
	SET main_deorbit_gui:STYLE:HSTRETCH TO TRUE.

	set main_deorbit_gui:skin:LABEL:TEXTCOLOR to guitextgreen.


	// Add widgets to the GUI
	GLOBAL title_box is main_deorbit_gui:addhbox().
	set title_box:style:height to 60. 
	set title_box:style:margin:top to 0.


	GLOBAL text0 IS title_box:ADDLABEL("<b><size=20>SPACE SHUTTLE OPS3 DEORBIT PLANNER</size></b>").
	SET text0:STYLE:ALIGN TO "center".


	
	GLOBAL quitb IS  title_box:ADDBUTTON("X").
	set quitb:style:margin:h to 7.
	set quitb:style:margin:v to 7.
	set quitb:style:width to 20.
	set quitb:style:height to 20.
	function quitcheck {
	  SET quit_program TO TRUE.
	}
	SET quitb:ONCLICK TO quitcheck@.


	main_deorbit_gui:addspacing(7).



	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_deorbit_gui:ADDVLAYOUT().
	SET popup_box:STYLE:WIDTH TO 200.	
	SET popup_box:STYLE:margin:h TO 50.	

	GLOBAL select_tgtbox IS popup_box:ADDHLAYOUT().
	GLOBAL tgt_label IS select_tgtbox:ADDLABEL("<size=15>Target : </size>").
	GLOBAL select_tgt IS select_tgtbox:addpopupmenu().
	SET select_tgt:STYLE:WIDTH TO 120.
	SET select_tgt:STYLE:HEIGHT TO 25.
	SET select_tgt:STYLE:ALIGN TO "center".
	FOR site IN ldgsiteslex:KEYS {
		select_tgt:addoption(site).
	}	
	set select_tgt:index to -1.
	SET select_tgt:ONCHANGE to { 
		PARAMETER lex_key.	
		//pick the first runway position 
		local firstrwyno is ldgsiteslex[lex_key]["rwys"]:keys[0].
		
		//taken from approach utility
		set tgtrwy to refresh_runway_lex(lex_key, firstrwyno, TRUE).

		
		SET deorbit_target_selected TO TRUE.
	}.


	GLOBAL all_box IS main_deorbit_gui:ADDVLAYOUT().
	SET all_box:STYLE:WIDTH TO main_deorb_gui_width.
	SET all_box:STYLE:HEIGHT TO 180.
	
	GLOBAL entry_interface_textlabel IS all_box:ADDLABEL("<b>ENTRY INTERFACE DATA</b>").	
	SET entry_interface_textlabel:STYLE:ALIGN TO "center".
	set entry_interface_textlabel:style:margin:v to 5.
	
	GLOBAL entry_interface_databox IS all_box:ADDVBOX().
	SET entry_interface_databox:STYLE:ALIGN TO "center".
	SET entry_interface_databox:STYLE:WIDTH TO 230.
    SET entry_interface_databox:STYLE:HEIGHT TO 170.
	set entry_interface_databox:style:margin:h to 28.
	set entry_interface_databox:style:margin:v to 0.
	
	GLOBAL textEI1 IS entry_interface_databox:ADDLABEL("").
	set textEI1:style:margin:v to -4.
	SET textEI1:STYLE:ALIGN TO "center".
	GLOBAL textEI2 IS entry_interface_databox:ADDLABEL("").
	set textEI2:style:margin:v to -4.
	SET textEI2:STYLE:ALIGN TO "center".
	GLOBAL textEI3 IS entry_interface_databox:ADDLABEL("").
	set textEI3:style:margin:v to -4.
	SET textEI3:STYLE:ALIGN TO "center".
	GLOBAL textEI4 IS entry_interface_databox:ADDLABEL("").
	set textEI4:style:margin:v to -4.
	SET textEI4:STYLE:ALIGN TO "center".
	GLOBAL textEI5 IS entry_interface_databox:ADDLABEL("").
	set textEI5:style:margin:v to -4.
	SET textEI5:STYLE:ALIGN TO "center".
	GLOBAL textEI6 IS entry_interface_databox:ADDLABEL("").
	set textEI6:style:margin:v to -4.
	SET textEI6:STYLE:ALIGN TO "center".
	GLOBAL textEI7 IS entry_interface_databox:ADDLABEL("").
	set textEI7:style:margin:v to -4.
	SET textEI7:STYLE:ALIGN TO "center".
	GLOBAL textEI8 IS entry_interface_databox:ADDLABEL("").
	set textEI8:style:margin:v to -4.
	SET textEI8:STYLE:ALIGN TO "center".
	
	
	
	


	main_deorbit_gui:SHOW().
}

FUNCTION update_deorbit_GUI {
	PARAMETER interf_t.
	PARAMETER ei_data.
	PARAMETER ei_ref_data.
	
	SET textEI1:text TO "  Time to EI  : " + sectotime(interf_t).
	
	LOCAL text2_color IS guitextredhex.
	if (ABS(ei_data["ei_delaz"]) < 15) {
		SET text2_color TO guitextgreenhex.
	}
	LOCAL text2_str IS "  Delaz at EI : " + ROUND(ei_data["ei_delaz"],1) + " °".
	
	SET textEI2:text TO "<color=#" + text2_color + ">" + text2_str + "</color>".
	
	SET textEI3:text TO "Ref FPA at EI : " + round(ei_ref_data["ei_fpa"], 2) + " °".
	LOCAL text4_str IS "    FPA at EI : " + round(ei_data["ei_fpa"], 2) + " °".
	
	LOCAL text4_color IS guitextredhex.
	if (ABS(ei_ref_data["ei_fpa"] - ei_data["ei_fpa"]) < 0.03) {
		SET text4_color TO guitextgreenhex.
	}
	
	SET textEI4:text TO "<color=#" + text4_color + ">" + text4_str + "</color>".
	
	SET textEI5:text TO "Ref Vel at EI : " + round(ei_ref_data["ei_vel"], 1) + " m/s".
	LOCAL text6_str IS "    Vel at EI : " + round(ei_data["ei_vel"], 1) + " m/s".
	
	LOCAL text6_color IS guitextredhex.
	if (ABS(ei_ref_data["ei_vel"] - ei_data["ei_vel"]) < 2) {
		SET text6_color TO guitextgreenhex.
	}
	
	SET textEI6:text TO "<color=#" + text6_color + ">" + text6_str + "</color>".
	
	SET textEI7:text TO "Ref Rng at EI : "+ round(ei_ref_data["ei_range"], 0) + " km".
	LOCAL text8_str IS "    Rng at EI : " + round(ei_data["ei_range"], 0) + " km".
	
	LOCAL text8_color IS guitextredhex.
	if (ABS(ei_ref_data["ei_range"] - ei_data["ei_range"]) < 100) {
		SET text8_color TO guitextgreenhex.
	}
	
	SET textEI8:text TO "<color=#" + text8_color + ">" + text8_str + "</color>".


}





						//GLOBAL ENTRY GUI FUNCTIONS


GLOBAL main_ops3_gui_width IS 550.
GLOBAL main_ops3_gui_height IS 510.

FUNCTION make_main_ops3_gui {
	

	//create the GUI.
	GLOBAL main_ops3_gui is gui(main_ops3_gui_width,main_ops3_gui_height).
	SET main_ops3_gui:X TO 180.
	SET main_ops3_gui:Y TO 670.
	SET main_ops3_gui:STYLe:WIDTH TO main_ops3_gui_width.
	SET main_ops3_gui:STYLe:HEIGHT TO main_ops3_gui_height.
	SET main_ops3_gui:STYLE:ALIGN TO "center".
	SET main_ops3_gui:STYLE:HSTRETCH  TO TRUE.

	set main_ops3_gui:skin:LABEL:TEXTCOLOR to guitextgreen.


	// Add widgets to the GUI
	GLOBAL title_box is main_ops3_gui:addhbox().
	set title_box:style:height to 35. 
	set title_box:style:margin:top to 0.


	GLOBAL text0 IS title_box:ADDLABEL("<b><size=20>SPACE SHUTTLE OPS3 ENTRY GUIDANCE</size></b>").
	SET text0:STYLE:ALIGN TO "center".
	
	GLOBAL hudcb IS  title_box:ADDBUTTON("☒").
	set hudcb:style:margin:h to 7.
	set hudcb:style:margin:v to 7.
	set hudcb:style:width to 20.
	set hudcb:style:height to 20.
	set hudcb:TOGGLE to TRUE.
	function recenterhud {
		PARAMETER pressed.
		recenter_hud().
		
		SET hudcb:pressed to false.
	}
	SET hudcb:ONTOGGLE TO recenterhud@.

	GLOBAL minb IS  title_box:ADDBUTTON("-").
	set minb:style:margin:h to 7.
	set minb:style:margin:v to 7.
	set minb:style:width to 20.
	set minb:style:height to 20.
	set minb:TOGGLE to TRUE.
	function minimizecheck {
		PARAMETER pressed.
		
		IF pressed {
			main_ops3_gui:SHOWONLY(title_box).
			SET main_ops3_gui:STYLe:HEIGHT TO 50.
		} ELSE {
			SET main_ops3_gui:STYLe:HEIGHT TO main_ops3_gui_height.
			for w in main_ops3_gui:WIDGETS {
				w:SHOW().
			}
		}
		
	}
	SET minb:ONTOGGLE TO minimizecheck@.

	GLOBAL quitb IS  title_box:ADDBUTTON("X").
	set quitb:style:margin:h to 7.
	set quitb:style:margin:v to 7.
	set quitb:style:width to 20.
	set quitb:style:height to 20.
	function quitcheck {
	  SET quit_program TO TRUE.
	}
	SET quitb:ONCLICK TO quitcheck@.

	
	main_ops3_gui:addspacing(7).

	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_ops3_gui:ADDHLAYOUT().
	SET popup_box:STYLE:ALIGN TO "center".	
	
	popup_box:addspacing(10).

	GLOBAL select_tgtbox IS popup_box:ADDHLAYOUT().
	SET select_tgtbox:STYLE:WIDTH TO 175.
	GLOBAL tgt_label IS select_tgtbox:ADDLABEL("<size=15>Target : </size>").
	GLOBAL select_tgt IS select_tgtbox:addpopupmenu().
	SET select_tgt:STYLE:WIDTH TO 110.
	SET select_tgt:STYLE:HEIGHT TO 25.
	SET select_tgt:STYLE:ALIGN TO "center".
	FOR site IN ldgsiteslex:KEYS {
		select_tgt:addoption(site).
	}		
		
	popup_box:addspacing(10).


	GLOBAL select_rwybox IS popup_box:ADDHLAYOUT().
	SET select_rwybox:STYLE:WIDTH TO 125.
	GLOBAL select_rwy_text IS select_rwybox:ADDLABEL("<size=15>Runway : </size>").
	GLOBAL select_rwy IS select_rwybox:addpopupmenu().
	SET select_rwy:STYLE:WIDTH TO 50.
	SET select_rwy:STYLE:HEIGHT TO 25.
	SET select_rwy:STYLE:ALIGN TO "center".
	
	FOR rwy IN ldgsiteslex[select_tgt:VALUE]["rwys"]:KEYS {
		select_rwy:addoption(rwy).
	}	
	
	popup_box:addspacing(10).
	
	

	GLOBAL select_apchbox IS popup_box:ADDHLAYOUT().
	SET select_apchbox:STYLE:WIDTH TO 195.
	//SET select_apchbox:STYLE:ALIGN TO "right".
	GLOBAL select_apch_text IS select_apchbox:ADDLABEL("<size=15>Apch mode : </size>").
	GLOBAL select_apch IS select_apchbox:addpopupmenu().
	SET select_apch:STYLE:WIDTH TO 90.
	SET select_apch:STYLE:HEIGHT TO 25.
	SET select_apch:STYLE:ALIGN TO "center".
	select_apch:addoption("Overhead").
	select_apch:addoption("Straight").
	
	SET select_apch:ONCHANGE to { 
		PARAMETER mode_.	
		SET tgtrwy["overhead"] TO is_apch_overhead().
		SET reset_guidb:PRESSED to TRUE.
	}.
	
	SET select_rwy:ONCHANGE to { 
		PARAMETER rwy.	
		
		SET tgtrwy TO refresh_runway_lex(select_tgt:VALUE, rwy, is_apch_overhead()).
		
		reset_overhead_apch().
		SET reset_guidb:PRESSED to TRUE.
	}.
	
	SET select_tgt:ONCHANGE to {
		PARAMETER lex_key.
		
		LOCAL newsite IS ldgsiteslex[lex_key].
		
		select_rwy:CLEAR.
		FOR rwy IN newsite["rwys"]:KEYS {
			select_rwy:addoption(rwy).
		}	
		
		select_random_rwy().
		reset_overhead_apch().
		SET tgtrwy TO refresh_runway_lex(select_tgt:VALUE, select_rwy:VALUE, is_apch_overhead()).
		
		SET reset_guidb:PRESSED to TRUE.
	}.	
	
	main_ops3_gui:addspacing(3).
	GLOBAL toggles_box IS main_ops3_gui:ADDHLAYOUT().
	SET toggles_box:STYLE:WIDTH TO 300.
	toggles_box:addspacing(5).	
	SET toggles_box:STYLE:ALIGN TO "center".
	
	GLOBAL dap_b_box IS toggles_box:ADDHLAYOUT().
	SET dap_b_box:STYLE:WIDTH TO 120.
	GLOBAL dap_b_text IS dap_b_box:ADDLABEL("DAP").
	set dap_b_text:style:margin:v to -3.
	GLOBAL dap_b IS dap_b_box:addpopupmenu().
	set dap_b:style:margin:v to -3.
	SET dap_b:STYLE:WIDTH TO 70.
	SET dap_b:STYLE:HEIGHT TO 25.
	SET dap_b:STYLE:ALIGN TO "center".
	dap_b:addoption("OFF").		//index 0
	dap_b:addoption("CSS").		//index 1
	dap_b:addoption("AUTO").		//index 2
	toggles_box:addspacing(15).
	
	SET dap_b:ONCHANGE to {
		PARAMETER mode_.
		
		if (mode_ = "OFF") {
			set dap_b:STYLE:BG to "Shuttle_OPS3/src/gui_images/steering_off_btn.png".
		} else {
			set dap_b:STYLE:BG to "Shuttle_OPS3/src/gui_images/default_btn.png". 
		}
	}.
	
	disengage_dap().
	
	GLOBAL flptrmb IS  toggles_box:ADDCHECKBOX("Auto Flaps",false).
	toggles_box:addspacing(15).	
	
	set flptrmb:pressed to true.
	
	GLOBAL arbkb IS  toggles_box:ADDCHECKBOX("Auto Airbk",false).
	toggles_box:addspacing(15).	
	
	set arbkb:pressed to true.
	
	GLOBAL reset_guidb is toggles_box:ADDBUTTON("RESET").
	SET reset_guidb:STYLE:WIDTH TO 55.
	SET reset_guidb:STYLE:HEIGHT TO 25.
	set reset_guidb:style:margin:v to -3.
	set reset_guidb:STYLE:BG to "Shuttle_OPS3/src/gui_images/steering_off_btn.png".
	
	toggles_box:addspacing(15).	
	
	GLOBAL logb IS  toggles_box:ADDCHECKBOX("Log Data",false).
	
	SET logb:ONTOGGLE to {
		PARAMETER activated.
		
		IF (activated) {
			set loglex TO LEXICON(
			                  "guid_id",1,
			                  "loop_dt",0,
			                  "rwy_alt",0,
			                  "vel",0,
			                  "surfv",0,
			                  "mach",0,
			                  "hdot",0,
			                  "lat",0,
			                  "long",0,
							  "range", 0,
			                  "delaz", 0,
			                  "nz", 0,
							  "drag", 0,
			                  "eow",0,
							  "prog_pch", 0,
							  "prog_roll", 0,
							  "prog_yaw", 0,
							  "flap_defl", 0,
							  "spdbk_defl", 0
			).
			log_data(loglex,"0:/Shuttle_OPS3/LOGS/ops3_log", TRUE).
	
		} ELSE {
			set loglex TO LEXICON().
		}
	}.

	select_random_rwy().
	SET tgtrwy TO refresh_runway_lex(select_tgt:VALUE, select_rwy:VALUE, is_apch_overhead()).

	main_ops3_gui:addspacing(3).
	GLOBAL ops3_main_display IS main_ops3_gui:addvlayout().
	SET ops3_main_display:STYLE:WIDTH TO main_ops3_gui_width - 22.
	SET ops3_main_display:STYLE:HEIGHT TO 382.
	SET ops3_main_display:STYLE:ALIGN TO "center".
	set ops3_main_display:style:margin:h to 11.
	
	set ops3_main_display:style:BG to "Shuttle_OPS3/src/gui_images/ops3_disp_bg.png".
	
	GLOBAL ops3_main_display_titlebox IS ops3_main_display:ADDHLAYOUT().
	SET ops3_main_display_titlebox:STYLe:WIDTH TO ops3_main_display:STYLE:WIDTH.
	SET ops3_main_display_titlebox:STYLe:HEIGHT TO 1.
	GLOBAL ops3_main_display_title IS ops3_main_display_titlebox:ADDLABEL("DISPLAY TITLE 1").
	SET ops3_main_display_title:STYLE:ALIGN TO "center".
	
	GLOBAL ops3_main_display_clockbox IS ops3_main_display:ADDHLAYOUT().
	SET ops3_main_display_clockbox:STYLe:WIDTH TO ops3_main_display:STYLE:WIDTH.
	SET ops3_main_display_clockbox:STYLe:HEIGHT TO 1.
	GLOBAL ops3_main_display_clock IS ops3_main_display_clockbox:ADDLABEL("MET 00:00:00:00").
	SET ops3_main_display_clock:STYLE:ALIGN TO "right".
	SET ops3_main_display_clock:STYLE:margin:h to 20.
	
	GLOBAL ops3_disp IS ops3_main_display:addvlayout().
	SET ops3_disp:STYLE:WIDTH TO ops3_main_display:STYLE:WIDTH.
	SET ops3_disp:STYLE:HEIGHT TO ops3_main_display:STYLE:HEIGHT - 2.
	SET ops3_disp:STYLE:ALIGN TO "center".
	
	GLOBAL ops3_disp_vmargin IS 18.

	main_ops3_gui:SHOW().
}

//sets the runway choice between the availle options to a random one
//to simulate daily wind conditions & introduce variability
FUNCTION select_random_rwy {
	LOCAL rwynum IS select_rwy:OPTIONS:LENGTH.
	SET select_rwy:INDEX TO FLOOR(rwynum*RANDOM()).
	
	WAIT 0.
}

FUNCTION reset_overhead_apch {
	SET select_apch:INDEX TO 0.
}

FUNCTION get_selected_tgt {
	return select_tgt:VALUE.
}

FUNCTION is_apch_overhead {
	
	IF (select_apch:VALUE = "Overhead") {
		RETURN TRUE.
	} ELSe IF (select_apch:VALUE = "Straight") {
		RETURN FALSE.
	}
}

FUNCTION disengage_dap {
	SET dap_b:INDEX TO 0.
	dap_b:ONCHANGE(dap_b:VALUE).	
	WAIT 0.
}

function set_dap_auto {
	SET dap_b:INDEX TO 2.
	dap_b:ONCHANGE(dap_b:VALUE).	
	WAIT 0.
}

FUNCTION is_dap_engaged {
	RETURN (NOT (dap_b:VALUE = "OFF")).
}

FUNCTION is_dap_css {
	return (dap_b:VALUE = "CSS").
}

FUNCTION is_autoflap {
	RETURN flptrmb:PRESSED.
}

FUNCTION is_autoairbk {
	RETURN arbkb:PRESSED.
}

FUNCTION is_guid_reset {
	return reset_guidb:TAKEPRESS.
}

FUNCTION is_log {
	RETURN logb:PRESSED.
}

function force_target_selection {
	parameter force_tgt_select.
	parameter freeze_tgt is FALSE.
	parameter tgt_index IS FALSE.
	
	if (tgt_index) {
		set select_tgt:index to force_tgt_select.
	} else {
		local k is 0.
		for t in select_tgt:options {
			if (t = force_tgt_select) {
				break.
			}
			set k to k + 1.
		}
		
		set select_tgt:index to k.
	}
	
	wait 0.
	
	if (freeze_tgt) {
		freeze_target_site().
	}
}

FUNCTION freeze_target_site {
	SET select_tgt:ENABLED to FALSE.
}

FUNCTION freeze_apch {
	SET select_rwy:ENABLED to FALSE.
	SET select_apch:ENABLED to FALSE.
}


FUNCTION close_global_GUI {
	main_ops3_gui:HIDE().
	IF (DEFINED(hud_gui)) {
		hud_gui:HIDE.
		hud_gui:DISPOSE.
		
	}
}

FUNCTION close_all_GUIs{
	CLEARGUIS().
	if (defined(main_ops3_gui)) {
		main_ops3_gui:DISPOSE().
	}
	IF (DEFINED(hud_gui)) {
		hud_gui:HIDE.
		hud_gui:DISPOSE.
		
	}
}


FUNCTION make_entry_traj_GUI {

	GLOBAL entry_traj_disp_counter IS 1.				   
	GLOBAL entry_traj_disp_counter_p IS entry_traj_disp_counter.				   
	
	GLOBAL traj_disp_overlaiddata IS ops3_disp:ADDVLAYOUT().
	SET traj_disp_overlaiddata:STYLE:ALIGN TO "Center".
	SET traj_disp_overlaiddata:STYLe:WIDTH TO ops3_disp:STYLE:WIDTH.
	SET traj_disp_overlaiddata:STYLe:HEIGHT TO 1.
	
	GLOBAL traj_disp_mainbox IS ops3_disp:ADDVLAYOUT().
	SET traj_disp_mainbox:STYLE:ALIGN TO "Center".
	SET traj_disp_mainbox:STYLe:WIDTH TO ops3_disp:STYLE:WIDTH.
	SET traj_disp_mainbox:STYLe:HEIGHT TO ops3_disp:STYLE:HEIGHT - ops3_disp_vmargin.
	SET traj_disp_mainbox:STYLE:margin:v to ops3_disp_vmargin.
	
	
	GLOBAL traj_disp_leftdatabox IS traj_disp_overlaiddata:ADDVLAYOUT().
	SET traj_disp_leftdatabox:STYLE:ALIGN TO "left".
	SET traj_disp_leftdatabox:STYLE:WIDTH TO 125.
    SET traj_disp_leftdatabox:STYLE:HEIGHT TO 115.
	set traj_disp_leftdatabox:style:margin:h to 20.
	set traj_disp_leftdatabox:style:margin:v to 10 + ops3_disp_vmargin.
	
	GLOBAL trajleftdata1 IS traj_disp_leftdatabox:ADDLABEL("XLFAC xxxxxx").
	set trajleftdata1:style:margin:v to -4.
	GLOBAL trajleftdata2 IS traj_disp_leftdatabox:ADDLABEL("L/D   xxxxxx").
	set trajleftdata2:style:margin:v to -4.
	GLOBAL trajleftdata3 IS traj_disp_leftdatabox:ADDLABEL("DRAG  xxxxxx").
	set trajleftdata3:style:margin:v to -4.
	GLOBAL trajleftdata4 IS traj_disp_leftdatabox:ADDLABEL("D REF xxxxxx").
	set trajleftdata4:style:margin:v to -4.
	GLOBAL trajleftdata5 IS traj_disp_leftdatabox:ADDLABEL("PHASE xxxxxx").
	set trajleftdata5:style:margin:v to -4.
	GLOBAL trajleftdata6 IS traj_disp_leftdatabox:ADDLABEL("LO ENERGY").
	set trajleftdata6:style:margin:v to -4.
	
	traj_disp_leftdatabox:addspacing(10).
	
	GLOBAL traj_disp_attitudebox IS traj_disp_leftdatabox:ADDVLAYOUT().
	SET traj_disp_attitudebox:STYLE:ALIGN TO "left".
	SET traj_disp_attitudebox:STYLE:WIDTH TO 75.
    SET traj_disp_attitudebox:STYLE:HEIGHT TO 75.
	
	GLOBAL trajattdata1 IS traj_disp_attitudebox:ADDLABEL("R  XXX").
	set trajattdata1:style:margin:v to -4.
	GLOBAL trajattdata2 IS traj_disp_attitudebox:ADDLABEL("P  XXX").
	set trajattdata2:style:margin:v to -4.
	GLOBAL trajattdata3 IS traj_disp_attitudebox:ADDLABEL("Y  XXX").
	set trajattdata3:style:margin:v to -4.
	
	GLOBAL traj_disp_rightdatabox IS traj_disp_overlaiddata:ADDVLAYOUT().
	SET traj_disp_rightdatabox:STYLE:ALIGN TO "left".
	SET traj_disp_rightdatabox:STYLE:WIDTH TO 145.
    SET traj_disp_rightdatabox:STYLE:HEIGHT TO 115.
	set traj_disp_rightdatabox:style:margin:h to 380.
	set traj_disp_rightdatabox:style:margin:v to 90 + ops3_disp_vmargin.
	
	GLOBAL trajrightdata1 IS traj_disp_rightdatabox:ADDLABEL("HDT REF xxxxx").
	set trajrightdata1:style:margin:v to -4.
	GLOBAL trajrightdata2 IS traj_disp_rightdatabox:ADDLABEL("ALPCMD xxxxx").
	set trajrightdata2:style:margin:v to -4.
	GLOBAL trajrightdata3 IS traj_disp_rightdatabox:ADDLABEL(" ALP MODULN ").
	set trajrightdata3:style:margin:v to -4.
	GLOBAL trajrightdata4 IS traj_disp_rightdatabox:ADDLABEL("ROLCMD  xxxxx").
	set trajrightdata4:style:margin:v to -4.
	GLOBAL trajrightdata5 IS traj_disp_rightdatabox:ADDLABEL("ROLREF  xxxxx").
	set trajrightdata5:style:margin:v to -4.
	GLOBAL trajrightdata6 IS traj_disp_rightdatabox:ADDLABEL("ROLL REVERSAL").
	set trajrightdata6:style:margin:v to -4.
	
	global traj_disp_trail_boxes_list is list().
	global traj_disp_trail_list is list().
	global traj_disp_trail_handler is traj_disp_trail_handler_fac().
	
	
	
	FROM {local k is 0.} UNTIL k >= traj_disp_trail_handler:num_points STEP {set k to k+1.} DO {
		local trail_box is traj_disp_mainbox:ADDHLAYOUT().
		SET trail_box:STYLE:ALIGN TO "Center".
		SET trail_box:STYLe:WIDTH TO 1.
		SET trail_box:STYLe:HEIGHT TO 1.
		
		traj_disp_trail_boxes_list:add(trail_box).
	
		local trail_marker IS trail_box:ADDLABEL().
		SET trail_marker:IMAGE TO "Shuttle_OPS3/src/gui_images/empty_bug.png".
		SET trail_marker:STYLe:WIDTH TO 12.
		traj_disp_trail_list:add(trail_marker).
	}
	
	GLOBAL traj_disp_orbiter_box IS traj_disp_mainbox:ADDVLAYOUT().
	SET traj_disp_orbiter_box:STYLE:ALIGN TO "Center".
	SET traj_disp_orbiter_box:STYLe:WIDTH TO 1.
	SET traj_disp_orbiter_box:STYLe:HEIGHT TO 1.
	
	GLOBAL traj_disp_orbiter IS traj_disp_orbiter_box:ADDLABEL().
	SET traj_disp_orbiter:IMAGE TO "Shuttle_OPS3/src/gui_images/orbiter_bug.png".
	SET traj_disp_orbiter:STYLe:WIDTH TO 22.
	
	GLOBAL traj_disp_pred_box IS traj_disp_mainbox:ADDVLAYOUT().
	SET traj_disp_pred_box:STYLE:ALIGN TO "Center".
	SET traj_disp_pred_box:STYLe:WIDTH TO 1.
	SET traj_disp_pred_box:STYLe:HEIGHT TO 1.
	
	GLOBAL traj_disp_pred_bug_ IS traj_disp_pred_box:ADDLABEL().
	SET traj_disp_pred_bug_:IMAGE TO "Shuttle_OPS3/src/gui_images/traj_pred_bug.png".
	SET traj_disp_pred_bug_:STYLe:WIDTH TO 8.
	
	reset_entry_traj_disp().
}

function reset_entry_traj_disp {
	set_entry_traj_disp_title().
	set_entry_traj_disp_bg().
	traj_disp_trail_handler:reset().
	for m_ in traj_disp_trail_list {
		SET m_:IMAGE TO "Shuttle_OPS3/src/gui_images/empty_bug.png".
	}
}

function update_entry_traj_disp {
	parameter gui_data.
	
	SET ops3_main_display_clock:text TO "MET " + sectotime_simple(MISSIONTIME, true).

	local vel_ is gui_data["ve"].

	//check if we shoudl update entry traj counter 
	if (entry_traj_disp_counter = 1 and vel_ <= 5181) {
		increment_entry_entry_traj_disp_counter().
	} else if (entry_traj_disp_counter = 2 and vel_ <= 4267) {
		increment_entry_entry_traj_disp_counter().
	} else if (entry_traj_disp_counter = 3 and vel_ <= 3200) {
		increment_entry_entry_traj_disp_counter().
	} else if (entry_traj_disp_counter = 4 and vel_ <= 1890) {
		increment_entry_entry_traj_disp_counter().
	}
	
	if (entry_traj_disp_counter_p <> entry_traj_disp_counter) {
		set entry_traj_disp_counter_p to entry_traj_disp_counter.
		reset_entry_traj_disp().
	}

	local orbiter_bug_pos is set_entry_traj_disp_bug(v(entry_traj_disp_x_convert(gui_data["ve"], gui_data["drag"]), entry_traj_disp_y_convert(gui_data["ve"]), 0)).
	SET traj_disp_orbiter:STYLE:margin:v to orbiter_bug_pos[1].
	SET traj_disp_orbiter:STYLE:margin:h to orbiter_bug_pos[0].
	
	LOCAL drag_err_delta IS 0.
	IF (gui_data["phase"] > 1) {
		//SET drag_err_delta TO 40 * (gui_data["drag_ref"]/gui_data["drag"] - 1).
		
		local drefd_bug_pos is set_entry_drag_error_bug(v(entry_traj_disp_x_convert(gui_data["ve"], gui_data["drag_ref"]), entry_traj_disp_y_convert(gui_data["ve"]), 0)).
		SET traj_disp_pred_bug_:STYLE:margin:h to drefd_bug_pos[0].
		
		traj_disp_trail_handler:update(gui_data["time"], gui_data["ve"], gui_data["drag"]).
	} else {
		SET traj_disp_pred_bug_:STYLE:margin:h to orbiter_bug_pos[0] - drag_err_delta + 5.
	}
	
	SET traj_disp_pred_bug_:STYLE:margin:v to orbiter_bug_pos[1] + 10.

	

	set trajleftdata1:text TO "XLFAC     " + ROUND(gui_data["xlfac"],1).
	set trajleftdata2:text TO "L/D          " + ROUND(gui_data["lod"],2).
	set trajleftdata3:text TO "DRAG      " + ROUND(gui_data["drag"],1).
	set trajleftdata4:text TO "D REF     " + ROUND(gui_data["drag_ref"],1).
	set trajleftdata5:text TO "PHASE     " + ROUND(gui_data["phase"],0).
	
	if (gui_data["ileflg"]) {	
		set trajleftdata6:text TO "<color=#" + guitextyellowhex + ">LO ENERGY</color>".
	} else {
		set trajleftdata6:text TO "".
	}
	
	
	set trajattdata1:text to "R  " + round(gui_data["prog_roll"], 0).
	set trajattdata2:text to "P  " + round(gui_data["prog_pch"], 0).
	set trajattdata3:text to "Y  " + round(gui_data["prog_yaw"], 0).
	
	set trajrightdata1:text TO "HDT REF    " + ROUND(gui_data["hdot_ref"],0).
	set trajrightdata2:text TO "ALPCMD    " + ROUND(gui_data["pitch_cmd"],0).
	
	if (gui_data["pitch_mod"]) {
		set trajrightdata3:text TO "<color=#" + guitextyellowhex + "> ALP MODULN </color>".
	} else {
		set trajrightdata3:text TO "".
	}
	
	set trajrightdata4:text TO "ROLCMD     " + ROUND(gui_data["roll_cmd"],0).
	set trajrightdata5:text TO "ROLREF     " + ROUND(gui_data["roll_ref"],0).
	
	if (gui_data["roll_rev"]) {
		set trajrightdata6:text TO "<color=#" + guitextyellowhex + ">ROLL REVERSAL</color>".
	} else {
		set trajrightdata6:text TO "".
	}

}

function increment_entry_entry_traj_disp_counter {
	set entry_traj_disp_counter to entry_traj_disp_counter + 1.
}

function set_entry_traj_disp_title {
	local text_ht is ops3_main_display_titlebox:style:height*0.75.
	
	set ops3_main_display_title:text to "<b><size=" + text_ht + ">ENTRY TRAJ " + entry_traj_disp_counter + "</size></b>".
}


function set_entry_traj_disp_bg {
	set traj_disp_mainbox:style:BG to "Shuttle_OPS3/src/gui_images/traj" + entry_traj_disp_counter + "_bg.png".
}

//rescale 
function set_entry_traj_disp_bug {
	parameter bug_pos.
	
	local bug_margin is 10.
	
	local bounds_x is list(10, traj_disp_mainbox:STYLe:WIDTH - 32).
	local bounds_y is list(traj_disp_mainbox:STYLe:HEIGHT - 29, 0).
	
	//print "calc_x: " + bug_pos:X + " calc_y: " +  + bug_pos:Y  + "  " at (0, 4).
	
	local pos_x is 1.04693*bug_pos:X  - 8.133 - 1.
	local pos_y is 395.55 - 1.1685*bug_pos:Y.
	
	//print "disp_x: " + pos_x + " disp_y: " + pos_y + "  " at (0, 5).
	
	set pos_x to clamp(pos_x, bounds_x[0], bounds_x[1] ).
	set pos_y to clamp(pos_y, bounds_y[0], bounds_y[1]).
	
	//print "disp_x: " + pos_x + " disp_y: " + pos_y + "  " at (0, 6).
	
	return list(pos_x,pos_y).
}

function set_entry_drag_error_bug {
	parameter bug_pos.
	parameter bias is 0.
	
	local bounds_x is list(10, traj_disp_mainbox:STYLe:WIDTH - 32).
	local bounds_y is list(traj_disp_mainbox:STYLe:HEIGHT - 29, 0).
	
	local pos_x is 1.04693*bug_pos:X  - 8.133 + 5.
	local pos_y is 395.55 - 1.1685*bug_pos:Y + bias.
	
	set pos_x to clamp(pos_x, bounds_x[0], bounds_x[1] ).
	set pos_y to clamp(pos_y, bounds_y[0], bounds_y[1]).
	
	return list(pos_x,pos_y).
}

function set_entry_trail_marker {
	parameter marker_pos.
	parameter marker_obj_handle.
	
	local bounds_x is list(15, traj_disp_mainbox:STYLe:WIDTH - 32).
	local bounds_y is list(traj_disp_mainbox:STYLe:HEIGHT - 29, 5).
	
	local pos_x is 1.04693*marker_pos:X  - 8.133 + 5.
	local pos_y is 395.55 - 1.1685*marker_pos:Y + 10.

	//if (pos_x >= bounds_x[1]) {
	//	set pos_x to bounds_x[1].
	//	SET marker_obj_handle:IMAGE TO "Shuttle_OPS3/src/gui_images/empty_bug.png".
	//} else if (pos_x <= bounds_x[0]) {
	//	set pos_x to bounds_x[0].	
	//	SET marker_obj_handle:IMAGE TO "Shuttle_OPS3/src/gui_images/empty_bug.png".
	//} else {
	//	SET marker_obj_handle:IMAGE TO "Shuttle_OPS3/src/gui_images/traj_trail_bug.png".
	//}
	//
	//if (pos_y >= bounds_y[1]) {
	//	set pos_y to bounds_y[1].
	//	SET marker_obj_handle:IMAGE TO "Shuttle_OPS3/src/gui_images/empty_bug.png".
	//} else if (pos_y <= bounds_y[0]) {
	//	set pos_y to bounds_y[0].	
	//	SET marker_obj_handle:IMAGE TO "Shuttle_OPS3/src/gui_images/empty_bug.png".
	//} else {
	//	SET marker_obj_handle:IMAGE TO "Shuttle_OPS3/src/gui_images/traj_trail_bug.png".
	//}
	
	SET marker_obj_handle:IMAGE TO "Shuttle_OPS3/src/gui_images/traj_trail_bug.png".
	
	set pos_x to clamp(pos_x, bounds_x[0], bounds_x[1] ).
	set pos_y to clamp(pos_y, bounds_y[0], bounds_y[1]).
	
	
	SET marker_obj_handle:STYLE:margin:v to pos_y.
	SET marker_obj_handle:STYLE:margin:h to pos_x.
}

function entry_traj_disp_x_convert {
	parameter vel.
	parameter drag.
	
	local out is 0.
	
	LOCAL drag2 IS drag * drag.
	LOCAL vel2 IS vel * vel.
	LOCAL vel3 IS vel2 * vel.
	LOCAL drag3 IS drag2 * drag.
	
	if (entry_traj_disp_counter=1) {
	
		set out to   -301.03675017070697 + 0.33855815734271033 * vel  + -60.60824776780207  * drag + -4.9417386634200165e-05 * vel2  + 0.005476770758642946 * vel * drag + 1.2917463262414464  * drag2 + 2.5832897487809703e-09 * vel3  + -2.410334538332365e-07 * vel2 * drag + -3.310567076068448e-05 * vel * drag2 + -0.010890925126885411  * drag3.

	} else if (entry_traj_disp_counter=2) {
		set out to  970.513742174761 + -0.30813459772818946 * vel  + -66.35018132660345  * drag + 6.925641359197617e-05 * vel2  + 0.00997745210980331 * vel * drag + 1.1326690671636324  * drag2 + -4.884222304379904e-09 * vel3  + -1.5918695213563983e-08 * vel2 * drag + -0.0001355676362552841 * vel * drag2 + -0.005495955515423207  * drag3.

	} else if (entry_traj_disp_counter=3) {
		set out to -169.89669862960386 + 0.19623953463938421 * vel + -13.736386540438081 * drag + -4.726735117477343e-07 * vel2 + 0.00040459906559150603 * vel * drag + 0.07268485357148893  * drag2.
   
	} else if (entry_traj_disp_counter=4) {
		set out to  -734.5494910944298 + 0.9290782496000264 * vel + -29.37866043040794 * drag + -0.0001350962705991554 * vel2 + 0.00109521485502761 * vel * drag + 0.31166666666704274  * drag2.
    
	} else if (entry_traj_disp_counter=5) {
		set out to -365.6282303867932 + 1.0003973495016918 * vel + -15.409853981961241 * drag + -0.00024196873768544958 * vel2 + -0.0016156332438259542 * vel * drag + 0.24249999999981453  * drag2.
        
	}
	
	return out.

}

function entry_traj_disp_y_convert {
	parameter vel.
	
	local out is 0.
	
	if (entry_traj_disp_counter=1) {
		set out to ( 0.00036 * vel - 1.85197).
	} else if (entry_traj_disp_counter=2) {
		set out to (0.0007300919 * vel - 2.92849015317).
	} else if (entry_traj_disp_counter=3) {
		set out to  (0.00093720712 * vel - 2.99906279288).
	} else if (entry_traj_disp_counter=4) {
		set out to (0.00076335877 * vel - 1.4427480916).
	} else if (entry_traj_disp_counter=5) {
		set out to (0.00088495575 * vel - 0.67256637168).
	}
	
	
	return 59.5 + 280.2 * out.

}


function traj_disp_trail_handler_fac {
	local this is lexicon().

	this:add("last_update", TIMe:SECONDs).
	this:add("update_interval", 25).
	
	this:add("num_points", 6).
	this:add("traj_points", fixed_list_factory(this:num_points)).

	this:add("update", {
		parameter time_.
		parameter ve.
		parameter drag.
		
		if (time_ < (this:last_update + this:update_interval)) {
			return.
		}
		
		set this:last_update to time_.
		
		this:traj_points:push(lexicon("drag", drag, "ve", ve)).
		
		this:refresh_trail().
	}).
	
	this:add("refresh_trail", {
	
		FROM {local k is 0.} UNTIL k >= this:traj_points:list:length STEP {set k to k+1.} DO {
			local m_ is traj_disp_trail_list[k].
			local data_ is this:traj_points:list[k].
			
			set_entry_trail_marker(
					v(entry_traj_disp_x_convert(data_["ve"], data_["drag"]), entry_traj_disp_y_convert(data_["ve"]), 0),
					m_
			).
		}

	}).
	
	this:add("reset", {
		set this:traj_points to fixed_list_factory(this:num_points).
	}).

	return this.
}


FUNCTION clear_ops3_disp {
	for w in ops3_disp:WIDGETS {
		w:DISPOSE().
	}
}	

FUNCTION make_taem_vsit_GUI {

	GLOBAL taem_vsit_disp_counter IS 1.				   
	GLOBAL taem_vsit_disp_counter_p IS taem_vsit_disp_counter.	
	
	set main_ops3_gui:skin:verticalslider:BG to "Shuttle_OPS3/src/gui_images/vspdslider2.png".
	set main_ops3_gui:skin:verticalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/vslider_thumb.png".
	set main_ops3_gui:skin:verticalsliderthumb:HEIGHT to 20.
	set main_ops3_gui:skin:verticalsliderthumb:WIDTH to 17.
	set main_ops3_gui:skin:horizontalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/hslider_thumb.png".
	set main_ops3_gui:skin:horizontalsliderthumb:HEIGHT to 17.
	set main_ops3_gui:skin:horizontalsliderthumb:WIDTH to 20.
	
	GLOBAL vsit_disp_overlaiddata IS ops3_disp:ADDHLAYOUT().
	SET vsit_disp_overlaiddata:STYLE:ALIGN TO "Center".
	SET vsit_disp_overlaiddata:STYLe:WIDTH TO ops3_disp:STYLE:WIDTH.
	SET vsit_disp_overlaiddata:STYLe:HEIGHT TO 1.
	SET vsit_disp_overlaiddata:style:vstretch to false.
	SET vsit_disp_overlaiddata:style:hstretch to false.
	
	GLOBAL vsit_disp_mainbox IS ops3_disp:ADDVLAYOUT().
	SET vsit_disp_mainbox:STYLE:ALIGN TO "Center".
	SET vsit_disp_mainbox:STYLe:WIDTH TO ops3_disp:STYLE:WIDTH.
	SET vsit_disp_mainbox:STYLe:HEIGHT TO ops3_disp:STYLE:HEIGHT - ops3_disp_vmargin.
	SET vsit_disp_mainbox:STYLE:margin:v to ops3_disp_vmargin.
	
	GLOBAL vsit_disp_leftdatabox IS vsit_disp_overlaiddata:ADDVLAYOUT().
	SET vsit_disp_leftdatabox:STYLE:ALIGN TO "left".
	SET vsit_disp_leftdatabox:STYLE:WIDTH TO 75.
    SET vsit_disp_leftdatabox:STYLE:HEIGHT TO 1.
	set vsit_disp_leftdatabox:style:margin:h to 20.
	set vsit_disp_leftdatabox:style:margin:v to ops3_disp_vmargin.
	
	GLOBAL vsit_disp_horiz_sliderbox IS vsit_disp_leftdatabox:ADDVLAYOUT().
	SET vsit_disp_horiz_sliderbox:STYLe:WIDTH TO vsit_disp_leftdatabox:STYLE:WIDTH.
	SET vsit_disp_horiz_sliderbox:STYLe:HEIGHT TO 1.
	set vsit_disp_horiz_sliderbox:style:margin:h to 148.
	
	vsit_disp_leftdatabox:addspacing(180).
	
	GLOBAL horiz_slider_label IS vsit_disp_horiz_sliderbox:ADDLABEL("").
	set horiz_slider_label:style:margin:h to 55.
	set horiz_slider_label:style:margin:v to 8.
	set horiz_slider_label:style:width to 120.
	GLOBAL vsit_horiz_slider is vsit_disp_horiz_sliderbox:addhslider(1,0,1).
	SET vsit_horiz_slider:STYLE:ALIGN TO "Center".
	SET vsit_horiz_slider:style:vstretch to false.
	SET vsit_horiz_slider:style:hstretch to false.
	SET vsit_horiz_slider:STYLE:WIDTH TO 180.
	set vsit_horiz_slider:style:margin:v to -3.
	set vsit_horiz_slider:style:margin:h to 5.
	
	make_time2hac_slider().
	
	for w in vsit_disp_horiz_sliderbox:WIDGETS {
		w:HIDE().
	}
	
	GLOBAL vsit_disp_attitudebox IS vsit_disp_leftdatabox:ADDVLAYOUT().
	SET vsit_disp_attitudebox:STYLE:ALIGN TO "left".
	SET vsit_disp_attitudebox:STYLE:WIDTH TO 75.
    SET vsit_disp_attitudebox:STYLE:HEIGHT TO 75.
	
	GLOBAL vsitleftdata1 IS vsit_disp_leftdatabox:ADDLABEL("R  XXX").
	set vsitleftdata1:style:margin:v to -4.
	GLOBAL vsitleftdata2 IS vsit_disp_leftdatabox:ADDLABEL("P  XXX").
	set vsitleftdata2:style:margin:v to -4.
	GLOBAL vsitleftdata3 IS vsit_disp_leftdatabox:ADDLABEL("Y  XXX").
	set vsitleftdata3:style:margin:v to -4.
	
	GLOBAL vsit_disp_rightdatabox IS vsit_disp_overlaiddata:ADDVLAYOUT().
	SET vsit_disp_rightdatabox:STYLE:ALIGN TO "left".
	SET vsit_disp_rightdatabox:STYLE:WIDTH TO 200.
    SET vsit_disp_rightdatabox:STYLE:HEIGHT TO 90.
	set vsit_disp_rightdatabox:style:margin:h to 85.
	set vsit_disp_rightdatabox:style:margin:v to 185 + ops3_disp_vmargin.
	
	
	GLOBAL vsitrightdata0 IS vsit_disp_rightdatabox:ADDLABEL("OTT ST IN").
	set vsitrightdata0:style:margin:h to 130.
	set vsitrightdata0:style:margin:v to 20.
	GLOBAL vsitrightdata1 IS vsit_disp_rightdatabox:ADDLABEL("NEP  /  MEP").
	set vsitrightdata1:style:margin:h to 30.
	set vsitrightdata1:style:margin:v to -4.
	GLOBAL vsitrightdata2 IS vsit_disp_rightdatabox:ADDLABEL("ALPHA LIMS xx xx").
	set vsitrightdata2:style:margin:v to -4.
	GLOBAL vsitrightdata3 IS vsit_disp_rightdatabox:ADDLABEL("SPDBK CMD xxx"). 
	set vsitrightdata3:style:margin:v to -2.
	GLOBAL vsitrightdata4 IS vsit_disp_rightdatabox:ADDLABEL("REF HDOT xxx").
	set vsitrightdata4:style:margin:v to -4.
	GLOBAL vsitrightdata5 IS vsit_disp_rightdatabox:ADDLABEL("TGT NZ   xxxxx").
	set vsitrightdata5:style:margin:v to -4.
	
	
	
	GLOBAL herror_sliderbox IS vsit_disp_overlaiddata:ADDVLAYOUT().
	SET herror_sliderbox:STYLe:WIDTH TO 55.
	set herror_sliderbox:style:margin:h to 0.
	set herror_sliderbox:style:margin:v to 100 + ops3_disp_vmargin.
	SET herror_sliderbox:STYLE:ALIGN TO "Center".
	GLOBAL herror_slider_label IS herror_sliderbox:ADDLABEL("H ERR").
	set herror_slider_label:style:margin:h to 1.
	set herror_slider_label:style:margin:v to 0.
	GLOBAL herror_slider is herror_sliderbox:addvslider(0,-1.85,1.85).
	SET herror_slider:STYLE:ALIGN TO "Center".
	SET herror_slider:style:vstretch to false.
	SET herror_slider:style:hstretch to false.
	SET herror_slider:STYLE:WIDTH TO 20.
	SET herror_slider:STYLE:HEIGHT TO 180.
	set herror_slider:style:margin:h to 0.
	set herror_slider:style:margin:v to 5.
	
	
	GLOBAL vsit_disp_orbiter_box IS vsit_disp_mainbox:ADDVLAYOUT().
	SET vsit_disp_orbiter_box:STYLE:ALIGN TO "Center".
	SET vsit_disp_orbiter_box:STYLe:WIDTH TO 1.
	SET vsit_disp_orbiter_box:STYLe:HEIGHT TO 1.
	
	GLOBAL vsit_disp_orbiter IS vsit_disp_orbiter_box:ADDLABEL().
	SET vsit_disp_orbiter:IMAGE TO "Shuttle_OPS3/src/gui_images/orbiter_bug.png".
	SET vsit_disp_orbiter:STYLe:WIDTH TO 22.
	
	reset_taem_vsit_disp().
}

function make_time2hac_slider {
	set vsit_horiz_slider:STYLe:BG to "Shuttle_OPS3/src/gui_images/hac_entry_slider.png".
	SET vsit_horiz_slider:STYLE:HEIGHT TO 36.
	SET vsit_horiz_slider:MIN TO 0.
	SET vsit_horiz_slider:MAX TO 6.5.
	set horiz_slider_label:text to "TIME TO HAC".
}

function make_xtrackerr_slider {
	set vsit_horiz_slider:STYLe:BG to "Shuttle_OPS3/src/gui_images/xtrack_err_slider.png".
	SET vsit_horiz_slider:STYLE:HEIGHT TO 25.
	SET vsit_horiz_slider:MIN TO -18.5.
	SET vsit_horiz_slider:MAX TO 18.5.
	set horiz_slider_label:text to "XTRACK ERR ".
}

function reset_taem_vsit_disp {
	set_taem_vsit_disp_title().
	set_taem_vsit_disp_bg().
}

function increment_taem_vsit_disp_counter {
	set taem_vsit_disp_counter to taem_vsit_disp_counter + 1.
	//meant to be executed just once 
	for w in vsit_disp_horiz_sliderbox:WIDGETS {
		w:SHOW().
	}
}

function set_taem_vsit_disp_title {
	parameter title_str is "VERT".

	local text_ht is ops3_main_display_titlebox:style:height*0.75.
	
	set ops3_main_display_title:text to "<b><size=" + text_ht + "> " + title_str + " SIT " + taem_vsit_disp_counter + "</size></b>".
}


function set_taem_vsit_disp_bg {
	set vsit_disp_mainbox:style:BG to "Shuttle_OPS3/src/gui_images/vsit" + taem_vsit_disp_counter + "_bg.png".
}
function set_taem_vsit_herror_slider {
	parameter herror.
	
	local val is 0.
	
	local abs_herr is abs(herror).
	
	local first_range_val is 100.
	local second_range_val is 1000.
	
	if (abs_herr < first_range_val) {
		set val to abs_herr / first_range_val.
	} else {
		set val to 1 + (abs_herr - first_range_val) / (second_range_val - first_range_val).
	}

	return val * sign(herror).
}

function update_taem_vsit_disp {
	parameter gui_data.
	
	SET ops3_main_display_clock:text TO "MET " + sectotime_simple(MISSIONTIME, true).

	if (taem_vsit_disp_counter = 1 and gui_data["rpred"] <= 64000) {
		increment_taem_vsit_disp_counter().
	}
	
	if (taem_vsit_disp_counter_p <> taem_vsit_disp_counter) {
		set taem_vsit_disp_counter_p to taem_vsit_disp_counter.
		reset_taem_vsit_disp().
	}
	
	local title_str is "VERT".
	
	if (gui_data["ecal_flag"]) {
		set title_str to "ECAL".
	} else if (gui_data["cont_flag"]) {
		set title_str to "CONT".
	} else if (gui_data["grtls_flag"]) {
		set title_str to "GRTLS".
	}
	
	set_taem_vsit_disp_title(title_str).
	
	if (taem_vsit_disp_counter=2) {
		//horiz slider 
		if (gui_data["guid_id"] <= 21) {
			set vsit_horiz_slider:value to CLAMP(gui_data["hac_entry_t"],vsit_horiz_slider:MIN,vsit_horiz_slider:MAX).
		} else {
			set vsit_horiz_slider:value to CLAMP(gui_data["xtrack_err"],vsit_horiz_slider:MIN,vsit_horiz_slider:MAX).
		}
	}
	
	local orbiter_bug_pos is LIST(0,0).
	
	if (gui_data["guid_id"] <= 26) AND (gui_data["guid_id"] >= 24) {
		set orbiter_bug_pos to set_taem_vsit_disp_bug(v(grtls_disp_x_convert(gui_data["mach"]),grtls_disp_y_convert(gui_data["prog_pch"]), 0)).
	} ELSE {
		set orbiter_bug_pos to set_taem_vsit_disp_bug(v(taem_vsit_disp_x_convert(gui_data["rpred"]),taem_vsit_disp_y_convert(gui_data["eow"]), 0)).
	}
	
	SET vsit_disp_orbiter:STYLE:margin:v to orbiter_bug_pos[1].
	SET vsit_disp_orbiter:STYLE:margin:h to orbiter_bug_pos[0].
	
	set herror_slider:value to CLAMP(set_taem_vsit_herror_slider(gui_data["herror"]),herror_slider:MIN,herror_slider:MAX).
	
	if (gui_data["eowlof"]) {
		set vsitrightdata0:text TO "<color=#" + guitextredhex + ">LO ENERGY</color>".
	} else if (gui_data["ottstin"]) {
		set vsitrightdata0:text TO "<color=#" + guitextyellowhex + ">OTT ST IN</color>".
	} else {
		set vsitrightdata0:text TO "".
	}
	
	if (gui_data["mep"]) {
		set vsitrightdata1:text TO "         /  " + "<color=#" + guitextyellowhex + ">MEP</color>".
	} ELSE {
		set vsitrightdata1:text TO "NEP  /".
	}
	
	set vsitrightdata2:text to "ALPHA LIMS  " + round(gui_data["alpll"], 0) + "  " +  round(gui_data["alpul"], 0).
	set vsitrightdata3:text to "SPDBK CMD  " + round(gui_data["spdbkcmd"], 1).
	set vsitrightdata4:text to "REF HDOT  " + round(gui_data["tgthdot"], 0).
	
	set vsitrightdata5:text to "LOAD FAC    " + round(gui_data["xlfac"], 1) + " G".
	
	if (gui_data["xlfac"] > 3.2) {
		set vsitrightdata5:text to "<color=#" + guitextredhex + ">" + vsitrightdata5:text + "</color>".
	} else if (gui_data["xlfac"] > 2.2) {
		set vsitrightdata5:text to "<color=#" + guitextyellowhex + ">" + vsitrightdata5:text + "</color>".
	}
	
	set vsitleftdata1:text to "R  " + round(gui_data["prog_roll"], 0).
	set vsitleftdata2:text to "P  " + round(gui_data["prog_pch"], 0).
	set vsitleftdata3:text to "Y  " + round(gui_data["prog_yaw"], 0).
}

function set_taem_vsit_disp_bug {
	parameter bug_pos.
	
	local bug_margin is 10.
	
	local bounds_x is list(10, vsit_disp_mainbox:STYLe:WIDTH - 32).
	local bounds_y is list(vsit_disp_mainbox:STYLe:HEIGHT - 29, 0).
	
	//print "calc_x: " + bug_pos:X + " calc_y: " +  + bug_pos:Y  + "  " at (0, 4).
	
	local pos_x is 1.04693*bug_pos:X  - 8.133.
	local pos_y is 395.55 - 1.1685*bug_pos:Y.
	
	//print "disp_x: " + pos_x + " disp_y: " + pos_y + "  " at (0, 5).
	
	set pos_x to clamp(pos_x, bounds_x[0], bounds_x[1] ).
	set pos_y to clamp(pos_y, bounds_y[0], bounds_y[1]).
	
	//print "disp_x: " + pos_x + " disp_y: " + pos_y + "  " at (0, 6).
	
	return list(pos_x,pos_y).
}

function taem_vsit_disp_x_convert {
	parameter rpred.
	
	local out is 0.
	
	if (taem_vsit_disp_counter=1) {
		set out to (rpred / 93000 -  0.64235294117).
	} else if (taem_vsit_disp_counter=2) {
		set out to (rpred / 60000).
	}	
	
	return out * 380.
}


function taem_vsit_disp_y_convert {
	parameter eow.
	
	local out is 0.
	
	if (taem_vsit_disp_counter=1) {
		set out to (eow / 75000  - 0.33757142857).
	} else if (taem_vsit_disp_counter=2) {
		set out to (eow / 45000 + 0.03).
	}	
	
	return 50 + 300 * out.
}

function grtls_disp_x_convert {
	parameter mach.
	
	local mach_ is clamp(mach, 3.2, 6.5).
	
	return 60.31746 * mach_ -140.95238. 
}

function grtls_disp_y_convert {
	parameter alp.

	return 3.33333 * alp + 190.
}


//			HUD stuff


FUNCTION make_hud_gui {
	IF (DEFINED hud_gui AND hud_gui:visible) {
		RETURN.
	}
	
	LOCAL hudfont IS "Consolas".
	
	GLOBAL hudwidth IS 450.
	GLOBAL hudheight IS 340.

	GLOBAL hud_gui is gui(hudwidth,hudheight).
	SET hud_gui:STYLe:WIDTH TO hudwidth.
	SET hud_gui:STYLe:HEIGHT TO hudheight.
	
	recenter_hud().
	SET hud_gui:skin:LABEL:TEXTCOLOR to guitextgreen.
	hud_gui:SHOW.


	set hud_gui:skin:horizontalslider:BG to "Shuttle_OPS3/src/gui_images/brakeslider.png".
	set hud_gui:skin:horizontalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/hslider_thumb.png".
	set hud_gui:skin:horizontalsliderthumb:HEIGHT to 17.
	set hud_gui:skin:horizontalsliderthumb:WIDTH to 20.
	set hud_gui:skin:verticalslider:BG to "Shuttle_OPS3/src/gui_images/vspdslider2.png".
	set hud_gui:skin:verticalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/vslider_thumb.png".
	set hud_gui:skin:verticalsliderthumb:HEIGHT to 20.
	set hud_gui:skin:verticalsliderthumb:WIDTH to 17.


	GLOBAL hud IS hud_gui:ADDVLAYOUT().

	GLOBAL hdg IS hud:ADDVLAYOUT().
	SET hdg:STYLE:ALIGN TO "Center".
	SET hdg:STYLe:HEIGHT TO 20.

	GLOBAL hdg_box IS hdg:ADDVLAYOUT().
	SET hdg_box:STYLe:WIDTH TO 60.
	SET hdg_box:STYLe:HEIGHT TO 20.
	SET hdg_box:STYLE:MARGIN:left TO 165.
	GLOBAL hdg_text IS hdg_box:ADDLABEL("").
	SET hdg_text:STYLE:ALIGN TO "Center".
	SET hdg_text:STYLE:FONT TO hudfont.
	
	GLOBAL overlaiddata IS hud:ADDVLAYOUT().
	SET overlaiddata:STYLE:ALIGN TO "Center".
	SET overlaiddata:STYLe:WIDTH TO 360.
	SET overlaiddata:STYLe:HEIGHT TO 1.
	
	GLOBAL spdaltbox IS overlaiddata:ADDHLAYOUT().
	SET spdaltbox:STYLe:WIDTH TO 360.
	SET spdaltbox:STYLe:HEIGHT TO 30.
	
	GLOBAL spdbox IS spdaltbox:ADDHLAYOUT().
	SET spdbox:STYLe:WIDTH TO 70.
	SET spdbox:STYLe:HEIGHT TO 30.
	SET spdbox:STYLe:MARGIN:left TO 10.
	SET spdbox:STYLe:MARGIN:top TO 87.
	GLOBAL spd_text IS spdbox:ADDLABEL("<size=18>M26.5</size>").
	SET spd_text:STYLE:ALIGN TO "Right".
	SET spd_text:STYLE:WIDTH TO 60.
	SET spd_text:STYLE:FONT TO hudfont.
	
	
	GLOBAL altbox IS spdaltbox:ADDHLAYOUT().
	SET altbox:STYLe:WIDTH TO 70.
	SET altbox:STYLe:HEIGHT TO 30.
	SET altbox:STYLe:MARGIN:left TO 245.
	SET altbox:STYLe:MARGIN:top TO 87.
	GLOBAL alt_text IS altbox:ADDLABEL("<size=18>100.5</size>").
	SET alt_text:STYLE:ALIGN TO "Left".
	SET alt_text:STYLE:FONT TO hudfont.
	
	
	
	
	
	GLOBAL hudrll IS overlaiddata:ADDVLAYOUT().
	SET hudrll:STYLe:WIDTH TO 20.
	SET hudrll:STYLe:HEIGHT TO 20.
	SET hudrll:STYLE:MARGIN:left TO 176.
	SET hudrll:STYLE:MARGIN:top TO 49.
	GLOBAL hudrll_text IS hudrll:ADDLABEL("rll").
	SET hudrll_text:STYLe:WIDTH TO 30.
	SET hudrll_text:STYLE:ALIGN TO "Center".
	SET hudrll_text:STYLE:FONT TO hudfont.
	
	GLOBAL hudpch IS overlaiddata:ADDVLAYOUT().
	SET hudpch:STYLe:WIDTH TO 20.
	SET hudpch:STYLe:HEIGHT TO 20.
	SET hudpch:STYLE:MARGIN:top TO 6.
	SET hudpch:STYLE:MARGIN:left TO 213.
	GLOBAL hudpch_text IS hudpch:ADDLABEL("pch").
	SET hudpch_text:STYLe:WIDTH TO 30.
	SET hudpch_text:STYLE:ALIGN TO "Left".
	SET hudpch_text:STYLE:FONT TO hudfont.


	GLOBAL hud_nz IS overlaiddata:ADDHLAYOUT().
	SET hud_nz:STYLe:WIDTH TO 70.
	SET hud_nz:STYLe:HEIGHT TO 30.
	SET hud_nz:STYLE:MARGIN:top TO 1.
	SET hud_nz:STYLE:MARGIN:left TO 58.
	GLOBAL nz_text IS hud_nz:ADDLABEL("").
	SET nz_text:STYLe:WIDTH TO 100.
	SET nz_text:STYLE:ALIGN TO "Right".
	SET nz_text:STYLE:FONT TO hudfont.

	GLOBAL hud_main IS hud:ADDHLAYOUT().
	SET hud_main:STYLe:WIDTH TO 430.
	SET hud_main:STYLe:HEIGHT TO 230.
	SET hud_main:STYLE:ALIGN TO "Center".
	hud_main:addspacing(0).
	
	GLOBAL flaptrim_sliderbox IS hud_main:ADDVLAYOUT().
	SET flaptrim_sliderbox:STYLe:WIDTH TO 15.
	SET flaptrim_sliderbox:STYLE:ALIGN TO "right".
	flaptrim_sliderbox:addspacing(72).
	GLOBAL flaptrim_slider is flaptrim_sliderbox:addvslider(0,1,-1).
	SET flaptrim_slider:STYLE:ALIGN TO "Center".
	SET flaptrim_slider:style:vstretch to false.
	SET flaptrim_slider:style:hstretch to false.
	SET flaptrim_slider:STYLE:WIDTH TO 20.
	SET flaptrim_slider:STYLE:HEIGHT TO 100.



	


	GLOBAL pointbox IS hud_main:addhbox().
	SET pointbox:STYLE:ALIGN TO "Center".
	SET pointbox:STYLe:WIDTH TO 360.
	SET pointbox:STYLe:HEIGHT TO 240.
	set pointbox:style:margin:top to 0.
	set pointbox:style:margin:left to 0.
	SET pointbox:style:vstretch to false.
	SET pointbox:style:hstretch to false.
	SET  pointbox:style:BG to "Shuttle_OPS3/src/gui_images/bg_marker_square.png".
	
	
	
	GLOBAL diamond IS pointbox:ADDLABEL().
	SET diamond:IMAGE TO "Shuttle_OPS3/src/gui_images/diamond.png".
	SET diamond:STYLe:WIDTH TO 22.
	SET diamond:STYLe:HEIGHT TO 22.
	

	//GLOBAL diamond_hmargin IS  pointbox:STYLe:WIDTH*0.458 .
	//GLOBAL diamond_vmargin IS pointbox:STYLE:HEIGHT*0.447.
	
	//define central position as global constants.
	GLOBAL diamond_central_x IS pointbox:STYLe:WIDTH*0.4783.
	GLOBAL diamond_central_y IS pointbox:STYLE:HEIGHT*0.449.
	
	SET diamond:STYLE:margin:h TO diamond_central_x.
	SET diamond:STYLE:margin:v TO diamond_central_y.



	GLOBAL vspd_sliderbox IS hud_main:ADDHLAYOUT().
	SET vspd_sliderbox:STYLe:WIDTH TO 20.
	SET vspd_sliderbox:STYLE:ALIGN TO "Center".
	GLOBAL vspd_slider is vspd_sliderbox:addvslider(0,-150,150).
	SET vspd_slider:STYLE:ALIGN TO "Center".
	SET vspd_slider:style:vstretch to false.
	SET vspd_slider:style:hstretch to false.
	SET vspd_slider:STYLE:WIDTH TO 20.
	SET vspd_slider:STYLE:HEIGHT TO 230.




	GLOBAL bottom_box IS hud:ADDHLAYOUT().
	SET bottom_box:STYLe:WIDTH TO 500.

	GLOBAL bottom_data_box IS bottom_box:ADDHLAYOUT().
	SET bottom_data_box:STYLe:WIDTH TO 260.
	SET bottom_data_box:STYLE:HSTRETCH TO TRUE.
	

	GLOBAL bottom_textbox IS bottom_data_box:ADDVLAYOUT().
	SET bottom_textbox:STYLe:WIDTH TO 150.
	SET bottom_textbox:STYLE:ALIGN TO "Left".
	SET bottom_textbox:STYLE:HSTRETCH TO TRUE.

	GLOBAL mode_txt IS bottom_textbox:ADDLABEL("<size=18>    </size>").
	SET mode_txt:STYLe:WIDTH TO 75.
	SET mode_txt:STYLE:MARGIN:left TO 50.
	SET mode_txt:STYLE:MARGIN:top TO 13.
	SET mode_txt:STYLE:FONT TO hudfont.
	
	GLOBAL steer_txt IS bottom_textbox:ADDLABEL("<size=18>    </size>").
	SET steer_txt:STYLe:WIDTH TO 55.
	SET steer_txt:STYLE:MARGIN:left TO 20.
	SET steer_txt:STYLE:MARGIN:top TO 13.
	SET steer_txt:STYLE:FONT TO hudfont.
	
	

	GLOBAL mode_dist_text IS  bottom_data_box:ADDLABEL( "<size=18>"+"</size>" ).
	SET steer_txt:STYLe:WIDTH TO 75.
	SET mode_dist_text:STYLE:MARGIN:top TO 13.
	SET mode_dist_text:STYLE:FONT TO hudfont.


	GLOBAL spdbk_slider_box IS bottom_box:ADDHLAYOUT().
	GLOBAL spdbk_slider is spdbk_slider_box:addhslider(0,-0.01,1).
	SET spdbk_slider:style:vstretch to false.
	SET spdbk_slider:style:hstretch to false.
	SET spdbk_slider:STYLE:WIDTH TO 110.
	SET spdbk_slider:STYLE:HEIGHT TO 20.

}

//set to the centre of the screen
FUNCTION recenter_hud {
	SET hud_gui:X TO (ops3_parameters["game_resolution_width"] - hudwidth)/2.
	SET hud_gui:Y TO (ops3_parameters["game_resolution_height"] - hudheight)/2.
}

//sets bright or dark hud background based on the local time at the target
FUNCTION reset_hud_bg_brightness {
	IF NOT (DEFINED hud_gui) {RETURN.}

	LOCAL tgt_lng IS tgtrwy["position"]:LNG.

	LOCAL tgt_local_time IS local_time_seconds(tgt_lng).
	
	IF (tgt_local_time < 19800 OR tgt_local_time>66000) {
		SET hud_gui:style:BG to "Shuttle_OPS3/src/gui_images/hudbackground_bright.png".
	} ELSe {
		SET hud_gui:style:BG to "Shuttle_OPS3/src/gui_images/hudbackground_dark.png".
	}
	
	
}

fUNCTION get_hud_datalex {
	RETURN LEXICON(
					"phase", 0,
					"pipper_deltas", 0,
					"altitude", 0,
					"hdot", 0,
					"distance", 0,
					"delaz", 0,
					"cur_pch", 0,
					"cur_roll", 0,
					"spdbk_val", 0,
					"flapval", 0,
					"cur_nz", 0
	).
}

FUNCTION update_hud_gui {
	PARAMETER hud_datalex.
	
	reset_hud_bg_brightness().
	
	LOCAL steer_str IS "".
	IF (is_dap_engaged) {
		IF (is_dap_css()) {
			SET steer_str TO "CSS ".
		} ELSE {
			SET steer_str TO "AUTO".
		}
	} ELSE {
		SET steer_str TO "OFF ".
	}

	SET steer_txt:text TO "<size=18>" + steer_str + "</size>".
	
	SET mode_txt:text TO "<size=18>" + hud_guid_labels(hud_datalex["phase"]) + "</size>".

	// set the pipper to an intermediate position between the desired and the current position so the transition is smoother
	LOCAL smooth_fac IS 0.25.
	
	LOCAL pipper_pos_cur IS LIST(diamond:STYLE:margin:h, diamond:STYLE:margin:v).
	
	local altt_format is altitude_format(hud_datalex["altitude"], hud_datalex["phase"]).
	local dist_format is distance_format(hud_datalex["distance"], hud_datalex["phase"]).

	local spd_format is speed_format(hud_datalex["phase"]).

	set_vspd_slider_limits(hud_datalex["phase"]).

	LOCAL pipper_deltas IS diamond_deviation_phase(hud_datalex["pipper_deltas"], hud_datalex["phase"]).

	SET diamond:STYLE:margin:h TO pipper_pos_cur[0] + smooth_fac*(pipper_deltas[0] - pipper_pos_cur[0]).
	SET diamond:STYLE:margin:v TO pipper_pos_cur[1] + smooth_fac*(pipper_deltas[1] - pipper_pos_cur[1]).
	
	SET vspd_slider:VALUE TO CLAMP(-hud_datalex["hdot"],vspd_slider:MIN,vspd_slider:MAX).
	
	SET hdg_text:text TO "<size=18>" + ROUND(hud_datalex["delaz"], 0)  + "</size>".
	
	SET spd_text:text TO "<size=18>"+ spd_format + "</size>".
	SET alt_text:text TO "<size=18>" + altt_format + "</size>".
	
	SET nz_text:text TO "<size=18>" + ROUND(hud_datalex["cur_nz"],1) + " G</size>".
	
	SET mode_dist_text:text TO "<size=18>" + dist_format + "</size>".
		
	SET spdbk_slider:VALUE TO hud_datalex["spdbk_val"].
	
	SET flaptrim_slider:VALUE TO hud_datalex["flapval"].
	
	SET hudrll_text:text TO "<size=12>" + ROUND(hud_datalex["cur_roll"],0) + "</size>".
	SET hudpch_text:text TO "<size=12>" + ROUND(hud_datalex["cur_pch"],0) + "</size>".

}


//scales the deltas by the right amount for display
//accounting for the diamond window width
FUNCTION diamond_deviation_debug {
	
	LOCAL hmargin IS diamond_central_x.
	LOCAL vmargin IS diamond_central_y.
	
	LOCAL horiz IS SHIP:CONTROL:PILOTROLL.
	LOCAL vert IS -SHIP:CONTROL:PILOTPITCH.


	//transpose the deltas to the interval [0, 1] times the window widths
	LOCAL diamond_horiz IS hmargin*(1 + horiz).
	LOCAL diamond_vert IS vmargin*(1 + vert).

	//clamp them 
	SET diamond_horiz TO CLAMP(diamond_horiz,0,2*hmargin).
	SET diamond_vert TO CLAMP(diamond_vert,0,2*vmargin). 
	

	RETURN LIST(diamond_horiz,diamond_vert).

}

//set slider limits based on phase
FUNCTION set_vspd_slider_limits {
	PARAMETEr iphase.
	
	IF (iphase<20) {
		//entry
		SET vspd_slider:MIN TO -200.
		SET vspd_slider:MAX TO +200.
	} ELSE {
		IF (iphase<= 24) OR (iphase>= 30) {
			//taem, a_l and alpha tran
			SET vspd_slider:MIN TO -100.
			SET vspd_slider:MAX TO +100.
		} ELSE {
			//grtls alpha rec and nz-hold
			SET vspd_slider:MIN TO -300.
			SET vspd_slider:MAX TO +300.
		}
	}

}

//scales the deltas by the right amount for display
//accounting for the diamond window width
FUNCTION diamond_deviation_phase {
	PARAMETER deltas.
	PARAMETER iphase.

	LOCAL vmult iS 0.
	LOCAL hmult iS 0.
	
	//the vertical multiplier needs to be negative
	IF (iphase<20) {
		SET vmult TO -0.07.
		SET hmult TO 0.03.
	} ELSE {
		SET vmult TO -0.013.
		SET hmult TO 0.02.
	}
	
	LOCAL hmargin IS diamond_central_x.
	LOCAL vmargin IS diamond_central_y.
	
	LOCAL vdelta IS deltas[1].
	LOCAL hdelta IS deltas[0].
	
	
	LOCAL horiz IS hmult*hdelta.
	LOCAL vert IS  vmult*vdelta.


	//transpose the deltas to the interval [0, 1] times the window widths
	LOCAL diamond_horiz IS hmargin*(1 + horiz).
	LOCAL diamond_vert IS vmargin*(1 + vert).

	//clamp them 
	SET diamond_horiz TO CLAMP(diamond_horiz,0,2*hmargin).
	SET diamond_vert TO CLAMP(diamond_vert,0,2*vmargin). 
	

	RETURN LIST(diamond_horiz,diamond_vert).
}

FUNCTION hud_guid_labels{
	PARAMETEr iphase.
	
	IF (iphase>=30) {
		//a/l
		IF (iphase=31) {
			RETURN "CAPT ".
		} ELSE IF (iphase=32 OR iphase=33) {
			RETURN "OGS  ".
		} ELSE IF (iphase=34) {
			RETURN "FLARE ".
		} ELSE IF (iphase=35) {
			RETURN "FNLFL".
		} ELSE IF (iphase=36) {
			RETURN "ROLLOUT".
		}
		
	} ELSE IF (iphase>=20) {
		//taem / grtls
		IF (iphase=20) {
			RETURN "STURN".
		} ELSE IF (iphase=21) {
			RETURN "ACQ  ".
		} ELSE IF (iphase=22) {
			RETURN "HDG  ".
		} ELSE IF (iphase=23) {
			RETURN "PRFNL".
		} ELSE IF (iphase=24) {
			RETURN "ALPTRN".
		} ELSE IF (iphase=25) {
			RETURN "NZHOLD".
		} ELSE IF (iphase=26) {
			RETURN "ALPREC".
		} ELSE IF (iphase=27) {
			RETURN "STURN".
		} 
	} ELSE IF (iphase>=10) {
		//entry
		IF (iphase=11) {
			RETURN "PREEN".
		} ELSE IF (iphase=12) {
			RETURN "TEMP ".
		} ELSE IF (iphase=13) {
			RETURN "EQGL ".
		} ELSE IF (iphase=14) {
			RETURN "CONSTD".
		} ELSE IF (iphase=15) {
			RETURN "TRAN ".
		}
	}

}


FUNCTION altitude_format {
	PARAMETER altt. 	//takes altitude in metres
	PARAMETER iphase.
	

	//also calculate in km 
	LOCAL alttkm IS altt/1000.
	
	//accurate to 0.5 km
	IF (iphase < 30) {
		LOCAL altout IS FLOOR(alttkm).
		LOCAL dec IS alttkm - altout.
		IF (dec > 0.5) {
			SET altout TO altout + 0.5.
		}
		RETURN altout.
	} ELSE {
		//show full digits, floored to nearest ten or hundred depending
		LOCAL altout IS altt.
		
		IF (iphase >= 33) {
			//radar alt with more accuracy
			SET altt to ALT:RADAR.
			
			//accurate to 10m
			IF (altt >= 100) {
				SET altout TO FLOOR(altt/10)*10.
			} ELSE {
				SET altout TO FLOOR(altout).
			}
			
			set altout to altout + " R".
		
		} else {
			//accurate to 100m
			SET altout TO FLOOR(altt/100)*100.
		}
		
		RETURN altout.
	}
}


FUNCTION distance_format {
	PARAMETER dist.	//expected in km
	PARAMETER iphase.
	
	IF (iphase>=30) {
		//simply round to the single decimal point
		RETURN ROUND(dist,1).
	} ELSE {
		IF (dist > 100) {
			//floor down to 10km
			LOCAL distout IS 10*ROUND(dist/10,0).
			RETURN distout.
		} ELSE {
			//floor down to the unit
			RETURN FLOOR(dist).
		}
	}

}

FUNCTION speed_format {
	PARAMETER iphase.

	if (iphase >= 30) OR (iphase = 22) OR (iphase = 23) {
		return ROUND(SHIP:VELOCITY:SURFACE:MAG, 0).
	} else { 
		return "M" + ROUND(ADDONS:FAR:MACH, 1).
	}
}
	

FUNCTION hud_decluttering {
	PARAMETER iphase.

	if (iphase >= 30 OR iphase = 23) {
		//hide g indicator and change nose marker 
		nz_text:HIDE().
		SET  pointbox:style:BG to "Shuttle_OPS3/src/gui_images/bg_marker_round.png".
	}

	if (iphase >= 30) { 
		//hide attitude angles
		hudrll_text:HIDE().
		hudpch_text:HIDE().
	}

	if (iphase >= 33) { 
		//remove trim indicator, heading, vertical speed and attitude angles
		//also move altitude and speed indicators
		flaptrim_slider:HIDE().
		vspd_slider:HIDE().
		hdg_text:HIDE().
		mode_dist_text:HIDE().
		
		SET spdbox:STYLe:MARGIN:left TO 80.
		SET altbox:STYLe:MARGIN:left TO 88.
	}

	if (iphase >= 35) { 
		//hide pipper
		SET diamond:IMAGE TO "Shuttle_OPS3/src/gui_images/diamond_empty.png".
	}
}