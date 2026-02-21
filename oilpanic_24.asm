// Oil Panic (Game&Watch)
// Fan tribute to Nintendo handheld game
// Commodore 64 version by metesev
// Start date: 02.02.2026
// End date: 19.02.2026

.var COLOUR_MEM             = $d800
.var INTERRUPT_REG          = $dc0d
.var INTERRUPT_REG2         = $dd0d
.var RASTER_SPRITE_INT_REG  = $d01a
.var SPRITE_PRIORITY		= $d01b
.var SPRITE_COLOR_DEPTH		= $d01c
.var RASTER_LINE_MSB        = $d011
.var SCREEN_MULTICOLOUR     = $d016
.var RASTER_LINE            = $d012
.var INTERRUPT_STATUS       = $d019
.var SYS_IRQ_HANDLER        = $ea31
.var DIGIT_SPRITE_ADDR		= $4c00
.var MULTICOLOR_1		    = $d022
.var MULTICOLOR_2	    	= $d023
.var MULTICOLOR_3		    = $d024
.var SPRITE_MULCOL_1	    = $d025
.var SPRITE_MULCOL_2		= $d026
.var SPRITE_COLOR		    = $d027
.var VIC_CONTR_REG       	= $d016 
.var SCREEN_CONTROL_REG  	= $d011
.var BORDER_COLOR         	= $d020
.var SCREEN_COLOR         	= $d021
.var GRAPHICS_POINTER     	= $d018
.var VIC_BANK_POINTER     	= $dd00
.var SPRITE_ENABLE        	= $d015		
.var VIC_SCREEN_MEMORY		= $5c00						// screen memory
.var Sprite_Pointer			= VIC_SCREEN_MEMORY+$3f8	// set sprite pointer --> VIC BANK + $800 (32 x 64)
.var CIA_TIME_A_LO			= $dc04
.var CIA_TIME_A_HI			= $dc05
.label smooth 				= $02     					// Control for smooth scroll
.label screenloc 			= VIC_SCREEN_MEMORY+$398
.label SCNKEY     			= $ff9f  					// scan keyboard - kernal routine
.label GETIN     			= $ffe4   					// read keyboard buffer - kernal routine
.label MOVE_SPEED 			= $ff
.const music_init 			= $3000
.const music_play 			= $3003
.const screen_ptr			= $fb
.const data_ptr				= $fd
.const CATCH_WAIT_A         = $11 
.const CATCH_WAIT_B         = $0f
.const SCORE_INCREMENT_DELAY = $05
.const POUR_ANIM_DURATION 	= $32
.const FIRE_ANIM_SPEED 		= $20      			  	// frames between fire animation frames
.const FIRE_ANIM_DURATION 	= $ff
.const LADY_SPILL_ANIM_SPEED = $30     			 	// frames per animation step
.const LADY_SPILL_ANIM_FRAMES = $05 
.const MAX_SPEED_LEVEL 		= $04
.const BONUS_MODE_DURATION 	= $5dc 					// apprx. 30 seconds for a second collector

#import ".\sources\helper.asm"
#import ".\sources\intro_24.asm"

BasicUpstart2(start)
*=$0820 "Main Program"

start:	{
		sei
		lda #$36		    	// disable BASIC ROM, all memory but $e000-$ffff  
		sta $01 		    	// is available (%0011 0110)

	    lda #$2f 		    	// when hit runstop/restore
	    sta $0318 		    	// it points to the  
	    lda #$08    			// start section
	    sta $0319	

		SetBorderColor(BLACK)
		SetBackgroundColor(BLACK)

		lda VIC_BANK_POINTER		// bit 0-1=%10 VIC bank #1 ($4000-$7fff)
		and #%11111100				// $dd00
		ora #%00000010
        sta VIC_BANK_POINTER   

        lda #%01110000      	   	// bit1-3 = %000 VIC+$0000 ($4000) character memory
        sta GRAPHICS_POINTER  		// bit4-7 = %0111 VIC+$1C00 ($5C00) screen memory

// initialize the score
        lda high_score_bcd           // Check if already initialized
        ora high_score_bcd+1
        bne !skip_init+              // If not zero, skip initialization
        
        lda #$00                     // Set to 000 initially
        sta high_score_bcd
        sta high_score_bcd+1

!skip_init:
		jsr intro_screen
}

main:	{
		sei		
        lda #%00111011        		// bit 3=1 25 rows, bit 4=1 screen on
        sta SCREEN_CONTROL_REG 		// bit 5=1 bitmap on ($d011)

		lda #%00011000 				// bit 3=1 40 cols, bit4 =1 multicolor on
        sta SCREEN_MULTICOLOUR		// $d016

		lda VIC_BANK_POINTER		// bit 0-1=%10 VIC bank #1 ($4000-$7fff)
		and #%11111100				// $dd00
		ora #%00000010
        sta VIC_BANK_POINTER   

        lda #%01111000      	   	// bit1-3 = %100 VIC+$2000 ($6000) character memory
        sta GRAPHICS_POINTER  		// bit4-7 = %0111 VIC+$1C00 ($5C00) screen memory

        DrawBitmap($7f40,$5c00,$8328)

		SetBorderColor(LIGHT_GRAY)
		SetBackgroundColor(LIGHT_GRAY)

		lda #$00
		sta SPRITE_PRIORITY			// all sprites are drawn in front of the screen
		sta SPRITE_COLOR_DEPTH		// all sprites are single color
		ldx #$00					// and they are all black
!:		lda #$00		
		sta $d027,x
		inx
		cpx #$08
		bne !-

		lda #$00					// pointer for the collector movement table
		sta collector_pointer		// of the bottom screen

		lda #$00					// set the lives to 0
		sta top_lives				// missed lives increment
		sta bottom_lives

		lda #$03
		sta player_pointer

    	// RESET ALL GAME VARIABLES
		lda #$00
		sta score_bcd               // Reset score to 0
		sta score_bcd+1
		sta consecutive_score       // Reset consecutive score
		sta consecutive_score+1
		sta last_hundred            // Reset hundred tracker
		sta top_lives               // Reset lives
		sta bottom_lives
		sta collector_pointer
		sta oildrop_active
		sta fire_active
		sta lady_spill_active
		sta gent_spill_active
		sta bonus_mode_active
		sta bonus_mode_timer
		sta bonus_mode_timer+1
		sta drop_speed_level
		sta score_increment_timer

		lda #$01
		sta miss_free_run       	// Start with miss-free status
		lda #$03
		sta player_pointer
		sta player_position         // Center player
		lda #$00
		sta player_drop_number      // Empty bucket
		lda #$00					// Update score display to show 0
		sta points_to_add
		jsr add_score               // Display initial score of 0

									// randomize player start point
		lda CIA_TIME_A_LO           // CIA Timer A low byte (changes rapidly)
		eor CIA_TIME_A_HI          
		and #$0f               	    
		cmp #$0f                   
		bcc !ok+                    
		lda #$00                    
	!ok:
		sta oildrop_table_index 	// Set random starting point (0-8)

		lda #$00					// Initialize SID chip
		ldx #$00
	!:  sta $d400,x
		inx
		cpx #$18
		bne !-
		lda #$0f					// Set volume to maximum
		sta $d418

}

split_screen:	{
// raster interrupts for split screen
// raster interrupt routine starts here
		lda #$7f					// disable CIA interrupts
		sta $dc0d
		sta $dd0d

		lda #$01					// enable raster interrupts
		sta $d01a

		lda #$20					// Trigger at raster line 50
		sta RASTER_LINE

		lda RASTER_LINE_MSB			// Clear bit 7 of $d011 (for raster lines < 256)
		and #$7f
		sta RASTER_LINE_MSB

		lda #<sprite_irq
		sta $0314
		lda #>sprite_irq
		sta $0315

		cli							// Re-enable interrupts
}

