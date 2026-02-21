* = $8c00   "Intro Screen"

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
        
        // jsr stop_music
        // lda #$31
        // sta $0314
        // lda #$ea
        // sta $0315
        // lda #$1b
        // sta $d011
        // lda #$00
        // sta $d016
        // lda #$00
        // sta $d01a
        // cli 
        // jmp main

        ClearScreen(VIC_SCREEN_MEMORY,$20)
        //ClearColorRam(LIGHT_GRAY)
  
        lda #<VIC_SCREEN_MEMORY
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
 
 hold2:
        jsr $ffe4       
        beq hold2 
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
        jmp main
  
// new_key:
//         ldx #$00
// key_l:  lda new_left_key_text,x
//         sta VIC_SCREEN_MEMORY + $320,x          // write it to 21st row   
//         inx
//         cpx #$28
//         bne key_l

// !:      jsr $ffe4   
//         beq !-
//         sta leftkey

//         ldx #$00
// key_r:  lda new_right_key_text,x
//         sta VIC_SCREEN_MEMORY + $348,x          // write it to 21st row   
//         inx
//         cpx #$28
//         bne key_r   

// !:      jsr $ffe4   
//         beq !-
//         sta rightkey

//         jmp key_check
 
// continue:
//         jsr stop_music



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
}

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
        .text "       oil panic for commodore 64       "
        .text "         (c) 1982 nintendo              "
        .text "    a leaky pipe is dripping oil.       "
        .text "  the station helper must collect these "
        .text "    drops in a bucket and dump them     "
        .text "      into his boss's oil drum.         "
        .text "                                        "
        .text "   for every drop of oil the station    "
        .text "  helper catches, he receives a point.  "
        .text " he earns a point for dumping one drop  "
        .text "  of oil into the oil drum, two points  "
        .text " for dumping two drops, and five points "
        .text "      for dumping three drops.          "
        .text "                                        "
        .text "  use crsr down for left, crsr right    "
        .text "  for right. press return for new key   "
        .text "  assignment. press space bar to start  "
        .text "               the game.                "
        .text "                                        "      
        
new_left_key_text:
        .text "  press new key for left control        "  
new_right_key_text:
        .text "  press new key for right control       "  

        

        
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
