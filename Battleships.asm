# Unit Width = 32, Unit Height = 32, Display Width = 512, Display Height = 512 (16x16 board)
# Base address for display 0x10008000 ($gp)
.data
	screen:			.word	0x10008000	# start of screen
	lightBlue:		.word	0x004876FF	# lighter blue hex
	darkBlue:		.word	0x004169E1	# darker blue hex
	black:			.word	0x00212F3D	# black
	green:			.word	0x001E8449	# green
	red:			.word	0x00922B21	# red
	lightGreen:		.word	0x00BFC9CA	# light green
	
	battleshipBoardStart:	.word	0x10008110	# start of battle portion of board
	playerIndicatorStart:	.word	0x10008180	# start of player indicator portion of battle screen
	placeIndicatorStart:	.word	0x100081B0	# start of placing indicator portion of battle screen
	fireIndicatorStart:	.word	0x100081B0	# start of placing indicator portion of battle screen
	key:			.word	0xffff0004	# keyboard start
	p1ShipsMem:		.space	48		# space for placing p1Ships
	p1ShipSize:		.word	12		# amount of bits on bitmap used for p1's ships
	p2ShipsMem:		.space	48		# space for placing p2Ships	
	p2ShipSize:		.word	12		# amount of bits on bitmap used for p2's ships	
	p1BoardStart:		.word	0x10008110	# used to redraw p1's board after p1's ships have been placed
	p2BoardStart:		.word	0x10008210	# used to redraw p2's board after p2's ships have been placed	
.text

# Draw welcome screen, pause for 2 seconds, draw battle screen.... Go time!
main:
	jal	drawWelcomeScreen
	jal	sleepScreen2Sec
	jal	drawGameScreen
	
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
#---------------------------------P1 and P2 SHIP PLACEMENT---------------------------#
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
   
# $s0 = counter for ships size
# $s1 = memory allocation for holding array position of ships
# $s2 = used to switch to player 2 initialization when player 1 is done placing ships
# $s3 = keyboard input
# $s4 = holds previous value to repaint when moving cursor
# $s5 = used to branch to either p1's or p2's array for placing positions of ships (0 = p1, 1 = p2)
# $s6 = used to alternate player indicator

# Used once to give $s6 the value to change the indicator to p1's turn
# Initializes $t5 to 0 which is used to determine where to put the cursor after firing and missing
p1FireInit:
	jal	initCursorBoundaries
	addi	$s6, $zero, 1				# start at player 1 indicator

# Initializes the counters and memory for p1 placing ships
p1ShipsInit:
	jal	p1TurnIndicator
	jal	placeIndicator
	lw	$s0, p1ShipSize				# stores integer 12 into $s0 to keep track of how many ships the player has placed
	la	$s1, p1ShipsMem				# allocates the amount of memory (12x4 so 48) to $s1
	li	$s2, 0					# counter while placing ships (when $s2 = 12 we switch to p2Ships)
	li	$s5, 0					# used in placeShips to determine who is placing ships (0 = p1, 1 = p2)
	
	j	initialPositionOfKeyboardP1Placing

# Redraws p1's portion of the board after they have placed their ships		
redrawForP2:
	jal	initCursorBoundaries
	jal	redrawP1PortionOfBoard
	
	j	p2ShipsInit	
	
# Initializes the counters and memory for p2 placing ships
p2ShipsInit:
	jal	p2TurnIndicator
	lw	$s0, p2ShipSize				# stores integer 12 into $s0 to keep track of how many ships the player has placed
	la	$s1, p2ShipsMem				# allocates the amount of memory (12x4 so 48) to $s1
	li	$s2, 0					# counter while placing ships (when $s2 = 12 we switch to attacking ships)
	li	$s5, 1					# used in placeShips to determine who is placing ships (0 = p1, 1 = p2)
	
	j	initialPositionOfKeyboardP2Placing
	