main_loop:   {
		lda frame_done_flag			// ensure sysynchronization between main loop and raster interrupt 
		beq main_loop				
		lda #$00
		sta frame_done_flag

		jsr read_input
		jsr update_collector
		jsr update_oil_drops
		jsr check_for_bottom_score
		jsr update_pour_animation 
		jsr update_fire_animation
		jsr update_lady_spill
		jsr update_gent_spill
		jsr update_score
		jsr update_bonus_mode
		jsr update_sfx 

    	jmp main_loop
}

sprite_irq:	{
// Split the play area into two sections with raster interrupt

		asl INTERRUPT_STATUS		// acknowledge the interrupt

		lda RASTER_LINE
		cmp #$96
		bne!+

		jmp bottom_position

//--------------------------------------------------------------
// we are at the top half of the screen

!:		lda #%00001000				// sprites  3 & 4 are double height
		sta $d017
		lda #%00001000				// sprites 3 & 4 are double width
		sta $d01d

		lda #%00011111
		sta SPRITE_ENABLE

		lda game_mode				// check the game mode
		bne !b_mode+

// game mode A for sprite 0
		lda #$61
		sta $d000
		lda #$3e
		sta $d001
		lda #$61
		sta Sprite_Pointer
		jmp !+

// game mode B for sprite 0
!b_mode:	
		lda #$ef
		sta $d000
		lda #$3e
		sta $d001
		lda #$62
		sta Sprite_Pointer

// miss (lives) sprite 1
!:		ldx top_lives					// check the top lives (incrementing)
		lda sprite_top_1_pointer,x		// and add the missed lives to the pointer
		sta Sprite_Pointer+1			// of the miss sprite
		lda #$ef
		sta $d002
		lda #$4e
		sta $d003

// oil drops sprite 2
		lda oildrop_active
		beq !no_drop+

		ldx oildrop_current_step
		lda sprite_top_2_pointer,x
		sta Sprite_Pointer+2
		lda oildrop_y_coord,x 
		sta $d005
		ldx oildrop_current_track
		lda oildrop_x_coord,x 
		sta $d004
		jmp !player_logic+

!no_drop:
		lda #$64
		sta Sprite_Pointer+2

!player_logic:
		ldx player_pointer
		lda sprite_top_3_pointer,x
		sta Sprite_Pointer+3
		lda player_x_coord,x
		sta $d006
		lda player_y_coord,x 
		sta $d007

		lda fire_active					// check if there is fire (for sprite 4)
    	beq !no_fire+

    	// Select correct fire pointer table based on track
		ldx fire_frame                  // get animation frame (0-7)
		lda fire_active
		cmp #$01
		beq !fire_left+
		cmp #$02
		beq !fire_mid+		

		// if not left or mid, then fire right
		lda sprite_top_4_r_pointer,x
		sta Sprite_Pointer+4
		lda #$cc                       // X coord for right fire
		sta $d008
		lda #$79
		sta $d009
		jmp !skip+

!fire_left:
		lda sprite_top_4_l_pointer,x
		sta Sprite_Pointer+4
		lda #$70                      // X coord for left fire
		sta $d008
		lda #$77
		sta $d009
		jmp !skip+

!fire_mid:
		lda sprite_top_4_m_pointer,x
		sta Sprite_Pointer+4
		lda #$9a                        // X coord for middle fire
		sta $d008
		lda #$77
		sta $d009
		jmp !skip+

!no_fire:	
		lda #$64					// no fire, so empty sprite for sprite 4
		sta Sprite_Pointer+4

!skip:
// load the rasterline
		lda #$96
		sta RASTER_LINE
		jmp irq_exit

//--------------------------------------------------------------------------------------
// we are at the bottom half of the screen
//--------------------------------------------------------------------------------------
bottom_position:
		lda #%00000000					// no sprite is double width or height
		sta $d017						// on bottom screen
		sta $d01d

		lda #%11111111					// enable all sprites
		sta SPRITE_ENABLE

		lda #$64						
		sta Sprite_Pointer+4
		sta Sprite_Pointer+7

//first we write the score on screen (sprite 0)
		lda #$80						// sprite 0 x and y coordinates
		sta $d000
		lda #$9d
		sta $d001
		lda #$30						// sprite pointer for the score
		sta Sprite_Pointer	

// miss (lives) sprite 1
		ldx bottom_lives				// check the bottom lives (incrementing)
		lda sprite_bottom_1_pointer,x	// and add the missed lives to the pointer
		sta Sprite_Pointer+1			// of the miss sprite
		lda #$ef
		sta $d002
		lda #$a0
		sta $d003

// player sprite 2
		ldx player_position
		lda sprite_bottom_2_pointer,x
		sta Sprite_Pointer+2

		lda player_bot_x_coord,x
		sta $d004
		lda player_bot_y_coord,x
		sta $d005

// sprite 3 - collector (left in bonus, moving in normal)
		lda bonus_mode_active
		beq !normal_collector+

		// Bonus mode - left collector fixed
		lda sprite_bottom_3_pointer
		sta Sprite_Pointer+3
		lda #$83
		sta $d006
		lda #$c5
		sta $d007
		jmp !collector_done+

	!normal_collector:
		ldx collector_pointer
		lda collector_table,x
		tay
		lda sprite_bottom_3_pointer,y
		sta Sprite_Pointer+3
		lda collector_x_coord,y
		sta $d006
		lda collector_y_coord
		sta $d007

!collector_done:
	// sprite 4 - right collector (bonus) OR oil spill (normal)
		lda bonus_mode_active
		beq !check_spill+

		// Bonus mode - right collector fixed
		lda sprite_bottom_3_pointer+3
		sta Sprite_Pointer+4
		lda #$cd
		sta $d008
		lda #$c5
		sta $d009
		jmp !spill4_done+

	!check_spill:
		// Normal mode - check for oil spill
		lda lady_spill_active
		bne !lady_oil+
		lda gent_spill_active
		bne !gent_oil+
		jmp !no_spill4+

!lady_oil:
		lda lady_spill_frame
		beq !oil_air_right+
		// frames 1-4 = oil on ground (lady side)
		lda #$5f
		sta Sprite_Pointer+4
		lda #$dd
		sta $d008
		lda #$e3
		sta $d009
		jmp !spill4_done+

!gent_oil:
		lda gent_spill_frame
		beq !oil_air_left+

    // frame 1 = oil on ground only
		lda #$5f
		sta Sprite_Pointer+4
		lda #$78
		sta $d008
		lda #$e3
		sta $d009
		jmp !spill4_done+

!oil_air_right:
		lda #$5e
		sta Sprite_Pointer+4
		lda #$dd
		sta $d008
		lda #$d5
		sta $d009
		jmp !spill4_done+

!oil_air_left:
		lda #$5e
		sta Sprite_Pointer+4
		lda #$78
		sta $d008
		lda #$d5
		sta $d009
		jmp !spill4_done+

!no_spill4:
		lda #$64
		sta Sprite_Pointer+4

!spill4_done:

// the lady (sprite 5)
		lda lady_spill_active
		beq !lady_normal+

		lda lady_spill_frame
		cmp #$02
		bcc !lady_normal+           // frames 0-1 = show lady in normal position

		cmp #$03					// frames 2-4 = lady jumping on right
		beq !lady_jump+             // frame 3 = jumping

		lda #$59					// frames 2 & 4 = standing angry
		sta Sprite_Pointer+5
		lda #$ea
		sta $d00a
		lda #$df
		sta $d00b
		jmp !lady_done+

!lady_jump:
		lda #$5a
		sta Sprite_Pointer+5
		lda #$ea
		sta $d00a
		lda #$d0                    // higher Y position
		sta $d00b
		jmp !lady_done+

// !lady_hide:
// 		lda #$64                    // empty sprite
// 		sta Sprite_Pointer+5
// 		jmp !lady_done+

!lady_normal:
		lda sprite_bottom_5_pointer
		sta Sprite_Pointer+5
		lda #$dd
		sta $d00a
		lda #$df
		sta $d00b

!lady_done:

// the gentleman (sprite 6)
		lda gent_spill_active
		beq !gent_normal+
		
		lda gent_spill_frame
		cmp #$02
		bcc !gent_normal+           // frames 0-1 = show in normal position

    // frames 2-4 = gentleman on left side
		cmp #$03
		beq !gent_hands+            // frame 3 = hands moving
		
		// frames 2 & 4 = standing angry
		lda #$5c
		sta Sprite_Pointer+6
		lda #$68                    // X position left side
		sta $d00c
		lda #$df
		sta $d00d
		jmp !gent_done+
		
!gent_hands:
		lda #$5d                    // hands up sprite
		sta Sprite_Pointer+6
		lda #$68
		sta $d00c
		lda #$df
		sta $d00d
		jmp !gent_done+
		
!gent_normal:
		lda sprite_bottom_6_pointer
		sta Sprite_Pointer+6
		lda #$78
		sta $d00c
		lda #$df
		sta $d00d

!gent_done:

// sprite 7 - pour animation or puff
		lda pour_animation_active
		bne !pour_anim+
		lda gent_spill_active
		bne !gent_puff+
		jmp !no_sprite7+

!gent_puff:
		lda gent_spill_frame
		cmp #$02
		bcc !no_sprite7+            // frames 0-1 = no puff yet
		
		// frames 2-4 = puff
		lda #$60
		sta Sprite_Pointer+7
		lda #$60                    // X coord
		sta $d00e
		lda #$d5                    // Y coord
		sta $d00f
		jmp !pour_done+

!pour_anim:
		lda pour_animation_active
		cmp #$01
		beq !pour_left+
		
		// pour right
		lda #$66
		sta Sprite_Pointer+7
		lda #$d2
		sta $d00e
		lda #$bc
		sta $d00f
		jmp !pour_done+

!pour_left:
		lda #$65
		sta Sprite_Pointer+7
		lda #$7f
		sta $d00e
		lda #$bc
		sta $d00f
		jmp !pour_done+

!no_sprite7:
		lda #$64
		sta Sprite_Pointer+7


!pour_done:
// exit the IRQ
		lda #$20
		sta RASTER_LINE
		
		lda #$01
		sta frame_done_flag

irq_exit:
		jmp $ea31
}

