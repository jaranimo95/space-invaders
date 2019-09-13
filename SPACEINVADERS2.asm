.data
queue:	.space 1024
strBugs:	.asciiz	"The game score is "
strColon:	.asciiz " : "
.text
beforeStart:
	lw $t0, 0xFFFF0000
	bne $t0, 1, beforeStart
	lw $t1, 0xFFFF0004
	bne $t1, 0x42, beforeStart
#set time reference
li $s6, 0
la $s0, queue	#start point
la $s1, queue	#endpoint
li $a0, 32
li $a1, 63
li $a2, 2
jal setLED
li $k0, 0	#counter for # of hits
li $t8, 32		#HOLDS BUG BUSTER X
li $t9, 0
li $v0, 30
li $t7, 0	#total time passed
syscall
move $s7, $a0
sw $zero, 0xFFFF0000	
j moreBugz	
timeLoop:
	li 	$v0, 30
	syscall
	subu 	$s7, $a0, $s7
	addu 	$s6, $s7, $s6
	addu 	$t7, $s7, $t7
	addu 	$t9, $s7, $t9
	li 	$v0, 30
	syscall
	move 	$s7, $a0
	lw 	$s4, 0xFFFF0000
	beq 	$s4, 1, keyPressed
	loopBug:
	bgeu 	$s6, 3000, moreBugz
	loopAdv:
	bgeu 	$t9, 100, ADVANCE
	bgeu 	$t7, 120000, GAMEOVER
	j 	timeLoop

keyPressed:
	bgeu 	$s6, 100, updateTime
	j 	timeLoop
	updateTime:
		
		sw 	$zero, 0xFFFF0000
		lw 	$t0, 0xFFFF0004
		sw 	$zero, 0xFFFF0004
		beq	$t0, 0xE0, up
		beq 	$t0, 0xE1, down
		beq 	$t0, 0xE2, left
		beq 	$t0, 0xE3, right
		li 	$v0, 30
		syscall
		move 	$s7, $a0
		j 	timeLoop


up:
	addiu $k1, $k1, 1
	li 	$a0, 1
	move 	$a1, $t8
	li 	$a2, 62
	li 	$a3, 0 
	jal	insert
	j 	loopAdv
	
down:
	j GAMEOVER


left:
	move 	$a0, $t8
	li 	$a1, 63
	li 	$a2, 0
	jal 	setLED
	subiu 	$t8, $t8, 1
	bgt 	$t8, 65, setToRight
	busterResetLeft:
	move 	$a0, $t8
	li 	$a2, 2
	jal 	setLED
	j 	loopAdv
	setToRight:
	li $t8, 63
	j busterResetLeft

right:
	move 	$a0, $t8
	li 	$a1, 63
	li 	$a2, 0
	jal 	setLED
	addiu 	$t8, $t8, 1
	bgt $t8, 63, setToLeft
	busterResetRight:
	move 	$a0, $t8
	li 	$a2, 2
	jal 	setLED
	j 	loopAdv
	setToLeft:
	li $t8, 0
	j busterResetRight

midKey:

	j GAMEOVER

ADVANCE:
	#li $v0, 30
	#syscall
	#move $s7, $a0
	li 	$t9, 0
	jal 	length
	move 	$s5, $v0
	li 	$s3, 0
	advancingLoop:
		jal 	remove
		jal 	checkType
		addiu 	$s3, $s3, 1
		bne 	$s3, $s5, advancingLoop
		j 	timeLoop
checkType:
	move 	$t0, $v0
	andi 	$t0, $t0, 0x3
	beq 	$t0, 0, bugWork
	beq 	$t0, 1, phaseWork
	beq 	$t0, 2, waveWork
	beq 	$t0, 3, GAMEOVER
	jr 	$ra
 
remove:
	la 	$t0, queue
	addiu 	$t0, $t0, 1024
	move 	$t1, $ra
	jal 	checkEnd
	move 	$ra, $t1
	lw 	$v0, ($s1)
	sw 	$zero, ($s1)
	#li $t0, 4
	#sb $t0, 3($s1)
	addiu 	$s1, $s1, 4
	#lbu $v1, ($s1)
	#addiu $s1, $s1, 4
	#sb $zero, ($s1)
	
	jr 	$ra



