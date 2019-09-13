#Christian Jarani
#Professor Childers
#CS447, Project 1
#3/18/2016

#------------------------------------------------------------#
#-----------------------WHAT TO DO TODAY---------------------#
#------------------------------------------------------------#
#     1. Start on bug/pulse/wave movement
#
#     2. Deal with how events interact with each other
#
#     3. Deal with bug spawning with $s6
#
#     4. Keep track of bugs killed / pulses fired
#

.data
queue: .space 1024
end:    .asciiz "The game score is "
col:    .asciiz " : "


.text
# Global Variables
#     $s0: start time
#     $s1: start of the queue
#     $s2: end of the queue
#     $s3: bugs killed
#     $s4: pulses fired
#     $s5: timestep
#     $s6: spawn accumulator			#added to spawn time
#     $s7: event information to save across calls

#------------------------------------------------------------#
#----------------------PRELIMINARY SETUP---------------------#
#------------------------------------------------------------#

	la	$s1,queue	     	# load starting address of queue into start of queue (initializiation)
	move	$s2,$s1	     	# copy start of queue to end of queue (initialization)
	li 	$v0,30	       
	syscall		     	# get start time
	move 	$s0,$a0        	# save start time to $s0
	move	$s5,$s0	     	# move start time to timestep
	addi 	$k0,$0,31      	# set player starting x coordinate
	move 	$a0,$k0	     	# pass starting x coord into _setLED
	addi 	$a1,$0,63	     	# pass starting y coord into _setLED
	addi 	$a2,$0,2	     	# pass color (yellow) into _setLED
	jal  	_setLED

#------------------------------------------------------------#
#-------------------------GAME LOGIC-------------------------#
#------------------------------------------------------------#

gameload: sub 	$t0,$s5,$s0      	#subtract start time from current time
	# 2 minutes == 0x1D4C0 in hex
	blt 	$t0,0xFFFFFF,poll 	#look for key press if current time is less than time limit
	#Print results
endgame:	la 	$a0,end
          li 	$v0,4
          syscall			#print prompt
          move 	$a0,$s4
          li 	$v0,1
          syscall			#print bugs killed
          la 	$a0,col
          li 	$v0,4
          syscall			#print colon
          move      $a0,$s4
          li        $v0,1
          syscall			#print pulses fired
          li        $v0,10
          syscall			#terminate program
 	
poll:	la	$v0,0xffff0000	# address for reading key press status
	lw	$t0,0($v0)	# read the key press status
	andi	$t0,$t0,1
	beq	$t0,$0,events	# no key pressed, jump to event processing
	lw	$t0,4($v0)	# read key value
ukey:     addi 	$v0,$t0,-224	# check for left key press
	bne	$v0,0,lkey	# left key not pressed, check if right key
	addi	$a0,$0,112	# put ascii value for 'p' into first parameter
	addi	$a1,$k0,0		# put current player x coord into second parameter
	sll	$a1,$a1,8
	addi	$a2,$0,62		# put current player y coord minus 1 into third parameter
	sll	$a2,$a2,16
	addi	$a3,$0,0		# put radius value into fourth parameter
	sll	$a3,$a3,24
	or	$a0,$a0,$a1
	or	$a0,$a0,$a2
	or	$a0,$a0,$a3
	jal	_insert_q		# insert pulse event into queue
	addi	$s4,$s4,1
	sw	$0,0xFFFF0000
	sw	$0,0xFFFF0004
	j 	poll
lkey:	addi	$v0,$t0,-226	# check for left key press
	bne	$v0,$0,rkey	# wasn't left key, so try right key
	move	$a0,$k0		# keep current position
	addi	$a1,$0,63		
	addi	$a2,$0,0		# turn LED at current position off
	jal	_setLED
	addi	$k0,$k0,-1	# update next position to the left
	move	$a0,$k0
	addi	$a1,$0,63
	addi	$a2,$0,2		# turn LED on at updated positon
	jal	_setLED
	sw	$0,0xFFFF0000
	sw	$0,0xFFFF0004
	j	poll
