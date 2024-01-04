

//general parameters to control main executive

GLOBAL parameters is LEXICON(
					"full_debug", TRUE,	//will dump the input and internal lexicons of entryg and taemg separately, in imperial units, and print dap data
					"atmalt",140000,
					"interfalt",122000,
					"surfv_skip_to_taem", 1000,	//m/s if the executive is called below this surfv, skip entry
					"mach_rcs_off",0.9,		//this must be 1 or less
					"entry_aoa_feedback", 0,	//should be zero
					"taem_aoa_feedback", 50,	//should be around 50 to help the dap keep stability
					"control_loop_dt",0.1,	//this should be as low as feasible
					"entry_loop_dt",0.5,	//this should be between 0.5 and 2
					"taem_loop_dt",0.0,		//this should be zero
					"game_resolution_width", 1920,		//to center the hud
					"game_resolution_height", 1080		//to center the hud
).

