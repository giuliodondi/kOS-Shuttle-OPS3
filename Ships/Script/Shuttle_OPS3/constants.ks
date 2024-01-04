

//put these constants in their own file to enable checking of deorbit/entry conditions
//without cluttering the memory in case they fail

GLOBAL constants is LEXICON(
					"full_debug", TRUE,
					"atmalt",140000,
					"interfalt",122000,
					"mach_rcs_off",0.9,
					"control_loop_dt",0.1,
					"entry_loop_dt",0.5,
					"taem_loop_dt",0.0,
					"game_resolution_width", 1920,		//to center the hud
					"game_resolution_height", 1080		//to center the hud
).