length:
	beq 	$s0, $s1, noLength
	bgt 	$s0, $s1, endFirst
	endLast:
		la 	$t2, queue
		addiu	$t3, $t2, 1024
		subu 	$v1, $s0, $t2
		subu 	$v0, $t3, $s1
		addu 	$v0, $v0, $v1
		j 	endL
	endFirst:
		subu 	$v0, $s0, $s1
	endL:
		divu 	$v0, $v0, 4
		jr   	$ra
	noLength:
		li 	$v0, 0
		jr 	$ra


moreBugz:
	
	li 	$s3, 0
	subiu 	$sp, $sp, 4
	sw 	$ra, ($sp)
	bugloop:
		li 	$v0, 42
		li 	$a0, 4
		li 	$a1, 63
		syscall
		li 	$a1, 0
		li 	$a2, 3
		jal 	setLED
		move 	$a1, $a0	#now a1 stores random x for bug to start
		li 	$a0, 0	#bug event type
		li 	$a2, 0	#new bugs are at y=0
		li 	$a3, 0	#radius for bugs =0
		jal 	insert
		addiu 	$s3, $s3, 1
		bne 	$s3, 2, bugloop
	lw 	$ra, ($sp)
	addiu 	$sp, $sp, 4
	li 	$v0, 30
	syscall
	move 	$s7, $a0
	li 	$s6, 0	
	j 	timeLoop




insert:		#a0 = event type, $a1 = x, $a2 = y, $a3 = radius
	subiu 	$sp, $sp, 4
	sw 	$ra, ($sp)
	la 	$t1, queue
#	move $t3, $a0
	addiu 	$t1, $t1, 1024
	subu 	$t0, $t1, $s0 	#check start pos.
	jal 	checkStart
	sb 	$a0, ($s0)
	#ble $t0, 2, resetStart
	sb 	$a1, 1($s0)
	#ble $t0, 3, resetStart
	sb 	$a2, 2($s0)
	#ble $t0, 4, resetStart
	sb 	$a3, 3($s0)
	addiu 	$s0, $s0, 4
	######FIXENDING!!!
	lw 	$ra, ($sp)
	addiu 	$sp, $sp, 4
	jr 	$ra 


checkStart:
	bltu 	$t0, 4, resetStart
	jr 	$ra
	resetStart:
		la 	$s0, queue
		jr 	$ra
checkEnd:
	ble 	$t0, $s1, resetEnd
	jr 	$ra	
	resetEnd:
		la $s1, queue
		jr $ra







bugWork:	#v0 holds bug
	subiu $sp, $sp, 8
	sw $v0, ($sp)	#put bug in stack!
	sw $ra, 4($sp)	
	#sw $v1, 8($sp)	#store event type to make sure bug event isn't misinterpreted
	lbu $a0, 1($sp)	#a0 holds x
	lbu $a1, 2($sp)	#a1 holds y
	#beq $a1, 0, newBug
	jal getLED
	beq $v0, 1, bugKilled
	li $a2, 0
	jal setLED
	lbu $a0, 1($sp)	#restore just in case!
	lbu $a1, 2($sp)
	addiu $a1, $a1, 1	#incrementing y creates new bug 
	bge $a1, 62, bugDone
	jal getLED
	beq $v0, 1, bugKilled
	#beq $v0, 2, bugKilled
	sb $a1, 2($sp)
	#lw $v0, ($sp)
	#lbu $a0, 1($sp)
	#lbu $a1, 2($sp)
	#newBug:
	li $a2, 3
	jal setLED
	li $a0, 0
	lbu $a1, 1($sp)
	lbu $a2, 2($sp)
	li $a3, 0
	jal insert
	bugDone:
	lw $v0, ($sp)
	lw $ra, 4($sp)
	addiu $sp, $sp, 8
	jr $ra
	bugKilled:
		#jal DestroyIFphaser
		addiu $k0, $k0, 1
		lw	$ra, 4($sp)
		lw 	$v0, ($sp)
		addiu 	$sp, $sp, 8
		move 	$a2, $a1
		move 	$a1, $a0
		li 	$a0, 2
		li 	$a3, 0
		j 	insert





search:				#a0 holds x, a1 holds y
	subiu $sp, $sp, 4
	sw $ra, ($sp)
	#sw $v0, 4($sp)
	jal length
	la $t0, ($s1)
	la $t4, queue
	addiu $t4, $t4, 1024
	li $t6, 0
	srchLoop:
		lbu $t1, 1($t0)	#holds test x
		lbu $t2, 2($t0) #holds test y
		addiu $t6, $t6, 1
		bge $t6, $v0, endSrchFail
		beq $t1, $a0, sameX
		bge $t4, $t0, resetSrchStr
		addiu $t0, $t0, 4
		j srchLoop
	sameX:
		beq $t2, $a1, endSrchSuccess
		j srchLoop
	resetSrchStr:
		la $t0, queue
		j srchLoop
	endSrchFail:
		li $v0, 100
		j endSrch
	endSrchSuccess:
		la $v0, ($t0)
	endSrch:
		lw $ra, ($sp)
		#lw $v0, 4($sp)
		addiu $sp, $sp, 4
		jr $ra