# Used once to initialize the attacking to start at player 1 and also redraws p2's board to original to get rid of ship placements
p1Turn:
	jal	initCursorBoundaries
	li	$a1, 1					# so that we jump to userInputFire from now on instead of userInputPlacing
	li	$t5, 2					# used as a counter to indicate where to start the keyboard (p1 or p2) after attacking
	li	$s2, 0					# finished using s2 for placing ships, now used as a counter for p1's ships it hit
	li	$s5, 0					# finished using s1 for placing ships, now used as a counter for p2's ships it hit
	jal	redrawP2PortionOfBoard
	jal	p1TurnIndicator
	jal	fireIndicator	
	
	j	initialPositionOfKeyboardP2Fire
	
# Set cursor to top left position of p1's side of the board
initialPositionOfKeyboardP1Placing:
	lw	$t0, p1BoardStart			# start of Battleship board for p1	
	lw	$s4, ($t0)				# load original color at top left position of battleboard into $s4
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# color current position in memory to green
	
	j	userInputPlacing
	
# Set cursor to top left position of p1's side of the board
initialPositionOfKeyboardP2Placing:
	lw	$t0, p2BoardStart			# start of Battleship board for p2	
	lw	$s4, ($t0)				# load original color at top left position of battleboard into $s4
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# color current position in memory to green
	
	j	userInputPlacing	
	
# Set cursor to top left position of p1's side of the board
initialPositionOfKeyboardP1Fire:
	lw	$t0, p1BoardStart			# start of Battleship board for p1	
	lw	$s4, ($t0)				# load original color at top left position of battleboard into $s4
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# color current position in memory to green
	
	j	userInputFire
	
# Set cursor to top left position of p1's side of the board
initialPositionOfKeyboardP2Fire:
	lw	$t0, p2BoardStart			# start of Battleship board for p2	
	lw	$s4, ($t0)				# load original color at top left position of battleboard into $s4
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# color current position in memory to green
	
	j	userInputFire		
		
# Takes in user input from the keyboard while constantly looping to wait for input
# NOTE: CURRENTLY CRASHING HERE AFTER ABOUT 10 SECONDS OF RUNNING LOOP
userInputPlacing:
	li	$a0, 1000				# used for buffer
	lw	$s3, key				# loads keyboard address
	lw	$s3, ($s3)				# loads key from memory	
	beq	$s3, 0x00000064, cursorRight		# lowercase d in hex
	beq	$s3, 0x00000061, cursorLeft		# lowercase a in hex
	beq	$s3, 0x00000073, cursorDown		# lowercase s in hex
	beq	$s3, 0x00000077, cursorUp		# lowercase w in hex
	beq	$s3, 0x00000070, placeShip		# spacebar in hex
	
	j	bufferPlace	
	
# Buffer when placing (prevents crashing)	
bufferPlace:
	subi	$a0, $a0, 1
	bgtz	$a0, bufferPlace
	j	userInputPlacing	
	
# We just go to this input when firing because we do not want to be able to place ships during this stage
userInputFire:
	li	$a0, 1000				# used for buffer
	lw	$s3, key				# loads keyboard address
	lw	$s3, ($s3)				# loads key from memory	
	beq	$s3, 0x00000064, cursorRight		# lowercase d in hex
	beq	$s3, 0x00000061, cursorLeft		# lowercase a in hex
	beq	$s3, 0x00000073, cursorDown		# lowercase s in hex
	beq	$s3, 0x00000077, cursorUp		# lowercase w in hex
	beq	$s3, 0x00000066, alternateFire		# lowercase f in hex
	
	j	bufferFire

# Buffer when firing (prevents crashing)		
bufferFire:
	subi	$a0, $a0, 1
	bgtz	$a0, bufferFire
	j	userInputFire

# Move cursor right (d on keyboard)
cursorRight:
	addi	$a2, $a2, 1				# move right, increment ycoord by 1
	jal	cursorBoundaries			# check and see if the requested movement is OB
	sw	$s4, ($t0)				# restore original color
	addi	$t0, $t0, 4				# jump to next address (forward 1 bit on bitmap)
	lw	$s4, ($t0)				# load current color at memory address into $s4
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# load $t2 into current address
	
	j	resetInput

