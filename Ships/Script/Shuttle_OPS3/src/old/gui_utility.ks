						//DEORBIT GUI FUNCTIONS 
						
//GLOBAL guitextgreen IS RGB(167/255,207/255,147/255).
GLOBAL guitextgreen IS RGB(20/255,255/255,21/255).

FUNCTION make_global_deorbit_GUI {
	//create the GUI.
	GLOBAL main_gui is gui(400,350).
	SET main_gui:X TO 550.
	SET main_gui:Y TO 350.
	SET main_gui:STYLe:WIDTH TO 400.
	SET main_gui:STYLe:HEIGHT TO 450.

	set main_gui:skin:LABEL:TEXTCOLOR to guitextgreen.


	// Add widgets to the GUI
	GLOBAL title_box is main_gui:addhbox().
	set title_box:style:height to 35. 
	set title_box:style:margin:top to 0.


	GLOBAL text0 IS title_box:ADDLABEL("<b><size=20>SHUTTLE DEORBIT ASSISTANT</size></b>").
	SET text0:STYLE:ALIGN TO "center".


	
	GLOBAL quitb IS  title_box:ADDBUTTON("X").
	set quitb:style:margin:h to 7.
	set quitb:style:margin:v to 7.
	set quitb:style:width to 20.
	set quitb:style:height to 20.
	function quitcheck {
	  SET quitflag TO TRUE.
	}
	SET quitb:ONCLICK TO quitcheck@.


	main_gui:addspacing(7).



	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_gui:ADDVLAYOUT().
	SET popup_box:STYLE:ALIGN TO "center".
	SET popup_box:STYLE:WIDTH TO 200.	
	set popup_box:style:margin:h to 100.

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
	}.

	GLOBAL force_roll IS popup_box:addhlayout().
	SET force_roll:STYLE:ALIGN TO "center".
	GLOBAL force_roll_text IS force_roll:addlabel("Force Roll ref. : ").
	GLOBAL force_roll_box is force_roll:addtextfield(vehicle_params["rollguess"]:tostring).
	set force_roll_box:style:width to 65.
	set force_roll_box:style:height to 18.
		
	set force_roll_box:onconfirm to { 
		parameter val.
		SET roll_ref tO val:tonumber(vehicle_params["rollguess"]).
	}.
	
	
	GLOBAL pitchngains IS popup_box:ADDHLAYOUT().
	SET pitchngains:STYLE:ALIGN TO "Center".

	//button to override pitch profile

	GLOBAL pchprof_but IS  pitchngains:ADDBUTTON("<size=13>Override               Pitch Profile</size>").
	SET pchprof_but:STYLE:WIDTH TO 115.
	SET pchprof_but:STYLE:HEIGHT TO 45.
	SET pchprof_but:STYLE:ALIGN TO "Center".
	set pchprof_but:style:wordwrap to true.
	SET pchprof_but:ONCLICK TO profgui@.

	//button to override controller gains
	GLOBAL gains_but IS  pitchngains:ADDBUTTON("<size=13>Override Controller Gains</size>").
	SET gains_but:STYLE:WIDTH TO 115.
	SET gains_but:STYLE:HEIGHT TO 45.
	SET gains_but:STYLE:ALIGN TO "Center".
	set gains_but:style:wordwrap to true.
	SET gains_but:ONCLICK TO gainsgui@.
	
	
	
	
	


	GLOBAL all_box IS main_gui:ADDVLAYOUT().
	SET all_box:STYLE:WIDTH TO 400.
	SET all_box:STYLE:HEIGHT TO 380.
	SET all_box:STYLE:ALIGN TO "center".
	
	GLOBAL entry_interface_textlabel IS all_box:ADDLABEL("Entry Interface Data").	
	SET entry_interface_textlabel:STYLE:ALIGN TO "left".
	set entry_interface_textlabel:style:margin:h to 80.
	set entry_interface_textlabel:style:margin:v to 5.
	
	GLOBAL entry_interface_databox IS all_box:ADDVBOX().
	SET entry_interface_databox:STYLE:ALIGN TO "center".
	SET entry_interface_databox:STYLE:WIDTH TO 230.
    SET entry_interface_databox:STYLE:HEIGHT TO 115.
	set entry_interface_databox:style:margin:h to 80.
	set entry_interface_databox:style:margin:v to 0.
	
	
	GLOBAL textEI1 IS entry_interface_databox:ADDLABEL("Time to interface : ").
	set textEI1:style:margin:v to -4.
	GLOBAL textEI2 IS entry_interface_databox:ADDLABEL("Azimuth  error    : ").
	set textEI2:style:margin:v to -4.
	GLOBAL textEI3 IS entry_interface_databox:ADDLABEL("Ref. FPA at EI   : ").
	set textEI3:style:margin:v to -4.
	GLOBAL textEI5 IS entry_interface_databox:ADDLABEL("Flight-path angle : ").
	set textEI5:style:margin:v to -4.
	GLOBAL textEI6 IS entry_interface_databox:ADDLABEL("Range at EI       : ").
	set textEI6:style:margin:v to -4.
	
	
	
	GLOBAL entry_terminal_textlabel IS all_box:ADDLABEL("Entry terminal data").	
	SET entry_terminal_textlabel:STYLE:ALIGN TO "left".
	set entry_terminal_textlabel:style:margin:h to 80.
	set entry_terminal_textlabel:style:margin:v to 5.
	
	GLOBAL entry_terminal_databox IS all_box:ADDVBOX().
	SET entry_terminal_databox:STYLE:ALIGN TO "center".	
	SET entry_terminal_databox:STYLE:WIDTH TO 230.	
	SET entry_terminal_databox:STYLE:HEIGHT TO 80.	
	set entry_terminal_databox:style:margin:h to 80.
	set entry_terminal_databox:style:margin:v to 0.	
	
	GLOBAL textTM1 IS entry_terminal_databox:ADDLABEL("Distance error  : ").
	set textTM1:style:margin:v to -4.
	GLOBAL textTM2 IS entry_terminal_databox:ADDLABEL("Downrange error       : ").
	set textTM2:style:margin:v to -4.
	GLOBAL textTM3 IS entry_terminal_databox:ADDLABEL("Ref. bank angle   : ").
	set textTM3:style:margin:v to -4.	

	


	main_gui:SHOW().
}


