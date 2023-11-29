@LAZYGLOBAL OFF.

close_all_GUIs().

GLOBAL guitextgreen IS RGB(20/255,255/255,21/255).
GLOBAL guitextred IS RGB(255/255,21/255,20/255).
global trajbgblack IS RGB(5/255,8/255,8/255).

GLOBAL guitextgreenhex IS "14ff15".
GLOBAL guitextredhex IS "ff1514".


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
	SET select_tgt:STYLE:WIDTH TO 100.
	SET select_tgt:STYLE:HEIGHT TO 25.
	SET select_tgt:STYLE:ALIGN TO "center".
	FOR site IN ldgsiteslex:KEYS {
		select_tgt:addoption(site).
	}		
	SET select_tgt:ONCHANGE to { 
		PARAMETER lex_key.	
		SET tgtrwy TO ldgsiteslex[lex_key].		
		SET reset_entry_flag TO TRUE.
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
	SET textEI2:text TO "  Delaz at EI : " + ROUND(ei_data["ei_delaz"],1) + " °".
	
	SET textEI3:text TO "Ref FPA at EI : " + round(ei_ref_data["ei_fpa"], 2) + " °".
	LOCAL text4_str IS "    FPA at EI : " + round(ei_data["ei_fpa"], 2) + " °".
	
	LOCAL text4_color IS guitextredhex.
	if (ABS(ei_ref_data["ei_fpa"] - ei_data["ei_fpa"]) < 0.02) {
		SET text4_color TO guitextgreenhex.
	}
	
	SET textEI4:text TO "<color=#" + text4_color + ">" + text4_str + "</color>".
	
	SET textEI5:text TO "Ref Vel at EI : " + round(ei_ref_data["ei_vel"], 1) + " m/s".
	LOCAL text6_str IS "    Vel at EI : " + round(ei_data["ei_vel"], 1) + " m/s".
	
	LOCAL text6_color IS guitextredhex.
	if (ABS(ei_ref_data["ei_vel"] - ei_data["ei_vel"]) < 5) {
		SET text6_color TO guitextgreenhex.
	}
	
	SET textEI6:text TO "<color=#" + text6_color + ">" + text6_str + "</color>".
	
	SET textEI7:text TO "Ref Rng at EI : "+ round(ei_ref_data["ei_range"], 0) + " km".
	LOCAL text8_str IS "    Rng at EI : " + round(ei_data["ei_range"], 0) + " km".
	
	LOCAL text8_color IS guitextredhex.
	if (ABS(ei_ref_data["ei_range"] - ei_data["ei_range"]) < 50) {
		SET text8_color TO guitextgreenhex.
	}
	
	SET textEI8:text TO "<color=#" + text8_color + ">" + text8_str + "</color>".


}





						//GLOBAL ENTRY GUI FUNCTIONS


GLOBAL main_entry_gui_width IS 550.
GLOBAL main_entry_gui_height IS 510.