rkey:	addi	$v0,$t0,-227	# check for right key press
	bne	$v0,$0,quit	# wasn't right key, so check for center
	move	$a0,$k0		# keep current position
	addi	$a1,$0,63	
	addi	$a2,$0,0		# turn LED at current position off
	jal	_setLED
	addi	$k0,$k0,1		# update next position to the right
	move	$a0,$k0
	addi	$a1,$0,63
	addi	$a2,$0,2		# turn LED on at updated position
	jal	_setLED
	sw	$0,0xFFFF0000
	sw	$0,0xFFFF0004
	j	poll
quit:	move	$t1,$t0		# copy key press value to $t1
	addi	$v0,$t0,-66	# check for center key press
	bne	$v0,$0,poll	# invalid key, ignore it
	addi	$v0,$t0,-159	# check for down key press
	bne	$v0,$0,poll
	j	endgame
						  	  
events:   li        $v0,30		
	syscall			# get current time
	move	$t0,$a0		# move current time to $t0
	sub	$t0,$t0,$s5	# subtract timestep from current time
	move	$a0,$t0
	li	$v0,1
	syscall
	la	$a0,col
	li	$v0,4
	syscall
	# if (current_time-timestep >= 100)
	bge	$t0,100,process	# check if 100 ms have passed
 pr_end:	li 	$v0,30		
	syscall		          #get current time
	move 	$s5,$a0		#move current time to timestep for process if statement/outermost while loop
	j	gameload		
process:  jal	_size_q		# find size of queue
	move	$t5,$v0		# move size into $t0
	move      $t6,$0		# initialize event count
	
# pr_loop	
#
#   $t2: mutated event info
#   $t5: size of queue
#   $t6: event count
#
pr_loop:  li	$v0,30		# get current time
	syscall
	move	$t0,$a0		# move current time into $t0
	sub	$t0,$t0,$s5	# subtract timestep from current time
	add	$s6,$s6,$t0
	bgt	$s6,8000,bug_spawn	# after 4000 ms, spawn another bug
spawned:	beq	$t5,$t6,pr_end	# if all events have been processed, end loop
	jal	_remove_q		# remove next entry to be processed
	beq	$v0,$0,pr_end	# if no entry at end of queue
	move	$s7,$v0		# save event info for later processing
	andi	$t2,$s7,0xFF	# mask first 8 bits of event info to determine event type
	beq	$t2,0x70,pulse 	# if hex value is 0x70 (p), treat as pulse event
	beq	$t2,0x62,bug	# if hex value is 0x62 (b), treat as bug event
	beq	$t2,0x77,wave_move	# if hex value is 0x77 (w), treat as wave event
event_inc: move	$a0,$s7
	 jal	_insert_q		# insert event back into queue
	 addi	$s6,$s6,1		# increment spawn timer
	 addi	$t6,$t6,1		# increment number of events processed
	 j	pr_loop		# process next event
 
#------------------------------------------------------------#
#----------------------EVENT FUNCTIONS-----------------------#
#------------------------------------------------------------#
#
#   $a0: x coord
#   $a1: y coord
#

pulse:      andi	$a0,$s7,0xFF00	# mask event's x coord, pass as first param
	  srl	$a0,$a0,8		# shift right 8 bits for use by _setLED
	  andi	$a1,$s7,0xFF0000	# mask event's y coord, pass as second param
	  srl	$a1,$a1,16	# shift right 16 bits for use by _setLED
	  addi	$a1,$a1,1		# move to previous position
	  jal	_getLED		# _getLED at previous position
            beq	$v0,1,pulse_move    # if pulse at previous position, turn it off
ret_pmove:  beq	$a1,-1,oob	# if pulse reaches end of display, set it's type as 0
	  addi	$a2,$0,1		# pass 1 (red) as third parameter
	  jal	_setLED
	  andi	$s7,$s7,0xFF00FFFF	# mask event info to pass in updated y coord
	  addi	$a1,$a1,-1	# decrement y coord
	 #jal	_getLED		# check for collision with bug
	  sll	$a1,$a1,16	# shift left 16 bits to or back into event info
	  or	$s7,$s7,$a1	# or back into event info
	  j	event_inc