# Move cursor left (a on keyboard)	
cursorLeft:
	addi	$a2, $a2, -1				# move left, decrement ycoord by 1
	jal	cursorBoundaries			# check and see if the requested movement is OB
	sw	$s4, ($t0)				# restore original color
	addi	$t0, $t0, -4				# jump to next address (back 1 bit on bit map)
	lw	$s4, ($t0)				# load current color at memory address into $s4 (we do this so that we can repaint back to orginal color after if we move cursor)
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# load $t2 into current address
	
	j	resetInput

# Move cursor down (s on keyboard)
cursorDown:
	addi	$a3, $a3, 1				# move down, increment xcoord by 1
	jal	cursorBoundaries			# check and see if the requested movement is OB
	sw	$s4, ($t0)				# restore original color
	addi	$t0, $t0, 64				# jump to next address (down a full row)
	lw	$s4, ($t0)				# load current color at memory address into $s4 (we do this so that we can repaint back to orginal color after if we move cursor)
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# load $t2 into current address
	
	j	resetInput
	
# Move cursor up (w on keyboard)
cursorUp:
	addi	$a3, $a3, -1				# move up, decrement xcoord by 1
	jal	cursorBoundaries			# check and see if the requested movement is OB
	sw	$s4, ($t0)				# restore original color
	addi	$t0, $t0, -64				# jump to next address (up a full row)
	lw	$s4, ($t0)				# load current color at memory address into $s4 (we do this so that we can repaint back to orginal color after if we move cursor)
	lw	$t2, green				# load green into $t2
	sw	$t2, ($t0)				# load $t2 into current address
	
	j	resetInput
							
# Place ship (spacebar on keyboard)
# Indicates ship is being placed and determines which player is currently placing the ship
placeShip:
	jal	validShipPlacement
	lw	$s4, green				# color square green and leave it green so player can see where they placed
	lw	$s3, key				# load key into $s3
	sw	$zero, ($s3)				# make value of key zero (so that the keyboard doesnt constantly assume we are inputting thus constantly moving a repainting)
	beq	$s5, 1, p2PlaceShip			# when p1 has placed their ships, p2Init will be run and will initialize $s5 to 1 thus switching to p2Ships placement

	j	p1PlaceShip	
	
# Place ship into p1's array
p1PlaceShip:
	sw	$t0, ($s1)				# load current position into player 1's array of ship positions
	addi	$s1, $s1, 4				# increment to next memory position
	addi	$s2, $s2, 1				# increment counter
	beq	$s2, $s0, redrawForP2			# after 12 iterations branch to p2
	
	j	userInputPlacing

# Place ship into p2's array
p2PlaceShip:
	sw	$t0, ($s1)				# load current position into player 1's array of ship positions
	addi	$s1, $s1, 4				# increment to next memory position
	addi	$s2, $s2, 1				# increment counter
	beq	$s2, $s0, p1Turn			# after 12 iterations branch to p1 turn indicator for attacking
	
	j	userInputPlacing
				
# Resets the keyboard input to avoid replicating input
resetInput:
	lw	$s3, key				# load key into $s3
	sw	$zero, ($s3)				# make value of key zero (so that the keyboard doesnt constantly assume we are inputting thus constantly moving a repainting)

	beq	$a1, 1, userInputFire			# we initialize $t6 to 1 when we enter the attacking phase so we know when t6 is 1 we can jump to fire input
	beq	$t6, 0, userInputPlacing		# t6 is default 0 so we are initially jumping user placing as desired at the beginning					
			
	j	exit					# should not get here, bug if we do
	
# Checks if current position to be placed has already been placed
# If so it jumps back to resetInputOBPlacing (which places it in top left position) for the player to attack again	
validShipPlacement:
	lw	$t2, green				# load green into t2
	beq	$s4, $t2, resetInputOB			# if original color of the square (which is covered by green cursor) is green (which means placed already) then just jump back to input
	
	jr	$ra	
	
