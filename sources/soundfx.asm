//--------------------------------------
// SID SFX ENGINE (Voice 3 Only)
//--------------------------------------

.const SID = $D400

// Voice 3 offsets
.const V3_FREQ_LO = $0E
.const V3_FREQ_HI = $0F
.const V3_PW_LO   = $10
.const V3_PW_HI   = $11
.const V3_CTRL    = $12
.const V3_AD      = $13
.const V3_SR      = $14

//--------------------------------------
// Variables
//--------------------------------------

drop_active:      .byte 0
drop_timer:       .byte 0

//--------------------------------------
// INIT (Call once at game start)
//--------------------------------------

sfx_init:
    lda #$0F
    sta SID+$18        // Volume max, no filter
    rts

//--------------------------------------
// TRIGGER DROP
//--------------------------------------

sfx_drop_trigger:

    lda #0
    sta SID+V3_CTRL        // ensure gate off

    // ADSR
    lda #$08               // fast attack/decay
    sta SID+V3_AD
    lda #$20               // low sustain, fast release
    sta SID+V3_SR

    jsr random
    and #3
    cmp #3
    bne !+
    lda #2
!:
    tax

    lda drop_freq_lo,x
    sta SID+V3_FREQ_LO
    lda drop_freq_hi,x
    sta SID+V3_FREQ_HI

    // Triangle waveform + Gate
    lda #$11
    sta SID+V3_CTRL

    lda #1
    sta drop_active

    lda #6                 // duration (frames)
    sta drop_timer

    rts

//--------------------------------------
// UPDATE (Call every frame from IRQ)
//--------------------------------------


random:
    lda $DC04
    rts


sfx_update:

    lda drop_active
    beq sfx_done

    lda drop_timer
    beq sfx_stop

    dec drop_timer

    // small downward sweep
    lda SID+V3_FREQ_LO
    sec
    sbc #2
    sta SID+V3_FREQ_LO

    lda SID+V3_FREQ_HI
    sbc #0
    sta SID+V3_FREQ_HI

    rts

sfx_stop:
    lda #$10               // triangle without gate
    sta SID+V3_CTRL

    lda #0
    sta drop_active

sfx_done:
    rts

drop_freq_lo:
    .byte $40, $48, $60
drop_freq_hi:
    .byte $15, $17, $19