FUNCTION update_deorbit_GUI {
	PARAMETER interf_t.
	PARAMETER interf_azerr.
	PARAMETER rei.
	PARAMETER interf_vel.
	PARAMETER fpa.
	
	PARAMETER term_dist.
	PARAMETER range_err.
	PARAMETER roll0.
	
	LOCAL ref_fpa IS FPA_reference(interf_vel).

		//data output
	SET textEI1:text TO "Time to EI       : " + sectotime(interf_t).
	SET textEI2:text TO "Azimuth  error   : " + ROUND(interf_azerr,1) + " °".
	SET textEI3:text TO "Ref. FPA at EI   :  " + ROUND(ref_fpa,2) + " °".
	SET textEI5:text TO "FPA at EI        : " + ROUND(fpa,2) + " °".
	SET textEI6:text TO "Range at EI      : " + ROUND(rei,1) + " km".
	
	
	SET textTM1:text TO "Distance error   : " + ROUND(term_dist,1) + " km".
	SET textTM2:text TO "Downrange error  : " + ROUND(range_err,1) + " km".
	SET textTM3:text TO "Ref. bank angle  : " + ROUND(roll0,1) + " °".

}






						//GLOBAL ENTRY GUI FUNCTIONS


GLOBAL entry_gui_height IS 220.