#DestroyIFphaser:	#Make sure a0 is x and a1 is y
#subiu $sp, $sp, 12
#sw $ra, ($sp)
#sw $t0, 4($sp)
#sw $t1, 8($sp)
#jal search
#bne $v0, 100, checkIfPhase
#destroyedPhaser:
#lw $ra, ($sp)
#lw $t0, 4($sp)
#lw $t1, 8($sp)
#addiu $sp, $sp, 12
#jr $ra
#checkIfPhase:
#lbu $t0, ($v0)
#beq $t0, 1, phaseRemove
#j destroyedPhaser
#phaseRemove:
#sw $zero, ($v0)
#li $t1, 4
#sb $t1, ($v0)
#j destroyedPhaser


	# void _setLED(int x, int y, int color)
	#   sets the LED at (x,y) to color
	#   color: 0=off, 1=red, 2=yellow, 3=green
	#
	# arguments: $a0 is x, $a1 is y, $a2 is color
	# trashes:   $t0-$t3
	# returns:   none
	#
setLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      # y * 16 bytes
	srl	$t1,$a0,2      # x / 4
	add	$t0,$t0,$t1    # byte offset into display
	li	$t2,0xffff0008 # base address of LED display
	add	$t0,$t2,$t0    # address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    # remainder is led position in byte
	neg	$t1,$t1        # negate position for subtraction
	addi	$t1,$t1,3      # bit positions in reverse order
	sll	$t1,$t1,1      # led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3		
	sllv	$t2,$t2,$t1
	not	$t2,$t2        # bit mask for clearing current color
	sllv	$t1,$a2,$t1    # bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     # read current LED value	
	and	$t3,$t3,$t2    # clear the field for the color
	or	$t3,$t3,$t1    # set color field
	sb	$t3,0($t0)     # update display
	jr	$ra
	
	# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0, 1, 2 or 3)
	#
getLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
	jr   $ra
				
		

GAMEOVER:	#notenough!
	la $a0, strBugs
	li $v0, 4
	syscall
	move $a0, $k0
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, strColon
	syscall
	li $v0, 1
	move $a0, $k1
	syscall
	li $v0, 10
	syscall
	#FINISH