FUNCTION make_main_entry_gui {
	

	//create the GUI.
	GLOBAL main_entry_gui is gui(main_entry_gui_width,main_entry_gui_height).
	SET main_entry_gui:X TO 170.
	SET main_entry_gui:Y TO 670.
	SET main_entry_gui:STYLe:WIDTH TO main_entry_gui_width.
	SET main_entry_gui:STYLe:HEIGHT TO main_entry_gui_height.
	SET main_entry_gui:STYLE:ALIGN TO "center".
	SET main_entry_gui:STYLE:HSTRETCH  TO TRUE.

	set main_entry_gui:skin:LABEL:TEXTCOLOR to guitextgreen.


	// Add widgets to the GUI
	GLOBAL title_box is main_entry_gui:addhbox().
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
			main_entry_gui:SHOWONLY(title_box).
			SET main_entry_gui:STYLe:HEIGHT TO 50.
		} ELSE {
			SET main_entry_gui:STYLe:HEIGHT TO main_entry_gui_height.
			for w in main_entry_gui:WIDGETS {
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

	
	main_entry_gui:addspacing(7).

	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_entry_gui:ADDHLAYOUT().
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
	}.
	
	SET select_rwy:ONCHANGE to { 
		PARAMETER rwy.	
		
		SET tgtrwy TO refresh_runway_lex(select_tgt:VALUE, rwy).
		
		reset_overhead_apch().
	}.
	
	SET select_tgt:ONCHANGE to {
		PARAMETER lex_key.
		
		LOCAL newsite IS ldgsiteslex[lex_key].
		
		select_rwy:CLEAR.
		FOR rwy IN newsite["rwys"]:KEYS {
			select_rwy:addoption(rwy).
		}	
		
		select_random_rwy().

		reset_hud_bg_brightness().
	}.	
	
	
	GLOBAL toggles_box IS main_entry_gui:ADDHLAYOUT().
	SET toggles_box:STYLE:WIDTH TO 300.
	toggles_box:addspacing(55).	
	SET toggles_box:STYLE:ALIGN TO "center".
	
	GLOBAL logb IS  toggles_box:ADDCHECKBOX("Log Data",false).
	toggles_box:addspacing(20).	
	
	GLOBAL fbwb IS  toggles_box:ADDCHECKBOX("Fly-by-wire",false).
	//SET fbwb:ONTOGGLE TO toggle_fbw@.
	toggles_box:addspacing(20).	
	
	GLOBAL flptrm IS  toggles_box:ADDCHECKBOX("Auto Flaps",false).
	toggles_box:addspacing(20).	
	
	GLOBAL arbkb IS  toggles_box:ADDCHECKBOX("Auto Airbk",false).

	select_random_rwy().
	SET tgtrwy TO refresh_runway_lex(select_tgt:VALUE, select_rwy:VALUE).	

	main_entry_gui:SHOW().
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

FUNCTION is_apch_overhead {
	
	IF (select_apch:VALUE = "Overhead") {
		RETURN TRUE.
	} ELSe IF (select_apch:VALUE = "Straight") {
		RETURN FALSE.
	}
}

FUNCTION close_global_GUI {
	main_entry_gui:HIDE().
	IF (DEFINED(hud_gui)) {
		hud_gui:HIDE.
		hud_gui:DISPOSE.
		
	}
}

FUNCTION close_all_GUIs{
	CLEARGUIS().
}




FUNCTION make_entry_traj_GUI {

	GLOBAL entry_traj_disp_counter IS 1.				   
	GLOBAL entry_traj_disp_counter_p IS entry_traj_disp_counter.				   
	
	GLOBAL traj_disp IS main_entry_gui:addvlayout().
	SET traj_disp:STYLE:WIDTH TO main_entry_gui_width - 22.
	SET traj_disp:STYLE:HEIGHT TO 380.
	SET traj_disp:STYLE:ALIGN TO "center".
	
	set traj_disp:style:BG to "Shuttle_OPS3/src/gui_images/entry_traj_bg.png".
	
	set main_entry_gui:skin:horizontalslider:BG to "Shuttle_OPS3/src/gui_images/brakeslider.png".
	set main_entry_gui:skin:horizontalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/hslider_thumb.png".
	set main_entry_gui:skin:horizontalsliderthumb:HEIGHT to 17.
	set main_entry_gui:skin:horizontalsliderthumb:WIDTH to 20.
	set main_entry_gui:skin:verticalslider:BG to "Shuttle_OPS3/src/gui_images/vspdslider2.png".
	set main_entry_gui:skin:verticalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/vslider_thumb.png".
	set main_entry_gui:skin:verticalsliderthumb:HEIGHT to 20.
	set main_entry_gui:skin:verticalsliderthumb:WIDTH to 17.
	
	GLOBAL traj_disp_titlebox IS traj_disp:ADDHLAYOUT().
	SET traj_disp_titlebox:STYLe:WIDTH TO traj_disp:STYLE:WIDTH.
	SET traj_disp_titlebox:STYLe:HEIGHT TO 20.
	GLOBAL traj_disp_title IS traj_disp_titlebox:ADDLABEL("").
	SET traj_disp_title:STYLE:ALIGN TO "center".
	
	GLOBAL traj_disp_overlaiddata IS traj_disp:ADDVLAYOUT().
	SET traj_disp_overlaiddata:STYLE:ALIGN TO "Center".
	SET traj_disp_overlaiddata:STYLe:WIDTH TO traj_disp:STYLE:WIDTH.
	SET traj_disp_overlaiddata:STYLe:HEIGHT TO 1.
	
	GLOBAL traj_disp_mainbox IS traj_disp:ADDVLAYOUT().
	SET traj_disp_mainbox:STYLE:ALIGN TO "Center".
	SET traj_disp_mainbox:STYLe:WIDTH TO traj_disp:STYLE:WIDTH.
	SET traj_disp_mainbox:STYLe:HEIGHT TO traj_disp:STYLE:HEIGHT - 22.
	
	
	
	
	
	GLOBAL traj_disp_leftdatabox IS traj_disp_overlaiddata:ADDVLAYOUT().
	SET traj_disp_leftdatabox:STYLE:ALIGN TO "left".
	SET traj_disp_leftdatabox:STYLE:WIDTH TO 125.
    SET traj_disp_leftdatabox:STYLE:HEIGHT TO 115.
	set traj_disp_leftdatabox:style:margin:h to 20.
	set traj_disp_leftdatabox:style:margin:v to 10.
	
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
	
	GLOBAL traj_disp_rightdatabox IS traj_disp_overlaiddata:ADDVLAYOUT().
	SET traj_disp_rightdatabox:STYLE:ALIGN TO "left".
	SET traj_disp_rightdatabox:STYLE:WIDTH TO 125.
    SET traj_disp_rightdatabox:STYLE:HEIGHT TO 115.
	set traj_disp_rightdatabox:style:margin:h to 400.
	set traj_disp_rightdatabox:style:margin:v to 90.
	
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
	
	//GLOBAL traj_disp_trail IS traj_disp_mainbox:ADDLABEL().
	//SET traj_disp_trail:IMAGE TO "Shuttle_OPS3/src/gui_images/traj_trail_bug.png".
	//SET traj_disp_trail:STYLe:WIDTH TO 10.
	//SET traj_disp_trail:STYLE:margin:v to 10.
	//SET traj_disp_trail:STYLE:margin:h to 10.
	
	reset_entry_traj_disp().
}

function reset_entry_traj_disp {
	set_entry_traj_disp_title().
	set_entry_traj_disp_bg().
}

function update_entry_traj_disp {
	parameter gui_data.

	local vel_ is gui_data["vi"].

	//check if we shoudl update entry traj counter 
	if (entry_traj_disp_counter = 1 and vel_ <= 5500) {
		increment_entry_entry_traj_disp_counter().
	} else if (entry_traj_disp_counter = 2 and vel_ <= 4330) {
		increment_entry_entry_traj_disp_counter().
	} else if (entry_traj_disp_counter = 3 and vel_ <= 3400) {
		increment_entry_entry_traj_disp_counter().
	} else if (entry_traj_disp_counter = 4 and vel_ <= 1950) {
		increment_entry_entry_traj_disp_counter().
	}
	
	if (entry_traj_disp_counter_p <> entry_traj_disp_counter) {
		set entry_traj_disp_counter_p to entry_traj_disp_counter.
		reset_entry_traj_disp().
	}

	local orbiter_bug_pos is set_entry_traj_disp_bug(v(entry_traj_disp_x_convert(gui_data["vi"], gui_data["drag"]),entry_traj_disp_y_convert(gui_data["vi"]), 0)).
	SET traj_disp_orbiter:STYLE:margin:v to orbiter_bug_pos[1].
	SET traj_disp_orbiter:STYLE:margin:h to orbiter_bug_pos[0].
	
	LOCAL drag_err_delta IS 0.
	IF (gui_data["phase"] > 1) {
		SET drag_err_delta TO 40 * (gui_data["drag_ref"]/gui_data["drag"] - 1).
	}
	
	SET traj_disp_pred_bug_:STYLE:margin:v to orbiter_bug_pos[1] + 10.
	SET traj_disp_pred_bug_:STYLE:margin:h to orbiter_bug_pos[0] - drag_err_delta + 5.
	
	
	
	set trajleftdata1:text TO "XLFAC     " + ROUND(gui_data["xlfac"],2).
	set trajleftdata2:text TO "L/D          " + ROUND(gui_data["lod"],2).
	set trajleftdata3:text TO "DRAG      " + ROUND(gui_data["drag"],2).
	set trajleftdata4:text TO "D REF     " + ROUND(gui_data["drag_ref"],2).
	set trajleftdata5:text TO "PHASE     " + ROUND(gui_data["phase"],0).
	
	set trajrightdata1:text TO "HDT REF    " + ROUND(gui_data["hdot_ref"],1).
	set trajrightdata2:text TO "ALPCMD    " + ROUND(gui_data["pitch"],1).
	
	if (gui_data["pitch_mod"]) {
		set trajrightdata3:text TO "<color=#fff600> ALP MODULN </color>".
	} else {
		set trajrightdata3:text TO "".
	}
	
	set trajrightdata4:text TO "ROLCMD     " + ROUND(gui_data["roll"],1).
	set trajrightdata5:text TO "ROLREF     " + ROUND(gui_data["roll_ref"],1).
	
	if (gui_data["roll_rev"]) {
		set trajrightdata6:text TO "<color=#fff600>ROLL REVERSAL</color>".
	} else {
		set trajrightdata6:text TO "".
	}

}

function increment_entry_entry_traj_disp_counter {
	set entry_traj_disp_counter to entry_traj_disp_counter + 1.
}

function set_entry_traj_disp_title {
	local text_ht is traj_disp_titlebox:style:height*0.75.
	
	set traj_disp_title:text to "<b><size=" + text_ht + ">ENTRY TRAJ " + entry_traj_disp_counter + "</size></b>".
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
	
	local pos_x is 1.04693*bug_pos:X  - 8.133.
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
	
	local bounds_x is list(10, traj_disp_mainbox:STYLe:WIDTH - 5).
	local bounds_y is list(traj_disp_mainbox:STYLe:HEIGHT - 5, 0).
	
	local pos_x is 1.04693*bug_pos:X  - 8.133.
	local pos_y is 395.55 - 1.1685*bug_pos:Y + bias.
	
	set pos_x to clamp(pos_x, bounds_x[0], bounds_x[1] ).
	set pos_y to clamp(pos_y, bounds_y[0], bounds_y[1]).
}

function entry_traj_disp_x_convert {
	parameter vel.
	parameter drag.
	
	local out is 0.
	
	LOCAL drag2 IS drag * drag.
	LOCAL vel2 IS vel * vel.
	
	if (entry_traj_disp_counter=1) {
		LOCAL vel3 IS vel2 * vel.
		LOCAL drag3 IS drag2 * drag.
		set out to  555.3926783243992 
					+ 0.137078652046288 * vel 
					- 94.72561947028342 * drag
					- 3.344538192253144e-05 * vel2
					+ 0.00906907118021625 * vel * drag
					+ 1.8200934250524303 * drag2
					+ 2.3076131838717373e-09 * vel3
					- 3.512244427130015e-07 * vel2 * drag
					- 5.082702175883116e-05 * vel * drag2
					- 0.014714191410748175 * drag3.
	} else if (entry_traj_disp_counter=2) {
		set out to - 38.0268152009462 
					+ 0.09906578419425373 * vel 
					- 12.707084859116666 * drag
					+ 1.3305326295037778e-06 * vel2
					+ 0.0011766877774739082 * vel * drag
					- 0.014838331795402771 * drag2.
	} else if (entry_traj_disp_counter=3) {
		set out to - 531.1596833649385 
					+ 0.2369508010818678 * vel
					- 0.7771572651359938 * drag
					- 2.1586890749936138e-07 * vel2
					+ 0.00021100580946806138 * vel * drag
					- 0.1132059499998106 * drag2.
	} else if (entry_traj_disp_counter=4) {
		set out to - 748.4063596835092 
					+ 0.7408869827508833 * vel
					- 13.833348494044804 * drag
					- 8.626522934807035e-05 * vel2
					+ 2.9372518671475292e-05 * vel * drag
					+ 0.10761028181794845 * drag2.
	} else if (entry_traj_disp_counter=5) {
		set out to - 776.3651212085673
					+ 1.0608120994108508 * vel
					- 0.0012408627622487007 * drag
					- 0.000190689080882267 * vel2
					- 0.0018267317853930109 * vel * drag
					- 0.062043138111733405 * drag2.
	}
	
	return out.

}

function entry_traj_disp_y_convert {
	parameter vel.
	
	local out is 0.
	
	if (entry_traj_disp_counter=1) {
		set out to (-0.1187007912 * vel + 966.857 + 32.7).
	} else if (entry_traj_disp_counter=2) {
		set out to (-0.23731299972 * vel + 1342.6666 + 32.7).
	} else if (entry_traj_disp_counter=3) {
		set out to (-0.255413394 * vel + 1170 + 32.7).
	} else if (entry_traj_disp_counter=4) {
		set out to (-0.171587932 * vel + 639 + 32.7).
	} else if (entry_traj_disp_counter=5) {
		set out to (-0.2568241552 * vel + 565.714 + 32.7).
	}
	
	
	return 400 - out.

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
	reset_hud_bg_brightness().
	SET hud_gui:skin:LABEL:TEXTCOLOR to guitextgreen.
	hud_gui:SHOW.


	set hud_gui:skin:horizontalslider:BG to "Shuttle_entrysim/src/gui_images/brakeslider.png".
	set hud_gui:skin:horizontalsliderthumb:BG to "Shuttle_entrysim/src/gui_images/hslider_thumb.png".
	set hud_gui:skin:horizontalsliderthumb:HEIGHT to 17.
	set hud_gui:skin:horizontalsliderthumb:WIDTH to 20.
	set hud_gui:skin:verticalslider:BG to "Shuttle_entrysim/src/gui_images/vspdslider2.png".
	set hud_gui:skin:verticalsliderthumb:BG to "Shuttle_entrysim/src/gui_images/vslider_thumb.png".
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
	SET spdbox:STYLe:MARGIN:left TO 20.
	SET spdbox:STYLe:MARGIN:top TO 87.
	GLOBAL spd_text IS spdbox:ADDLABEL("<size=18>M26.5</size>").
	SET spd_text:STYLE:ALIGN TO "Right".
	SET spd_text:STYLE:WIDTH TO 60.
	SET spd_text:STYLE:FONT TO hudfont.
	
	
	GLOBAL altbox IS spdaltbox:ADDHLAYOUT().
	SET altbox:STYLe:WIDTH TO 70.
	SET altbox:STYLe:HEIGHT TO 30.
	SET altbox:STYLe:MARGIN:left TO 230.
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
	SET hudpch:STYLE:MARGIN:top TO 4.
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
	SET  pointbox:style:BG to "Shuttle_entrysim/src/gui_images/bg_marker_square.png".
	
	
	
	GLOBAL diamond IS pointbox:ADDLABEL().
	SET diamond:IMAGE TO "Shuttle_entrysim/src/gui_images/diamond.png".
	SET diamond:STYLe:WIDTH TO 22.
	SET diamond:STYLe:HEIGHT TO 22.
	

	//GLOBAL diamond_hmargin IS  pointbox:STYLe:WIDTH*0.458 .
	//GLOBAL diamond_vmargin IS pointbox:STYLE:HEIGHT*0.447.
	
	//define central position as global constants.
	GLOBAL diamond_central_x IS pointbox:STYLe:WIDTH*0.4785.
	GLOBAL diamond_central_y IS pointbox:STYLE:HEIGHT*0.450.
	
	SET diamond:STYLE:margin:h TO diamond_central_x.
	SET diamond:STYLE:margin:v TO diamond_central_y.



	GLOBAL vspd_sliderbox IS hud_main:ADDHLAYOUT().
	SET vspd_sliderbox:STYLe:WIDTH TO 20.
	SET vspd_sliderbox:STYLE:ALIGN TO "Center".
	GLOBAL vspd_slider is vspd_sliderbox:addvslider(0,-20,20).
	SET vspd_slider:STYLE:ALIGN TO "Center".
	SET vspd_slider:style:vstretch to false.
	SET vspd_slider:style:hstretch to false.
	SET vspd_slider:STYLE:WIDTH TO 20.
	SET vspd_slider:STYLE:HEIGHT TO 230.




	GLOBAL bottom_box IS hud:ADDHLAYOUT().
	SET bottom_box:STYLe:WIDTH TO 500.
	
	
	GLOBAL bottom_txtbox IS bottom_box:ADDHLAYOUT().
	SET bottom_txtbox:STYLe:WIDTH TO 260.
	SET bottom_txtbox:STYLE:ALIGN TO "Left".
	SET bottom_txtbox:STYLE:HSTRETCH TO TRUE.
	
	bottom_txtbox:addspacing(30).
	
	GLOBAL steer_txt IS bottom_txtbox:ADDLABEL("<size=18>    </size>").
	SET steer_txt:STYLe:WIDTH TO 55.
	SET steer_txt:STYLE:MARGIN:top TO 40.
	SET steer_txt:STYLE:ALIGN TO "Left".
	SET steer_txt:STYLE:FONT TO hudfont.
	
	
	GLOBAL mode_txt IS bottom_txtbox:ADDLABEL("<size=18>    </size>").
	SET mode_txt:STYLe:WIDTH TO 75.
	SET mode_txt:STYLE:ALIGN TO "Left".
	SET mode_txt:STYLE:MARGIN:top TO 13.
	SET mode_txt:STYLE:FONT TO hudfont.
	

	GLOBAL mode_dist_text IS  bottom_txtbox:ADDLABEL( "<size=18>"+"</size>" ).
	SET mode_dist_text:STYLE:MARGIN:top TO 13.
	SET mode_dist_text:STYLE:FONT TO hudfont.


	GLOBAL spdbk_slider_box IS bottom_box:ADDHLAYOUT().
	GLOBAL spdbk_slider is spdbk_slider_box:addhslider(0,0,1).
	SET spdbk_slider:style:vstretch to false.
	SET spdbk_slider:style:hstretch to false.
	SET spdbk_slider:STYLE:WIDTH TO 110.
	SET spdbk_slider:STYLE:HEIGHT TO 20.

}

//set to the centre of the screen
FUNCTION recenter_hud {
	SET hud_gui:X TO (constants["game_resolution_width"] - hudwidth)/2.
	SET hud_gui:Y TO (constants["game_resolution_height"] - hudheight)/2.
}

//sets bright or dark hud background based on the local time at the target
FUNCTION reset_hud_bg_brightness {
	IF NOT (DEFINED hud_gui) {RETURN.}

	LOCAL tgt_lng IS tgtrwy["td_pt"]:LNG.

	LOCAL tgt_local_time IS local_time_seconds(tgt_lng).
	
	IF (tgt_local_time < 19800 OR tgt_local_time>66000) {
		SET hud_gui:style:BG to "Shuttle_entrysim/src/gui_images/hudbackground_bright.png".
	} ELSe {
		SET hud_gui:style:BG to "Shuttle_entrysim/src/gui_images/hudbackground_dark.png".
	}
	
	
}



FUNCTION update_hud_gui {
	PARAMETER mode_str.
	PARAMETER steer_str.
	PARAMETER pipper_pos.
	PARAMETER altt.
	PARAMETEr dist.
	PARAMETER hdgval.
	PARAMETER spd.
	PARAMETER pch.
	PARAMETER rll.
	PARAMETER spdbk_val.
	PARAMETER flapval.
	PARAMETER cur_nz.

	SET steer_txt:text TO "<size=18>" + steer_str + "</size>".
	
	SET mode_txt:text TO "<size=18>" + mode_str + "</size>".

	// set the pipper to an intermediate position between the desired and the current position so the transition is smoother
	LOCAL smooth_fac IS 0.5.
	
	LOCAL pipper_pos_cur IS LIST(diamond:STYLE:margin:h, diamond:STYLE:margin:v).
	
	SET diamond:STYLE:margin:h TO pipper_pos_cur[0] + smooth_fac*(pipper_pos[0] - pipper_pos_cur[0]).
	SET diamond:STYLE:margin:v TO pipper_pos_cur[1] + smooth_fac*(pipper_pos[1] - pipper_pos_cur[1]).
	
	SET vspd_slider:VALUE TO CLAMP(-SHIP:VERTICALSPEED,vspd_slider:MIN,vspd_slider:MAX).
	
	SET hdg_text:text TO "<size=18>" + hdgval + "</size>".
	
	SET spd_text:text TO "<size=18>M"+ ROUND(spd,1) + "</size>".
	SET alt_text:text TO "<size=18>" + ROUND(altt,1) + "</size>".
	
	SET nz_text:text TO "<size=18>" + ROUND(cur_nz,1) + " G</size>".
	
	SET mode_dist_text:text TO "<size=18>" + dist + "</size>".
		
	SET spdbk_slider:VALUE TO spdbk_val.
	
	SET flaptrim_slider:VALUE TO flapval.
	
	SET hudrll_text:text TO "<size=12>" + ROUND(rll,0) + "</size>".
	SET hudpch_text:text TO "<size=12>" + ROUND(pch,0) + "</size>".

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