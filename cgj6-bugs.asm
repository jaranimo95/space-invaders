#Christian Jarani
#CS447, Professor Childers
#Project 1: Space Invaders
#3/18/2016

.data
queue: .space 1024
end:    .asciiz "The game score is "
col:    .asciiz " : "

.text
# Global Variables
#     $s0: total time elapsed
#     $s2: start of the queue
#     $s3: end of the queue
#     $s4: event information to save across calls
#     $s5: bugs killed
#     $s6: pulses fired
#     $s7: *unused*

# Additional Variables
#     $k0: player x coord
#     $k1: timestep
#     $t4: # of events	usage exclusive to get_size
#     $t5: event count	usage exclusive to get_size
#     $t7: process timer
#

#------------------------------------------------------------#
#----------------------PRELIMINARY SETUP---------------------#
#------------------------------------------------------------#
wait4start:    lw	$v0,0xFFFF0000		# load key press status
               bne	$v0,1,wait4start	# if key wasn't pressed, keep waiting for input
	lw	$v0,0xFFFF0004		# if key was pressed, read value
	bne	$v0,0x42,wait4start 	# if key pressed wasn't the center key, keep waiting
	  			#   else begin the game
	  
##################### Let the Games Begin #####################

	# Restore Key Press Info
	sw	$0,0xFFFF0000		# reinitialize key press indicator
	sw	$0,0xFFFF0004		# reinitialize value of key pressed  
	# Seed RNG
	li	$v0, 30		# get time
	syscall
	move	$t0,$a0		# save lower 32-bits of time returned
	li	$a0, 1		# set rng id
	move	$a1, $t0		# use time as seed
	li	$v0, 40		# seed random number generator
	syscall
	# Initialize queue
	la	$s2,queue	     	# load starting address of queue into start of queue (initializiation)
	move	$s3,$s2	     	# set start of queue to end of queue (no events)
	# Spawn initial 3 bugs
	jal	bug_spawn		# spawn preliminary bugs
	move	$t7,$0		# initialize process timer
	# Initialize player location
	addi 	$k0,$0,32      	# set player starting x coordinate
	move	$a0,$k0		# pass player starting x coord into _setLED
	addi 	$a1,$0,63	     	# pass player starting y coord into _setLED
	addi 	$a2,$0,2	     	# pass color (yellow) into _setLED
	jal  	_setLED
	# Initialize Stats
	move	$s5,$0		# initialize bugs killed
	move	$s6,$0		# initialize pulses fired
	# Initialize timestep
          li 	$v0,30			# get time
	syscall			
	move 	$k1,$a0        	# initialize timestep to start of game

#------------------------------------------------------------#
#-------------------------GAME LOGIC-------------------------#
#------------------------------------------------------------#

gameloop: li	$v0,30
	syscall
	sub	$k1,$a0,$k1		# find time to process queue
	add	$t7,$t7,$k1		# add time to process timer
	li	$v0,30		
	syscall
	move	$k1,$a0
	lw	$v0,0xFFFF0000		# Load key pressed status
	beq	$v0,1,process_key		# if key pressed, process it
	bge	$s0,120000,gameover 	# if total time elapsed >= 2 mins, end the game
post_key: 	bge	$t7,200,pre_event		# if 100+ ms have passed, process events in queue
	j	gameloop		#    else go back through gameloop

pre_event:     jal	_size_q		# find size of queue
	move	$t4,$v0		# move size of queue into $t4
	move	$t5,$0		# initialize event count
eventloop:     jal	_remove_q
	move	$s4,$v0		# move event into event info variable
	andi	$t0,$s4,0x000000FF  	# isolate event type byte
	beq	$t0,0x62,bug		# if event type byte == 0x62 ('b'), process as bug
	beq	$t0,0x70,pulse		# if event type byte == 0x70 ('p'), process as pulse
	beq	$t0,0x77,wave		# if event type byte == 0x77 ('w'), process as wave
post_event:    move	$a0,$s4		# pass event info into insert
	jal	_insert_q		# insert event at the start of queue
	addi	$t5,$t5,1		# increment event count
	blt	$t5,$t4,eventloop	# if event count is less than size of queue, process next event
	li	$t7,0
	jal	bug_spawn		# once all events processed, spawn more bugs
	j	gameloop		#    else all events have been processed so return to gameloop
	 
