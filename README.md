[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/80x15.png)](https://creativecommons.org/licenses/by/4.0/)

# Kerbal Space Program Space Shuttle OPS3 Entry Guidance

## updated May 2024

<p align="center">
  <img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/ops3_cover.png" width="700" >
</p>

This is the kOS implementation of the real-world Shuttle Entry, TAEM and Approach guidance, also including GRTLS guidance.  
Only designed for use in KSP with full RSS - Realism Overhaul andm y fork of Space Shuttle System

## References
- [MCC level C formulation requirements. Entry guidance and entry autopilot, optional TAEM targeting](https://ntrs.nasa.gov/api/citations/19800016873/downloads/19800016873.pdf)
- [MCC level C formulation requirements. Shuttle TAEM Guidance and Flight Control, optional TAEM targeting](https://ntrs.nasa.gov/api/citations/19800016874/downloads/19800016874.pdf)
- [Space Shuttle Entry Terminal Area Energy Management](https://ntrs.nasa.gov/api/citations/19920010688/downloads/19920010688.pdf)
- [SPACE SHUTTLE ORBITER OPERATIONAL LEVEL C FUNCTIONAL SUBSYSTEM SOFTWARE REQUIREMENTS GUIDANCE, NAVIGATION AND CONTROL PART A - ENTRY THROUGH LANDING GUIDANCE](https://www.ibiblio.org/apollo/Shuttle/sts83-0001-34%20-%20Guidance%20Entry%20Through%20Landing.pdf)


# Installation

## Requirements
- Your KSP language **must be set to English** or else the script will not be able to execute actions on the Shuttle parts
- If you use a joystick, check that the wheel steering axis is bound to the same control axs you use for yaw, or the program won't be able to stay on the runway on landing
- A complete install of RSS/Realism Overhaul
- kOS version 1.3 at least
- kOS Ferram, now available on CKAN
- [My own fork of Space Shuttle System, no other version will work](https://github.com/giuliodondi/Space-Shuttle-System-Expanded).
  - as part of the SSS-fork installation, you will also need to install my fork of Ferram on top of the one coming from RO, follow the README therein

### This program for the moment is not usable with SOCK

## Known Incompatibilities
- Atmospheric Autopilot

## (Warmly) Suggested mods
- Kerbal Konstructs to place runways to land on, they must be at least 1.5x longer than the stock KSC runway.
- [My fork of SpaceODY's STS Locations mod, which contains definitions for runways all over the globe](https://github.com/giuliodondi/STS-Locations.git)
- Some mod to display the surface-relative trajectory in the map view. I recommend Principia.

## Installation

Put the contents of the Scripts folder inside Ship/Script so that kOS can see all the files.
In particular, you will have several scripts to run:
- **ops3_deorbit.ks** for deorbit targeting
- **ops3.ks**, the main reentry program
- **measurerwy.ks** which is a little helper to make your own runway definitions

# Setup

## Runways
First, you need to place runways to land on. Use KK to place them wherever you like, or use my fork of STS Locations to have my own Shuttle sites across the globe.  

**You will need to measure the runway manually in either case.** This is because the exact placement and altitude depends on your terrain map which is likely different from mine.  
There is a helper script in the main kOS root **measurerwy.ks** just for that. Here is how you use it:  
- spawn on the runway you want to measure in some kind of rover or wheeled vehicle
- drive to the near edge behind you, exactly on the runway centerline
- run the script and press Action Group 9
- without halting the script, drive to the opposite end of the runway, stop at the edge like before and press AG9 again,.
- The script will print to screen all the information you need to input into the lexicon inside **Shuttle_OPS3/landing_sites.ks**.

## Shuttle assembly

Assemble the Orbiter from the main **Orbiter** part from my fork. **There is no longer any need for additional Airbrake parts**, the split rudder in my fork is now fully functional.

Check the following settings
- The elevons should have +100% pitch authority, +50% roll authority, 15 deflection and the rest to zero.
- The body flap should have +100% pitch authority, 15 deflection zero for the rest.
- The rudder should have two stock control surface modules (one for each panel) instead of one FAR module. Set deflection to 18 and control surface range to 48.
- Flaps and spoiler settings are now irrelevant since the program will manipulate them automatically
- **Check that the rudder airbrakes deploy and the bodyflap spoiler are NOT present in the brakes Action Group**
- For realistic braking performance, set the main gear braking limit to 35% and the nose braking limit to 0.

### Balancing CG and fuel

The Shuttle Orbiter part is CG-adjusted in order to be slightly tail-heavy during reentry and on the edge of stability during approach and landing. **This is deliberate and realistic. Please refer to [the Shuttle Aerodynamic data book](https://archive.org/details/nasa_techdoc_19810067693)**.  

If you're carrying payload you need to ensure it does not shift the empty CG too much. **IT IS CRUCIAL THAT YOU MEASURE THE CG WITH NO OMS OR RCS FUEL.** If the yellow CG meatball in the SPH is shifted by an entire diameter, that's already almost too much for the flaps to handle.

You will need to save some 80 m/s RCS fuel for reentry balancing and control, and remember you need 80 - 100 m/s on top of that for the deorbit burn. Keep in mind that those RCS figures assume that the CG is within trim limits, If it's outside the limits, RCS will drain **fast**.  
As a rule of thumb, I measured that in well balanced and trimmed conditions the Orbiter will drain about 350L of MMH from a single OMS pod during the entire reentry.
Do not reenter with the OMS pods more than 50% - 60% full or you might be too tail-heavy.

# Deorbit planning

**Before you even start, plan your mission so that you have 80 m/s of RCS for reentry plus 80-100 m/s for the deorbit burn. Thanks to body flap trimming, there is some leeway either way but I couldn't say exactly how much.**

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
- _Auto Flaps_ will enable pitch trimming by moving the elevons and body flap. **99.9% of the time you want this ON**. Automatic trimming only activates when the aerodynamic load crosses a threshold
- _Auto Airbk_ will toggle between manual (off) and automatic (on) rudder speedbrake functionality. **Also leave this ON during Entry** and don't worry about it until TAEM
- _RESET_ allows you to completely reset the guidance algorithms during either Entry or TAEM. The program will also actuate this every time you change target, runway or approach.
- _Log Data_ will log some telemetry data to the file **Ships/Script/Shuttle_OPS3/LOGS/ops3_log.csv**
- the _Display_ will show different things depending on the flight phase. There will be plenty more about this later on.

The other GUI to look at is the **HUD**:  
![hud](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/hud.png)

- the HUD background is either transparent or darkened based on the current time of the day at your position, to provide best visibility
- _AZ ERROR_ is the compass angle between your current trajectory and the current target point. When it's zero you're flying directly towards the target. Positive values mean the target is to your right.
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

The DAP will rely on RCS from entry interface all the way to below Mach 1. You may disable RCS on the forward fuselage, but keep all actuation toggles enabled on the OMS pods.
I do not advise you to disengage the DAP at all above Mach 2, if you do you definitely need the KSP SAS and RCS and even so you might lose control very quickly.


# Entry guidance

This algorithm guides the Shuttle from Entry Interface (122km altitude, Mach 27/28) all the way to TAEM interface (30/35km altitude, 80km from the site, Mach 2.5).  

The Shuttle is a glider, so guidance must manage drag to ensure that the Shuttle makes it to TAEM Interface with the proper energy. The Shuttle generates drag by managing its descent into the atmosphere. But it cannot just pitch down to descend, as thermal considerations force the Angle of Attack to stay close to a rigid profile, the profile being an equation of AoA vs surface-relative velocity.
Entry guidance thus manages atmospheric drag by modulating the bank angle, given the value of pitch. At the same time, there are limits on the drag that is safe to experience at any one time, which define a **reentry corridor**. Entry guidance will continuously calculate a drag profile that meets the range requirement while threading through the corridor.

In a nutshell: Entry guidance is a fancy algorithm that calculates a few interesting numbers:
- the reference drag profile you need to reach the target
- the reference vertical speed to track the drag profile
- the vertical Lift-to-Drag (LOD) you need given the drag and vertical speed errors (with respect to the reference values just calculated)
- the AoA value from the profile and the corresponding Bank angle that satisfies the vertical LOD value just calculated
  
These last two angle values are the steering commands sent to the DAP, and to the HUD pipper.

## The detailed workings

Both the corridor and the profiles are defined as curves in the velocity-drag profile. More precisely it's surface-relative velocity and drag acceleration. All drag units from here on are ft/s^2 to be consistent with all the existing real-world documents and data.

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/drag_vel.png" width="800">

In this plot, the Shuttle will move from left to right along the drag profile curves, and hopefully stay within the corridor boundaries:
- The top curve is the _high drag_ or _hard_ limit. This is the envelope of all constraints the Shuttle is subject to (thermal, load factor, dynamic pressure). If the boundary is crossed, it doesn't mean instant death, but rather there is no guarantee that nothing catastrophic will happen
- The bottom curve is the _low drag_ or _soft_ limit. The Shuttle only crosses this when it's in a low energy condition, nothing catastrophic will happen but the Shuttle might not make TAEM Interface with the proper energy
  
The central curves instead show the _drag profile_. This is a piecewise curve made of several segments, each of which is tied to the **Phase** of the Entry guidance algorithm. The algorithm will adjust the current segment of the drag profile to try to bring the Shuttle back on profile , which is why you see three profile lines all converging to the same profile curve at the end.

It makes sense to discuss the drag segments along with the general flow of the guidance algorithm:
- At entry interface, the program is in Phase 1 : **Pre-entry (PREEN)**. This is an open-loop phase with no fancy calculations, just steady pitch and 0° bank. This phase is terminated when the total aeordynamic load reaches about 0.1G, and Phase 2 is triggered. This usually happens below 90km altitude
- Phase 2 is **Temperature Control (TEMP)**. The drag segments are two quadratic functions of velocity.  At the start, the Shuttle will be far off the reference drag and hdot values and so guidance will keep 0° of bank until the descent stabilises, it then performs the first roll towards the target and start tracking the drag profile. This phase normally switches to phase 3 around Mach 19, but in high-energy cases it might switch to phase 4 directly
- Phase 3 is **Equilibrium Glide (EQGL)**. The drag profile is adjusted to balance vertical lift, centrifugal force and gravity. This phase switches to Phase 4 anywhere between Mach 17 and Mach 11 depending on the energy, but it can aso switch directly to phase 5 if energy is very low
- Phase 4 is **Constant Drag (CONSTD)**. As the name suggests, the drag profile is a constant value calculated previously to reach phase 5 with the proper energy at the proper range. This phase can only switch to phase 5, it usually happens no later than Mach 11
- Phase 5 is **Transition(TRAN)**. The drag is actually a function of Energy over Weight (EOW) but, since most of the energy is kinetic from velocity, we'll ignore the distinction. The name refers to the fact that in this phase the Shuttle will start pitching down to 10° Aoa and below, which is needed by TAEM guidance. This phase terminates at TAEM interface.

Since the velocity-drag profiles are important, they are visualised at a glance in the **ENTRY TRAJ Displays**, the five displays that are shown along the Entry phase:

![traj_disp](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/entry_traj_displays.png)

The central plot is a little involved:
- Velocity is on the vertical, decreasing going down the plot
- Drag is not on the horizontal, instead the dashed lines act as markers of the drag values. The corresponding drag value is written at the top (in ft/s^2)
- The bundle of straight lines dislays the reentry corridor:  
  - The lines are approximately the same velocity-drag lines as the plot above
  - The top-left line is always the high-drag line, the bottom-right is the low-drag line
  - The reference profile is the centre-most line, TRAJ 1 and 2 have multiple reference curves to mark typical situations
- The Shuttle bug will invariably move from top-right to bottom-left as it makes its way through the reentry corridor
- The square box below the bug is the Drag error indicator, it follows the bug down the screen and is placed left or right based on the reference drag value. If it's to the left of the bug, it means that Guidance would like you to have more drag than the current value

The other data printouts display useful information:
- Top left you have a bunch of aerodynamic data:
  - _XLFAC_, the total aerdynamic acceleration in the same units as drag
  - _L/D_, you current measured Lift-to-Drag ratio
  - _DRAG_, the current drag acceleration
  - _D REF_, the reference drag value fro mthe profile that Guidance calculated
- also the _PHASE_ counter of the guidance algorithm
- Bottom right:
  - _HDT REF_, the reference vertical speed to track the drag profile
  - _ALPCMD_, the commanded Angle of Attack value from the fixed profile
  - _ROLCMD_, the commaned bank angle
  - _ROLREF_, the bank angle to track the profile if we had no hdot or drag error right now

  Also there are two yellow printouts that will only show in special situations:
  - _ALP MODULN_ indicates that AoA modulation is in effect: if the drag error is too large, Guidance will alter the Angle of Attack a little off-profile to change drag quickly, up to a maximum of 3 degrees
  - _ROLL REVERSAL_ shows when the azimuth error is too large and it's time to bank in the opposite direction to stay on course, it will go off once the az error is decreasing and within limits

The TRAJ displays will advance based on velocity, not the guidance phase:
- TRAJ 1 covers phases 1 and 2, and sometimes the start of phase 3
- TRAJ 2 is usually phase 3
- TRAJ 3 usually covers late phase 3, phase 4 and the switch to phase 5
- TRAJ 4 and 5 are almost always phase 5 only

Some remarks:
- There are some Mach vs Range checkpoints that you should look out for to see if guidance is doing well:
  - Mach 12 at 1000km
  - Mach 10 at 750 km
  - Mach 5 at 250 km
  - Mach 3 at 100 km
  - bear in mind that Guidance is not programmed to hit these points, the're just rules of thumb I devised.
- Nevertheless, even if Entry is a bit off-nominal in range or energy, usually proper ranging is achieved by phase 4/5
- I still haven't explored the full "envelope" of Entry Interface conditions that Guidance can handle and achieve the proper ranging. Try to hit the deorbit targets as accurately as possible
- The aerodynamics of the Shuttle in KSP are close but not exactly like in real life. The biggest difference is during the Transition phase, which is usually entered high on energy. Guidance will consistently command high drag but the Shuttle never seems to reach it. In any case, ranging works fine
- The Angle of Attack profile is 40° at Entry Interface, ramping down to 30° by Mach 18, and then ramping down again from Mach 8.
  - In reality the Shuttle used 40° fixed until the rampdown at Mach 12. Technical documents show that the 40/30 profile was suggested for high-crossrange missions such as the 3B once-around mission out of Vandenberg, which is why I chose it
- If Speedbrakes are set to Auto, they will open at Mach 3.8
  - In real life they would open at Mach 10 to help with trimming. I saw that this generates too much drag in KSP
  - If you want manual speedbrakes, I suggest to leave them closed until about Mach 3 and then open them about 2/3 before TAEM
- Flying CSS is tricky because Guidance will comand continuous corrections of bank angle to track the drag profile. In particular, it will overbank right after a roll reversal to counter the extra lift gained. **You MUST be focussed closely on the HUD and follow the commands if you fly CSS**

## Entry guidance during a TAL abort

The trajectory after an ascent TAL abort is suborbital, with not enough velocity to keep the flight-path angle within the nominal reentry values. As a result, the Shuttle will unavoidably descent rapidly and experience a drag spike.  

When Phase 2 is triggered, the initial hdot error is so large that Guidance keeps wings level for much longer than usual. Drag will rise rapidly, and possibly even break the high-drag limit for a short while. Drag will peak at the moment the descent is arrested, but guidance will stay at wings level for even longer as the drag error term is still large. The Shuttle will start climbing and drag will decrease down towards the reference profile.  

Once the drag error becomes small enough, guidance will command a large roll, to stop the climb and re-establish the reference hdot value. This roll will exceed 90° which is normal and expected in this situation. The descent should not take too long to stabilise close to the reference drag and from there on the rest of reentry plays out pretty much normally.

# Terminal Area Energy Management (TAEM) guidance

Entry guidance has delivered the Shuttle some 80km from the runway, some 30km altitude at Mach 2.5 or a little higher. In addition, the Angle of Attack has been lowered to transition to the front-side of the Lift-to-Drag curve. This just means that now the Shuttle can fly like an aircraft.

TAEM is all about Energy, to slow down just in time to acquire the runway and get on the proper descent profile for landing. There is an altitude profile as well as an energy profile to track. TAEM terminates when the Shuttle is established on final approach within some margin of error.  

To cover all possible energy conditions, there are several approaches that can be chosen:

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/hac.png" width="600">

- HAC stands for Heading Alignment Cone, it's a fixed point to use as a guidepost to align with the runway
- **Overhead (OVHD)** is the default choice, but you have a GUI button to change to **Straight-in (ST IN)**. This will reduce the distance to fly by quite a lot in a very low energy case.
  - **The switch from Overhead to Straight-in is always manual and up to you, never done automatically**
- The HACs can be placed at the **Nominal Entry Point (NEP)** and switched to the **Minimum Entry Point (MEP)** if low on energy. This is a less drastic change than the Overhead/Straight-in switch
  - **The NEP to MEP switch happens automatically within TAEM guidance, you have no control over it**
 
The guidance outputs sent to the DAP are bank angle to steer towards a guidance point and a target vertical speed value to achieve.
The phases of TAEM guidance are:
- **Acquisiton (ACQ)**, the Shuttle is guided on a course to the HAC entry point. The target vertical speed depends on a combination of errors with respect to the altitude and energy profile
- **S-turn (STURN)**, if energy is too far avode the nominal profile, the Shuttle turns away from the HAC for a little while to increase distance to fly and raise the energy profile. This phase is only entered from Acquisition and is forcibly disabled if too close to the HAC
- **Heading alignment (HDG)** which is the turn around the HAC. The AZ ERROR number on the HUD will indicate the degrees of turn left to sweep. The Shuttle will bank by an angle that depends on the crosstrack error, the target hdot instead depends only on the error from the vertical profile, with no more contibution from energy. The phase terminates when the turn angle around the HAC is less than 30° and the Shuttle is close enough to centreline
- **Pre-final (PRFNL)** which manages pitch and bank to stabilise the Shuttle on the final descent path and course. The AZ ERROR number indicates the heading degrees off runway centreline.
 
The TAEM displays are **VERT SIT** and show the energy situation against distance to fly, along with other data:

![vsit_disp](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/vsit_displays.png)

- The central plot shows the three Energy-over-Weight against Range to go profiles:
  - **Keep in mind that most of the energy by this stage is potential i.e. dominated by altitude**
  - The middle profile is the Nominal, if the Orbiter bug is too far off-nominal, guidance will respond in the following ways:
    - if high energy, pitch down a little to dive into thicker air and generate drag, while shedding altitude to reduce energy
    - if low energy, pitch up to conserve some altitude and thus energy until the profile is restored
  - The lower profile is the Minimum Entry Point line, if the Shuttle crosses this line, guidance automatically moves the HAC to the NEP, this usually brings the bug within margins
  - The higher profile is the S-turn line, crossing this line will trigger the S-turn, which is disabled once the bug returns below the line
- The data displayed in the left panel are the current body attitude angles
- In the bottom-right panel you have:
  - The indicator of nominal (NEP) or minimum (MEP) entry points currently enabled. MEP is yellow.
  - _ALPHA LIMS_ the lower and upper limits on Angle of Attack needed to prevent dangerous commands
  - _SPDBK CMD_ the current commanded speedbrake deflection on a scale of 0 to 1
  - _REF HDOT_ the vertical speed to track the altitude profile
  - _TGT NZ_ the target vertical load factor
    - normally this is a DAP calculated quantity to maintain target hdot, but in some cases this is a direct guidance target value
- The left slider is the error with respect to the altitude profile
  - The middle ticks are +/- 100m, then the slider is scaled so that the outer ticks are +/- 1000m. This allows to visualise different scales of error at the proper resolution
- VERT SIT 1 covers the early part of Acquisition (and S-turn if needed)
- VERT SIT 2 covers late Acquisition around the time that S-turns are inhibited all the way to Approach and Landing
- A few elements appear in the VERT SIT 2 display:
  - during late Acquisition, a **Time-to-HAC** indicator that will start to move when the Shuttle is about 7 seconds away from the HAC
  - This is replaced by the **Cross-track XTRACK** indicator during Heading align and pre-final, as well as Approach and Landing

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/vsit_low.png" width="350">

Finally, this is the Vert Sit display in a very low energy situation:
- The MEP selection is displayed instead of NEP
- A message OTT ST IN appears: guidance is signalling that it would be a good idea to switch to a Straight-in approach
  - remember that you need to switch manually, the program will never do it for you

Remarks:
- The moment S-turns are disabled is also the moment the program will not allow you to change runway or approach anymore. You will notice because all GUI button selectors become frozen
- The auto speedbrake logic is as follows:
  - the maximum constant 65° above Mach 1.5
  - A function of the error with respect to a target Dynamic Pressure profile (i.e. velocity corrected for air density)
  - max open above the S-turn energy line and min open (or closed) below the MEP energy line
- You can use manual speedbrakes to add or subtract drag if you're way off the energy profile
- Tips for flying with DAP set to CSS:
  -  you should make small corrections especially in pitch, as it's very easy to overshoot the HUD command
  - In any case, you don't need super crisp vertical control during Acquisition and S-turns, it's enough to be within the +/- 1000m mark by HAC acquisition
  - During Heading align and Prefinal, it's easier to manage altitude and acquire the altitude profile. You should keep an eye on the Altitude error slider and, if needed, deliberately over-correct your pitch inputs to track the profile. The important thing is to be reasonably close to 0 error by pre-final
- The energy profile is calibrated intentionally to place the Shuttle above profile by HAC acquisition. If the HAC turn is less than 180°, there might not be enough time to null the altitude error by the end of TAEM, usually this is not a major issue for what follows.

# Glide-RTLS abort guidance

Glide-RTLS is the atmospheric guidance mode used during an RTLS abort after MECO and External Tank separation.  
The powered guidance part is taken care of by my OPS1 ascent program, it will automatically transition to OPS3 and GRTLS guidance at the right moment.  

The orbiter will be around 70km of altitude and travelling far too slowly to glide in a controlled manner, and so it will start falling very soon. Things happen fast in a GRTLS. As soon as the program engages you must enable the DAP (AUTO or CSS) and auto flaps and spoilers.  
The display during GRTLS is VERT SIT 1 like for early TAEM, but you only focus on the top left part of the monitor, disregard the energy profile lines.

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/vsit_grtls.png" width="350">

- The mini plot in the top-left corner is Pitch vs. Mach number. THe bug will move to the left as you slow down. It is designed to give a reference to monitor what guidance is trying to do or if you fly CSS
- The solid zig-zagged line is the lower limit, you should always stay above this line
- The dashed line is the pitch profile during Alpha Transition, you should see the bug settle on this line eventually.

The phases of GRTLs are:  

- **Alpha-recovery (ALPREC)**, the Orbiter will maintain 0 bank and 45° Aoa as it plunges in the atmosphere The vertical load factor (NZ) will start climbing as the wings generate lift, above a threshold the program will transition to NZHOLD. The orbiter shoudl climb abobe the solid pitch limit line.
- **NZ-hold (NZHOLD)**, the program will keep wings level and modulate the Orbiter's pitch to maintain a target NZ. The target value is a canned profile plus corrections to keep the total load factor (lift plus drag) within the structural limit of 2.5G. You will see the orbiter bug descend a little as pitch is modulated, and the total load factor value possibly turn yellow. The program transitions to ALPTRN when the vertical speed rises above a threshold
- **Alpha-transition (ALPTRN)**, the pitch is lowered in a controlled manner from whatever value it had at the end of NZHOLD to a profile of Mach. Once the pitch profile is established, the program will start banking for lateral guidance. S-turns might be performed if energy is very high. The orbiter pitch bug will descend gently and should settle on the dashed line.

At Mach 3.2 the program will transition to regular TAEM guidance, either ACQ or STURN phase depending on the energy state.

- The energy state at the end of GTLS depends on the Range-Velocity line targeted by Powered RTLS guidance and also depends on payload, since a heavier orbiter is less affected by drag. At times the orbiter might be in a low energy condition at TAEM interface, with the **OTT ST IN** message suggesting a downmode to a Straight-In approach



# Approach & Landing (A/L) guidance

TAEM has delivered the Shuttle on final approach, with hopefully small errors in the vertical and cross-track. The last step is to make fine alignment corrections and flare to achieve a shallow glide right over the runway, until the wheels touch down. The guidance and control algorithms are superficially similar to TAEM (actually they are incorporated in the same routines).

<img src="https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/a_l_profile.png" width="800">

The phases of A/L are as follows:
- **Capture (CAPT)**, the Shuttle will use the same guidance laws as TAEM prefinal but monitor the vertical and cross-track errors. The phase terminates when the errors stay small enough for 4 seconds
- **Outer Glideslope (OGS)**, a steep descent on the vertical profile (24° normally, 22* if the Shuttle is very heavy) designed to overcome the Shuttle's base drag and allow control of airspeed with the speedbrake. It ends at around 600m altitude above the runway
- **Flare (FLARE)**, a pitch-up command on an imaginary circle followed by an exponential to settle down on the final shallow glidepath. 
  - In this phase and beyond, altitude errors are no longer used to correct the pitch command, just the hdot error. The reason is that crisp control of altitude is not necessary if the flare is timed right, and this makes it simpler to achieve a stable shallow glide after the flare
- **Final Flare (FNLFL)**, the Shuttle keeps a shallow 2.5° glideslope and deploys the landing gear. Yaw is used instead of bank to correct cross-track errors. It ends right before touchdown
- **Rollout(ROLLOUT)**, the mode that controls the Shuttle from touchdown to wheels stop. Horizontally, yaw and wheel steering are used to track the centreline. Vertically, the DAP will command pitch-down to prevent a second lift-off in case the Angle of Attack was too large at touchdown. 

During A/L you should completely disregard the Vert Sit display and focus on the HUD and the runway.  
The HUD will change to let you know you reached certain checkpoints:  
- The hud nose marker will change to a circle to indicate that A/L guidance is in effect
- The G-meter and attitude angles disappear to see the runway better
- 1500m above the runway there is a checkpoint that forces guidance from Capture into Outer Glideslope mode even if the errors are not small by then. You will notice because flap trim, vertical speed and distance will all disappear from the HUD, and altitude will be displayed in a finer format
- During final flare, the guidance pipper disappears. If you're flying CSS, guide yourself relative to the runway

Speed-wise, the Orbiter should be at around 180 m/s at the start of A/L, slow down in a controlled manner to about 145 m/s at the start of the flare, complete the flare around 120m/s and decelerating and touchdown between 90 and 80 m/s. If the dap is on AUTO, there will be some oscillations during Final Flare as it attempts to stabilise the vertical speed, I still haven't been able to dampen these out reliably 




# Results from a test reentry to Edwards Runway 23

![sample_traj](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/traj.png)

The first plot show the long-range Reentry and short-range TAEM.:
- roll reversals are clearly visible
- during TAEM, the vehicle stayed within the energy corridor for most of the early Acquisition phase
- Then, eventually, an S-turn was deemed necessary. The S-turn chaged the location of the HAC entry point and the HAC turn angle

![entry_plots](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/entry_plots_1.png)

- The first plot is Angle-of-Attack versus velocity. The 40/30 profile can be identified by the general shape. On top of this profile, Guidance will modulate Angle of Attack to correcr drag errors. This happens a lot during the Transition phase, as the drag errors are quite large
- The second plot is the Roll and Yaw history. The roll reversals are identifiable, as well as the roll modulation done right after the reversal is complete to re-establish the proper vertical speed profile. Yaw shows small deviations during and right after the roll reversal, this is a limitation of the DAP and a consequence of the need to do the reversal quickly enough
- The third plot is Drag v. velocity superimposed over the drag profiles. A small drag spike can be seen at the far left, this is the early portion of Temperature Control during which roll is kept at 0 to stabilise the descent before the first roll. Tracking of the reference lines is good up until the Transition phase, at that point Guidance has a harder time tracking the drag profile. More investigation is necessary on why this happens.

![entry_eow](https://github.com/giuliodondi/kOS-Shuttle-OPS3/blob/master/Ships/Script/Shuttle_OPS3/images/eow.png)

This plot is the Energy-over-Weight vs range-to-go during TAEM. The three profile lines can be seen, The blue track is the actual flight data.  
As evidenced by the trajectory plto above, Energy was within limits and strayed above the S-turn line just a little. The S-turn increases range-to-go and brings the Shuttle back insde the corridor.