# Checks if the current position to be attacked has already been attacked
# If so it jumps back to resetInputOBPlacing (which places it in top left position) for the player to attack again	
validFire:
	lw	$t2, red				# load red in t2
	beq	$s4, $t2, resetInputPrevAttacked	# if original color of the square (which is covered by green cursor) is red (which means hit already) then just jump back to input
	
	jr	$ra	
		
# If the cursor will go into OB territory if input is executed then we jump back to original starting position 
# while also repainting the original color of the square before we went OB
# We must also reset initPlaceBoundaries so that the counters are correct
# Input from keyboard is also reset							
resetInputOB:
	jal	initCursorBoundaries
	lw	$s3, key				# load key into $s3
	sw	$zero, ($s3)				# make value of key zero (so that the keyboard doesnt constantly assume we are inputting thus constantly moving a repainting)
		
	sw	$s4, ($t0)				# repaint original color of square we were at when we went OB
		
	beq	$t5, 2, initialPositionOfKeyboardP2Fire	# t5 = 2 when its p2's attacking turn (it happens below in attack section)
	beq	$t5, 3, initialPositionOfKeyboardP1Fire	# t5 = 3 when its p1's attacking turn
		
	beq	$s5, 1, initialPositionOfKeyboardP2Placing	# $s5 = 1 when we initialize P2ships so that when we know to go to P2's initial start
	beq	$s5, 0, initialPositionOfKeyboardP1Placing	# $s5 = 0 when we initialize P1ships and doesnt change to 1 until P1 is done placing ships
		
	j	exit					# bug if we get here	
																																
# Checks to see if cursor moved out of bounds
cursorBoundaries:
	beq	$a2, -1, resetInputOB			# xcoord OB left side
	beq	$a2, 8, resetInputOB			# xcoord OB right side
	beq	$a3, -1, resetInputOB			# ycoord OB top side
	beq	$a3, 4, resetInputOB			# ycoord OB bottom side
																																																																																														
	jr	$ra

#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
#---------------------------------P1 and P2 SHIP ATTACKING---------------------------#
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#

# Alternate which player is firing																								
alternateFire:
	li	$t8, 0					# initialize t8 to 0
	addi	$t6, $zero, 1				# initialize t6 to 1
	addi	$t7, $zero, 2				# initialize t7 to 2
	beq	$s6, $t6, p1FireLoadArray		# branch to p1fire if s6 = t6 (s6 initialized to 1 at beginning)
	beq	$s6, $t7, p2FireLoadArray		# branch to p2fire if s6 = t7

	j	exit					# shouldnt get here, bug if we do
	
# Loads opponents array and changes player indicator
p1FireLoadArray:
	addi	$t5, $t5, 1				# increment t5 to alternate cursor positions
	jal	p2TurnIndicator
	la	$s1, p2ShipsMem				# loads starting address of allocated memory to hold p2's ships locations
	
	j	p1Fire

# Takes position currently at and checks the opponents array of locations of ships to see if there was a hit	
p1Fire:
	addi	$s6, $zero, 2				# p2 will fire next
	jal	validFire
	addi	$t8, $t8, 1				# starting at 0, increment by 1
	lw	$t9, ($s1)				# loads the value at current index of array into t9
	beq	$t0, $t9, p2Hit				# checks if current position on map is a position at current index of array
	addi	$s1, $s1, 4				# go to next index in array
	beq	$t8, $s0, resetInputFire		# if we have gone through the array with no hits
	
	j	p1Fire

# Loads opponents array and changes player indicator
p2FireLoadArray:
	addi	$t5, $t5, -1				# decrement t5 to alternate cursor positions
	jal	p1TurnIndicator
	la	$s1, p1ShipsMem				# loads starting address of allocated memory to hold p1's ships locations
	
	j	p2Fire