gameover:	la 	$a0,end		
          	li 	$v0,4
          	syscall			#print first part of gameover prompt
          	move 	$a0,$s5
          	li 	$v0,1
          	syscall			#print bugs killed
          	la 	$a0,col
          	li 	$v0,4
          	syscall			#print colon
          	move      	$a0,$s6
          	li        	$v0,1
          	syscall			#print pulses fired
          	li        	$v0,10
          	syscall			#terminate program
          
#------------------------------------------------------------#
#----------------------EVENT FUNCTIONS-----------------------#
#------------------------------------------------------------#
#
#   $a0 (passed into): x coord
#   $a1: y coord
#	

# Pulse Event
pulse:	andi	$a0,$s4,0x0000FF00	# mask event's x coord, pass as first param
	srl	$a0,$a0,8		# shift right 8 bits for use by _setLED
	andi	$a1,$s4,0x00FF0000	# mask event's y coord, pass as second param
	srl	$a1,$a1,16		# shift right 16 bits for use by _setLED
	beq	$a1,63,ini_pulse	# if pulse y coord == 63, no pulse LED to turn off
	jal	_getLED		# check LED at current position
	beq	$v0,3,collision	# if bug at current position, jump to collision handling
	move	$a2,$0		# set color param to off for previous position
	jal	_setLED		# turn LED off at current position
	beq	$a1,$0,oob		# if y coord == 0, skip to oob
ini_pulse: 	addi	$a1,$a1,-1		# check next y coord
	jal	_getLED		# check for collision with bug
	beq	$v0,3,collision	# if bug at next position, jump to collision handling
	li	$a2,1		# if not, pass 1 (red) as color parameter to _setLED
	jal	_setLED		# LED set at new position
	andi	$s4,$s4,0xFF00FFFF	# mask out previous y coord in event info to pass in updated y coord
	sll	$a1,$a1,16		# shift left 16 bits to or back into event info
	or	$s4,$s4,$a1		# or back into event info
	j	post_event

# Bug Event  
bug:	andi	$a0,$s4,0x0000FF00	# mask event's x coord, pass as first param
	srl	$a0,$a0,8		# shift right 8 bits for use by _setLED
	andi	$a1,$s4,0x00FF0000  	# mask event's y coord, pass as second param
	srl	$a1,$a1,16		# shift right 16 bits for use by _setLED
	li	$a2,0		# set color param off
	jal	_setLED		# turn LED off at current position
	beq	$a1,62,oob		# if y == 62, set bug as oob
	addi	$a1,$a1,1		# increment y coord
	li	$a2,3		
	jal	_setLED		# LED set at new position
	andi	$s4,$s4,0xFF00FFFF	# mask out previous y coord in event info to pass in updated y coord
	sll	$a1,$a1,16		# shift left 16 bits to or back into event info
	or	$s4,$s4,$a1		# or back into event info
	j	post_event	   
	   
	  	  
bug_spawn:  	move	$s1,$ra		# move $ra to caller into $s1
spawnloop:  	li	$a0,1		# load rng id used in seeding
	li	$a1,63		# set upper bound on int range
	li	$v0,42         	# generate random int range (returns in $a0)
	syscall
	move	$a1,$0		# set y coord to 0
	li	$a2,3		# set color to green
	move	$t9,$ra		# store $ra in $s1
	jal	_setLED
	move	$ra,$t9		# restore $ra
	move	$a1,$a0		# move random number to x coord param
	addi	$a0,$0,98		# move 98 (ascii value of b) into event type param
	sll	$a1,$a1,8		# shift $a1 left 8 bits for or-ing
	or	$a0,$a0,$a1		# or $a0 and $a1 for processing as one word
	move	$t9,$ra
	jal	_insert_q		# insert bug event into start of queue
	move	$ra,$t9		# restore $ra to caller
	addi	$t6,$t6,1		# increment spawn counter
	blt	$t6,3,spawnloop	# spawn atleast 3 bugs
	move	$s1,$0		# reset spawn accumulator
	li	$v0,30		# get current time
	syscall
	move	$k1,$a0	  	# set timestep
	jr	$ra