read_input: {
// read keyboard input and adjust player pointer
// this routine only adjusts the location of the player
// the sprite pointer related with the number of drops is calculated in update_player

		lda fire_active					// if there is fire on the upper part
		bne !done+						// don't let the player move

		lda lady_spill_active       	// if oil is spilling over lady
		bne !done+						// don't let the player move
		
		lda gent_spill_active       	// if oil is spilling over gent
		bne !done+						// don't let the player move

		jsr GETIN
		cmp leftkey 
		beq moveleft
		cmp rightkey 
		beq moveright
		jmp !done+

moveleft:
		lda player_position
		beq !done+
		dec player_position
		jsr calculate_player_safe
		jmp !done+

moveright:
		lda player_position
		cmp #$06
		beq !done+
		inc player_position
		jsr calculate_player_safe

!done:	rts
}

calculate_player_safe: {
		php
        sei
        
        lda player_drop_number
        cmp #$03
        bcc !+
        lda #$03                    // Clamp drops at 3
!:      sta math_temp

        lda player_position
        cmp #$07                    // Is position > 6?
        bcc !+
        lda #$06                    // Clamp position at 6
!:      
        // --- MATH: (Drops * 7) + Position ---
        // (A is already player_position here)
        sta player_position_temp    // Store temporarily
        
        lda math_temp               // Get clamped drops
        asl; asl; asl               // x8
        sec
        sbc math_temp               // x7
        clc
        adc player_position_temp    // + position
        
        sta player_pointer
        
        plp
        rts
}

update_collector:	{
// update oile collector (bottom screen)

		lda fire_active					// stop collector if there is any fire
		bne !skip+
		lda lady_spill_active			// stop collector if there is lady spill
		bne !skip+
		lda gent_spill_active			// stop collector if there is gent spill
		bne !skip+	
		lda score_update_flag			// stop collector if score is updating
		bne !skip+

        lda player_drop_number			// freeze collector if player has a full bucket
        cmp #$03						// and also at the edges
        bne !not_full+
        lda player_position				// and also 
        beq !skip+          			// position 0 = left edge, freeze
        cmp #$06
        beq !skip+          			// position 6 = right edge, freeze

!not_full:
		inc collector_timer

		lda collector_pointer			// check if the collector is on the edges (waits a little bit longer)
		beq !edge_wait+
		cmp #$03
		beq !edge_wait+

		ldx drop_speed_level			// get the current speed level
		lda collector_timer
		ldy game_mode
		bne !speed_b+
		cmp collector_speed_table_a,x	// check with the game A collector speed table
		bne !skip+
		jmp !move+
				
!speed_b:
		cmp collector_speed_table_b,x	// check with the game B collector speed table
		bne !skip+
		jmp !move+

!edge_wait:
		lda collector_timer
		ldx drop_speed_level
		ldy game_mode
		bne !edge_b+
		cmp collector_edge_wait_table_a,x	// check with the game A collector edge table
		bne !skip+
		jmp !move+

!edge_b:
		cmp collector_edge_wait_table_b,x	// check with the game B collector edge table
    	bne !skip+

!move:
		lda #$00
		sta collector_timer

		inc collector_pointer
		lda collector_pointer
		cmp #$06
		bne!skip+
		lda #$00
		sta collector_pointer

!skip:	rts

}

update_oil_drops:	{		
// update oil drop spawning and dripping 

		lda pour_animation_active
		bne !skip_to_end+

		lda oildrop_active
		bne !update+

!spawn:		// spawn oil drop
		lda fire_active					// if there is fire, don't spawn
		bne !skip_to_end+

		lda lady_spill_active       	// if there is oil over lady, don't spawn
		bne !skip_to_end+
		
		lda gent_spill_active      	 	// if there is oil over gent, don't spawn
		bne !skip_to_end+

		//Check if we should delay spawn
		lda drop_spawn_timer
		beq !do_spawn+
		dec drop_spawn_timer
		jmp !skip_to_end+

!do_spawn:
		lda #$00
		sta drop_spawn_timer

		ldx oildrop_table_index			// get the spawn point from the table
		lda oildrop_spawn_pattern,x
		sta oildrop_current_track		// and put it on the track

		// Sound fx in accordance with the track no of the drop
		// Track 0 = left (sound #2), Track 1 = mid (sound #1), Track 2 = right (sound #3)
		lda oildrop_current_track
		cmp #$01
		beq !play_mid+
		cmp #$00
		beq !play_left+
		// Must be track 2 (right)
		lda #$02
		jmp !set_sound+
!play_mid:
		lda #$01
		jmp !set_sound+
!play_left:
		lda #$00
!set_sound:
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter
		// END OF SOUND TRIGGER

		inx
		cpx #$0f						// if we reached 15, reset the table index
		bne !+
		ldx #$00
!:		stx oildrop_table_index

		lda #$00
		sta oildrop_current_step
		inc oildrop_active
		jmp !end_drop+
		// spawn finishes here

!skip_to_end:	
		jmp !end_drop+

!update:	// there is already a drop, so update it

		lda oildrop_current_step		// check if the drop is at the bottom
		cmp #$03
		beq !at_bottom+					// if yes, go to bottom routine

		inc drop_fall_timer
		lda drop_fall_timer

		// Get speed from table based on level and game mode
		ldx drop_speed_level
		ldy game_mode
		bne !speed_b+
		
		// Game A
		lda drop_fall_speed_table_a,x
		jmp !check_speed+
		
!speed_b:
		// Game B
		lda drop_fall_speed_table_b,x

!check_speed:
		cmp drop_fall_timer
		bne !end_drop+              // not time to fall yet

!fall:
		lda #$00
		sta drop_fall_timer
		inc oildrop_current_step

		// Play drop sound when falling
		lda oildrop_current_track
		cmp #$01
		beq !play_mid_fall+
		cmp #$00
		beq !play_left_fall+
		// Must be track 2 (right)
		lda #$02
		jmp !set_sound_fall+
!play_mid_fall:
		lda #$01
		jmp !set_sound_fall+
!play_left_fall:
		lda #$00
!set_sound_fall:
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter
    	// END OF SOUND TRIGGER

		jmp !end_drop+

!at_bottom:
		inc catch_timer
		lda catch_timer
		ldx game_mode
		bne !catch_b+
		cmp #CATCH_WAIT_A
		bne !end_drop+
		jmp !missed+
!catch_b:
		cmp #CATCH_WAIT_B
		bne !end_drop+

!missed:
		lda #$00
		sta catch_timer
		jmp check_for_catch

!end_drop:	rts
}