pulse_move: move	$a2,$0		# set color param to off for previous position
	  jal	_setLED
	  addi	$a1,$a1,-1	# return y coord to current position
	  j	ret_pmove		# return to loop
	  
bug:        andi	$a0,$s7,0xFF00	# mask event's x coord, pass as first param
	  srl	$a0,$a0,8		# shift right 8 bits for use by _setLED
	  andi	$a1,$s7,0xFF0000	# mask event's y coord, pass as second param
	  beq	$a1,0x0,ret_bmove	# if the bug's y coord == 0, skip to setting the LED at it's position
	  srl	$a1,$a1,16	# shift right 16 bits for use by _setLED
	  addi	$a1,$a1,-1	# move to previous position
	  jal	_getLED		# check if bug at previous position
	  beq	$v0,3,bug_move	# if bug at previous position, turn it off
ret_bmove:  beq	$a1,64,oob	# if bug reaches end of display, set it's type as 0
	  addi	$a2,$0,3		# pass 1 (green) as third parameter
	  jal	_setLED
	  andi	$s7,$s7,0xFF00FFFF	# mask event info to pass in updated y coord
	  addi	$a1,$a1,1		# increment y coord
	  beq	$a1,63,oob	# if bug reaches end of display, remove it
	 #jal	_getLED		# check for collision with bug
	  sll	$a1,$a1,16	# shift left 16 bits to or back into event info
	  or	$s7,$s7,$a1	# or back into event info
	  j	event_inc
bug_move:   move	$a2,$0
	  jal	_setLED
	  addi	$a1,$a1,1		# return y coord to current position
	  j	ret_bmove

oob:        andi	$s7,0xFFFFFF00
	  j	event_inc
	   	   
bug_spawn:  li	$a1,64
	  li	$v0,42         	# random int range
	  move	$a0,$0		# select seed
	  syscall            	# generate random int range (returns in $a0)
	  move	$a1,$a0		# move random number to x coor param
	  addi	$a0,$0,98		# move 98 (ascii value of b) into event type param
	  sll	$a1,$a1,8		# shift 
	  or	$a0,$a0,$a1
	  jal	_insert_q
	  move	$s6,$0
	  jr	$ra
	  
wave_move:  

collision: 

#------------------------------------------------------------#
#-----------------------DATA STRUCTURE-----------------------#
#-----------------------((  QUEUE  ))------------------------#
#------------------------------------------------------------#
#
# Events are stored in an aggregate format within a
#    circularly-linked queue.
#
# Each event uses one word (8 bytes) of space
#   - Byte 0 contains the event type
#   - Byte 1 contains the x coordinate
#   - Byte 2 contains the y coordinate
#   - Byte 3 contains the radius (for wave event)
#
# Events types are as follows
#   - Pulse Move (denoted by p): 
#       -> represents the pulse generated by the player
#       -> generated by pressing the w key (stored as 0xE0 at 0xFFF0004)
#
#   - Bug Move (denoted by b):   
#       -> represents the bug movement down the LED display
#       -> generated by rng at top of display (y = 0)
#
#   - Kill Event (denoted by x):
#       -> if a pulse hits a bug, set byte 0 to x to indicate it was killed
#       -> turns LED at current position off
#
#   - Wave Move (denoted by w):  
#       -> represents the shockwave generated after a pulse hits a bug
#       -> each part of the wave moves 3 positions
#	 -> if wave pulse hits another bug, generate another wave event
#	 -> if wave pulse reaches radius of 3 without hitting anything,
#	    remove event
#
#   - Game Over (denoted by g):
#       -> ends the game
#       -> generated by pressing center or down key
#           -> Center key stored as 0x42 at 0xFFFF0004
#	  -> Down key (s) stored as 0xE1 at 0xFFFF0004

# void _insert_q(char type, int x, int y, int color)
#   inserts new event into the queue
#
# arguments: $a0 is event type, $a1 is x, $a2 is y, $a3 is color
# trashes:   $t0-$t3
# returns:   none
#
_insert_q: move	$t8,$ra		# move return address into $t8
	 move	$t9,$a0 		# move event info into $t9
	 move	$a0,$s1		# move start of queue into $a0 for oob checking
	 jal	check_oob
	 move	$s1,$v0		# move start of queue back into $s1
	 move	$ra,$t8		# move original return address back into $ra
	 move 	$a0,$t9		# move event info back into $a0	
	 sw	$a0,0($s1)	# push event to start of queue
	 addi	$s1,$s1,4		# increment start of queue
	 jr   	$ra