# Wave Event
wave:	andi	$a0,$s4,0x0000FF00	# mask x coord
	srl	$a0,$a0,8		# shift right 8 bits
	andi	$a1,$s4,0x00FF0000	# mask y coord
	srl	$a1,$a1,16		# shift right 16 bits
	andi	$t6,$s4,0xFF000000	# mask radius value
	srl	$t6,$t6,24		# shift right 24 bits
	beq	$t6,2,rad_1off		# if radius byte == 2, turn off rad_1 wave
	beq	$t6,3,rad_2off		# else if radius byte == 3, turn off rad_2 wave
	beq	$t6,4,clear_wave	# else if radius byte == 4, turn rad_3 wave off
	li	$a2,1		# else radius byte == 1, set color to red
	j	rad_1
rad_1off:	li	$a2,0		# if radius == 2, turn LED's from rad1 off
	# top left pulse
rad_1:	addi	$a0,$a0,-1
	addi	$a1,$a1,-1
	jal	_setLED
	# top middle pulse
	addi	$a0,$a0,1
	jal	_setLED
	# top right pulse
	addi	$a0,$a0,1
	jal	_setLED
	# middle left pulse
	addi	$a0,$a0,-2
	addi	$a1,$a1,1
	jal	_setLED
	# middle right pulse
	addi	$a0,$a0,2
	jal	_setLED
	# bottom left pulse
	addi	$a0,$a0,-2
	addi	$a1,$a1,1
	jal	_setLED
	# bottom middle pulse
	addi	$a0,$a0,1
	jal	_setLED
	# bottom right pulse
	addi	$a0,$a0,1
	jal	_setLED
	li	$a2,1	# set color param to red for rad_2 wave
	beq	$t6,2,rad_2	# if rad == 2, rad_1 wave turned off so turn on rad_2 wave
	j	wave_done
rad_2off:    	li	$a2,0	# if radius == 3, turn LED's from rad_2 off
	# top left pulse
rad_2:	addi	$a0,$a0,-2
	addi	$a1,$a1,-2
	jal	_setLED
	# top middle pulse
	addi	$a0,$a0,2
	jal	_setLED
	# top right pulse
	addi	$a0,$a0,2
	jal	_setLED
	# middle left pulse
	addi	$a0,$a0,-4
	addi	$a1,$a1,2
	jal	_setLED
	# middle right pulse
	addi	$a0,$a0,4
	jal	_setLED
	# bottom left pulse
	addi	$a0,$a0,-4
	addi	$a1,$a1,2
	jal	_setLED
	# bottom middle pulse
	addi	$a0,$a0,2
	jal	_setLED
	# bottom right pulse
	addi	$a0,$a0,2
	jal	_setLED
	li	$a2,1	# set color param to red for rad_2 wave
	beq	$t6,3,rad_3	# if rad == 3, rad_2 wave turned off so turn on rad_3 wave
	j	wave_done
rad_3off:	li	$a2,0	# if radius == 4, turn LED's from rad_3 off
	addi	$a0,$a0,-3
	addi	$a1,$a1,-3
	# top left pulse
rad_3:	addi	$a0,$a0,-3
	addi	$a1,$a1,-3
	jal	_setLED
	# top middle pulse
	addi	$a0,$a0,3
	jal	_setLED
	# top right pulse
	addi	$a0,$a0,3
	jal	_setLED
	# middle left pulse
	addi	$a0,$a0,-6
	addi	$a1,$a1,3
	jal	_setLED
	# middle right pulse
	addi	$a0,$a0,6
	jal	_setLED
	# bottom left pulse
	addi	$a0,$a0,-6
	addi	$a1,$a1,3
	jal	_setLED
	# bottom middle pulse
	addi	$a0,$a0,3
	jal	_setLED
	# bottom right pulse
	addi	$a0,$a0,3
	jal	_setLED
	beq	$t6,4,clear_wave	# if rad == 4, rad_3 wave turned off so clear wave event
	j	wave_done
wave_done:	addi	$t6,$t6,1		# wave completed, increment radius
	sll	$t6,$t6,24		# shift 24 bits left for oring
	andi	$s4,$s4,0x00FFFFFF	# mask out previous radius from event info
	or	$s4,$s4,$t6		# or in updated radius
	j	post_event
clear_wave:	li	$s4,0		# null wave event
	j	post_event

# When a bug/pulse reaches the end of it's range
oob:	 move	$s4,$0		# set event to null
	 j	post_event	
				