check_for_catch: {
// check if the player catches the drop in the bucket
		lda player_position			// check the player position (0-6)
		sec
		sbc #$02
		cmp oildrop_current_track	// against the oil drop track
		beq !success+				// if yes, go to success
		jsr silence_all_channels	// stop drop sound cause fire sound is coming
		jmp cause_fire				// if no, the drop has been missed to cause a fire

!success:
		lda player_drop_number		// since it is success (catched)
		cmp #$03
		beq !full+
		
		inc player_drop_number
		jsr calculate_player_safe

		lda #$00
		sta oildrop_active
		sta oildrop_current_step
		sta catch_timer

		lda #$01
		sta points_to_add
		sta score_update_flag

		// Trigger catch sound
		lda #$03
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter
		// END SOUND TRIGGER

		lda #$08                    // 8 frame delay
		sta drop_spawn_timer

		rts 

!full:
		jmp cause_fire

}

check_for_bottom_score:	{
// check if the bucket is being emptied in the bottom screen

		lda player_drop_number		// is there any oil to pour?
		beq !exit+					// if not, exit

		lda player_position			// check if the player is at the leftmost position
		beq !at_left_edge+			// if yes, go and check if collector is in the same edge
		cmp #$06					// check if the player is at the rightmost position
		beq !at_right_edge+			//  if yes, go and check if collector is in the same edge

		lda #$00					// not at the edge
		sta bucket_poured			// so clear the poured flag
		sta pour_animation_active   // clear animation
		rts							// otherwise exit

!at_left_edge:
    	// In bonus mode, right collector is always at position 3
		ldx bonus_mode_active
		bne !ok_to_continue+	

    	// Normal mode - check collector position	
		ldx collector_pointer		// check where the collector is
		lda collector_table,x
		beq !ok_to_continue+		// if zero, he is on the left edge
		jmp cause_spill				// otherwise, oil is spilled		

!at_right_edge:
    	// In bonus mode, right collector is always at position 3
		ldx bonus_mode_active
		bne !ok_to_continue+

    	// Normal mode - check collector position
		ldx collector_pointer		// check where the collector is
		lda collector_table,x
		cmp #$03
		beq !ok_to_continue+
		jmp cause_spill				// otherwise, oil is spilled			

// the player (above) and the collector (bottom) are on the same edge
!ok_to_continue:
		lda bucket_poured			// already poured
		bne !exit+					// don't do it again

		lda player_drop_number		// check the number of drops in the bucket
		beq !exit+					// if zero, exit

		lda player_position			// Trigger pour animation
		beq !trigger_left+			// is the player on the left?
		lda #$02                    // No, he is on the right
		jmp !set_anim+
!trigger_left:
		lda #$01                    // yes, he is on the left
!set_anim:
		sta pour_animation_active
		lda #$00
		sta pour_animation_timer

// scoring code continues here
		ldx player_drop_number
		dex
		lda oil_bottom_score,x		// get how many points to add +1

		ldx bonus_mode_active
		beq !normal_points+
		asl                 
!normal_points:   	
		sta score_counter		

		lda #$01
		sta score_update_flag
		sta bucket_poured			// mark as poured

		lda #$00
		sta player_drop_number

!exit:	rts
}

update_pour_animation:	{
// check for the oil drop pour animation timer for bottom screen
    lda pour_animation_active
    beq !done+

    inc pour_animation_timer
    lda pour_animation_timer
    cmp #POUR_ANIM_DURATION
    bne !done+

    // Animation done
    lda #$00
    sta pour_animation_active
    sta pour_animation_timer

!done:
    rts
}

update_fire_animation: {
// fire animation if the player misses a drop or catches a drop while the 
// bucket is full on the top screen

		lda fire_active
		beq !done+                      // no fire active
		
		inc fire_timer					// Update fire duration
		lda fire_timer
		cmp #FIRE_ANIM_DURATION
		bne !continue+
		
		inc top_lives				 	// increment top lives and check for game over
		lda top_lives
		cmp #$03
		bne!+             				// 3 misses = game over
		jmp game_over

!:		lda #$00						// Fire animation done - turn off
		sta fire_active
		sta fire_timer
		sta fire_frame
		sta fire_anim_timer
		rts
		
!continue:

		inc fire_anim_timer				// Update animation frame
		lda fire_anim_timer
		cmp #FIRE_ANIM_SPEED
		bne !done+
		
		lda #$00
		sta fire_anim_timer
		
		inc fire_frame					// Cycle through 8 animation frames
		lda fire_frame
		cmp #$08
		bne !frame_changed+
		lda #$00
		sta fire_frame
		
!frame_changed:
		lda #$04                   	 // Miss sound type
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter

!done:
		rts
}

update_lady_spill:	{
// lady animation when the oil is not spilled on the collector's drum

		lda lady_spill_active
		beq !done+

		inc lady_spill_timer
		lda lady_spill_timer
		cmp #LADY_SPILL_ANIM_SPEED
		bne !done+

		lda #$00
		sta lady_spill_timer

		//Play miss sound on frame change
		lda #$04
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter
		// END SOUND TRIGGER

		inc lady_spill_frame
		lda lady_spill_frame
		cmp #LADY_SPILL_ANIM_FRAMES
		bne !done+

		inc bottom_lives					// Animation complete (reached frame 5)
		lda bottom_lives
		cmp #$03
		bne !+
		jmp game_over

!:
		lda #$00
		sta lady_spill_active
		sta lady_spill_frame

		lda #$00
		sta oildrop_active
		sta oildrop_current_step
		sta drop_fall_timer
		lda #$40            		
		sta drop_spawn_timer


		jsr silence_all_channels
		lda #$00
		sta sfx_active
		sta sfx_counter
		sta pwm_counter

!done:
    	rts
}

update_gent_spill: {
// gent animation when the oil is not spilled on the collector's drum
		lda gent_spill_active
		beq !done+

		inc gent_spill_timer
		lda gent_spill_timer
		cmp #LADY_SPILL_ANIM_SPEED      // use same speed
		bne !done+

		lda #$00
		sta gent_spill_timer

		//Play miss sound on frame change
		lda #$04
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter
		// END SOUND TRIGGER

		inc gent_spill_frame
		lda gent_spill_frame
		cmp #LADY_SPILL_ANIM_FRAMES     // 5 frames
		bne !done+

		inc bottom_lives
		lda bottom_lives
		cmp #$03
		bne !+
		jmp game_over
!:
		// Animation complete
		lda #$00
		sta gent_spill_active
		sta gent_spill_frame

		lda #$00
		sta oildrop_active
		sta oildrop_current_step
		sta drop_fall_timer
		lda #$40            		
		sta drop_spawn_timer

		jsr silence_all_channels
		lda #$00
		sta sfx_active
		sta sfx_counter
		sta pwm_counter

!done:
    rts
}

