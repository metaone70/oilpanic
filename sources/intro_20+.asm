* = $2400   "Intro Screen"      // intro.asm for v8
* = *   "Intro Screen"      // intro.asm for v8

intro_screen:   
        DrawScreen2($8800,$5c00,$4800)
        // ClearColorRam(LIGHT_GRAY)

        lda #$00            // Song number 0
        jsr music_init      // Initialize the GoatTracker tune

        lda #<intro_message
        ldy #>intro_message
        sta read+1
        sty read+2
        lda #<textirq1
        sta $314
        lda #>textirq1
        sta $315
        lda #$1b
        sta $d011
        lda #$7f
        sta $dc0d
        lda #$01
        sta $d01a
        lda $dc0d
        lda $dd0d
        cli

hold:   
        jsr $ffe4       
        beq hold 

text_intro_screen:        

	SetBorderColor(BLACK)
	SetBackgroundColor(BLACK)
         ClearScreen(VIC_SCREEN_MEMORY,$20)
        ClearColorRam(LIGHT_GRAY)

        lda #<VIC_SCREEN_MEMORY                 // write text data to screen
        sta screen_ptr
        lda #>VIC_SCREEN_MEMORY
        sta screen_ptr+1
        lda #<info_text
        sta data_ptr
        lda #>info_text
        sta data_ptr+1

        ldx #$00
        ldy #$00
itext:  lda (data_ptr),y
        sta (screen_ptr),y        
        iny
        bne itext
        inc screen_ptr+1
        inc data_ptr+1
        inx
        cpx #$04
        bne itext

// write the game mode on screen (A or B)
        lda game_mode   
        clc
        adc #$01
        sta VIC_SCREEN_MEMORY + (40*13) + 28

        // Title line (row 2) - WHITE
        ldx #$00
!:      lda #WHITE
        sta $d800 + (40*2),x
        inx
        cpx #$28
        bne !-

        // Copyright (row 3) - WHITE
        ldx #$00
!:      lda #WHITE
        sta $d800 + (40*3),x
        inx
        cpx #$28
        bne !-

        // Story text (rows 5-8) - YELLOW
        ldx #$00
!:      lda #YELLOW
        sta $d800 + (40*5),x
        sta $d800 + (40*6),x
        sta $d800 + (40*7),x
        sta $d800 + (40*8),x
        inx
        cpx #$28
        bne !-

        // F1 instruction (row 10) - LIGHT GREEN
        ldx #$00
!:      lda #LIGHT_GREEN
        sta $d800 + (40*10),x
        inx
        cpx #$28
        bne !-

        // F3 instruction (row 12-13) - GREEN
        ldx #$00
!:      lda #GREEN
        sta $d800 + (40*12),x
        sta $d800 + (40*13),x
        inx
        cpx #$28
        bne !-

        // Keys info (row 15-16) - LIGHT GREEN
        ldx #$00
!:      lda #LIGHT_GREEN
        sta $d800 + (40*15),x
        sta $d800 + (40*16),x
        inx
        cpx #$28
        bne !-

        // F5 instruction (row 18) - GREEN
        ldx #$00
!:      lda #GREEN
        sta $d800 + (40*18),x
        inx
        cpx #$28
        bne !-

        // Rest (row 19-24) - WHITE
        ldx #$00
!:      lda #WHITE
        sta $d800 + (40*19),x
        inx
        cpx #$f0
        bne !-

        lda leftkey
        sec
        sbc #$40
        sta VIC_SCREEN_MEMORY + (40*16) + 7

        lda rightkey
        sec
        sbc #$40
        sta VIC_SCREEN_MEMORY + (40*16) + 20


// now lets draw the top and bottom frame
        ldx #$00
draw_horizontal:
        lda #$3c
        sta VIC_SCREEN_MEMORY,x
        sta VIC_SCREEN_MEMORY+960,x
        inx
        cpx #$28
        bne draw_horizontal

 // we have text on screen, now to stop music and scrolling text
        jsr stop_music
        lda #$31
        sta $0314
        lda #$ea
        sta $0315
        lda #$1b
        sta $d011
        lda #$00
        sta $d016
        lda #$00
        sta $d01a
        cli 

// check keyboard for function keys
	lda #$01                
        sta $0289		// disable keyboard buffer
	lda #$7f
	sta $028a		// disable key repeat

