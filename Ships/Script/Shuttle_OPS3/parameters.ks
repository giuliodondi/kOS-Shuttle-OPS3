

//general parameters to control main executive

GLOBAL parameters is LEXICON(
					"full_debug", FALSE,	//will dump the input and internal lexicons of entryg and taemg separately, in imperial units, and print dap data
					"atmalt",140000,
					"interfalt",122000,
					"xlfac_trim_on", 0.3,		//ft/s load factor to enable flap trimming
					"surfv_skip_to_taem", 1000,	//m/s if the executive is called below this surfv, skip entry
					"mach_rcs_off",0.9,		//this must be 1 or less
					"entry_aoa_feedback", 0,	//should be zero
					"taem_aoa_feedback", 5,
					"control_loop_dt",0.1,	//DO NOT CHANGE
					"entry_loop_dt",0.45,	//DO NOT CHANGE
					"taem_loop_dt",0.0,		//DO NOT CHANGE
					"game_resolution_width", 1920,		//to center the hud
					"game_resolution_height", 1080		//to center the hud
).