cause_fire:	{		
// drop missed, fire animation

		lda oildrop_current_track
		clc
		adc #$01
		sta fire_active				// convert 0,1,2 to 1,2,3 (left,mid,right)

		lda #$00					// reset animation variables
		sta fire_timer
		sta fire_frame
		sta fire_anim_timer		

		lda #$00					// reset drop variables
		sta oildrop_active
		sta oildrop_current_step
		sta catch_timer
		sta miss_free_run   
		sta consecutive_score       
		sta consecutive_score+1  

		//Trigger miss sound immediately when fire starts
		lda #$04
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter
		// END SOUND TRIGGER

		lda #$00					// empty player bucket
		sta player_drop_number
		jsr calculate_player_safe	

		rts
}

cause_spill:	{

		lda player_position
		cmp #$06
		beq !spill_lady+                    // player position 6 = right = lady

		lda #$01							// position 0 = left = gentleman
		sta gent_spill_active
		lda #$00
		sta gent_spill_timer
		sta gent_spill_frame
		jmp !spill_common+

!spill_lady:
		lda #$01							// activate lady spill
		sta lady_spill_active
		lda #$00
		sta lady_spill_timer
		sta lady_spill_frame

!spill_common:
		jsr silence_all_channels

		lda #$04
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter

		lda #$00							// Clear active drop so new one can spawn after animation
		sta oildrop_active
		sta oildrop_current_step
		sta catch_timer
		sta drop_fall_timer 
		sta miss_free_run
		sta consecutive_score      
		sta consecutive_score+1 

!skip:        
        lda #$00
        sta score_update_flag   // Stop the update_score routine
        sta score_counter       // Clear any remaining points to be added
        sta player_drop_number
        jsr calculate_player_safe

        rts
}

game_over:	{
// when get more than 2 misses in any screen, game is over

		lda #$00					// stop game
		sta oildrop_active
		sta fire_active
		sta lady_spill_active
		sta gent_spill_active

		ldx #$64
	!:  jsr simple_delay
		dex
		bne !-
		
		sei							// disable interrupts
		lda #$00
		sta $d01a

		// Manually set up score sprite (sprite 0) since IRQ is now off
		lda #$30                    // Score sprite pointer
		sta Sprite_Pointer
		lda #$80                    // X position
		sta $d000
		lda #$9d                    // Y position
		sta $d001
		
		// Clear other sprites
		lda #$64
		sta Sprite_Pointer+1        // Miss sprite
		sta Sprite_Pointer+2        // Player
		sta Sprite_Pointer+3        // Collector
		sta Sprite_Pointer+4        // Oil/fire
		sta Sprite_Pointer+6        // Gentleman

		// Enable ONLY sprite 0 (score) for now
		lda #%00000001
		sta $d015
		lda #%00000000              // No doubling yet
		sta $d017
		sta $d01d

		ldx #$64
	!:  jsr simple_delay
		dex
		bne !-

// Set up GAME OVER sprite (sprite 5)
		lda #$67
		sta Sprite_Pointer+5
		lda #$9d
		sta $d00a
		lda #$50
		sta $d00b
		lda #RED
		sta $d027+5
		
		// Enable sprites 0 (score) AND 5 (GAME OVER)
		lda #%00100001              // Sprites 0 and 5
		sta $d015
		
		// Double ONLY sprite 5
		lda #%00100000
		sta $d017
		sta $d01d

		ldy #$02            
!out:
		ldx #$ff                  
!in:
		jsr simple_delay
		dex
		bne !in-
		dey
		bne !out-

// Check for high score
		// First check if score is at least 1
		lda score_bcd
		bne !has_score+             // High byte not zero = at least 100 points
		lda score_bcd+1
		beq !not_high+              // Both bytes zero = 0 points, skip high score
		
!has_score:
		// Now check if it beats the high score
		lda score_bcd
		cmp high_score_bcd
		bcc !not_high+
		bne !new_high+
		lda score_bcd+1
		cmp high_score_bcd+1
		bcc !not_high+

!new_high:
// Save new high score
		lda score_bcd
		sta high_score_bcd
		lda score_bcd+1
		sta high_score_bcd+1

		// Add HIGH SCORE sprite (sprite 6) - DOUBLED
		lda #$68
		sta Sprite_Pointer+6
		lda #$9d
		sta $d00c
		lda #$ac
		sta $d00d
		lda #YELLOW
		sta $d027+6
		
		// Enable sprites 0, 5, AND 6
		lda #%01100001              // Sprites 0, 5, and 6
		sta $d015
		
		// Double sprites 5 and 6 (NOT sprite 0)
		lda #%01100000
		sta $d017
		sta $d01d

    // Flash for 10 seconds 
    	ldy #$06                // Add outer loop
!reload_x:
    	ldx #$ff                // Increase from $c8 to $ff
!flash:
    	jsr simple_delay

		txa
		and #$07
		bne !skip_flash+
		lda $d015
		eor #%01000000
		sta $d015
		
!skip_flash:
		dex
		bne !flash-
		dey
		bne !reload_x-

!not_high:
 		// Wait 10 seconds (was 5)
    	ldy #$04
!wait_outer:
    	ldx #$ff
!wait:
    	jsr simple_delay
    	dex
    	bne !wait-
    	dey
   		bne !wait_outer-

// !cleanup:
		lda #$00
		sta $d011                   // Turn off screen

		// Wait a bit
		ldx #$32
!:  	jsr simple_delay
		dex
		bne !-

		// Clear everything before returning to intro
		lda #$00
		sta $d015                   // Disable sprites
		sta $d017                   // Normal height
		sta $d01d                   // Normal width

    	// Switch to text mode
		lda VIC_BANK_POINTER
		and #%11111100
		ora #%00000010
		sta VIC_BANK_POINTER

		lda #%01110000
		sta GRAPHICS_POINTER

		lda #%00001000
		sta $d016                   // Multicolor OFF

        ClearScreen(VIC_SCREEN_MEMORY,$20)
        ClearColorRam(LIGHT_GRAY)

    // Now turn screen back on in TEXT mode
		lda #%00011011              // 25 rows, screen on, TEXT mode
		sta SCREEN_CONTROL_REG

		// lda #$00					// default game A
		// sta game_mode
    	jmp text_intro_screen
}

simple_delay: {
    // Simple CPU delay
		pha               // Save A
		tya               // Save Y
		pha

		ldy #$00
!:	  	nop
		nop
		nop
		dey
		bne !-

		pla               // Restore Y
		tay
		pla  

		rts
}

