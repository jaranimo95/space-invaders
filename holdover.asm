


pulse:	  andi	$a0,$s4,0x0000FF00	# mask event's x coord, pass as first param
	  srl	$a0,$a0,8		# shift right 8 bits for use by _setLED
	  andi	$a1,$s4,0x00FF0000	# mask event's y coord, pass as second param
	  srl	$a1,$a1,16	# shift right 16 bits for use by _setLED
	  beq	$a1,62,ret_pulse	# if y coord == 62, skip to setting the LED at it's position
	  addi	$a1,$a1,1		# move to previous position
	  move	$a2,$0		# set color param to off for previous position
	  jal	_setLED
	  addi	$a1,$a1,-1	# return y coord to current position
ret_pulse:  addi	$a2,$0,1		# pass 1 (red) as third parameter
	  jal	_setLED
	  beq	$a1,$0,pulse_oob	# if y coord == 0, skip to pulse_oob
	  addi	$a1,$a1,-1	# decrement y coord
	  jal	_getLED		# check for collision with bug
	  beq	$v0,3,bug_hit	# if bug at net position, jump to collision
	  andi	$s4,$s4,0xFF00FFFF	# mask out previous y coord in event info to pass in updated y coord
	  sll	$a1,$a1,16	# shift left 16 bits to or back into event info
	  or	$s4,$s4,$a1	# or back into event info
	  j	post_event
pulse_oob: move	$a2,$0		# set color param to off for previous position
	 jal	_setLED
	 j	oob

bug:	  andi	$a0,$s4,0x0000FF00	# mask event's x coord, pass as first param
	  srl	$a0,$a0,8		# shift right 8 bits for use by _setLED
	  andi	$a1,$s4,0x00FF0000  # mask event's y coord, pass as second param
	  srl	$a1,$a1,16	# shift right 16 bits for use by _setLED
	  #jal	_getLED		# check if bug already spawned at x coord
	  #beq	$v0,3,reroll	#     change bug's x coord if so
	  beq	$a1,$0,ret_bug	# if the bug's y coord == 0, skip turning off LED at position-1
	  addi	$a1,$a1,-1	#    else move to previous position
	  move	$a2,$0		# set color param to off for previous position
	  jal	_setLED
	  addi	$a1,$a1,1		# return y coord to current position
ret_bug:    beq	$a1,63,oob	# if bug reaches end of display, set it's type as 0
	  addi	$a2,$0,3		# pass 1 (green) as third parameter
	  jal	_setLED
	  addi	$a1,$a1,1		# increment y coord
	  andi	$s4,$s4,0xFF00FFFF	# mask event info to pass in updated y coord
	  sll	$a1,$a1,16	# shift left 16 bits to or back into event info
	  or	$s4,$s4,$a1	# or back into event info
	  j	post_event	# return to bug function
 beq	$a1,$0,checked	# if non-duplicate, turn on LED at coordinates
	   beq	$v0,1,pulse_hit	# if pulse at next position, jump to collision handling
	   move	$a2,$0		# set color param to off for previous position
	   jal	_setLED		# turn LED off at current position
	   beq	$a1,62,oob	# if y coord == 62, skip to oob
	   addi	$a1,$a1,1		# check next y coord
	   jal	_getLED		# check for collision with pulse
	   addi	$a2,$0,3		# if not, pass 3 (green) as color parameter to _setLED
	   jal	_setLED		# LED set at new position



# When pulse hits bug	  	  	  
bug_hit:	  sll	$a0,$a0,8		# shift collision x coord left 8 bits
	  ori	$a0,$a0,0x00000062	# ori collision x coord into event data to search (0x62 == bug event type)
	  sll	$a1,$a1,16	# shift pulse y coord left 16 bits
	  or	$a0,$a0,$a1	# or pulse y coord into event data to search
	  j	collision
# When bug hits pulse
pulse_hit:  sll	$a0,$a0,8		# shift bug x coord left 8 bits
	  ori	$a0,$a0,0x00000070	# ori bug x coord into event data to search (0x70 == pulse event type)
	  sll	$a1,$a1,16	# shift bug y coord left 16 bits
	  or	$a0,$a0,$a1	# or bug y coord into event data to search
collision:  jal	_search_q 	# search for event collided with
	  beq	$v0,$0,post_event	# if nothing found, false reading. move to next event
	  move	$s4,$a0		# move updated pulse event back into $s4
	  andi	$a0,$s4,0x0000FF00	# mask x coord to pass into _setLED
	  srl	$a0,$a0,8		
	  andi	$a1,$s4,0x00FF0000	# mask y coord to pass into _setLED
	  srl	$a1,$a1,16
	  move	$a2,$0		# set color param to off
	  jal	_setLED
	  addi	$t0,$0,0x78	# set $t0 to kill event type (0x78 == 'x')
	  sb	$t0,0($v0)	# save $t0 to event type of bug event hit
	  andi	$s4,$s4,0xFFFFFF00  # mask out event type
	  ori	$s4,$s4,0x00000077	# or $s4 to set event type to wave event
	  j	post_event	
