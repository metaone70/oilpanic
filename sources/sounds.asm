// Sound Effects Tester for Oil Panic
// Press keys to test different sounds:
// 1,2,3 = Drop spawn on left/middle/right track
// C = Catch drop / score increment
// F = Fire animation sound
// S = Spill animation sound
// SPACE = Stop all sound

BasicUpstart2(start)

start: {
    lda #$00
    sta $d020
    sta $d021
    
    // Initialize SID
    lda #$00
    ldx #$00
!:  sta $d400,x
    inx
    cpx #$18
    bne !-
    
    // Set volume
    lda #$0f
    sta $d418
    
    // Clear screen
    ldx #$00
    lda #$20
!:  sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne !-
    
    // Print instructions on screen
    ldx #$00
!:  lda text_line1,x
    beq !next1+
    sta $0400,x
    inx
    jmp !-
    
!next1:
    ldx #$00
!:  lda text_line2,x
    beq !next2+
    sta $0450,x
    inx
    jmp !-
    
!next2:
    ldx #$00
!:  lda text_line3,x
    beq !next3+
    sta $04a0,x
    inx
    jmp !-

!next3:
    ldx #$00
!:  lda text_line4,x
    beq !next4+
    sta $04f0,x
    inx
    jmp !-

!next4:
    ldx #$00
!:  lda text_line5,x
    beq !next5+
    sta $0540,x
    inx
    jmp !-

!next5:
    ldx #$00
!:  lda text_line6,x
    beq main_loop
    sta $0590,x
    inx
    jmp !-
}
    
main_loop: {
    // Wait for raster to create timing
!:  lda $d012
    cmp #$ff
    bne !-
    
    jsr update_sfx      // Update sound effects
    
    jsr $ffe4           // Get key
    beq main_loop
    
    cmp #$31            // '1'
    bne !check2+
    jmp play_drop_left
!check2:
    cmp #$32            // '2'
    bne !check3+
    jmp play_drop_mid
!check3:
    cmp #$33            // '3'
    bne !checkc+
    jmp play_drop_right
!checkc:
    cmp #$43            // 'C'
    bne !checkf+
    jmp play_catch
!checkf:
    cmp #$46            // 'F'
    bne !checks+
    jmp play_fire
!checks:
    cmp #$53            // 'S'
    bne !checkspace+
    jmp play_spill
!checkspace:
    cmp #$20            // SPACE
    bne !skip+
    jmp stop_sound
!skip:
    jmp main_loop
}

play_drop_left: {
    lda #$01
    sta sfx_active
    lda #$00
    sta sfx_type
    lda #$00
    sta sfx_counter
    jmp main_loop
}

play_drop_mid: {
    lda #$01
    sta sfx_active
    lda #$01
    sta sfx_type
    lda #$00
    sta sfx_counter
    jmp main_loop
}

play_drop_right: {
    lda #$01
    sta sfx_active
    lda #$02
    sta sfx_type
    lda #$00
    sta sfx_counter
    jmp main_loop
}

play_catch: {
    lda #$01
    sta sfx_active
    lda #$03
    sta sfx_type
    lda #$00
    sta sfx_counter
    jmp main_loop
}

play_fire: {
    lda #$01
    sta sfx_active
    lda #$04
    sta sfx_type
    lda #$00
    sta sfx_counter
    jmp main_loop
}

play_spill: {
    lda #$01
    sta sfx_active
    lda #$04            // Same as fire (type 4)
    sta sfx_type
    lda #$00
    sta sfx_counter
    jmp main_loop
}

stop_sound: {
    lda #$00
    sta $d404           // Voice 1 control
    sta $d40b           // Voice 2 control
    sta $d412           // Voice 3 control
    sta sfx_active
    jmp main_loop
}

// Sound effect player - call this regularly
update_sfx: {
    lda sfx_active
    bne !continue+
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
    jmp miss_sound      // Both fire and spill use this
!done:
    rts
}

drop_left: {
    lda sfx_counter
    bne !continue+
    
    // Low pitched drip (left track)
    lda #$00
    sta $d407           // Frequency low
    lda #$18            // Lower frequency
    sta $d408
    lda #$00            // Fast attack
    sta $d40c
    lda #$f5            // Quick decay
    sta $d40d
    lda #$11            // Triangle wave for drip
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
    
    // Mid pitched drip (middle track)
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

drop_right: {
    lda sfx_counter
    bne !continue+
    
    // High pitched drip (right track)
    lda #$00
    sta $d407
    lda #$30            // Close to catch frequency
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
    sta $d407           // Frequency low
    lda #$35            // Highest frequency
    sta $d408
    lda #$00            // Fast attack
    sta $d40c
    lda #$f5            // Quick decay
    sta $d40d
    lda #$11            // Triangle wave for drip
    sta $d40b
    
!continue:
    inc sfx_counter
    lda sfx_counter
    cmp #$04            // Short drip sound
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
    lda #$a0            // Higher frequency
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
    
    // Toggle every 2 frames instead of 4 for faster buzz
    lda pwm_counter
    // lsr                 // Divide by 2
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
    cmp #$08            // Duration
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

// Variables
sfx_active:  .byte $00      // 0=off, 1=playing
sfx_type:    .byte $00      // 0-2=drop tracks, 3=catch, 4=miss (fire/spill)
sfx_counter: .byte $00      // Frame counter for duration
pwm_counter: .byte $00      // For pulse width modulation


// Text strings in data section
text_line1:
.encoding "screencode_mixed"
.text "oil panic sound fx tester"
.byte $00

text_line2:
.encoding "screencode_mixed"
.text "press 1,2,3 - drop spawn (left/mid/right)"
.byte $00

text_line3:
.encoding "screencode_mixed"
.text "press c - catch drop / score tick"
.byte $00

text_line4:
.encoding "screencode_mixed"
.text "press f - fire/miss sound"
.byte $00

text_line5:
.encoding "screencode_mixed"
.text "press s - spill/miss sound (same as f)"
.byte $00

text_line6:
.encoding "screencode_mixed"
.text "press space - stop all sound"
.byte $00

