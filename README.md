[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/80x15.png)](https://creativecommons.org/licenses/by/4.0/)

# Kerbal Space Program Space Shuttle OPS3 Entry Guidance
Real Entry and Landing guidance for the Space Shuttle in KSP / RO

# Work In Progress, not yet functional

This will be the kOS implementation of the real-world Shuttle Entry, TAEM and Approach guidance, also including GRTLS  

Only designed to be compatible with my fork of Space Shuttle System (https://github.com/giuliodondi/Space-Shuttle-System-Expanded) with realistic aerodynamics  

## References
- [MCC level C formulation requirements. Entry guidance and entry autopilot, optional TAEM targeting](https://ntrs.nasa.gov/api/citations/19800016873/downloads/19800016873.pdf)
- [MCC level C formulation requirements. Shuttle TAEM Guidance and Flight Control, optional TAEM targeting](https://ntrs.nasa.gov/api/citations/19800016874/downloads/19800016874.pdf)
- [Space Shuttle Entry Terminal Area Energy Management](https://ntrs.nasa.gov/api/citations/19920010688/downloads/19920010688.pdf)
- [SPACE SHUTTLE ORBITER OPERATIONAL LEVEL C FUNCTIONAL SUBSYSTEM SOFTWARE REQUIREMENTS GUIDANCE, NAVIGATION AND CONTROL PART A - ENTRY THROUGH LANDING GUIDANCE](https://www.ibiblio.org/apollo/Shuttle/sts83-0001-34%20-%20Guidance%20Entry%20Through%20Landing.pdf)


# Installation

WIP


# Setup

WIP


# Deorbit planning

Entry Interface is the point at which reentry begins, defined as 122km (400kft) altitude. The goal of deorbit planning is to reach this point at the right conditions for a proper reentry.  
The critical parameters to control are velocity, range, and flight-path-angle (FPA), the angle of descent with respect to the horizontal. All these depend on the initial orbit and the placement/magnitude of the deorbit burn.

First, you need to place a deorbit manoeuvre node on the last orbital pass before the landing site, it's crucial that you use a surface-relative trajectory tool like Principia or Trajectories to pick the right orbital pass. The node need only be created coarsely at this stage, plan a periapsis of near 0km a bit downrange from the landing site.

Then run **ops3_deorbit.ks** to fire up the planning tool. Choose carefully the landing site (it will be frozen after this).  
The tool will predict your state at Entry Interface which you will use to adjust your deorbit burn. The _Ref_ numbers are your desired parameters, the actual parameters will be red if they're too far off from the reference numbers, you should try to get all numbers in the green.

![main_gui](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/deorbit_gui.png)


Rules of thumb:
- Start from a near-circular orbit if you can
- Adjust velocity at EI by changing the retrograde deltaV
- Adjust range and FPA together by changing the radial deltaV and moving the node forward and backward
- Make small adjustments as it takes a second or two for the tool to predict the new trajectory
- Expect the ref. velocity at EI to also change a little as you do this
- Make small adjustments until you converge to a good burn


# The main Entry script

The main script to run is **ops3.ks**. You need to run it below entry interface, until then it will exit without doing anything. The script will take you from Entry Interface all the way to wheels stop on the runway.  
You interact with the script using two GUIS. The **Main GUI** is a panel of buttons and a data display:

![main_gui](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/ops3_gui.png)

- the _☒_ button is to recenter the HUD, _X_ will interrupt the program
- _Target_ is the target site, **select and double-check this immediately after starting the program**
- _Runway_ is the runway you will land on. There are always at least two runways even if there is a single strip of tarmac (one for each side). The choice is random upon selecting the landing site, but you can override it here
- _Apch mode_ is a parameter used by TAEM guidance, by default is set to Overhead. Leave it be for now.
- _DAP_ selects the digital autopilot modes. **As long as you leave it OFF the program will not send any steering commands**. More on autopilot modes later on.
- _Auto Flaps_ will enable pitch trimming by moving the elevons and body flap. **99.9% of the time you want this ON**.
- _Auto Airbk_ will toggle between manual (off) and automatic (on) rudder speedbrake functionality. **Also leave this ON during Entry** and don't worry about it until TAEM
- _RESET_ allows you to completely reset the guidance algorithms during either Entry or TAEM. The program will also actuate this every time you change target, runway or approach.
- _Log Data_ will log some telemetry data to the file **Ships/Script/Shuttle_OPS3/LOGS/ops3_log.csv**
- the _Display_ will show different things depending on the flight phase. There will be plenty more about this later on.

The other GUI to look at is the **HUD**:  
![hud](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/hud.png)

- the HUD background is either transparent or darkened based on the current time of the day at your position, to provide best visibility
- _AZ ERROR_ is the compass angle between your current trajectory and the target. When it's zero you're flying directly towards the site. Positive values mean the target is to your right
- _FLAP TRIM_ is an indicator of the current trim setting, from minimum (-1) to maximum (+1). The deflection angle of each control surface is proportional to this
- _VERT SPEED_ indicates your current vertical speed at a glance
  - During Reentry the scale is 200 m/s
  - during TAEM and Landing it's 100m/s
  - during GRTLS alpha recovery and NZ Hold it's 300 m/s, during Alpha transition it's like TAEM
- _MACH_ will indicate your Mach number until TAEM HDG phase, afterwards it will display the true airspeed in m/s
- _LOAD FACTOR_ is the vertical component of the total aerodynamic force, along the gravity vector, in units of G-force
- The central square indicator indicates the Shuttle's nose. After the A/L interface it changes ot a circle
- _BANK_ is intuitively the angle of roll. Actually, it's the angle between the lift vector and the local vertical, since the Shuttle is supposed to fly at zero sideslip angle at all times
- _AOA_ is the angle between the nose and the surface velocity vector
- the _GUIDANCE PIPPER_ indicates the values of Bank and AoA that the guidance algorithm wants you to have right now. If it's centered on the nose indicator, you're following the guidance commands perfectly
- _GUID PHASE_ indicates the status of the underlying guidance algorithms. More on this later
- _DISTANCE_ is in km. During reentry it's the distance to the guidance point, during TAEM it indicates the total groundtrack prediction all the way to the runway
- _SPEEDBRAKE_ indicates the speedbrake deflection from 0 to 1. The actual maximum deflection is 47° either side
- _STEER MODE_ is a repeater of the DAP mode you selected in the main GUI

## Digital Autopilot modes

There are two DAP modes: 
- **CSS** or _Control Stick Steering_ : it's a fly-by-wire control mode where you can control by hand (with keyboard or joystick) the target values of Angle of Attack and Bank, the DAP will take care to send the proper steering commands to the kOS steering manager
- **AUTO** where everything is taken care of by kOS. Beneath the program, there are several DAP AUTO modes that control one target quantity or the other depending on the flight phase. More on this later, but externally you won't notice the difference anyways.
- The **OFF** setting is the completely-manual vanilla KSP steering you may be used to, without any augmentation whatsoever

The entire point of having a DAP is that the Shuttle is yaw-unstable through most of the reentry regime, and may be on the edge of stability at landing depending on centre-of-gravity and trimming.  
Additionally, some guidance modes require the Shuttle to control quantities (such as vertical speed or load factor) that are several steps removed from the manual elevon control inputs, making it very hard to do this by hand.

The program is able to take the Shuttle from Entry Interface all the way to wheels stop completely automatically with the DAP set to AUTO. It's also possible to fly a complete reentry in CSS but there are a couple quirks to keep in ming dring both entry and TAEM, more on this later.

I do not advise you to disengage the DAP at all above Mach 2, if you do you definitely need the KSP SAS and RCS and even so you might lose control very quickly.


# Entry guidance

This algorithm guides the Shuttle from Entry Interface (122km altitude, Mach 27/28) all the way to TAEM interface (30/35km altitude, 80km from the site, Mach 2.5).
The Shuttle is a glider, so guidance must manage drag to ensure that the Shuttle makes it to TAEM Interface with the proper energy. At the same time, there are limits on the drag that is safe to experience at any one time, which define a **reentry corridor**. Entry guidance will continuously calculate a drag profile that meets the range requirement while threading through the corridor.

Both the corridor and the profiles are defined as curves in the velocity-drag profile. More precisely it's surface-relative velocity and drag acceleration. All drag units from here on are ft/s^2 to be consistent with all the existing real-world documents and data.

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/drag_vel.png" width="800">

In this plot, the Shuttle will move from left to right along the drag profile curves, and hopefully stay within the corridor boundaries:
- The top curve is the _high drag_ or _hard_ limit. This is the envelope of all constraints the Shuttle is subject to (thermal, load factor, dynamic pressure). If the boundary is crossed, it doesn't mean instant death, but rather there is no guarantee that nothing catastrophic will happen
- The bottom curve is the _low drag_ or _soft_ limit. The Shuttle only crosses this when it's in a low energy condition, nothing catastrophic will happen but the Shuttle might not make TAEM Interface with the proper energy
  
The central curves instead show the _drag profile_. This is a piecewise curve made of several segments, each of which defines the **Mode** of the Entry guidance algorithm. The curves show high, nominal and low energy situations, and show how Guidance adjusts the profile to satisfy range to the site while still respecting the corridor:
- First is **Temperature Control**, the union of two quadratic curves (drag ∝ velocity^2), it lasts from Entry interface until about Mach 19 (5700 m/s)
- The next one is **Equilibrium Glide**, drag is modulated to balance lift, centrigufal force and gravity. It lasts until somewhere between Mach 11 and Mach 17 depending on the Shuttle's energy.
- The next one is **Constant Drag**, which is a constant value determined by Guidance to reach the last segment with the proper energy. If you're high on energy, Guidance might switch to constant drag early, in the nominal case this phase should not last very long before the last phase
- The final phase is **Transition** which is a linear drag vs. energy-over-Weight profile. Strictly speaking this is not a drag-velocity profile, but it's close enough since most of your energy is kinetic anyways.

Now it's time to talk about the actual flow of the algorithm through Reentry and the various phases. Remember that the current guidance phase is displayed on the HUD:

- The first phase is **Pre-entry (PREEN, aka Phase 1)**, from program activation until the total aerodynamic acceleration reaches about 0.1G. The Shuttle will keep wings level throughout this phase, if the DAP is AUTO, of course. Pre-entry always transitions to Temp control
- The second phase is **Temperature Control (TEMP, aka Phase 2)**, and the third phase is ** Both the quadratic and equilibrium glide profile segments are adjusted as you see in the velocity-drag


![traj_disp](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/entry_traj_displays.png)

- Mach 12 / 1000km
- Mach 10 / 750 km
- Mach 5 / 250 km
- Mach 3 / 100 km


# TAEM guidance

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/hac.png" width="600">

![vsit_disp](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/vsit_displays.png)

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/vsit_low.png" width="350">

# GRTLS guidance

WIP

# Approach & Landing guidance

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/a_l_profile.png" width="800">


# Results from a test reentry to Edwards

![sample_traj](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/traj.png)

![entry_plots](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/entry_plots_1.png)

![entry_eow](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/eow.png)

![]()