collision:  	  li	$a2,0		# turn LED off
	  jal	_setLED		
	  sll	$a0,$a0,8		# shift collision x coord left 8 bits
	  ori	$a0,$a0,0x00000062	# ori collision x coord into event data to search (0x62 == bug event type)
	  sll	$a1,$a1,16		# shift pulse y coord left 16 bits
	  or	$a0,$a0,$a1		# or pulse y coord into event data to search
	  jal	_search_q 		# search for event collided with
	  li	$t0,0		# initialize $t0 to 0
	  sw	$t0,0($v0)		# set bug event to null
	  ori	$a0,$a0,0x01000077	# or x coord with wave event of radius 1
	  or	$a0,$a0,$a1		# or y coord ""
	  move	$s4,$a0		# update event info with wave event
	  addi	$s5,$s5,1		# increment bugs killed count
	  j	post_event	
				
process_key: sw	$0,0xFFFF0000		# reset key pressed status
	   lw	$v0,0xFFFF0004		# load value of key pressed
	   sw	$0,0xFFFF0004		# reset value of key pressed
	   beq	$v0,0xE0,ukey	
	   beq	$v0,0xE1,quit	
	   beq	$v0,0xE2,lkey	
	   beq	$v0,0xE3,rkey	
	   beq	$v0,0x42,quit	
	   li	$v0,30		# get current time
	   syscall
	   move	$k1,$a0		# reset timestep
	   j	gameloop
ukey:        addi	$a0,$0,112		# put ascii value for 'p' into first parameter
         	   addi	$a1,$k0,0		# put current player x coord into second parameter
	   sll	$a1,$a1,8		
	   addi	$a2,$0,63		# put current player y coord into third parameter
	   sll	$a2,$a2,16
	   addi	$a3,$0,0		# put radius value into fourth parameter
	   sll	$a3,$a3,24
	   # Or all event data bytes into one word for easier insertion/removal	
	   or	$a0,$a0,$a1
	   or	$a0,$a0,$a2
	   or	$a0,$a0,$a3
	   jal	_insert_q		# insert pulse event into queue
	   addi	$s6,$s6,1		# increment pulses fired
	   j 	post_key
lkey:	   move	$a0,$k0		# keep current position
	   addi	$a1,$0,63		
	   addi	$a2,$0,0		# turn LED "off" at current position
	   jal	_setLED
	   beq	$a0,$0,left2right	# if player position = 0, switch over to right side
	   addi	$k0,$k0,-1		# update next position to the left
	   move	$a0,$k0		# pass updated x coord into _setLED
	   addi	$a1,$0,63		# pass y coord into _setLED
	   addi	$a2,$0,2		# turn LED "on" at updated positon
	   jal	_setLED
	   j	post_key
left2right:  addi	$k0,$k0,63
	   move	$a0,$k0		# pass updated x coord into _setLED
	   addi	$a1,$0,63		# pass y coord into _setLED
	   addi	$a2,$0,2		# turn LED "on" at updated positon
	   jal	_setLED
	   j	post_key
rkey:	   move	$a0,$k0		# keep current position
	   addi	$a1,$0,63	
	   addi	$a2,$0,0		# turn LED "off" at current position off
	   jal	_setLED
	   beq	$a0,63,right2left	# if player position = 63, switch over to left side
	   addi	$k0,$k0,1		# update next position to the right
	   move	$a0,$k0
	   addi	$a1,$0,63
	   addi	$a2,$0,2		# turn LED "on" at updated position
	   jal	_setLED
	   j	post_key
right2left:  move	$k0,$0		# set player x coord to 0
	   move	$a0,$k0		# pass 0 into x coord for _setLED
	   addi	$a1,$0,63		# pass y coord into _setLED
	   addi	$a2,$0,2		# turn LED "on" at updated positon
	   jal	_setLED
	   j	post_key
quit:	   j	gameover
	     
#------------------------------------------------------------#
#-----------------------DATA STRUCTURE-----------------------#
#-----------------------((  QUEUE  ))------------------------#
#------------------------------------------------------------#