FUNCTION make_global_entry_GUI {
	

	//create the GUI.
	GLOBAL main_gui is gui(530,230).
	SET main_gui:X TO 200.
	SET main_gui:Y TO 750.
	SET main_gui:STYLe:WIDTH TO 530.
	SET main_gui:STYLe:HEIGHT TO entry_gui_height.
	SET main_gui:STYLE:ALIGN TO "center".

	set main_gui:skin:LABEL:TEXTCOLOR to guitextgreen.


	// Add widgets to the GUI
	GLOBAL title_box is main_gui:addhbox().
	set title_box:style:height to 35. 
	set title_box:style:margin:top to 0.


	GLOBAL text0 IS title_box:ADDLABEL("<b><size=20>SHUTTLE ENTRY AND APPROACH ASSISTANT</size></b>").
	SET text0:STYLE:ALIGN TO "center".

	GLOBAL minb IS  title_box:ADDBUTTON("-").
	set minb:style:margin:h to 7.
	set minb:style:margin:v to 7.
	set minb:style:width to 20.
	set minb:style:height to 20.
	set minb:TOGGLE to TRUE.
	function minimizecheck {
		PARAMETER pressed.
		
		IF pressed {
			main_gui:SHOWONLY(title_box).
			SET main_gui:STYLe:HEIGHT TO 50.
		} ELSE {
			SET main_gui:STYLe:HEIGHT TO entry_gui_height.
			for w in main_gui:WIDGETS {
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
	  SET quitflag TO TRUE.
	}
	SET quitb:ONCLICK TO quitcheck@.

	
	main_gui:addspacing(7).



	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_gui:ADDHLAYOUT().
	SET popup_box:STYLE:ALIGN TO "center".	

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
		
	popup_box:addspacing(20).


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
	
	popup_box:addspacing(20).
	
	

	GLOBAL select_sidebox IS popup_box:ADDHLAYOUT().
	SET select_sidebox:STYLE:WIDTH TO 175.
	//SET select_sidebox:STYLE:ALIGN TO "right".
	GLOBAL select_side_text IS select_sidebox:ADDLABEL("<size=15>HAC Position : </size>").
	GLOBAL select_side IS select_sidebox:addpopupmenu().
	SET select_side:STYLE:WIDTH TO 60.
	SET select_side:STYLE:HEIGHT TO 25.
	SET select_side:STYLE:ALIGN TO "center".
	select_side:addoption("Right" ).
	select_side:addoption("Left" ).
	
	SET select_side:ONCHANGE to { 
		PARAMETER side.	
		SET tgtrwy["hac_side"] TO side.
		define_hac(SHIP:GEOPOSITION,tgtrwy,vehicle_params).
	}.
	SET select_rwy:ONCHANGE to { 
		PARAMETER rwy.	
		
		LOCAL newsite IS ldgsiteslex[select_tgt:VALUE].
		
		SET tgtrwy["heading"] TO newsite["rwys"][rwy]["heading"].
		SET tgtrwy["td_pt"] TO newsite["rwys"][rwy]["td_pt"].
		
		select_opposite_hac().
		
		define_hac(SHIP:GEOPOSITION,tgtrwy,vehicle_params).
	}.
	SET select_tgt:ONCHANGE to {
		PARAMETER lex_key.
		
		LOCAL newsite IS ldgsiteslex[lex_key].
		
		SET tgtrwy TO refresh_runway_lex(newsite).
		
		select_rwy:CLEAR.
		FOR rwy IN newsite["rwys"]:KEYS {
			select_rwy:addoption(rwy).
		}	
		
		select_random_rwy().
		
		SET tgtrwy["heading"] TO newsite["rwys"][select_rwy:VALUE]["heading"].
		SET tgtrwy["td_pt"] TO newsite["rwys"][select_rwy:VALUE]["td_pt"].
		SET tgtrwy["hac_side"] TO select_side:VALUE.
		define_hac(SHIP:GEOPOSITION,tgtrwy,vehicle_params).
		
		reset_hud_bg_brightness().
	}.	
	
	
	GLOBAL toggles_box IS main_gui:ADDHLAYOUT().
	SET toggles_box:STYLE:WIDTH TO 300.
	toggles_box:addspacing(55).	
	SET toggles_box:STYLE:ALIGN TO "center".
	
	GLOBAL logb IS  toggles_box:ADDCHECKBOX("Log Data",false).
	toggles_box:addspacing(20).	
	
	GLOBAL fbwb IS  toggles_box:ADDCHECKBOX("Fly-by-wire",false).
	SET fbwb:ONTOGGLE TO toggle_fbw@.
	toggles_box:addspacing(20).	
	
	GLOBAL flptrm IS  toggles_box:ADDCHECKBOX("Auto Flaps",false).
	toggles_box:addspacing(20).	
	
	//SET flptrm:ONTOGGLE TO {
	//	parameter b. 
	//	IF NOT b {
	//		null_flap_deflection().
	//	}
	//
	//}.
	
	GLOBAL arbkb IS  toggles_box:ADDCHECKBOX("Auto Airbk",false).


	main_gui:SHOW().
}


//sets the runway choice between the availle options to a random one
//to simulate daily wind conditions & introduce variability
FUNCTION select_random_rwy {
	LOCAL rwynum IS select_rwy:OPTIONS:LENGTH.
	SET select_rwy:INDEX TO FLOOR(rwynum*RANDOM()).
	
	select_opposite_hac().
	WAIT 0.
}



//given current runway choice selects the overhead HAC option 
FUNCTION select_opposite_hac {

	LOCAL newsite IS ldgsiteslex[select_tgt:VALUE].
	
	LOCAL rwyhdg IS newsite["rwys"][select_rwy:VALUE]["heading"].
	
	LOCAL shiprwybng IS bearingg(SHIP:GEOPOSITION,newsite["position"]).
	
	LOCAL rel_hdg IS unfixangle(shiprwybng - rwyhdg).
	
	//print "rwyhdg : " + rwyhdg at (0,20).
	//print "shiprwybng : " + shiprwybng at (0,21).
	//print "relativehdg : " + rel_hdg at (0,22).
	
	//this assumes that option 0 is "right" and option 1 is "left".
	IF (rel_hdg < 0) {
		SET select_side:INDEX TO 0.
	} ELSE {
		SET select_side:INDEX TO 1.
	}


}

FUNCTION toggle_fbw {
	PARAMETER enabled_.
	
	//direction P_att must be defined
	if (enabled_) {
		LOCK STEERING TO P_att.
	} ELSE {
		UNLOCK STEERING.
	}
}

FUNCTION close_global_GUI {
	main_gui:HIDE().
	IF (DEFINED(hud_gui)) {
		hud_gui:HIDE.
		hud_gui:DISPOSE.
		
	}
}

FUNCTION close_all_GUIs{
	CLEARGUIS().
}

//interface functions between the main loops and the GUI

//generic GUI 

FUNCTION is_fbw {
	RETURN fbwb:PRESSED.
}

FUNCTION is_autoairbk {
	RETURN arbkb:PRESSED.
}

FUNCTION is_log {
	RETURN logb:PRESSED.
}





					// HUD SPECIFIC FUNCTIONS
					
					
FUNCTION make_hud_gui {
	IF (DEFINED hud_gui AND hud_gui:visible) {
		RETURN.
	}

	GLOBAL hud_gui is gui(430,320).
	SET hud_gui:X TO 700.
	SET hud_gui:Y TO 150.
	SET hud_gui:STYLe:WIDTH TO 450.
	SET hud_gui:STYLe:HEIGHT TO 320.
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
	
	
	GLOBAL altbox IS spdaltbox:ADDHLAYOUT().
	SET altbox:STYLe:WIDTH TO 70.
	SET altbox:STYLe:HEIGHT TO 30.
	SET altbox:STYLe:MARGIN:left TO 230.
	SET altbox:STYLe:MARGIN:top TO 87.
	GLOBAL alt_text IS altbox:ADDLABEL("<size=18>100.5</size>").
	SET alt_text:STYLE:ALIGN TO "Left".
	
	
	
	
	
	GLOBAL hudrll IS overlaiddata:ADDVLAYOUT().
	SET hudrll:STYLe:WIDTH TO 20.
	SET hudrll:STYLe:HEIGHT TO 20.
	SET hudrll:STYLE:MARGIN:left TO 176.
	SET hudrll:STYLE:MARGIN:top TO 49.
	GLOBAL hudrll_text IS hudrll:ADDLABEL("rll").
	SET hudrll_text:STYLe:WIDTH TO 30.
	SET hudrll_text:STYLE:ALIGN TO "Center".
	
	GLOBAL hudpch IS overlaiddata:ADDVLAYOUT().
	SET hudpch:STYLe:WIDTH TO 20.
	SET hudpch:STYLe:HEIGHT TO 20.
	SET hudpch:STYLE:MARGIN:top TO 4.
	SET hudpch:STYLE:MARGIN:left TO 213.
	GLOBAL hudpch_text IS hudpch:ADDLABEL("pch").
	SET hudpch_text:STYLe:WIDTH TO 30.
	SET hudpch_text:STYLE:ALIGN TO "Left".


	GLOBAL hud_nz IS overlaiddata:ADDHLAYOUT().
	SET hud_nz:STYLe:WIDTH TO 70.
	SET hud_nz:STYLe:HEIGHT TO 30.
	SET hud_nz:STYLE:MARGIN:top TO 13.
	SET hud_nz:STYLE:MARGIN:left TO 75.
	GLOBAL nz_text IS hud_nz:ADDLABEL("").
	SET nz_text:STYLe:WIDTH TO 100.
	SET nz_text:STYLE:ALIGN TO "Right".

	GLOBAL hud_main IS hud:ADDHLAYOUT().
	SET hud_main:STYLe:WIDTH TO 430.
	SET hud_main:STYLe:HEIGHT TO 240.
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
	SET bottom_box:STYLe:WIDTH TO 400.
	//SET bottom_box:STYLE:ALIGN TO "left".

	bottom_box:addspacing(75).

	GLOBAL bottom_txtbox IS bottom_box:ADDHLAYOUT().
	SET bottom_txtbox:STYLe:WIDTH TO 185.
	GLOBAL mode_txt IS bottom_txtbox:ADDLABEL("<size=20>    </size>").
	SET mode_txt:STYLE:ALIGN TO "Left".

	GLOBAL mode_dist_text IS  bottom_txtbox:ADDLABEL( "<size=18>"+"</size>" ).

	bottom_box:addspacing(0).

	GLOBAL spdbk_slider_box IS bottom_box:ADDHLAYOUT().
	GLOBAL spdbk_slider is spdbk_slider_box:addhslider(0,0,1).
	SET spdbk_slider:style:vstretch to false.
	SET spdbk_slider:style:hstretch to false.
	SET spdbk_slider:STYLE:WIDTH TO 110.
	SET spdbk_slider:STYLE:HEIGHT TO 20.

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


//called at mode5 transition
//removes the load indicator  and attitude angles
//also changes the marker
FUNCTION hud_declutter5_gui {
	
	nz_text:HIDE().
	hudrll_text:HIDE().
	hudpch_text:HIDE().
	SET  pointbox:style:BG to "Shuttle_entrysim/src/gui_images/bg_marker_round.png".

}

//called at 1200 m
//removes trim indicator, heading, vertical speed and attitude angles
//also modes altitude and speed indicators
FUNCTION hud_declutter6_gui {
	
	flaptrim_slider:HIDE().
	vspd_slider:HIDE().
	hdg_text:HIDE().
	mode_dist_text:HIDE().
	
	SET spdbox:STYLe:MARGIN:left TO 80.
	SET altbox:STYLe:MARGIN:left TO 88.
}

//called at mode7 transition
//hides the pipper 
FUNCTION hud_declutter7_gui {
	
	SET diamond:IMAGE TO "Shuttle_entrysim/src/gui_images/diamond_empty.png".

}


FUNCTION update_hud_gui {
	PARAMETER mode_str.
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

	SET mode_txt:text TO "<size=20>" + mode_str + "</size>".

	// set the pipper to an intermediate position between the desired and the current position so the transition is smoother
	LOCAL smooth_fac IS 0.3.
	
	//for debug only
	//SET pipper_pos TO diamond_deviation_debug().
	
	LOCAL pipper_pos_cur IS LIST(diamond:STYLE:margin:h, diamond:STYLE:margin:v).
	
	SET diamond:STYLE:margin:h TO pipper_pos_cur[0] + smooth_fac*(pipper_pos[0] - pipper_pos_cur[0]).
	SET diamond:STYLE:margin:v TO pipper_pos_cur[1] + smooth_fac*(pipper_pos[1] - pipper_pos_cur[1]).
	
	SET vspd_slider:VALUE TO CLAMP(-SHIP:VERTICALSPEED,vspd_slider:MIN,vspd_slider:MAX).
	
	SET hdg_text:text TO "<size=18>" + hdgval + "</size>".
	
	SET spd_text:text TO "<size=18>" + spd + "</size>".
	SET alt_text:text TO "<size=18>" + altt + "</size>".
	
	SET nz_text:text TO "<size=18>" + ROUND(cur_nz,1) + "G</size>".
	
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




					//ENTRY SPECIFIC GUI FUNCTIONS


FUNCTION make_entry_GUI {

					   
	GLOBAL all_box IS main_gui:ADDHLAYOUT().
	SET all_box:STYLE:WIDTH TO 650.
	SET all_box:STYLE:HEIGHT TO 200.


	GLOBAL leftbox IS all_box:ADDVLAYOUT().
	SET leftbox:STYLE:WIDTH TO 230.
	all_box:addspacing(30).	
	
	//GLOBAL switchtxtbox IS leftbox:ADDVLAYOUT().
	//SET switchbox:STYLE:ALIGN TO "center".
	//GLOBAL switchtext2 IS switchtxtbox:ADDLABEL("First disable Auto Steer and Guidance").
	//SET switchtext2:style:padding:h tO -70.
	//SET switchtext2:STYLE:ALIGN TO "center".

	//leftbox:addspacing(5).	
	GLOBAL switchbtbox IS leftbox:ADDHLAYOUT().
	
	SET switchbtbox:STYLE:ALIGN TO "center".
	GLOBAL exitb IS  switchbtbox:ADDBUTTON("<Size=16>  Switch to Approach         </Size><Size=10>First disable Auto Steer and Guidance</Size>").
	set exitb:style:wordwrap to true.
	set exitb:style:width to 220.
	set exitb:style:height to 75.
	SET exitb:style:margin:left to 15.
	
	function exitcheck {
		IF (NOT sasb:PRESSED) AND (NOT guidb:PRESSED) { 
			SET stop_entry_flag TO TRUE.
		}
	}
	SET exitb:ONCLICK TO exitcheck@.
	
	


	GLOBAL rightbox IS all_box:ADDVLAYOUT().
	SET rightbox:STYLE:WIDTH TO 240.
	SET rightbox:STYLE:ALIGN TO "center".
	
	
	GLOBAL sasbox IS rightbox:ADDHLAYOUT().
	SET sasbox:STYLE:HEIGHT TO 30.
	SET sasbox:STYLE:ALIGN TO "center".
	
	GLOBAL sasb IS  sasbox:ADDCHECKBOX("Auto Steering",false).
	
	sasbox:addspacing(20).

	GLOBAL guidb IS  sasbox:ADDCHECKBOX("Guidance",false).
	SET guidb:ONTOGGLE TO {
		PARAMETER val.
		SET reset_entry_flag TO TRUE.
	}.
	
	GLOBAL pitchngains IS rightbox:ADDHLAYOUT().
	SET pitchngains:STYLE:ALIGN TO "Center".

	//button to override pitch profile

	GLOBAL pchprof_but IS  pitchngains:ADDBUTTON("<size=13>Override               Pitch Profile</size>").
	SET pchprof_but:STYLE:WIDTH TO 115.
	SET pchprof_but:STYLE:HEIGHT TO 45.
	SET pchprof_but:STYLE:ALIGN TO "Center".
	set pchprof_but:style:wordwrap to true.
	SET pchprof_but:ONCLICK TO profgui@.

	//button to override controller gains
	GLOBAL gains_but IS  pitchngains:ADDBUTTON("<size=13>Override Controller Gains</size>").
	SET gains_but:STYLE:WIDTH TO 115.
	SET gains_but:STYLE:HEIGHT TO 45.
	SET gains_but:STYLE:ALIGN TO "Center".
	set gains_but:style:wordwrap to true.
	SET gains_but:ONCLICK TO gainsgui@.
	
	
	make_hud_gui().
	
	
	
	
	SET vspd_slider:MIN TO -200.
	SET vspd_slider:MAX TO +200.


}

function profgui {
			GLOBAL prof_gui is gui(145,200).
			SET prof_gui:X TO main_gui:X + + main_gui:STYLE:WIDTH.
			SET prof_gui:Y TO main_gui:Y.
			GLOBAL proftext IS prof_gui:ADDLABEL("<size=18>Pitch Profile</size>").
			SET proftext:STYLE:ALIGN TO "center".
			
			
			GLOBAL profsegs_box IS prof_gui:ADDVLAYOUT().
			SET profsegs_box:STYLE:ALIGN TO "center".
			SET profsegs_box:STYLE:WIDTH TO 145.
			
			GLOBAL profseg_boxes_list Is LIST().
			
			FROM {local k is 0.} UNTIL k >= pitchprof_segments:LENGTH STEP {set k to k+1.} DO {
			
				LOCAL s IS pitchprof_segments[k].
			
				LOCAL newsegbox IS profsegs_box:addhlayout().
				LOCAL newsegveltext IS newsegbox:addtextfield(s[0]:tostring).
				set newsegveltext:style:width to 65.
				set newsegveltext:style:height to 18.
				LOCAL newsegpcgtext IS newsegbox:addtextfield(s[1]:tostring).
				set newsegpcgtext:style:width to 65.
				set newsegpcgtext:style:height to 18.
				
				
				set newsegveltext:onconfirm to { 
					parameter val.
					
					set val to val:tonumber(0).
					if val = 0 {RETURN.}
					
					SET s[0] TO val.
					
				}.
				
				set newsegpcgtext:onconfirm to { 
					parameter val.
					
					set val to val:tonumber(0).
					if val = 0 {RETURN.}
					
					SET s[1] TO val.
					
				}.
				
				profseg_boxes_list:ADD(newsegbox).
				
			}
			
			
			GLOBAL prof_close IS  prof_gui:ADDBUTTON("<size=16>Close</size>").
			SET prof_close:STYLE:WIDTH TO 50.
			SET prof_close:STYLE:ALIGN TO "center".
			//SET quitb:style:width TO 80.
			function profclosecheck {
				log_new_pitchprof(pitchprof_log_path).
				prof_gui:HIDE().
			}
			SET prof_close:ONCLICK TO profclosecheck@.
			prof_gui:SHOW().
	}

function gainsgui {
	  //create the gains gui
		GLOBAL gains_gui is gui(180,200).
		SET gains_gui:X TO main_gui:X + main_gui:STYLE:WIDTH + 200.
		SET gains_gui:Y TO main_gui:Y - 250.
		GLOBAL gainstext IS gains_gui:ADDLABEL("<size=18>Controller Gains</size>").
		SET gainstext:STYLE:ALIGN TO "center".
		
		GLOBAL gainsbox IS gains_gui:ADDVLAYOUT().
		SET gainsbox:STYLE:ALIGN TO "center".
		SET gainsbox:STYLE:WIDTH TO 180.
		GLOBAL p_gain IS gainsbox:addhlayout().
		GLOBAL p_gain_text IS p_gain:addlabel("Range P Gain: ").
		GLOBAL Kp_box is p_gain:addtextfield(gains["rangeKP"]:tostring).
		set Kp_box:style:width to 65.
		set Kp_box:style:height to 18.
		GLOBAL d_gain IS gainsbox:addhlayout().
		GLOBAL d_gain_text IS d_gain:addlabel("Range D Gain: ").
		GLOBAL Kd_box is d_gain:addtextfield(gains["rangeKD"]:tostring).
		set Kd_box:style:width to 65.
		set Kd_box:style:height to 18.
		GLOBAL hdot_gain IS gainsbox:addhlayout().
		GLOBAL hdot_gain_text IS hdot_gain:addlabel("Roll hdot Gain: ").
		GLOBAL Khdot_box is hdot_gain:addtextfield(gains["Khdot"]:tostring).
		set Khdot_box:style:width to 65.
		set Khdot_box:style:height to 18.
		GLOBAL rollramp_gain IS gainsbox:addhlayout().
		GLOBAL rollramp_gain_text IS rollramp_gain:addlabel("Roll ramp Gain: ").
		GLOBAL rollramp_box is rollramp_gain:addtextfield(gains["Roll_ramp"]:tostring).
		set rollramp_box:style:width to 65.
		set rollramp_box:style:height to 18.
		GLOBAL pchmod_gain IS gainsbox:addhlayout().
		GLOBAL pchmod_gain_text IS pchmod_gain:addlabel("Pitch mod Gain: ").
		GLOBAL pchmod_box is pchmod_gain:addtextfield(gains["pchmod"]:tostring).
		set pchmod_box:style:width to 65.
		set pchmod_box:style:height to 18.
		GLOBAL taem_p_gain IS gainsbox:addhlayout().
		GLOBAL taem_p_gain_text IS taem_p_gain:addlabel("TAEM P Gain: ").
		GLOBAL taem_Kp_box is taem_p_gain:addtextfield(gains["taemKP"]:tostring).
		set taem_Kp_box:style:width to 65.
		set taem_Kp_box:style:height to 18.
		GLOBAL taem_d_gain IS gainsbox:addhlayout().
		GLOBAL taem_d_gain_text IS taem_d_gain:addlabel("TAEM D Gain: ").
		GLOBAL taem_Kd_box is taem_d_gain:addtextfield(gains["taemKD"]:tostring).
		set taem_Kd_box:style:width to 65.
		set taem_Kd_box:style:height to 18.
		
		GLOBAL strmgr_gain IS gainsbox:addhlayout().
		GLOBAL strmgr_gain_text IS strmgr_gain:addlabel("Stopping T: ").
		GLOBAL strmgr_box is strmgr_gain:addtextfield(gains["strmgr"]:tostring).
		set strmgr_box:style:width to 65.
		set strmgr_box:style:height to 18.
		GLOBAL pitchd_gain IS gainsbox:addhlayout().
		GLOBAL pitchd_gain_text IS pitchd_gain:addlabel("Pitch D Gain: ").
		GLOBAL pitchd_gain_box is pitchd_gain:addtextfield(gains["pitchKD"]:tostring).
		set pitchd_gain_box:style:width to 65.
		set pitchd_gain_box:style:height to 18.
		GLOBAL yawd_gain IS gainsbox:addhlayout().
		GLOBAL yawd_gain_text IS yawd_gain:addlabel("Yaw D Gain: ").
		GLOBAL yawd_gain_box is yawd_gain:addtextfield(gains["yawKD"]:tostring).
		set yawd_gain_box:style:width to 65.
		set yawd_gain_box:style:height to 18.
		GLOBAL rolld_gain IS gainsbox:addhlayout().
		GLOBAL rolld_gain_text IS rolld_gain:addlabel("Roll D Gain: ").
		GLOBAL rolld_gain_box is rolld_gain:addtextfield(gains["rollKD"]:tostring).
		set rolld_gain_box:style:width to 60.
		set rolld_gain_box:style:height to 18.
	
		set Kp_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["rangeKP"]).
			if val < 0 set val to 0.
			set gains["rangeKP"] to val.
		}.
		set Kd_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["rangeKD"]).
			if val < 0 set val to 0.
			set gains["rangeKD"] to val.
		}.
		set Khdot_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["Khdot"]).
			set gains["Khdot"] to val.
		}.
		set rollramp_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["Roll_ramp"]).
			if val < 0 set val to 0.
			set gains["Roll_ramp"] to val.
		}.
		set pchmod_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["pchmod"]).
			if val < 0 set val to 0.
			set gains["pchmod"] to val.
		}.
		set taem_Kp_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["taemKP"]).
			if val < 0 set val to 0.
			set gains["taemKP"] to val.
		}.
		set taem_Kd_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["taemKD"]).
			if val < 0 set val to 0.
			set gains["taemKD"] to val.
		}.
		
		set strmgr_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["strmgr"]).
			if val < 0 set val to 0.
			set gains["strmgr"] to val.
			SET STEERINGMANAGER:MAXSTOPPINGTIME TO val.
		}.
		
		set pitchd_gain_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["pitchKD"]).
			if val < 0 set val to 0.
			set gains["pitchKD"] to val.
			SET STEERINGMANAGER:PITCHPID:KD TO val.
		}.
		set yawd_gain_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["yawKD"]).
			if val < 0 set val to 0.
			set gains["yawKD"] to val.
			SET STEERINGMANAGER:YAWPID:KD TO val.
		}.
		set rolld_gain_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["rollKD"]).
			if val < 0 set val to 0.
			set gains["rollKD"] to val.
			SET STEERINGMANAGER:ROLLPID:KD TO val.
		}.
		
		
		GLOBAL gains_close IS  gains_gui:ADDBUTTON("<size=16>Close</size>").
		SET gains_close:STYLE:WIDTH TO 50.
		SET gains_close:STYLE:ALIGN TO "center".
		//SET quitb:style:width TO 80.
		function gainsclosecheck {
			log_gains(gains,gains_log_path).
			gains_gui:HIDE().
		}
		SET gains_close:ONCLICK TO gainsclosecheck@.
		gains_gui:SHOW().
	}