kloop:  jsr $ff9f                // waits for any key
        jsr $ffe4       
        beq kloop 
  
        cmp #$85                // f1 key
        beq !+                  // go to start

        cmp #$86                // f3 key
        beq change_game_type    // toggle game type

        cmp #$87                // f5 key
        beq new_key             // assign new keys for control
  
        jmp kloop

 !:     jmp main

change_game_type:

        lda game_mode
        eor #$01
        sta game_mode
        lda game_mode
        clc
        adc #$01
        sta VIC_SCREEN_MEMORY + (40*13) +28     // write the current type on screen
        
        jmp kloop
        
new_key:        
        ldx #$00
key_l:  lda new_left_key_text,x
        sta VIC_SCREEN_MEMORY + $34a,x          // write message to screen
        inx
        cpx #$28
        bne key_l

!:      jsr $ff9f                               // clear keyboard buffer
        jsr $ffe4
        bne !-

lk:     jsr $ff9f 
        jsr $ffe4                               // get the new key for left
        beq lk
        sta leftkey

        lda leftkey
        sec
        sbc #$40
        sta VIC_SCREEN_MEMORY + (40*16) + 7

        ldx #$00
key_r:  lda new_right_key_text,x
        sta VIC_SCREEN_MEMORY + $34a,x          // write message to screen 
        inx
        cpx #$28
        bne key_r   

!:      jsr $ff9f                                // clear keyboard buffer
        jsr $ffe4
        bne !-

rk:     jsr $ff9f 
        jsr $ffe4                               // get the new key for right
        beq rk
        sta rightkey

        lda rightkey
        sec
        sbc #$40
        sta VIC_SCREEN_MEMORY + (40*16) + 20

        ldx #$00                                // finally clear the new key text
key_done:
        lda new_keys_assigned,x
        sta VIC_SCREEN_MEMORY + $34a,x          
        inx
        cpx #$28
        bne key_done

        jmp kloop

// scroll text routine
textirq1:      
        inc $d019
        lda #$00 
        sta $d012
        lda smooth         //Scroll 
        sta $d016
        lda #<textirq2
        ldx #>textirq2
        sta $314
        stx $315
        jsr music_play
        jmp $ea7e
                 
textirq2:      
        inc $d019
        lda #$e0
        sta $d012
        lda #$08                  //No scroll 
        sta $d016
        lda #<textirq1
        ldx #>textirq1
        sta $314
        stx $315
        jsr scroll
        jmp $ea31
                 
scroll: 
        lda smooth
        sec
        sbc #$02                //scroll speed
        and #$07 
        sta smooth
        bcs endscroll 
        ldx #$00

wrapmessage:
        lda screenloc+1,x
        sta screenloc,x
        inx
        cpx #$28
        bne wrapmessage
read:   
        lda screenloc+$27
        cmp #$00 
        bne nowrap 
        lda #<intro_message
        ldy #>intro_message
        sta read+1
        sty read+2
        jmp read
nowrap: 
        sta screenloc+$27
        inc read+1
        lda read+1
        cmp #$00
        bne endscroll
        inc read+2
endscroll:
        rts


stop_music: {

        ldx #$18        // 24 registers ($D400-$D418)
        lda #$00
clear_sid:
        sta $d400,x     // Zero out the register
        dex
        bpl clear_sid
        rts
}

intro_message:
        .text " oil panic       a fan tribute to nintendo       "
        .text "press any key to continue to info screen       coding, graphics and music"
        .text " by metesev 2026       this is a non-profit fan project created for educational "
        .text "purposes and to celebrate the history of commodore 64 programming       all " 
        .text "characters and original game designs are trademarks of nintendo co.ltd.       "
        .text "this project is not affiliated with or endorsed by nintendo       "
        .byte $00

info_text:
        .text "                                        " 
        .text "                                        " 
        .text "       oil panic for commodore64        "
        .text "       original game by nintendo        "
        .text "                                        " 
        .text "    a leaky pipe is dripping oil.       "
        .text "   the station helper must collect the  "
        .text "    drops in a bucket and dump them     "
        .text "      into his boss's oil drum.         "
        .text "                                        "
        .text "      press f1 to start the game        "
        .text "                                        "
        .text "   press f3 to change game type (a/b)   "
        .text "        default game type :             "
        .text "                                        "
        .text "          keys for movement             "
        .text "         : left and   : right           "    
        .text "                                        "        
        .text "    press f5 for new key assignment     "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "

new_left_key_text:      .text "       press new key for left           "  
new_right_key_text:     .text "       press new key for right          "  
new_keys_assigned:      .text "        new keys assigned               "

              
