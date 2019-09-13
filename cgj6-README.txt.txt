BUGS GAME README

Background Info (from Wikipedia article on Space Invaders)
----------------------------------------------------------
Bugs [Space Invaders] is an arcade video game created by Christian Jarani (Tomohiro Nishikado)
and released in 2016 (1978). It was originally manufactured and sold by Bruce Childers (Taito) in Pittsburgh, PA (Japan), 
and was later licensed for production in the United States by the Midway division of Bally. Bugs (Space Invaders) is one of the earliest 
shooting games and the aim is to defeat waves of bugs (aliens) with a pulse gun (laser cannon) to earn as many points as possible. In designing the game, 
Jarani drew inspiration from popular media: Breakout, The War of the Worlds, and Star Wars. To complete it, he had to design a custom assembly program.

It was one of the forerunners of modern video gaming and helped expand the video game industry from a novelty to a global industry 
(see golden age of video arcade games). When first released, Bugs (Space Invaders) was very successful.

The game has been the inspiration for other video games, re-released on numerous platforms, and led to several sequels. The 1980 
Atari 2600 version quadrupled the system's sales and became the first "killer app" for video game consoles. Bugs (Space Invaders) has been 
referenced and parodied in multiple television shows, and been a part of several video game and cultural exhibitions. The pixelated 
enemy alien has become a pop culture icon, often used as a synecdoche representing video games as a whole.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Algorithm Explanation
----------------------------------------------------------
Initally, three bugs are spawned when the game starts and are inserted into the queue. The game then initializes all necessary variables (mostly time-related)
and then drops into the game's main loop. At the start of the loop, the current time is recorded and the timestep from the last iteration is subtracted to
determine the speed of the last processing of events in milliseconds. The resulting number is then added to the process timer, as process iterations can only be performed
once 100 ms have passed between them, and is then added to the process timer and total execution time. After this, the current time is recorded into the timestep for further 
use later in the program. After the time counters are dealt with, I then check the total time of the program and end it if ~2 minutes have passed. If ~2 minutes have not passed, 
the loop then checks for a key press and processes it accordingly. After this, if enough time has passed, the program will begin to iterate throughh the events currently in the queue. 
Each iteration through the event queue takes 200 ms to process, during which events are removed, processed according to their event type, and inserted back into the queue. The number of 
iterations to perform is determined by the size of the queue, which is found by determining the range of addresses between the end and start of the queue, and then right shifting the 
result by two (effectively the same as dividing by four, which are the number of bytes that each aligned address space encompasses [each event uses one address space of 4 bytes to be 
represented: 1st Byte: event type, 2nd Byte: x coordinate, 3rd Byte: y coordinate, 4th Byte: radius (used for wave processing]). The events are not meant to exist on seperates planes of 
existence, so when a bug coincides with a pulse (and vice versa), a pulse/bug reaches the end of the screen, or a wave event hits a bug, there must exist some reaction. In order to determine 
whether or not a pulse hits a bug (and vice versa), I have the pulse check the LED status before it moves its position as well as after in order to account for a bug overriding its current 
position as well as said pulse overriding some bug's position. The bug doesn't think about what's surrounding it as to make collision less complicated to determine. Once a bug is hit, it is 
removed from available events toprocess by setting its event data to 0, which the process loop ignores and moves on to the next event when encountered (Occasionally, the program will crash 
upon dropping into the search method I use to set a zapped bug's event to null when generating a wave event. I was not able to determine the source, but, nevertheless, thought it important 
to mention). The pulse event is then changed into a wave event by setting its first byte, which I used to represent the event type, to the ascii value of 'w' and its last byte, which I used to 
represent the radius, to 1, so that when it is inserted back in the queue (and later removed), it is processed as a wave instead of a pulse. It was at this point that I ran into difficulties, 
as I'm sure was expected. I was able to generate and despawn the first iteration of the wave without issue, but had a great deal of trouble implementing the rest. I also was not able to implement
the cascading effect resulting from the wave interacting with bugs. These are the only aspects of this program that I was unable to complete to the extent that I wish I was able to, as I'm sure 
you will observe when running my program and take into account when assessing my performance.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------