# struct event _remove_q()
#   returns an event to be processed
# 
# arguments: none
# trashes:   fuckin everything
# returns:   event structure
#
_remove_q: move	$t7,$ra		# move return address into $t7
	 move	$a0,$s2		# move end of queue into $a0 for oob checking
	 jal	check_oob		
	 move	$s2,$v0		# return end of queue
	 move	$ra,$t7		# move return address back into $ra
	 lw	$v0,0($s2)	# load event from end of queue
	 addi	$s2,$s2,4		# increment end of queue
	 jr	$ra

# int _size_q()
#   return number of events in queue
#
# arguments: none
# trashes: $t0
# returns: $v0: size of queue
#
_size_q:   beq	$s1,$s2,no_event
	 bgt	$s1,$s2,start_g	# if start of queue is at a higher address than end of queue
	 bgt	$s2,$s1,end_g	# if end of queue is at a higher address than start of queue	 
no_event:  move	$v0,$0
	 jr	$ra
start_g:	 move	$t0,$s1		# move start of queue to $t0
	 move	$t1,$s2		# move end of queue to $t1
	 subu	$v0,$t0,$t1	# find bit difference between start of queue and end of queue
	 srl	$v0,$v0,2		# divide result by four to get number of elements
	 jr	$ra
end_g:	 la	$t0,queue		# load starting address of buffer into $t0
	 addi	$t1,$t0,1024	# add 1024 to find the end of the buffer
	 sub	$t1,$t1,$s2	# subtract end of queue from end of buffer
	 move	$t2,$s1		# move start address to $t2
	 sub	$t0,$t2,$t0	# subtract beginning of buffer from start of queue
	 add	$v0,$t0,$t1	# add (end of buffer - end of queue) and (start of queue - start of buffer)
	 jr	$ra
	
# int check_oob 
check_oob: la	$t0,queue
	 addi	$t0,$t0,1024
	 beq	$a0,$t0,circle_back
	 move	$v0,$a0
	 jr	$ra
circle_back: addi	$v0,$a0,-1024
	   jr	$ra

#------------------LED DISPLAY MANIPULATION------------------#

# void _setLED(int x, int y, int color)
#   sets the LED at (x,y) to color
#   color: 0=off, 1=red, 2=yellow, 3=green
#
# arguments: $a0 is x, $a1 is y, $a2 is color
# trashes:   $t0-$t3
# returns:   none
#

_setLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      	# y * 16 bytes
	srl	$t1,$a0,2      	# x / 4
	add	$t0,$t0,$t1    	# byte offset into display
	li	$t2,0xffff0008 	# base address of LED display
	add	$t0,$t2,$t0    	# address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    	# remainder is led position in byte
	neg	$t1,$t1        	# negate position for subtraction
	addi	$t1,$t1,3      	# bit positions in reverse order
	sll	$t1,$t1,1      	# led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3		
	sllv	$t2,$t2,$t1
	not	$t2,$t2        	# bit mask for clearing current color
	sllv	$t1,$a2,$t1    	# bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     	# read current LED value	
	and	$t3,$t3,$t2   	# clear the field for the color
	or	$t3,$t3,$t1   	# set color field
	sb	$t3,0($t0)    	# update display
	jr	$ra
	
	# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0, 1, 2 or 3)
	#
_getLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      	# y * 16 bytes
	srl  $t1,$a0,2      	# x / 4
	add  $t0,$t0,$t1    	# byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    	# address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    	# remainder is bit position in byte
	neg  $t1,$t1        	# negate position for subtraction
	addi $t1,$t1,3      	# bit positions in reverse order
    	sll  $t1,$t1,1      	# led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    	# shift LED value to lsb position
	andi $v0,$t2,0x3    	# mask off any remaining upper bits
	jr   $ra