waveWork:
	subiu $sp, $sp, 16
	sw $v0, ($sp)
	sw $ra, 4($sp)
	sw $s5, 8($sp)
	sw $s3, 12($sp)
	lbu $a3, 3($sp)	#holds radius 
	li $s3, 0
	li $a2, 0
	lbu $s4, 1($sp)	#x
	lbu $s5, 2($sp)	#y
	#SETTING OLD WAVE LEDs TO BLACK
	move $a0, $s4
	addu $a1, $s5, $a3
	bgeu $a1, 62, theTop
	jal setLED
	beqz $a3, newWave
	#jal waveInBounds
	theTop:
	subu $a1, $s5, $a3
	bgeu $a1, 65, midRight
	bleu $a1, 0, midRight
	jal setLED
	#jal waveInBounds
	midRight:
	move $a1, $s5
	addu $a0, $s4, $a3 #midright
	bgeu $a0, 63, midLeft
	jal setLED
	#jal waveInBounds
	midLeft:
 	subu $a0, $s4, $a3 #midleft
 	bgeu $a0, 65, topRight
 	bleu $a0, 0, topLeft
 	jal setLED
 	#jal waveInBounds
 	topLeft:
 	subu $a1, $s5, $a3 #topleft
 	bgeu $a1, 65, bottomRight
 	bleu $a1, 0, topRight
 	jal setLED
 	#jal waveInBounds
 	topRight:
 	addu $a0, $s4, $a3 #topright
 	#jal waveInBounds
 	bgeu $a0, 63, bottomRight
 	jal setLED
 	bottomRight:
 	addu $a1, $s5, $a3 #bottomright
 	#jal waveInBounds
 	bgeu $a1, 63, bottomLeft
 	jal setLED
 	bottomLeft:
 	subu $a0, $s4, $a3 #bottomleft
 	bleu $a0, 0, afterReset
 	bgeu $a0, 65, afterReset
 	jal setLED
 	#ALL SET, now extend radius if wave exists
 	afterReset:
 	beq $a3, 10, waveMax
 	newWave:
 	addiu $a3, $a3, 1
 	li $a2, 1
 	move $a0, $s4
 	addu $a1, $s5, $a3
 	bgeu $a1, 62, nTopMid
 	jal setLED
 	#jal waveInBounds
 	nTopMid:
 	subu $a1, $s5, $a3
 	#jal waveInBounds
 	bgeu $a1, 65, nMidRight
 	bleu $a1, 0, nMidRight
 	jal setLED
 	nMidRight:
 	move $a1, $s5
	addu $a0, $s4, $a3 #midright
	bgeu $a0, 63, nMidLeft
	jal setLED
	#jal waveInBounds
	nMidLeft:
 	subu $a0, $s4, $a3 #midleft
 	bgeu $a0, 65, nTopRight
 	bleu $a0, 0, nTopLeft
 	jal setLED
 	#jal waveInBounds
 	nTopLeft:
 	subu $a1, $s5, $a3 #topleft
 	bleu $a1, 0, nTopRight
 	bgeu $a1, 65, nTopRight
 	jal setLED
 	#bltz $a1, tooHigh
 	#jal waveInBounds
 	nTopRight:
 	addu $a0, $s4, $a3 #topright
 	bgeu $a1, 65, nBottomRight
 	bgeu $a0, 63, nBottomRight
 	jal setLED
 	#jal waveInBounds
 	nBottomRight:
 	addu $a1, $s5, $a3 #bottomright
 	bgeu $a1, 62, waveIns
 	jal setLED
 	#jal waveInBounds
 	nBottomLeft:
 	subu $a0, $s4, $a3 #bottomleft
 	#jal waveInBounds
 	bgeu $a0, 65, waveIns
 	bleu $a0, 0, waveIns
 	jal setLED
 	waveIns:
 	move $a2, $s5
 	move $a1, $s4
 	li $a0, 2
 	jal insert
 	waveMax:
 		lw $v0, ($sp)
 		lw $ra, 4($sp)
 		lw $s5, 8($sp)
 		lw $s3, 12($sp)
 		addiu $sp, $sp, 16
 		jr $ra
 	checkBugHit:
 		beq $v0, 3, hitBug
 		jr $ra
 	hitBug:
 	 	subiu $sp, $sp, 4
 	 	sw $ra, ($sp)
 	 	addiu $k0, $k0, 1
 		jal search
 		beq $v0, 100, dontStore
 		sw $zero, ($v0)
 		li $t5, 4
 		sb $t5, ($v0)
 		dontStore:
 		move $a2, $a1
 		move $a1, $a0
 		li $a0, 2
 		li $a3, 0
 		jal insert
 		lw $ra, ($sp)
 		addiu $sp, $sp, 4
 		#addiu $ra, $ra, 4
 		jr $ra
 		
 		
 		
 	#waveInBounds:
 	#	blt $a0, 63, step2
 	#	jr $ra
 	#	step2:
 	#	bgt $a0, 0, step3
 	#	jr $ra
 	#	step3:
 	#	blt $a1, 62, step4
 	#	jr $ra
 	#	step4:
 	#	bgt $a1, 0, valOk
 	#	jr $ra
 	#	valOk:
 	#	bnez $s3, secondWav
 	#	j setLED
 	#	secondWav:
 	#	subiu $sp, $sp, 4
 	#	sw $ra, ($sp)
 	#	jal getLED
 	#	jal checkBugHit
 	#	lw $ra, ($sp)
 	#	addiu $sp, $sp, 4
 	#	j setLED
 		
 
 		
 		
phaseWork:
	subiu $sp, $sp, 8
	sw $ra, 4($sp)
	sw $v0, ($sp)
	lbu $a0, 1($sp)	# x coordinate of phaser
	lbu $a1, 2($sp) # y coordinate of phaser
	li $a2, 0
	jal setLED
	jal getLED
	beq $v0, 3, phaserContact
	subiu $a1, $a1, 1
	blez $a1, endPhase
	li $a2, 1
	jal setLED
	jal getLED
	beq $v0, 3, phaserContact
	move $a2, $a1
	move $a1, $a0
	li $a0, 1
	li $a3, 0
	jal insert
	j endPhase
	phaserContact:	
		jal checkBugHit
	endPhase:
		lw $ra, 4($sp)
		lw $v0, ($sp)
		addiu $sp, $sp, 8
		jr $ra