add_score:	{
// Add 1 point to score and convert it to sprite 0 data

    	sed                 // Set Decimal mode
    	clc
    	lda score_bcd + 1   // Get tens/ones
		adc points_to_add
		sta score_bcd+1
		lda score_bcd
		adc #$00
		sta score_bcd

		// Also increment consecutive score
		clc
		lda consecutive_score+1
		adc points_to_add
		sta consecutive_score+1
		lda consecutive_score
		adc #$00
		sta consecutive_score
		cld

		lda score_bcd
		cmp #$10
		bne !+

		lda #$00
		sta score_bcd
		sta score_bcd+1
		sta consecutive_score      
		sta consecutive_score+1

// Convert score to sprite
!:		lda score_bcd+1
		and #$0f
		sta digit_ones

		lda score_bcd+1
		lsr
		lsr
		lsr
		lsr
		sta digit_tens

		lda score_bcd
		and #$0f
		sta digit_huns

// now convert the score to sprite data		
		lda #$00
		sta sprite_idx
		sta leading_zero_flag
		ldy #$00

row_loop:
		sty row_temp

// --- HUNDREDS ---
		lda digit_huns
		beq check_tens        		// If digit is 0, skip to Tens logic
		inc leading_zero_flag 		// It's not 0, so stop suppressing!
		jsr get_font_idx
		jmp draw_h
check_tens:
		lda #10              		 // Point to the "Space" (Index 10)
		jsr get_font_idx
draw_h:
		lda font_library, x
		ldx sprite_idx
		sta DIGIT_SPRITE_ADDR, x

// --- TENS ---
		lda digit_tens
		bne force_tens      		 // If it's not 0, we must draw it
		lda leading_zero_flag 		// Is Hundreds > 0?
		bne force_tens       		// Yes, so we must draw this 0 (e.g., 105)
		lda #10              		// No, Hundreds was 0, so suppress this 0 too
		jmp get_t
force_tens:
		lda digit_tens
get_t:
		jsr get_font_idx
		lda font_library, x
		ldx sprite_idx
		sta DIGIT_SPRITE_ADDR+1, x

// --- ONES --- We ALWAYS draw the ones digit
		lda digit_ones
		jsr get_font_idx
		lda font_library, x
		ldx sprite_idx
		sta DIGIT_SPRITE_ADDR+2, x

// --- Advance to next row ---
		lda sprite_idx
		clc
		adc #3              // Each sprite row is 3 bytes wide
		sta sprite_idx
		ldy row_temp        // Restore row counter
		iny
		cpy #12             // 12 rows total
		bne row_loop
		rts

// Helper: Calculate (A * 12) + Y
get_font_idx:
		sta math_temp
		asl                 // A * 2
		clc
		adc math_temp       // A * 3
		asl                 // A * 6
		asl                 // A * 12
		clc
		adc row_temp        // Add the row offset
		tax
		rts
}

update_score: {
// update screen score 

		lda score_update_flag
		beq !skip+

		lda score_counter
		bne !multi_add+

	// single point add when catching drops
		jsr add_score
		lda #$00
		sta score_update_flag
		jsr check_speed_increase
		jsr check_bonus_300
		jmp !skip+
	
	// multiple point add for pouring bucket
!multi_add:
    // multi-frame add with delay
		inc score_increment_timer
		lda score_increment_timer
		cmp #SCORE_INCREMENT_DELAY
		bne !skip+

		lda #$00
		sta score_increment_timer

		lda #$01
		sta points_to_add
		jsr add_score

		// Trigger catch sound for each score tick
		lda #$03
		sta sfx_type
		lda #$01
		sta sfx_active
		lda #$00
		sta sfx_counter
		// END SOUND TRIGGER

		dec score_counter
		bne !skip+

		lda #$00
		sta score_update_flag
		jsr check_speed_increase
		jsr check_bonus_300

!skip:
		rts
}

check_speed_increase:	{
// lets check if need to increase speed. 
// 0-199 points: Level 0 (slowest)
// 200-399 points: Level 1
// 400-599 points: Level 2
// 600-799 points: Level 3
// 800+ points: Level 4 (fastest, stays here)

		lda score_bcd
		and #$0f
		cmp last_hundred				// get the hundreds digits
		beq !done+
		
		sta last_hundred				// check if odd or even
		and #$01
		bne !done+						// if odd, no increase (100,300,500,700,900)

		lda drop_speed_level			// only increase on even hundreds
		cmp #MAX_SPEED_LEVEL
		bcs !done+
		inc drop_speed_level

!done:	rts
}

update_bonus_mode:	{
		lda bonus_mode_active
		beq !done+
		
		// 16-bit increment
		inc bonus_mode_timer
		bne !no_carry+
		inc bonus_mode_timer+1
!no_carry:

		// 16-bit compare with BONUS_MODE_DURATION ($5dc = 1500)
		lda bonus_mode_timer+1
		cmp #>BONUS_MODE_DURATION   // Compare high byte first
		bcc !done+                   // If less than, continue bonus
		bne !end_bonus+              // If greater than, end bonus
		
		lda bonus_mode_timer         // High bytes equal, check low byte
		cmp #<BONUS_MODE_DURATION
		bcc !done+                   // If less than, continue bonus
		
!end_bonus:
		// Bonus time over
		lda #$00
		sta bonus_mode_active
		sta bonus_mode_timer
		sta bonus_mode_timer+1

!done:
		rts
}

check_bonus_300:	{
		lda consecutive_score
		cmp #$03
		bcc !done+                  // < $0300
		bne !activate+              // > $03FF, definitely activate
    
    // Exactly $03xx - any value triggers (>= $0300)
!activate:
		lda miss_free_run
		beq !done+
		
		lda bonus_mode_active
		bne !done+
		
		lda #$01
		sta bonus_mode_active
		
		lda #$00
		sta consecutive_score
		sta consecutive_score+1
		sta top_lives          		// misses are cleard when entering the bonus stage
		sta bottom_lives  

!done:
    	rts
}

update_sfx: {
// Sound effect player
		lda sfx_active				// is there an acitve sfx?
		beq !done+					// if no, exit

		lda lady_spill_active		// is there any miss?
        ora gent_spill_active		// miss will be the priority
        ora fire_active
        beq !continue+				// if no, continue

		lda sfx_type
        cmp #$04                	// Is the current request a miss sound?
        beq !continue+

		// Otherwise, it's a "phantom" drop sound during a miss. Kill it!
        lda #$00
        sta sfx_active
        rts

!continue:
		lda sfx_type
		cmp #$00
		bne !check1+
		jmp drop_left
!check1:
		cmp #$01
		bne !check2+
		jmp drop_mid
!check2:
		cmp #$02
		bne !check3+
		jmp drop_right
!check3:
		cmp #$03
		bne !check4+
		jmp catch_sound
!check4:
		cmp #$04
		bne !done+
		jmp miss_sound 

!done:
    	rts
}

drop_left: {
		lda sfx_counter
		bne !continue+
    
    	// Mid pitched drip (for left track - sound #2)
		lda #$00
		sta $d407
		lda #$25            // Medium frequency
		sta $d408
		lda #$00
		sta $d40c
		lda #$f5
		sta $d40d
		lda #$11            // Triangle wave
		sta $d40b
    
!continue:
		inc sfx_counter
		lda sfx_counter
		cmp #$04
		bne !done+
		
		lda #$10
		sta $d40b
		lda #$00
		sta sfx_active
		sta sfx_counter
!done:
    	rts
}

drop_mid: {
		lda sfx_counter
		bne !continue+
    
		// Low pitched drip (for middle track - sound #1)
		lda #$00
		sta $d407
		lda #$18            // Lower frequency
		sta $d408
		lda #$00
		sta $d40c
		lda #$f5
		sta $d40d
		lda #$11            // Triangle wave
		sta $d40b
    
!continue:
		inc sfx_counter
		lda sfx_counter
		cmp #$04
		bne !done+
		
		lda #$10
		sta $d40b
		lda #$00
		sta sfx_active
		sta sfx_counter
!done:
    	rts
}

drop_right: {
		lda sfx_counter
		bne !continue+
		
		// High pitched drip (for right track - sound #3)
		lda #$00
		sta $d407
		lda #$30            // Higher frequency
		sta $d408
		lda #$00
		sta $d40c
		lda #$f5
		sta $d40d
		lda #$11            // Triangle wave
		sta $d40b
    
!continue:
		inc sfx_counter
		lda sfx_counter
		cmp #$04
		bne !done+
		
		lda #$10
		sta $d40b
		lda #$00
		sta sfx_active
		sta sfx_counter
!done:
   		rts
}

catch_sound: {
		lda sfx_counter
		bne !continue+
		
		// Highest pitched drip sound (catch/score)
		lda #$00
		sta $d407
		lda #$35            // Highest frequency
		sta $d408
		lda #$00
		sta $d40c
		lda #$f5
		sta $d40d
		lda #$11            // Triangle wave
		sta $d40b
    
!continue:
		inc sfx_counter
		lda sfx_counter
		cmp #$04
		bne !done+
		
		lda #$10
		sta $d40b
		lda #$00
		sta sfx_active
		sta sfx_counter
!done:
    	rts
}