# Takes position currently at and checks the opponents array of locations of ships to see if there was a hit
p2Fire:
	addi	$s6, $zero, 1				# p1 will fire next
	jal	validFire
	addi	$t8, $t8, 1				# starting at 0, increment by 1
	lw	$t9, ($s1)				# loads the value at current index of array into t9
	beq	$t0, $t9, p1Hit				# checks if current position on map is a position at current index of array
	addi	$s1, $s1, 4				# go to next index in array
	beq	$t8, $s0, resetInputFire		# if we have gone through the array with no hits
	
	j	p2Fire

# P1's ship was hit
p1Hit:
	jal	initCursorBoundaries
	addi	$s2, $s2, 1				# add 1 to p1's hit count
	beq	$s2, 12, victoryScreenPlayer2		# for abbreviated game, first person to sink the ship of size 2 wins
	lw	$t3, red				# load red into t3
	sw	$t3, ($t0)				# paint current position red
	lw	$s3, key				# load key into $s3
	sw	$zero, ($s3)				# make value of key zero (so that the keyboard doesnt constantly assume we are inputting thus constantly moving a repainting)
	
	j	initialPositionOfKeyboardP2Fire		# if p2 gets hit move to p1's starting position on board (since p2 will be attacking on p1's side)

# P2's ship was hit
p2Hit:
	jal	initCursorBoundaries
	addi	$s5, $s5, 1				# add 1 to p1's hit count
	beq	$s5, 12, victoryScreenPlayer1		# for abbreviated game, first person to sink the ship of size 2 wins
	lw	$t3, red				# load red into t3
	sw	$t3, ($t0)				# paint current position red
	lw	$s3, key				# load key into $s3
	sw	$zero, ($s3)				# make value of key zero (so that the keyboard doesnt constantly assume we are inputting thus constantly moving a repainting)
	
	j	initialPositionOfKeyboardP1Fire		# if p2 gets hit move to p1's starting position on board (since p2 will be attacking on p1's side)
	
# This is the reset in the case that an opponent attacks where they have previously attacked
# It repaints the original color, resets the keyboard input, resets the cursor boundaries, and switches turns	
resetInputPrevAttacked:	
	jal	initCursorBoundaries
	sw	$s4, ($t0)
	lw	$s3, key				# load key into $s3
	sw	$zero, ($s3)				# make value of key zero (so that the keyboard doesnt constantly assume we are inputting thus constantly moving a repainting)
	
	beq	$t5, 3, initialPositionOfKeyboardP1Fire	# when p2 attacking put cursor in p1's ship area
	beq	$t5, 2, initialPositionOfKeyboardP2Fire	# when p1 attacking put cursor in p2's ship area

	j	exit					# if we get here, something is wrong	
	
# We get here when we fire and miss
# We change the miss on the current bit to light green, reset input, and branch to p1 or p2 position accordingly
resetInputFire:
	jal	initCursorBoundaries
	lw	$t4, lightGreen
	sw	$t4, ($t0)				# paint the miss a light green
	lw	$s3, key				# load key into $s3
	sw	$zero, ($s3)				# make value of key zero (so that the keyboard doesnt constantly assume we are inputting thus constantly moving a repainting)
	
	beq	$t5, 3, initialPositionOfKeyboardP1Fire	# when p2 attacking put cursor in p1's ship area
	beq	$t5, 2, initialPositionOfKeyboardP2Fire	# when p1 attacking put cursor in p2's ship area

	j	exit					# if we get here, something is wrong
		
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
#---------------------------------WELCOME SCREEN-------------------------------------#
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#	

# Load colors into registers
drawWelcomeScreen:
	lw	$t0, screen		# store start of screen in $t0
	
	lw	$t1, black		# load black into #t1
	lw	$t2, lightBlue		# load lightblue into $t2
	lw	$t3, darkBlue		# load darkBlue into $t3

# Draws first two lines black	
drawBlankCounter1:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draws first two lines black
drawBlank1:	
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, battleWord
	addi	$t4, $t4, 1
	j	drawBlank1

# Draw word BATTLE
battleWord:
	# Row 3
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue 8
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	# Row 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 5
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 6
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 7
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	
drawBlankCounter2:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw rows 8 and 9 black
drawBlank2:	
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, shipWord
	addi	$t4, $t4, 1
	j	drawBlank2
	
