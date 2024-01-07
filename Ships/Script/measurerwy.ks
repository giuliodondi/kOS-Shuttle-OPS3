clearscreen.
clearvecdraws().

RUNONCEPATH("0:/Libraries/misc_library").	
RUNONCEPATH("0:/Libraries/maths_library").	
RUNONCEPATH("0:/Libraries/navigation_library").



print "press AG9 to confirm geoposition 1...." at (0,1).

LOCAL stop IS false.
ON AG9 {
	set stop to true.
}
UNTIL stop{
	WAIT 0.1.
}
LOCAL pos1 IS SHIP:GEOPOSITION.

print "press AG9 to confirm geoposition 2...." at (0,3).

LOCAL stop IS false.
ON AG9 {
	set stop to true.
}
UNTIL stop{
	WAIT 0.1.
}
LOCAL pos2 IS SHIP:GEOPOSITION.

local dist is greatcircledist(pos1, pos2).
local bng is bearingg(pos1, pos2).
local mid IS new_position(pos2,dist/2, bng).

pos_arrow(pos1, "1").
pos_arrow(pos2, "2").
pos_arrow(mid, "mid").

print "position : " + "LATLNG(" + round(mid:LAT,6) + "," + round(mid:LNG,6) + ")" at (0,5).
print "elevation : " + round(SHIP:ALTITUDE,1) at (0,6).
print "length : " + round(dist*1000,2) at (0,7).
print "heading : " + round(bng,2) at (0,8).


