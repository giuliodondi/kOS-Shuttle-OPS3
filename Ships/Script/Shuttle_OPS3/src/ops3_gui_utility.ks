GLOBAL guitextgreen IS RGB(20/255,255/255,21/255).
global trajbgblack IS RGB(5/255,8/255,8/255).

GLOBAL main_gui_width IS 550.
GLOBAL main_gui_height IS 510.

FUNCTION make_main_GUI {
	

	//create the GUI.
	GLOBAL main_gui is gui(main_gui_width,main_gui_height).
	SET main_gui:X TO 200.
	SET main_gui:Y TO 670.
	SET main_gui:STYLe:WIDTH TO main_gui_width.
	SET main_gui:STYLe:HEIGHT TO main_gui_height.
	SET main_gui:STYLE:ALIGN TO "center".
	SET main_gui:STYLE:HSTRETCH  TO TRUE.

	set main_gui:skin:LABEL:TEXTCOLOR to guitextgreen.


	// Add widgets to the GUI
	GLOBAL title_box is main_gui:addhbox().
	set title_box:style:height to 35. 
	set title_box:style:margin:top to 0.


	GLOBAL text0 IS title_box:ADDLABEL("<b><size=20>SPACE SHUTTLE OPS3 ENTRY GUIDANCE</size></b>").
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
			SET main_gui:STYLe:HEIGHT TO main_gui_height.
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
	  SET quit_program TO TRUE.
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
	
	//SET select_side:ONCHANGE to { 
	//	PARAMETER side.	
	//	SET tgtrwy["hac_side"] TO side.
	//	define_hac(SHIP:GEOPOSITION,tgtrwy,vehicle_params).
	//}.
	//SET select_rwy:ONCHANGE to { 
	//	PARAMETER rwy.	
	//	
	//	LOCAL newsite IS ldgsiteslex[select_tgt:VALUE].
	//	
	//	SET tgtrwy["heading"] TO newsite["rwys"][rwy]["heading"].
	//	SET tgtrwy["td_pt"] TO newsite["rwys"][rwy]["td_pt"].
	//	
	//	select_opposite_hac().
	//	
	//	define_hac(SHIP:GEOPOSITION,tgtrwy,vehicle_params).
	//}.
	//SET select_tgt:ONCHANGE to {
	//	PARAMETER lex_key.
	//	
	//	LOCAL newsite IS ldgsiteslex[lex_key].
	//	
	//	SET tgtrwy TO refresh_runway_lex(newsite).
	//	
	//	select_rwy:CLEAR.
	//	FOR rwy IN newsite["rwys"]:KEYS {
	//		select_rwy:addoption(rwy).
	//	}	
	//	
	//	select_random_rwy().
	//	
	//	SET tgtrwy["heading"] TO newsite["rwys"][select_rwy:VALUE]["heading"].
	//	SET tgtrwy["td_pt"] TO newsite["rwys"][select_rwy:VALUE]["td_pt"].
	//	SET tgtrwy["hac_side"] TO select_side:VALUE.
	//	define_hac(SHIP:GEOPOSITION,tgtrwy,vehicle_params).
	//	
	//	reset_hud_bg_brightness().
	//}.	
	
	
	GLOBAL toggles_box IS main_gui:ADDHLAYOUT().
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


	main_gui:SHOW().
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




FUNCTION make_entry_traj_GUI {

	GLOBAL traj_disp_counter IS 1.				   
	GLOBAL traj_disp_counter_p IS traj_disp_counter.				   
	
	GLOBAL traj_disp IS main_gui:addvlayout().
	SET traj_disp:STYLE:WIDTH TO main_gui_width - 22.
	SET traj_disp:STYLE:HEIGHT TO 380.
	SET traj_disp:STYLE:ALIGN TO "center".
	
	set traj_disp:style:BG to "Shuttle_OPS3/src/gui_images/entry_traj_bg.png".
	
	set main_gui:skin:horizontalslider:BG to "Shuttle_OPS3/src/gui_images/brakeslider.png".
	set main_gui:skin:horizontalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/hslider_thumb.png".
	set main_gui:skin:horizontalsliderthumb:HEIGHT to 17.
	set main_gui:skin:horizontalsliderthumb:WIDTH to 20.
	set main_gui:skin:verticalslider:BG to "Shuttle_OPS3/src/gui_images/vspdslider2.png".
	set main_gui:skin:verticalsliderthumb:BG to "Shuttle_OPS3/src/gui_images/vslider_thumb.png".
	set main_gui:skin:verticalsliderthumb:HEIGHT to 20.
	set main_gui:skin:verticalsliderthumb:WIDTH to 17.
	
	GLOBAL traj_disp_titlebox IS traj_disp:ADDHLAYOUT().
	SET traj_disp_titlebox:STYLe:WIDTH TO traj_disp:STYLE:WIDTH.
	SET traj_disp_titlebox:STYLe:HEIGHT TO 20.
	GLOBAL traj_disp_title IS traj_disp_titlebox:ADDLABEL("").
	SET traj_disp_title:STYLE:ALIGN TO "center".
	
	GLOBAL traj_disp_overlaiddata IS traj_disp:ADDVLAYOUT().
	SET traj_disp_overlaiddata:STYLE:ALIGN TO "Center".
	SET traj_disp_overlaiddata:STYLe:WIDTH TO traj_disp:STYLE:WIDTH.
	SET traj_disp_overlaiddata:STYLe:HEIGHT TO 1.
	
	GLOBAL traj_disp_mainbox IS traj_disp:ADDHLAYOUT().
	SET traj_disp_mainbox:STYLE:ALIGN TO "Center".
	SET traj_disp_mainbox:STYLe:WIDTH TO traj_disp:STYLE:WIDTH.
	SET traj_disp_mainbox:STYLe:HEIGHT TO traj_disp:STYLE:HEIGHT - 22.
	
	
	
	
	
	GLOBAL traj_disp_leftdatabox IS traj_disp_overlaiddata:ADDVLAYOUT().
	SET traj_disp_leftdatabox:STYLE:ALIGN TO "right".
	SET traj_disp_leftdatabox:STYLE:WIDTH TO 100.
    SET traj_disp_leftdatabox:STYLE:HEIGHT TO 115.
	set traj_disp_leftdatabox:style:margin:h to 20.
	set traj_disp_leftdatabox:style:margin:v to 10.
	
	GLOBAL trajleftdata1 IS traj_disp_leftdatabox:ADDLABEL("data1 : xxxxxx").
	GLOBAL trajleftdata2 IS traj_disp_leftdatabox:ADDLABEL("data2 : ").
	GLOBAL trajleftdata3 IS traj_disp_leftdatabox:ADDLABEL("data3 : ").
	GLOBAL trajleftdata4 IS traj_disp_leftdatabox:ADDLABEL("data4 : ").
	GLOBAL trajleftdata5 IS traj_disp_leftdatabox:ADDLABEL("data5 : ").
	
	GLOBAL traj_disp_rightdatabox IS traj_disp_overlaiddata:ADDVLAYOUT().
	SET traj_disp_rightdatabox:STYLE:ALIGN TO "right".
	SET traj_disp_rightdatabox:STYLE:WIDTH TO 100.
    SET traj_disp_rightdatabox:STYLE:HEIGHT TO 115.
	set traj_disp_rightdatabox:style:margin:h to 390.
	set traj_disp_rightdatabox:style:margin:v to 90.
	
	GLOBAL trajrightdata1 IS traj_disp_rightdatabox:ADDLABEL("data6 : xxxxxx").
	GLOBAL trajrightdata2 IS traj_disp_rightdatabox:ADDLABEL("data7 : ").
	GLOBAL trajrightdata3 IS traj_disp_rightdatabox:ADDLABEL("data8 : ").
	GLOBAL trajrightdata4 IS traj_disp_rightdatabox:ADDLABEL("data9 : ").
	GLOBAL trajrightdata5 IS traj_disp_rightdatabox:ADDLABEL("data10 : ").
	
	GLOBAL traj_disp_orbiter IS traj_disp_mainbox:ADDLABEL().
	SET traj_disp_orbiter:IMAGE TO "Shuttle_OPS3/src/gui_images/orbiter_bug.png".
	SET traj_disp_orbiter:STYLe:WIDTH TO 22.
	
	reset_traj_disp().
}

function reset_traj_disp {
	set_traj_disp_title().
	set_traj_disp_bg().
}

function update_traj_disp {
	parameter rng_.
	parameter vel_.

	//check if we shoudl update entry traj counter 
	if (traj_disp_counter = 1 and vel_ <= 5350) {
		increment_traj_disp_counter().
	} else if (traj_disp_counter = 2 and vel_ <= 4350) {
		increment_traj_disp_counter().
	} else if (traj_disp_counter = 3 and vel_ <= 3400) {
		increment_traj_disp_counter().
	} else if (traj_disp_counter = 4 and vel_ <= 1950) {
		increment_traj_disp_counter().
	} else if (traj_disp_counter = 5 and vel_ <= 500) {
		increment_traj_disp_counter().
	}
	
	if (traj_disp_counter_p <> traj_disp_counter) {
		set traj_disp_counter_p to traj_disp_counter.
		reset_traj_disp().
	}

	set_traj_disp_orbiter_bug_pos(v(trax_disp_x_convert(rng_),trax_disp_y_convert(vel_), 0)).

}

function increment_traj_disp_counter {
	set traj_disp_counter to traj_disp_counter + 1.
}

function set_traj_disp_title {
	local text_ht is traj_disp_titlebox:style:height*0.75.
	
	set traj_disp_title:text to "<b><size=" + text_ht + ">ENTRY TRAJ " + traj_disp_counter + "</size></b>".
}


function set_traj_disp_bg {
	set traj_disp_mainbox:style:BG to "Shuttle_OPS3/src/gui_images/traj" + traj_disp_counter + "_bg.png".
}

//rescale 
function set_traj_disp_orbiter_bug_pos {
	parameter bug_pos.
	
	local bug_margin is 10.
	
	local bounds_x is list(10, traj_disp_mainbox:STYLe:WIDTH - 32).
	local bounds_y is list(traj_disp_mainbox:STYLe:HEIGHT - 29, 0).
	
	print "calc_x: " + bug_pos:X + " calc_y: " +  + bug_pos:Y  + "  " at (0, 4).
	
	local pos_x is 1.04693*bug_pos:X  - 8.133.
	local pos_y is 395.55 - 1.1685*bug_pos:Y.
	
	print "disp_x: " + pos_x + " disp_y: " + pos_y + "  " at (0, 5).
	
	set pos_x to clamp(pos_x, bounds_x[0], bounds_x[1] ).
	set pos_y to clamp(pos_y, bounds_y[0], bounds_y[1]).
	
	
	
	print "disp_x: " + pos_x + " disp_y: " + pos_y + "  " at (0, 6).
	
	SET traj_disp_orbiter:STYLE:margin:v to pos_y.
	SET traj_disp_orbiter:STYLE:margin:h to pos_x.

}

function trax_disp_x_convert {
	parameter val.
	
	local par is val * 0.539957.
	
	local out is 0.
	
	if (traj_disp_counter=1) {
		if val > 7000 {
            set out to (par^2 * -0.00005111111 + par * 0.38844444 - 228.0444444).
        } else {
            set out to (par^2 * -0.000037792207 + par * 0.32866883 - 183.0636).
		}
	} else if (traj_disp_counter=2) {
		set out to (par^2 * - 0.00037578 + par * 1.0854212 -302.969942).
	} else if (traj_disp_counter=3) {
		set out to (par^2 * -0.00143805 + par * 2.4982 - 585.265).
	} else if (traj_disp_counter=4) {
		set out to (par^2 * -0.003597 + par * 3.49365 - 362.285714).
	} else if (traj_disp_counter=5) {
		set out to (par^2 * -0.015 + par * 6.425 - 204.75).
	}
	
	return out* 500/486.

}

function trax_disp_y_convert {
	parameter val.
	
	local par is val * 3.28084.
	
	local out is 0.
	
	if (traj_disp_counter=1) {
		set out to (-0.03728 * par + 966.857 + 32.7).
	} else if (traj_disp_counter=2) {
		set out to (-0.089333 * par + 1578.6666 + 32.7).
	} else if (traj_disp_counter=3) {
		set out to (-0.07785 * par + 1150 + 32.7).
	} else if (traj_disp_counter=4) {
		set out to (-0.0593 * par + 689 + 32.7).
	} else if (traj_disp_counter=5) {
		set out to (-0.07828 * par + 535.714 + 32.7).
	}
	
	
	return 400 - out.

}