# Draw word SHIP
shipWord:
	# Row 10
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 11
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 12
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 13
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 14
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4

# Draw last two rows black	
drawBlankCounter3:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw last two rows black
drawBlank3:	
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4		
	beq	$t4, $t5, return	# Goes to helper func that returns back to where this function was called
	addi	$t4, $t4, 1		# Increment counter
	j	drawBlank3
	
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
#---------------------------------BATTLE SCREEN-------------------------------------#
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
drawGameScreen:
	lw	$t0, screen		# store start of screen in $t0
	
	lw	$t1, black		# load black into #t1
	lw	$t2, lightBlue		# load lightblue into $t2
	lw	$t3, darkBlue		# load darkBlue into $t3
	
	#start of row 1
	sw	$t2, ($t0)		# put lightblue in memory location of $t2 (start of screen)
	addi	$t0, $t0, 4		# next memory address (4 or 128?)
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4		
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4	
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 2
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 3
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	# start of row 5
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 6
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 7
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 8
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 9
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 10
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 11
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 12
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 13
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	# start of row 14
	sw	$t2, ($t0)		# put lightblue in memory location of $t2 (start of screen)
	addi	$t0, $t0, 4		# next memory address (4 or 128?)
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4		
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4	
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	# start of row 15
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 16
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	
	jr	$ra
	
	
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
#---------------------------------P1 VICTORY SCREEN----------------------------------#
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
victoryScreenPlayer1:
	lw	$t0, screen		# store start of screen in $t0
	
	lw	$t1, black		# load black into #t1
	lw	$t2, lightBlue		# load lightblue into $t2
	lw	$t3, darkBlue		# load darkBlue into $t3
	
	li	$t4, 0
	li	$t5, 0
	
# Draw first two rows blank
drawBlankCounterP1Vic1:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw first two rows blank
drawBlankP1Vic1:
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, player1Word
	addi	$t4, $t4, 1
	j	drawBlankP1Vic1
	
player1Word:
	#start of row 3
	sw	$t2, ($t0)		# put lightblue in memory location of $t2 (start of screen)
	addi	$t0, $t0, 4		# next memory address (4 or 128?)
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4		
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4	
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 5
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 6
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	
# Draw rows 7 and 8 black	
drawBlankCounterP1Vic2:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw rows 7 and 8 black
drawBlankP1Vic2:
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, winsWordP1
	addi	$t4, $t4, 1
	j	drawBlankP1Vic2
	
winsWordP1:
	# Row 9
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	# Row 10
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 11
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	# Row 12
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	# Row 13
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	
# Draw last 3 rows black
drawBlankCounterP1Vic3:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 48	

# Draw last 3 rows black
drawBlankP1Vic3:
	sw	$t1, ($t0)				# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, vicP1Helper		# Need to branch to play again/quit screen
	addi	$t4, $t4, 1
	j	drawBlankP1Vic3
	
vicP1Helper:
	jal	sleepScreen5Sec
	j	playAgainScreen	
	
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
#---------------------------------P2 VICTORY SCREEN----------------------------------#
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
	
victoryScreenPlayer2:
	lw	$t0, screen		# store start of screen in $t0
	
	lw	$t1, black		# load black into #t1
	lw	$t2, lightBlue		# load lightblue into $t2
	lw	$t3, darkBlue		# load darkBlue into $t3
	
	li	$t4, 0
	li	$t5, 0

# Draw first rows black
drawBlankCounterP2Vic1:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw first rows black
drawBlankP2Vic1:
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, player2Word
	addi	$t4, $t4, 1
	j	drawBlankP2Vic1

player2Word:
	# start of row 3
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	# start of row 3
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4		
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4		
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4	
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	# start of row 5
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 6
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4

# Draw rows 7 and 8 black
drawBlankCounterP2Vic2:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw rows 7 and 8 black
drawBlankP2Vic2:
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, winsWordP2
	addi	$t4, $t4, 1
	j	drawBlankP2Vic2