# Insert Function
#
#    Insert event at start of queue
#
# $a0: event info
# $s2: start of queue
_insert_q: move	$t8,$ra		# move return address into $t8
	 move	$s4,$a0 		# move event info into $s4
	 move	$a0,$s2		# move start of queue into $a0 for oob checking
	 jal	check_oob_q
	 move	$s2,$v0		# move start of queue back into $s2
	 move	$ra,$t8		# move original return address back into $ra
	 move 	$a0,$s4		# move event info back into $a0	
	 sw	$a0,0($s2)		# push event to start of queue
	 addi	$s2,$s2,4		# increment start of queue
	 jr   	$ra		
	 			
# Remove Function			
#   				
#     Remove event at end of queue	
# 				
# a0: event info			
# s3: end of queue			
_remove_q: move	$t8,$ra		# move return address into $t8
	 move	$a0,$s3		# move end of queue into $a0 for oob checking
	 jal	check_oob_q	
	 move	$s3,$v0		# return end of queue
	 move	$ra,$t8		# move return address back into $ra
	 lw	$v0,0($s3)		# load event from end of queue
	 addi	$s3,$s3,4		# increment end of queue
	 jr	$ra	 
	 
# Search Function
#
#     Search for event in queue with specific parameters
#
# $a0: event info to find
# $v0: address of searched-for event
# 
_search_q:  	  move	$t0,$s3		# store end of queue is $t0
	  move	$t1,$s2		# store start of queue is $t1
searchloop: 	  beq	$t0,$t1,not_found	# if entry doesn't exist
	  lw	$t2,($t0)		# load word from end of queue in $t2
	  addi	$t0,$t0,4		# increment end of queue
	  bne	$t2,$a0,searchloop	# while matching event hasn't been found
	  addi	$t0,$t0,-4		# decrement end of queue (address of matching event)
	  move	$v0,$t0		# return address of matching event
	  jr	$ra
not_found:  	  move	$v0,$0		# set return value to 0
	  jr	$ra

# Check Out of Bounds Queue
#
#     Checks if an insert or remove will go beyond buffer allocated for queue
#
# $a0: address to check
#
# $v0: address post-check
check_oob_q: la	$t0,queue
	   addi	$t0,$t0,1024
	   beq	$a0,$t0,circle_back
	   move	$v0,$a0
	   jr	$ra
circle_back: addi	$v0,$a0,-1024
	   jr	$ra
	   
# Size Function
#   
#     Return number of events in queue
#
# $s2: start of queue
# $s3: end of queue
#
# $v0: size of queue
_size_q:   	 bgt	$s2,$s3,start_gt	# if start of queue is at a higher address than end of queue
	 bgt	$s3,$s2,end_gt		# if end of queue is at a higher address than start of queue	 
no_event:  	 move	$v0,$0
	 jr	$ra
start_gt:	 move	$t0,$s2		# move start of queue to $t0
	 move	$t1,$s3		# move end of queue to $t1
	 subu	$v0,$t0,$t1		# find bit difference between start of queue and end of queue
	 srl	$v0,$v0,2		# divide result by four to get number of elements
	 jr	$ra
end_gt:	 la	$t0,queue		# load starting address of buffer into $t0
	 addi	$t1,$t0,1024		# add 1024 to find the end of the buffer
	 sub	$t1,$t1,$s3		# subtract end of queue from end of buffer
	 move	$t2,$s2		# move start address to $t2
	 sub	$t0,$t2,$t0		# subtract beginning of buffer from start of queue
	 add	$v0,$t0,$t1		# add (end of buffer - end of queue) and (start of queue - start of buffer)
	 srl	$v0,$v0,2		# divide result by four to get number of elements
	 jr	$ra	 

#------------------------------------------------------------#
#------------------LED DISPLAY MANIPULATION------------------#
#------------------------------------------------------------#

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
	and	$t3,$t3,$t2   		# clear the field for the color
	or	$t3,$t3,$t1   		# set color field
	sb	$t3,0($t0)    		# update display
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
	sll  $t0,$a1,4      		# y * 16 bytes
	srl  $t1,$a0,2      		# x / 4
	add  $t0,$t0,$t1    		# byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    		# address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    		# remainder is bit position in byte
	neg  $t1,$t1        		# negate position for subtraction
	addi $t1,$t1,3      		# bit positions in reverse order
    	sll  $t1,$t1,1      		# led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    		# shift LED value to lsb position
	andi $v0,$t2,0x3    		# mask off any remaining upper bits
	jr   $ra
