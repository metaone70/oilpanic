* = $8c00   "Intro Screen"      // intro.asm for v8

intro_screen:   {
        DrawScreen2($8800,$5c00,$4800)
        ClearColorRam(LIGHT_GRAY)

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
        
        ClearScreen(VIC_SCREEN_MEMORY,$20)
  
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

// now lets draw the top and bottom frame
        ldx #$00
draw_horizontal:
        lda #$97
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
        sta VIC_SCREEN_MEMORY + (40*16) +23     // write the current type on screen
        
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

        ldx #$00                                // finally clear the new key text
key_done:
        lda new_keys_assigned,x
        sta VIC_SCREEN_MEMORY + $34a,x          
        inx
        cpx #$28
        bne key_done

        jmp kloop
}

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
        .text "    oil panic    (c) 1982 nintendo       c64 port by metesev 2026"
        .text "     press any key to continue to info screen        coding, graphics and sound "
        .text " by metesev      "
        .byte $00

info_text:
        .text "                                        " 
        .text "                                        " 
        .text "       oil panic for commodore 64       "
        .text "           (c) 1982 nintendo            "
        .text "                                        " 
        .text "    a leaky pipe is dripping oil.       "
        .text "   the station helper must collect the  "
        .text "    drops in a bucket and dump them     "
        .text "      into his boss's oil drum.         "
        .text "                                        "
        .text "      press f1 to start the game        "
        .text "                                        "
        .text "   press f3 to change game type (a/b)   "
        .text "                                        "
        .text "    press f5 for new key assignment     "
        .text "                                        "
        .text "           game type : a                "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "
        .text "                                        "



new_left_key_text:
        .text "       press new key for left           "  
new_right_key_text:
        .text "       press new key for right          "  
new_keys_assigned:
        .text "        new keys assigned               "

              
        // .text". c64 port by metesev 2026." 
        // .text "a leaky pipe is dripping oil. the station helper must collect these "
        // .text "drops in a bucket and dump them into his boss's oil drum. "
        // .text "the bucket can hold only three drops of oil. for every drop of oil "
        // .text "the station helper catches, he receives a point. he earns a point for "
        // .text "dumping one drop of oil into the oil drum, two points for dumping two "
        // .text "drops, and five points for dumping three drops. if a drop is missed, "
        // .text "if the bucket overflows, or if the station helper dumps his bucket on "
        // .text "a customer, he loses one of four lives. there are two miss counters: "
        // .text "one for missed or overflowing oil, and the other for spilling the oil "
        // .text "onto customers. if the player gets three misses from either of those "
        // .text "categories, the game ends. hope you enjoy playing this old game&watch port."
        // .text "hit any key to continue.             "
        // .byte $00