FUNCTION is_guidance {
	RETURN guidb:PRESSED.
}

FUNCTION is_auto_steering {
	RETURN sasb:PRESSED.
}


//FUNCTION get_roll_slider {
//	RETURN slider1:VALUE.
//}
//
//FUNCTION get_pitch_slider {
//	RETURN slider2:VALUE.
//}



//scales the deltas by the right amount for display
//accounting for the diamond window width
FUNCTION diamond_deviation_entry {
	PARAMETER deltas.
	
	LOCAL hmargin IS diamond_central_x.
	LOCAL vmargin IS diamond_central_y.
	
	LOCAL vdelta IS deltas[1].
	LOCAL hdelta IS deltas[0].
	
	//the vertical multiplier needs to be negative to simulate an ils needle.
	LOCAL vmult iS -0.07.
	
	LOCAL hmult iS 0.03.
	
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


FUNCTION update_entry_GUI {
	PARAMETER mode.
	PARAMETER pipper_deltas.
	PARAMETER az_err.
	PARAMETER tgt_range.
	PARAMETER spdbk_val.
	PARAMETER flapval.
	PARAMETER cur_nz.
	
	LOCAL mode_str IS "".
	IF is_auto_steering() {
		SET mode_str TO "AUTO".
	} ELSE {
		SET mode_str TO "CSS ".
	}
	
	update_hud_gui(
		mode_str,
		diamond_deviation_entry(pipper_deltas),
		altitude_format(mode),
		distance_format(tgt_range,mode),
		ROUND(az_err,1),
		"M" + ROUND(ADDONS:FAR:MACH,1),
		get_pitch_prograde(),
		get_roll_prograde(),
		spdbk_val,
		flapval,
		cur_nz
	).


}



//relatively few modifications to entry gui
FUNCTION make_TAEM_GUI {
	CLEARSCREEN.	//for good measure
	//freeze the target site selection 
	SET select_tgt:ENABLED to FALSE.

}



								//APPROACH GUI FUNCTIONS 
								

FUNCTION clean_entry_gui {

	//moved the clean entry gui commands here
	SET leftbox:STYLE:HEIGHT TO 0.
	SET rightbox:STYLE:HEIGHT TO 0.
	leftbox:DISPOSE().
	rightbox:DISPOSE().
	all_box:DISPOSE().
	
}								
								

FUNCTION make_apch_GUI {
	
	CLEARSCREEN.
	
	//freeze the target site selection 
	SET select_tgt:ENABLED to FALSE.
	
	//set manual flaps 
	SET flptrm:PRESSED TO FALSE.
	
	//set auto speedbrakes
	SET arbkb:PRESSED TO TRUE.
		
	SET entry_gui_height TO 130.
	SET main_gui:STYLe:HEIGHT TO entry_gui_height.
	
	make_hud_gui().
	
	
	SET vspd_slider:MIN TO -40.
	SET vspd_slider:MAX TO +40.
	
	
	
	//gui-related actions for mode switching (in case we got here manually)
	WHEN mode=4 THEN {
		SET select_rwy:ENABLED to FALSE.
		SET select_side:ENABLED to FALSE.
		
		WHEN mode=5 THEN {
			hud_declutter5_gui().
			
			WHEN ALT:RADAR < 1200 THEN  {
				hud_declutter6_gui().
				
				WHEN mode=6 THEN {
					
				
					WHEN mode=7 THEN {
						hud_declutter7_gui().
					}
				}
			
			}
		
			
		}
	}

}



//scales the deltas by the right amount for display
//accounting for the diamond window width
FUNCTION diamond_deviation_apch {

	PARAMETER deltas.
	PARAMETER mode.
	
	LOCAL hmargin IS diamond_central_x.
	LOCAL vmargin IS diamond_central_y.
	
	LOCAL vdelta IS deltas[1].
	LOCAL hdelta IS deltas[0].
	
	//the vertical multiplier needs to be negative to simulate an ils needle.
	LOCAL vmult iS -1/320.
	
	LOCAL hmult iS 0.04.
	IF mode=4 {
		SET hmult TO 0.02.
	}
	IF mode>=5 {
		SET hmult TO 0.008.
		SET vmult TO -1/300.
	}
	
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



FUNCTION update_apch_GUI {
	PARAMETER mode.
	PARAMETER pipper_deltas.
	PARAMETEr modedist.
	PARAMETER spdbk_val.
	PARAMETER flapval.
	PARAMETER cur_nz.
	
	LOCAL mode_str IS "".
	IF (mode=3) {
		SET mode_str TO "ACQ ".
	} ELSE IF (mode=4) {
		SET mode_str TO "HDG ".
	} ELSE IF (mode=5) {
		SET mode_str TO "OGS ".
	} ELSE IF (mode=6) {
		SET mode_str TO "FLARE".
	} ELSE IF (mode=7) {
		SET mode_str TO "FNLFL".
	} ELSE IF (mode=8) {
		SET mode_str TO "ROLLOUT".
	}
	
	update_hud_gui(
		mode_str,
		diamond_deviation_apch(pipper_deltas, mode),
		altitude_format(mode),
		distance_format(modedist,mode),
		ROUND(compass_for(SHIP:SRFPROGRADE:VECTOR,SHIP:GEOPOSITION),0),
		ROUND(ADDONS:FAR:IAS,0),
		get_pitch_prograde(),
		get_roll_lvlh(),
		spdbk_val,
		flapval,
		cur_nz
	).

}


FUNCTION altitude_format {
	PARAMETER mode.
	
	//always use altitude above landing site 
	LOCAL altt IS runway_alt(SHIP:ALTITUDE).
	
	//also calculate in km 
	LOCAL alttkm IS altt/1000.
	
	//accurate to 0.5 km
	IF (mode <= 4) {
		LOCAL altout IS FLOOR(alttkm).
		LOCAL dec IS alttkm - altout.
		IF (dec > 0.5) {
			SET altout TO altout + 0.5.
		}
		RETURN altout.
	} ELSE {
		//show full digits, floored to nearest ten or hundred depending
		LOCAL altout IS altt.
		//accurate to 100m
		IF (altt >= 1000 ) {
			SET altout TO FLOOR(altt/100)*100.
		//accurate to 10m
		} ELSE IF (altt >= 100) {
			SET altout TO FLOOR(altt/10)*10.
		} ELSE {
			SET altout TO FLOOR(altout).
		}
		RETURN altout.
	}
}


FUNCTION distance_format {
	PARAMETER dist.	//expected in km
	PARAMETER mode.
	
	IF (mode>=3) {
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



