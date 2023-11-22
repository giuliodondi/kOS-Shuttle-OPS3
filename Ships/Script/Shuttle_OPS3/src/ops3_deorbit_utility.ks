GLOBAL guitextgreen IS RGB(20/255,255/255,21/255).
GLOBAL guitextred IS RGB(255/255,21/255,20/255).

FUNCTION make_global_deorbit_GUI {
	//create the GUI.
	GLOBAL main_deorbit_gui is gui(400,350).
	SET main_deorbit_gui:X TO 550.
	SET main_deorbit_gui:Y TO 350.
	SET main_deorbit_gui:STYLe:WIDTH TO 400.
	SET main_deorbit_gui:STYLe:HEIGHT TO 450.

	set main_deorbit_gui:skin:LABEL:TEXTCOLOR to guitextgreen.


	// Add widgets to the GUI
	GLOBAL title_box is main_deorbit_gui:addhbox().
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


	main_deorbit_gui:addspacing(7).



	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_deorbit_gui:ADDVLAYOUT().
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
	
	
	
	
	


	GLOBAL all_box IS main_deorbit_gui:ADDVLAYOUT().
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
    SET entry_interface_databox:STYLE:HEIGHT TO 200.
	set entry_interface_databox:style:margin:h to 80.
	set entry_interface_databox:style:margin:v to 0.
	
	
	GLOBAL textEI1 IS entry_interface_databox:ADDLABEL(" Time to EI   : ").
	set textEI1:style:margin:v to -4.
	GLOBAL textEI2 IS entry_interface_databox:ADDLABEL(" Delaz at EI  : ").
	set textEI2:style:margin:v to -4.
	GLOBAL textEI3 IS entry_interface_databox:ADDLABEL("Ref FPA at EI : ").
	set textEI3:style:margin:v to -4.
	GLOBAL textEI4 IS entry_interface_databox:ADDLABEL("    FPA at EI : ").
	set textEI4:style:margin:v to -4.
	GLOBAL textEI5 IS entry_interface_databox:ADDLABEL("Flight-path angle : ").
	set textEI5:style:margin:v to -4.
	GLOBAL textEI6 IS entry_interface_databox:ADDLABEL("Range at EI       : ").
	set textEI6:style:margin:v to -4.
	
	
	
	


	main_deorbit_gui:SHOW().
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