miss_sound: {
		lda sfx_counter
		bne !continue+
		
		// Higher pitched buzzing sound
		lda #$80            // Higher frequency
		sta $d40e
		lda #$0f            // Higher high byte
		sta $d40f
		lda #$00
		sta $d413
		lda #$f0
		sta $d414
		lda #$08            // Pulse width
		sta $d410
		lda #$18
		sta $d411
		lda #$41            // Pulse wave for buzz
		sta $d412
		
!continue:
		// Faster pulse width modulation for more buzzing
		inc pwm_counter
		
		// Toggle every frame for faster buzz
		lda pwm_counter
		and #$01            // Check bit 0
		beq !width1+
		lda #$08
		sta $d410
		lda #$18
		sta $d411
		jmp !done_pwm+
!width1:
		lda #$10
		sta $d410
		lda #$10
		sta $d411
!done_pwm:
		
		inc sfx_counter
		lda sfx_counter
		cmp #$08            // Duration (10 frames as you liked)
		bne !done+
		
		lda #$40
		sta $d412
		lda #$00
		sta sfx_active
		sta sfx_counter
		sta pwm_counter
!done:
		rts
}

silence_all_channels: {
        lda #$00
        sta $d404   // Voice 1 Control (Gate Off)
        sta $d40b   // Voice 2 Control (Gate Off)
        sta $d412   // Voice 3 Control (Gate Off)
        rts
}

// * = $8800 "Score Font Library"
font_library:
    .byte $7c, $ba, $c6, $c6, $c6, $00, $00, $c6, $c6, $c6, $ba, $7c	    // 0
    .byte $02, $06, $06, $06, $06, $00, $00, $06, $06, $06, $06, $02	    // 1
    .byte $fc, $7a, $06, $06, $06, $7a, $bc, $c0, $c0, $c0, $bc, $7e	    // 2
    .byte $fc, $7a, $06, $06, $06, $7a, $3c, $06, $06, $06, $7a, $fc	    // 3
    .byte $82, $c6, $c6, $c6, $c6, $ba, $7c, $06, $06, $06, $06, $02	    // 4
    .byte $7e, $bc, $c0, $c0, $c0, $bc, $7a, $06, $06, $06, $7a, $fc	    // 5
    .byte $7e, $bc, $c0, $c0, $c0, $bc, $7a, $c6, $c6, $c6, $ba, $7c	    // 6
    .byte $fc, $7a, $06, $06, $06, $02, $04, $06, $06, $06, $06, $02	    // 7
    .byte $7c, $ba, $c6, $c6, $c6, $ba, $7c, $c6, $c6, $c6, $ba, $7c	    // 8
    .byte $7c, $ba, $c6, $c6, $c6, $ba, $7c, $06, $06, $06, $7a, $fc	    // 9
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00		// space

// Sprite pointer and data
// VIC bank 1 = $4000
// Sprite data at $4c00 - $4000 = $c00
// Each sprite is 64 ($40) bytes 
// $c00 / $40 = $30 , so first sprite pointer is $30

// * = $4800 "Variables and tables"
//sprite pointers for game playing - TOP ----------------------------------------------------------

sprite_top_0_pointer:			.byte $61, $62									// game A/B
sprite_top_1_pointer:			.byte $64, $4a, $4b, $4c						// top miss
sprite_top_2_pointer:			.byte $3f, $40, $40, $40, $00					// oil drop	
sprite_top_3_pointer:			.byte $31, $31, $32, $33, $34, $35, $35			// empty bucket pointers 
								.byte $31, $31, $36, $37, $38, $35, $35			// 1 drop bucket pointers
								.byte $31, $31, $39, $3a, $3b, $35, $35			// 2 drop bucket pointers
								.byte $31, $31, $3c, $3d, $3e, $35, $35			// 3 drop bucket pointers
sprite_top_4_l_pointer:			.byte $41, $42, $43, $41, $42, $43, $41, $42	// left fire	
sprite_top_4_m_pointer:			.byte $44, $45, $46, $44, $45, $46, $44, $45	// middle fire
sprite_top_4_r_pointer:			.byte $47, $48, $49, $47, $48, $49, $47, $48	// right fire

//sprite pointers for game playing - BOTTOM--------------------------------------------------------
sprite_bottom_0_pointer:		.byte $30								// score
sprite_bottom_1_pointer:		.byte $64, $4d, $4e, $4f				// bottom miss
sprite_bottom_2_pointer:		.byte $51, $50, $64, $64, $64, $52, $53	// bucket man left & right
sprite_bottom_3_pointer:		.byte $54, $55, $56, $57				// collector
sprite_bottom_4_pointer:		.byte $5e, $5f							// spilling oil (oil on floor stays), both for lady and gentleman
sprite_bottom_5_pointer:		.byte $58, $59, $5a, $59				// lady animation
sprite_bottom_6_pointer:		.byte $5b, $5c, $5d, $5c				// gentleman animation
sprite_bottom_7_pointer:		.byte $65, $66, $60						// oil droping from player & angry icon (puff) for gentleman

// oil drop related tables--------------------------------------------------------------------------

oildrop_spawn_pattern: 			.byte $01, $00, $02, $01, $02, $00, $01, $02, $00
                       			.byte $02, $01, $00, $02, $01, $00		// 0-1-2 = left-mid-right

oildrop_x_coord:				.byte $75, $9f, $c7				// X positions for the 3 horizontal tracks
oildrop_y_coord:				.byte $3c, $46, $50, $5c		// Y positions: 0=Spawn, 1=Fall, 2=Fall, 3=Catch Zone

oil_bottom_score:				.byte $01, $02,$05				// 1 point for 1 drop, 2 points for 2 drops
																// 5 points for 3 drops

drop_fall_speed_table_a: 		.byte $22, $1f, $1c, $19, $16, $13	// drop fall speed table for game A
drop_fall_speed_table_b: 		.byte $1f, $1c, $19, $16, $13, $10	// drop fall speed table for game B

// player movement (upper screen)--------------------------------------------------------------------
player_x_coord:				.byte $60, $60, $73, $9d, $c5, $dc, $dc
							.byte $60, $60, $73, $9d, $c5, $dc, $dc
							.byte $60, $60, $73, $9d, $c5, $dc, $dc
							.byte $60, $60, $73, $9d, $c5, $dc, $dc

player_y_coord:				.byte $65, $65, $63, $63, $63, $65, $65
							.byte $65, $65, $63, $63, $63, $65, $65
							.byte $65, $65, $63, $63, $63, $65, $65
							.byte $65, $65, $63, $63, $63, $65, $65

player_bot_x_coord:			.byte $87, $87, $00, $00, $00, $ca, $ca
player_bot_y_coord:			.byte $af, $af, $00, $00, $00, $af, $af

// collector movement (bottom secreen)----------------------------------------------------------------
collector_table:			.byte $03, $02, $01, $00, $01, $02

collector_x_coord:			.byte $83, $99, $b5, $cd
collector_y_coord:			.byte $c5

collector_speed_table_a:      .byte $2a, $28, $24, $22, $1e  // collector speeds per level for game A
collector_edge_wait_table_a:  .byte $48, $42, $3e, $38, $32  // edge waits per level for game A

collector_speed_table_b:      .byte $2a, $26, $22, $20, $1c  // collector speeds per level for game B
collector_edge_wait_table_b:  .byte $38, $34, $30, $2a, $26	// edge waits per level for game B

