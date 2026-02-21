// Macro List:
// ClearScreen(screen,clearByte)
// ClearColorRam(clearByte)
// SetBorderColor(color)
// SetBackgroundColor(color)
// PrintScreen(message,screenstart, xcoor,ycoor,color,textlength)
// PrintByteScreen(byteaddress,xcoor,ycoor,color)
// PrintByteScreen2(bytevalue,screenstart,xcoor,ycoor,color)
// DrawScreen(screenData,colorData,screenAddress)
// DrawScreen2(screenData,screenAddress)
// DrawBitmap(scrData,scrRam,colData)
// WaitSpaceKey()
// WaitAKey()
// StoreState()
// RestoreState()
// waitForRasterLine(line)

.macro ClearScreen(screen,value) {
	lda #value	// space
	ldx #0
!loop:
	sta screen, x
	sta screen + $100, x
	sta screen + $200, x
	sta screen + $2e9, x
	inx
	bne !loop-
}

.macro ClearColorRam(color) {
	lda #color
	ldx #0
!loop:
	sta $d800, x
	sta $d800 + $100, x
	sta $d800 + $200, x
	sta $d800 + $2e9, x
	inx
	bne !loop-
}

.macro SetBorderColor(color) {
	lda #color
	sta $d020
}

.macro SetBackgroundColor(color) {
	lda #color
	sta $d021
}

.macro WaitSpaceKey() {
!:	lda $dc01
	and #$10
	bne !-
}

.macro WaitAKey() {
loop:   jsr $ff9f                // waits for any key
        jsr $ffe4       
        beq loop 
}

.macro WaitJoy1Fire() {
!Joy1:	lda $dc01
	lsr 
	lsr 
	lsr 
	lsr 
	lsr 
	bcc !+
	jmp !Joy1-
!:		
}

.macro WaitJoy2Fire() {
!Joy2:	lda $dc00
	lsr 
	lsr 
	lsr 
	lsr 
	lsr 
	bcc !+
	jmp !Joy2-

!:		
}


.macro StoreState() {
		pha //A
		txa 
		pha //X
		tya 
		pha //Y
}

.macro RestoreState() {
		pla //A
		tay
		pla //X
		tax 
		pla //Y
}

.macro waitForRasterLine(line) {
		lda #line
!loop:	cmp $d012
		bne !loop-	
}

.macro PrintScreen(message,screenstart, xcoor,ycoor,color,textlength) {
	.var textAddress = screenstart + (ycoor*40)+xcoor
	.var colorAddress = $d800+(ycoor*40) + xcoor
	StoreState()
	ldx #$00
!loop:  lda message,x
	sta textAddress,x 
	inx
	cpx #textlength	
	bne !loop-

	ldx #$00
!loop:	lda #color 
	sta colorAddress,x 
	inx
	cpx #textlength
	bne !loop-
	RestoreState()
}

.macro DrawScreen(screenData,colorData,screenAddress) {
	lda #$00
	sta $f7
	sta $f9			
	sta $fb
	sta $fd			

	lda #>screenAddress	
	sta $fe 
	lda #$d8
	sta $f8			
	lda #<colorData
	sta $f9			
	lda #>colorData
	sta $fa
	lda #<screenData
	sta $fb
	lda #>screenData
	sta $fc
      	
        ldx #$00
loop1:       
        ldy #$00
loop2:     
        lda ($fb),y             
        sta ($fd),y            
        lda ($f9),y
        sta ($f7),y
        iny
        bne loop2
        inc $fc
        inc $fe
        inc $fa
        inc $f8
        inx
        cpx #$04
        bne loop1

//screen:
//        .byte    $20,$20
//color:
//        .byte    $01,$01
}

// draw full map to screen
.macro DrawScreen2(SourceAddress,TargetAddress, AttribAddress) {

	lda #<SourceAddress
	sta $f7
	lda #>SourceAddress
	sta $f8
	lda #<TargetAddress
	sta $f9 
	lda #>TargetAddress
	sta $fa
    	
        ldx #$00
loop1:       
        ldy #$00
loop2:     
        lda ($f7),y             
        sta ($f9),y            
        iny
        bne loop2
        inc $f8
        inc $fa 
        inx
        cpx #$04
        bne loop1

   	// this part is to set the color of multicolor characters
   	// we first get the character # from secreen, we find its attrib 
   	// from the attrib table and store it to its color RAM
   	// and we do it 4 times (4x256=1000 characters)
   	ldy #$00
!:	lda TargetAddress,y 	// get the character value from screen position
	tax 
   	lda AttribAddress,x 			// get the attribute of the character
   	sta $d800,y 		// and store it to its color RAM
   	lda TargetAddress+$100,y
   	tax 
   	lda AttribAddress,x 
   	sta $d800+$100,y
   	lda TargetAddress+$200,y
   	tax 
   	lda AttribAddress,x 
   	sta $d800+$200,y
   	lda TargetAddress+$300,y
   	tax 
   	lda AttribAddress,x 
   	sta $d800+$300,y
   	iny 
   	bne !-
}