winsWordP2:
	# Row 9
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	# Row 10
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 11
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	# Row 12
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	# Row 13
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4

# Draw last 3 rows black	
drawBlankCounterP2Vic3:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 48	

# Draw last 3 rows black
drawBlankP2Vic3:
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, vicP2Helper		
	addi	$t4, $t4, 1
	j	drawBlankP2Vic3
	
vicP2Helper:
	jal	sleepScreen5Sec
	j	playAgainScreen
	
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
#---------------------------------PLAY AGAIN SCREEN----------------------------------#
#------------------------------------------------------------------------------------#
#------------------------------------------------------------------------------------#
playAgainScreen:
	lw	$t0, screen			# store start of screen in $t0
	
	lw	$t1, black			# load black into #t1
	lw	$t2, lightBlue		# load lightblue into $t2
	lw	$t3, darkBlue		# load darkBlue into $t3
	
# Draw first two rows blank
drawBlankCounterPAS: 
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw first two rows blank
drawBlankPAS:
	sw	$t1, ($t0)			# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, playWord
	addi	$t4, $t4, 1
	j	drawBlankPAS 		#Loop through until play is painted
	
playWord:
	#start of row 3
	sw	$t2, ($t0)		# put lightblue in memory location of $t2 (start of screen)
	addi	$t0, $t0, 4		# next memory address (4 or 128?)
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4		
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4	
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw light black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw light black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	
	# start of row 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw light black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# start of row 5
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4

	
# Draw rows 7 and 8 black	
drawBlankCounterPAS2:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 32	

# Draw rows 7 and 8 black
drawBlankPAS2:
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, quitWord
	addi	$t4, $t4, 1
	j	drawBlankPAS2
	
quitWord:
	# Row 9
	sw	$t3, ($t0)		# Draw  dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw  black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw  light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw  black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw black light
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	# Row 10
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 11
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	# Row 12
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	
	# Row 13
	sw	$t3, ($t0)		# Draw  dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw  black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw  light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw  light blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t1, ($t0)		# Draw black
	addi	$t0, $t0, 4
	
	
# Draw last 3 rows black
drawBlankCounterPAS3:
	addi	$t4, $t4, 1
	addi	$t5, $t5, 48	

# Draw last 3 rows black
drawBlankPAS3:
	sw	$t1, ($t0)				# Draw black
	addi	$t0, $t0, 4
	beq	$t4, $t5, playAgain  	# Need to branch to play again/quit screen
	addi	$t4, $t4, 1
	j	drawBlankPAS3	
	
# We just go to this input when firing because we do not want to be able to place ships during this stage
playAgain:
	li	$a0, 1000				# used for buffer
	lw	$s3, key				# loads keyboard address
	lw	$s3, ($s3)				# loads key from memory	
	beq	$s3, 0x0000001B, cursorEsc		# lowercase d in hex
	beq	$s3, 0x00000070, cursorPlay		# lowercase a in hex
	
	j	bufferPlayAgain

# Buffer when firing (prevents crashing)		
bufferPlayAgain:
	subi	$a0, $a0, 1
	bgtz	$a0, bufferPlayAgain
	j	playAgain
	
cursorPlay:
	j	replay
	
cursorEsc:
	j	exit			

# Redraws an empty board once after p1 has finished placing its ships
redrawP1PortionOfBoard:
	lw	$t0, p1BoardStart	# top left corner of battle portion of board
	lw	$t1, black		# load black into #t1
	lw	$t2, lightBlue		# load lightblue into $t2
	lw	$t3, darkBlue		# load darkBlue into $t3

	# start of row 5
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 36
	# start of row 6
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 36
	# start of row 7
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 36
	# start of row 8
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	
	jr	$ra
	
