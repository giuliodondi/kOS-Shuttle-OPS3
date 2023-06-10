

FUNCTION airbrake_control_factory {

	LOCAL this IS LEXICON().
	
	this:ADD("parts",LIST(
						SHIP:PARTSDUBBED("airbrake1")[0]:MODULESNAMED("ModuleAeroSurface")[0],
						SHIP:PARTSDUBBED("airbrake1")[1]:MODULESNAMED("ModuleAeroSurface")[0]
					)
	).
	
	this:ADD("max_deploy", 40).
	
	this:ADD("deflection", 0).
	
	this:ADD("activate", {
		FOR bmod IN this["parts"] {
			bmod:SETFIELD("deploy",TRUE).
		}
	}).
	
	this:ADD("deflect",{
		PARAMETER new_deflection.
		
		SET this["deflection"] TO new_deflection.
		
		FOR bmod IN this["parts"] {
			bmod:SETFIELD("Deploy Angle",this["max_deploy"]*this["deflection"]). 
		}
	}).
	
	this:ADD("deactivate",{
		FOR bmod IN this["parts"] {
			bmod:SETFIELD("deploy",FALSE).
		}
	}).
	
	FOR bmod IN this["parts"] {
		bmod:SETFIELD("Deploy Angle",0). 
	}
	
	RETURN this.
}