// other variables -------------------------------------------------------------------------------
score_update_flag:				.byte $00
score_bcd:						.byte $00, $00      // Stores 0000
digit_ones:						.byte $00
digit_tens:						.byte $00
digit_huns:						.byte $00
row_temp:						.byte $00
sprite_idx:						.byte $00
math_temp:						.byte $00
leading_zero_flag:				.byte $00
leftkey:						.byte $4e			// n
rightkey:						.byte $4d			// m	
game_mode:						.byte $00			// 0=game A		1=game B
top_lives:						.byte $00
bottom_lives:					.byte $00
oildrop_table_index:			.byte $00			// index for looking at the spawn table
oildrop_current_track:			.byte $00			// current oil drop track (horizontally 1-2-3)
oildrop_current_step:			.byte $00			// current oil drop step (vertically 1-2-3-4)
oildrop_active:					.byte $00
collector_pointer:				.byte $00
collector_timer:				.byte $00
frame_done_flag:				.byte $00			// sync flag (IRQ and main loop)
drop_spawn_timer:				.byte $00
drop_fall_timer:				.byte $00
catch_timer:    				.byte $00
player_position:				.byte $03			// between 0-6, starting position = 3 middle
player_position_temp:			.byte $00
player_pointer:					.byte $03			// calculated togeter with the position and number of drops
player_drop_number:				.byte $00			// between 0-3
points_to_add:					.byte $00
score_counter: 					.byte $00
bucket_poured:					.byte $00
score_increment_timer: 			.byte $00
pour_animation_active: 			.byte $00   		// 0=off, 1=pouring left, 2=pouring right
pour_animation_timer:  			.byte $00
fire_active: 					.byte $00           // 0=no fire, 1=left, 2=middle, 3=right
fire_timer: 					.byte $00           // counts frames fire has been active
fire_frame: 					.byte $00           // current animation frame (0-7)
fire_anim_timer: 				.byte $00           // counts frames until next animation frame
lady_spill_active:				.byte $00           // 0=no spill, 1=spilling
lady_spill_timer: 				.byte $00           // counts frames between steps
lady_spill_frame: 				.byte $00  
gent_spill_active: 				.byte $00           // 0=no spill, 1=spilling
gent_spill_timer: 				.byte $00
gent_spill_frame: 				.byte $00
drop_speed_level: 				.byte $00
last_hundred: 					.byte $00 
bonus_mode_active: 				.byte $00        	// 0=normal, 1=bonus mode active
bonus_mode_timer: 				.word $0000        	// counts frames in bonus mode
consecutive_score: 				.word $0000 		// Tracks score since last miss (16-bit BCD)
miss_free_run: 					.byte $00   
high_score_bcd: 				.byte $00, $00
sfx_active:  					.byte $00      // 0=off, 1=playing
sfx_type:    					.byte $00      // 0=left drop, 1=mid drop, 2=right drop, 3=catch, 4=miss
sfx_counter: 					.byte $00      // Frame counter for duration
pwm_counter: 					.byte $00      // For pulse width modulation

// imported files ----------------------------------------------------------------------------------

* = $4c00 "Sprite data"
.import binary ".\assets\oil panic sprites.bin"
 
* = $6000 "Bitmap screen"
.import c64 ".\assets\oilpanic3.kla"
// Koala bitmap settings for image at $6000
//scrData=		$7f40
//scrRam=		$5c00
//colData=		$8328
//colRam=		$d800

* = $4000 "Character Set Data"
.import binary ".\assets\op_intro screen - Chars_alt.bin"

* = $4800 "Character Set Attributes"
.import binary ".\assets\op_intro screen_alt - CharAttribs_L1_alt.bin"

* = $8800 "Map Data"
.import binary ".\assets\op_intro screen - Map (8bpc, 40x25)_alt.bin"

* = $3000 "Intro Song"
.import c64 ".\assets\shikata-oilpanic.prg"

//LOG--------------------------------------------------------------------------------------------
//v1 & v2 bitmap graphics and sprites have been drawn (02-03.02.2026)
//v3 (04.02.2026)
// Using raster split, the 1st and 2nd sprites have been reused on the 
// bottom of the screen.
//v4 (04.02.2026)
// Sprites are being designed during this period. Due to the amount of sprites, 
// the base memory has been declared as $4800. 
// Also, the first sprite is reserved for score table. The score digits are converted to 
// single sprite and then combined by necessary number sprites from font library.
// After 999, it reverts back to 0.
//v5 (06.02.2026)
// In the score, now zero values in the tens and huns don't show.
// Sprite design stage has been completed. Sprite animation pointers have been added but to be checked.
// Sprite base address moved to $4c00.
//v6 (08.02.2026)
// An intro screen is added. A screen prepared in CharPad is accompanied with music 
// and scrolling text.
//v7 (08.02.2026)
// Addresses used for intro map etc. have been reorganized.
// Intro screen (in intro.asm) has been re-written. A text info screen has been added. 
// Also new key assignment routine has been included.
//v8 (09.02.2026)
// & sign has been fixed in intro screen. Top and bottom bars have been drawn in the text screen.
// Bitmap screen now has "Game A & B" buttons
// Game type selection, new key selection and start buttons are programmed on function keys in intro.asm
// Now game type is correctly shown on the game (bitmap) screen
//v9 (10.02.2026)
// Control keys have been changed to Z and M.
// Oil drop pattern has been written (not fully implemented)
// Collector moving routine has been written for both game modes (B is slightly faster)
//V10 (10.02.2026)
// Oil drop routine implemented
//v11 (11.02.2026)
// Oil drop delay routine implemented for both game modes
// Music has been relocated from $c400 to $9400 
// Top screen player routine implemented. Oil drops also fill the bucket.
//v12 (11.02.2026)
// Oild drops and the player routines have been rewritten (flicker and garbage sprites eliminated)
// Now the player can catch the drops and gets the point. 
//v13 (12.02.2026)
// Player on the bottom screen is active now. Also scoring algorith is revised.
// During pouring, the digits can been seen incrementing.
//v14 (14.02.2026)
// Bottom misses lives have been added. Collector at the bottom now waits while the bucket is emptied.
//v15 (14.02.2026)
// Animation for bottom oil drop emptying has been added (sprites updated).
// At the "manin" section, randmoization of drop spawn at the beginning of the game has been added.
// Animation of top fires have been added.
//v16 (14.02.2026)
// Both lady and gent animation have been added.
// v17 (14.02.2026)
// The speed of oils dripping now is increase at every 100 points (upto 500) and stays there.
// During lady and gent animation, now the player cannot play, oil does not spawn, and collector does not move.
//v18 (14.02.2026)
// Bonus section added. Any time in the game, after 300 points without a miss causes bonus stage, where
// the collector is doubled on the edges and also points for pouring are also doubled for around 30 seconds.
//V19 (14.02.2026)
// The ending routine has been established. Game Over sprite is written, and if there is a high score
// a High Score sprite flashes and returns back to the info text screen.
//v20 (15.02.2026)
// Sound effets for drops and misses have been added. Some timings were also finetuned.
// Intro screen has been changed to a new one (with red circular oil panic text).
// Intro text screen has been colored.
// Now the left/right keys are reflected to the screen together with the changes.
// Game code is between $0800-$9a3a (37.434 bytes - 36k)
//v21 (15.02.2026)
// The speed increase has been adjusted to work at even hundreds (200-400-600-800).
// The music has been relocated. I can't find the original .sng file for Goattracker but I have the
// SID file. I relocated it using SIDRELOC to $3000, and using Kickassembler's Loadsid command
// I could play it in the game. Since I moved the sonf from $9400 to $3000, the 3K at the end of
// the program freed, so now the  game is shorter. Some polishing in the lady/gent animation.
// The drop spawn pattern is increased to 15 steps to balance the patterns.
// Intro & game screens have been altered for any possible copyright claims from Nintendo.
// As mentioned now, this is a non-profit fan-made game.
//v22 (17.02.2026)
// New music has been written in Goattracker (shikata).
// Some minor tweaks done, some unused variables removed.
//v23 (18.02.206)
// Testing and some minor tweaks.
//v24
// Testing and collector speed table update. Now the collector also gets a speed increase.
// I'm not sure how I missed that before.
// Now misses will be cleared when entering the bonus stage.
// High score is now shown on the info text screen. If resetted the game after 999
// the high score will alway show 999.






