

//define the approach guidance constants

GLOBAL vehicle_params IS LEXICON(
					"rollguess",65,
					"TAEMtgtvel",260,
					"hac_radius",4.26,
					"hac_r2",0.0000283,
					"final_dist",7.5,
					"aiming_pt_dist", 2,
					"ogs_preacq_dist", 1.0,
					"glideslope",LEXICON(
								"outer",TAN(20),
								"inner",TAN(2),
								"middle",0	
					),
					"flare_circle",LEXICON(
									"radius",7000,
									"dist",0,
									"alt",0
					),
					"preflare_alt",0,
					"flare_alt",0,
					"postflare_alt",0
).