# Redraws an empty board once after p2 has finished placing its ships
redrawP2PortionOfBoard:
	lw	$t0, p2BoardStart	# top left corner of battle portion of board
	lw	$t1, black		# load black into #t1
	lw	$t2, lightBlue		# load lightblue into $t2
	lw	$t3, darkBlue		# load darkBlue into $t3

	# start of row 5
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 36
	# start of row 6
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 36
	# start of row 7
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 36
	# start of row 8
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	addi	$t0, $t0, 4
	sw	$t3, ($t0)		# Draw dark blue
	addi	$t0, $t0, 4
	sw	$t2, ($t0)		# Draw light blue
	
	jr	$ra

# Write "1" beside the game board 
# Writes that area blank (to erase the previous 2), then writes the "1"
p1TurnIndicator:
	lw	$t1, playerIndicatorStart
	lw	$t2, lightBlue
	lw	$t3, black
	
	# erase previous number (draw black)
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	
	# draw "1"
	lw	$t1, playerIndicatorStart
	
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 64
	sw	$t2, ($t1)
	addi	$t1, $t1, 64
	sw	$t2, ($t1)
	addi	$t1, $t1, 60
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	
	jr	$ra
	
# Write "2" beside the game board 
# Writes that area blank (to erase the previous 1), then writes the "2"
p2TurnIndicator:
	lw	$t1, playerIndicatorStart
	lw	$t2, lightBlue
	lw	$t3, black
	
	# erase previous number (paint black)
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	
	# draw "2"
	lw	$t1, playerIndicatorStart
	
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 64
	sw	$t2, ($t1)
	addi	$t1, $t1, 56
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 60
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	
	jr	$ra
	
# "P" of right side of screen to indicate placing	
placeIndicator:
	lw	$t1, placeIndicatorStart
	lw	$t2, lightBlue
	lw	$t3, black
	
	# erase previous number (paint black)
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	
	lw	$t1, placeIndicatorStart
	
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 56
	sw	$t2, ($t1)
	addi	$t1, $t1, 8
	sw	$t2, ($t1)
	addi	$t1, $t1, 56
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 56
	sw	$t2, ($t1)
	
	jr	$ra	
	
# "F" on right side of screen to indicate firing	
fireIndicator:
	lw	$t1, fireIndicatorStart
	lw	$t2, lightBlue
	lw	$t3, black
	
	# erase previous number (paint black)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 56
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	addi	$t1, $t1, 4
	sw	$t3, ($t1)
	
	lw	$t1, fireIndicatorStart
	
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 56
	sw	$t2, ($t1)
	addi	$t1, $t1, 64
	sw	$t2, ($t1)
	addi	$t1, $t1, 4
	sw	$t2, ($t1)
	addi	$t1, $t1, 60
	sw	$t2, ($t1)
	
	jr	$ra

# Sleep for 5 seconds
sleepScreen5Sec:
	ori 	$v0, $zero, 32			# Syscall sleep
	ori 	$a0, $zero, 5000		# For this many milliseconds
	syscall
	jr	$ra
	
# Sleep for 2 seconds
sleepScreen2Sec:
	ori 	$v0, $zero, 32			# Syscall sleep
	ori 	$a0, $zero, 2000		# For this many milliseconds
	syscall
	jr	$ra

# Returns in cases where we need to use a branch but return to original calling position	
return:
	jr	$ra

# Resets the cursor boundaries
initCursorBoundaries:
	li	$a2, 0					# x-coord (cursorRight and cursorLeft affect t8)
	li	$a3, 0					# y-coord (cursorUp and cursorDown affect t9)
	jr	$ra
		
# Resets all of the values then calls main to replay the game
replay:
	li	$t0, 0
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t4, 0
	li	$t5, 0
	li	$t6, 0
	li	$t7, 0
	li	$t8, 0
	li	$t9, 0
	
	li	$s0, 0
	li	$s1, 0
	li	$s2, 0
	li	$s3, 0
	li	$s4, 0
	li	$s5, 0
	li	$s6, 0
	li	$s7, 0
	
	li	$a0, 0
	li	$a1, 0
	li	$a2, 0
	li	$a3, 0
	
	j	main

# Terminate
exit:
	li	$v0, 10
	syscall	