.macro DrawScreen3(screenData,screenAddress) {
		lda #$00
		sta $f7
		sta $f9			
		sta $fb
		sta $fd			

		lda #>screenAddress	
		sta $fe 
		lda #<screenData
		sta $fb
		lda #>screenData
		sta $fc
      	
        ldx #$00
loop1:       
        ldy #$00
loop2:     
        lda ($fb),y             
        sta ($fd),y            
        lda ($f9),y
        sta ($f7),y
        iny
        bne loop2
        inc $fc
        inc $fe
        inc $fa
        inc $f8
        inx
        cpx #$04
        bne loop1

}

.macro DrawBitmap(scrData,scrRam,colData) {
	.var colRam = $d800
	.var backGroundColor = colData + $03e8

       	ldx #$00
!loop:  lda scrData,x
        sta scrRam,x
        lda scrData+$100,x
        sta scrRam+$100,x
        lda scrData+$200,x
        sta scrRam+$200,x       
        lda scrData+$2e8,x
        sta scrRam+$2e8,x
        lda colData,x
        sta colRam,x
        lda colData+$100,x
        sta colRam+$100,x
        lda colData+$200,x
        sta colRam+$200,x
        lda colData+$2e8,x
        sta colRam+$2e8,x
        inx
        bne !loop-
        lda backGroundColor
        sta $d021

}

.macro PrintByteScreen(byteaddress,xcoor,ycoor,color) {
.var textAddress = $5400+(ycoor*40)+xcoor
.var colorAddress = $d800+(ycoor*40)+xcoor

		StoreState()
		lda #color
		sta colorAddress
		sta colorAddress+1
		lda byteaddress 
		pha
        lsr
        lsr
        lsr
        lsr
		cmp #$0a
        bcs !+
		ora #$30
        bne !++
!:   	sbc #$09
!:	    sta textAddress
		pla
        and #$0f
		cmp #$0a
        bcs !+
	 	ora #$30
        bne !++
!:		sbc #$09
!:	    sta textAddress+1
		RestoreState()
}

.macro PrintChar2Screen(charnumber,screenstart,xcoor,ycoor) {
.var textAddress = screenstart+(ycoor*40)+xcoor
.var colorAddress = $d800+(ycoor*40)+xcoor

		lda #charnumber
		sta textAddress

		ldx #charnumber 	
		lda $5400,x 				
		sta colorAddress
 }

.macro PrintSameChar2Screen(charnumber,screenstart,xcoor,ycoor,number) {
.var textAddress = screenstart+(ycoor*40)+xcoor
.var colorAddress = $d800+(ycoor*40)+xcoor

		ldx #$00
		lda #charnumber
!:		sta textAddress,x 
		inx 
		cpx #number
		bne !-

		ldy #$00
		ldx #charnumber 	
		lda $5400,x 				
!:		sta colorAddress,y 
		iny
		cpy #number 
		bne !-
 }


// 16 bit functions and pseudocommands------------------------------------------
.function _16bit_nextArgument(arg) {
	.if (arg.getType()==AT_IMMEDIATE)
	.return CmdArgument(arg.getType(),>arg.getValue())
	.return CmdArgument(arg.getType(),arg.getValue()+1)
}

// Increment a 16bit variable
.pseudocommand inc16 arg {
		inc arg
	    bne over
		inc _16bit_nextArgument(arg)
over:
}

// Decrement a 16 bit variable
.pseudocommand dec16 arg {
		lda arg
       	bne skip
        dec _16bit_nextArgument(arg) 
skip:   dec arg
}

// Move or Load 16 bit values from/to 16 bit variables
.pseudocommand mov16 src:tar {
		lda src
		sta tar
		lda _16bit_nextArgument(src)
		sta _16bit_nextArgument(tar)
}

// Addition of 16 bits variables
.pseudocommand add16 arg1 : arg2 : tar {
.if (tar.getType()==AT_NONE) .eval tar=arg1
		lda arg1
        adc arg2
        sta tar
        lda _16bit_nextArgument(arg1)
		adc _16bit_nextArgument(arg2)
		sta _16bit_nextArgument(tar)
}
//------------------------------------------------------------------------