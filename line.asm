; RAM locations
SCREEN_LOC              = $1e00
COLOR_LOC               = $9600
BASIC_LOC               = $1001
CHAR_LOC                = $1800

; VIC registers
VIC_HORIZ               = $9000
VIC_VERT                = $9001
VIC_COLS                = $9002
VIC_ROWS                = $9003
VIC_RASTER              = $9004
VIC_CHARLOC             = $9005
VIC_MULTIC              = $900e
;VIC_COLORS_LOC          = $900f ; %11110000 => background, %111 => border

; Usable zero page locations (from "Mapping the VIC")
; $0 - $6
; $9 - $a
; $3b - $3c
; $92 - $96
; $9b - $9c
; $9e - $9f
; $a3 - $a5
; $a7 - $b1
; $b4 - $b6
; $bd - $bf 
; $f7 - $fe
CHAR_POINTER        = $0        ; Word
dx                  = $2 
dy                  = $3 
e1                  = $4 
e2                  = $5 
diff                = $6        ; Word
xi                  = $8 
yi                  = $9
pchar_buffer_max    = $a        ; Maximum is $40 or $80, when buffer size is 128 chars
char_ptr            = $3b       ; word
char_x              = $93
char_y              = $94 
char_buffer_index   = $95
coord_buffer_index  = $96
cell                = $9b
pixel               = $9c
yi16                = $9e
line_x1             = $a7
line_y1             = $a8
line_x2             = $a9
line_y2             = $aa


zp_temp             = $fb       ; Word
zp_temp2            = $fd       ; Ditto
 
; =================== Kernal calls ======================
kGetIn              = $ffe4 
kCharOut            = $ffd2

; =================== Cassette buffer ===================
*=$33c
.pixel          
        !byte $80,$40,$20,$10,$8,$4,$2,$1
.coordBuffer    
        !byte $0, $0, $7f, $7f
        !byte $7f, $0, $0, $7f
        !byte $40, $0, $40, $7f
        !byte $0, $40, $7f, $40 
        !byte $3a, $3d, $45, $3d
        !byte $3a, $43, $45, $43

; =================== Basic stub ========================
* = BASIC_LOC
        !byte $0b, $08
        !byte $E3               ; BASIC_LOC line number
        !byte $07, $9E
        !byte '0' + main % 10000 / 1000
        !byte '0' + main %  1000 /  100
        !byte '0' + main %   100 /   10
        !byte '0' + main %    10
        !byte $00, $00, $00     ; End of basic

.screenBuffer
        !fill 256, $0

; =================== Main loop =========================
main:        
        jsr initScreen 
mainloop
        jsr resetCoordBuffer
        jsr setCoordsFromBuffer 
        jsr drawLine
        jsr setCoordsFromBuffer
        jsr drawLine
        jsr setCoordsFromBuffer
        jsr drawLine
        jsr setCoordsFromBuffer 
        jsr drawLine
        jsr setCoordsFromBuffer 
        jsr drawLine
        jsr setCoordsFromBuffer 
        jsr drawLine
        
_wait   sei
        lda VIC_RASTER
        cmp #80
        cli
        bne _wait
        jmp swapScreen
        rts

waitKey:
        jsr kGetIn
        beq waitKey
        rts
; ============================================================================
; Setup
; ============================================================================
initScreen:     
        lda #$90                ; Screen size 16 x 16
        sta VIC_COLS
        lda #$20                ; Chars: 8x8 
        sta VIC_ROWS
        lda #$24                      ; #$14, #$1d
        sta VIC_VERT
        lda #$10
        sta VIC_HORIZ
        lda #$fe                ; Custom chars 
        sta VIC_CHARLOC
        lda #<CHAR_LOC          ; Store only high byte for char pointer
        sta CHAR_POINTER
        lda #>CHAR_LOC          ; Store only high byte for char pointer
        sta CHAR_POINTER + 1
cls:
        ldy #$ff
        lda #$0
-       sta SCREEN_LOC, y
        sta COLOR_LOC, y
        dey
        bne -
        sta SCREEN_LOC, y
        sta COLOR_LOC, y
        rts
neg:    
        eor #$ff
        clc
        adc #1
        rts 

setChar:
        ldy #$0
        sty char_ptr + 1
        ldy cell
        lda .screenBuffer, y
        bne +
        lda char_buffer_index   ; Save few cycles to do this instead of inc 
        adc #$1
        sta char_buffer_index
        sta .screenBuffer, y
+       asl
        asl
        rol char_ptr + 1
        asl
        sta char_ptr
        rol char_ptr + 1
        clc
        lda char_ptr + 1
        adc CHAR_POINTER + 1
        sta char_ptr + 1
        rts

swapScreen:
        ldy #$7f                ; Copy buffer to screen
-       lda .screenBuffer, y
        sta SCREEN_LOC, y
        lda .screenBuffer+$80, y
        sta SCREEN_LOC+$80, y
        dey
        bne -
        lda .screenBuffer, y
        sta SCREEN_LOC, y
        lda .screenBuffer+$80, y
        sta SCREEN_LOC+$80, y
        lda #$0                 ; clear buffer
        ldy #$7f
        sta .screenBuffer, y
        sta .screenBuffer+$80, y
-       dey
        sta .screenBuffer, y
        sta .screenBuffer+$80, y
        bne -
        ldx #$40                ; toggle char buffer index
        ldy #$00
        lda char_buffer_index
        cmp #$40
        bpl +
        ldx #$80
        ldy #$40
+       stx pchar_buffer_max
        sty char_buffer_index
        ldy #$ff                ; clear chars
        lda #$0
        cpx #$80
        bmi minloop
maxloop sta CHAR_LOC+$200, y
        sta CHAR_LOC+$300, y
        dey
        bne maxloop
        sta CHAR_LOC+$200, y
        sta CHAR_LOC+$300, y
        jmp mainloop
minloop sta CHAR_LOC, y
        sta CHAR_LOC+$100, y
        dey
        bne minloop
        sta CHAR_LOC, y
        sta CHAR_LOC+$100, y
        jmp mainloop

resetCoordBuffer:
        ldy #$0
        sty coord_buffer_index
        rts

setCoordsFromBuffer:
        ldy coord_buffer_index  
        lda .coordBuffer, y
        sta line_x1
        iny
        lda .coordBuffer, y
        sta line_y1
        iny
        lda .coordBuffer, y
        sta line_x2
        iny
        lda .coordBuffer, y
        sta line_y2
        iny
        sty coord_buffer_index
        rts
       
initCharCoords:
        ldy line_x1
        tya 
        lsr
        lsr
        lsr
        sta cell
        tya 
        and #$7
        sta char_x
        ldy line_y1
        tya 
        asl
        and #$f0
        clc
        adc cell
        sta cell
        tya 
        and #$7
        sta char_y
        rts

swapCoords:
        lda line_x1             ; Swap x
        ldy line_x2
        sty line_x1
        sta line_x2   
        lda line_y1             ; Swap y
        ldy line_y2
        sty line_y1
        sta line_y2
calcDeltaValues:
        ldx #$1
        sec
        lda line_x2
        sbc line_x1 
        bpl +
        jsr neg
        ldx #$ff
+       stx xi                  ; xinc/xdec
        sta dx
        ldx #$1
        ldy #$10
        sec
        lda line_y2
        sbc line_y1
        bpl +
        jsr neg
        ldx #$ff
        ldy #$f0
+       stx yi                  ; yinc/ydec
        sty yi16                ; yinc/ydec for cell
        sta dy
        rts

; ============================================================================
; Bresenham line draw
; ============================================================================
toLiney:
        jmp initLiney
drawLine:
        lda #$0
        sta diff + 1
        jsr calcDeltaValues     ; Acc = dy as result
        cmp dx
        bpl toLiney
        tay
        sec                     ; Init linex
        sbc dx
        asl
        sta e1                  ; e1 = 2 * dy - 2 * dx
        tya
        asl
        sta e2                  ; e2 = 2 * dy
        sec
        sbc dx                  ; diff = 2 * dy - dx
        bpl +
        dec diff + 1
+       sta diff    
        lda xi
        bpl linex 
        jsr swapCoords          ; Draw loop should always be from min to max
linex
        jsr initCharCoords
        ldy char_x              ; Set current pixel
        lda .pixel, y
        sta pixel
        jsr setChar
        ldx line_x1             ; Loop index
loopx
        ldy char_y              ; Plot
        lda pixel
        ora (char_ptr), y
        sta (char_ptr), y
        cpx line_x2             ; Last coord-x reached?
        beq end_loopx
        inx
        lda diff + 1
        bmi dmix
        clc
        lda line_y1
        adc yi
        sta line_y1
        lda yi
        clc
        adc char_y
        sta char_y
        bpl no_wrap             ; If char_y < 0, wrap value to 7
        lda #$7
        sta char_y
        jmp calc_cell
no_wrap
        cmp #$8                 ; If char_y > 7, mask value to 0-7
        bmi shift_pixel
        and #$7
        sta char_y
calc_cell
        clc
        lda cell
        adc yi16                ; Row up / down
        sta cell
        jsr setChar
shift_pixel       
        lda e1
        beq inc_x
        clc
        adc diff
        bpl +
        dec diff + 1
+       sta diff
inc_x   lsr pixel               ; Inc pixel-x
        bcc loopx
        ror pixel
        inc cell
        jsr setChar 
        jmp loopx
dmix
        lda diff
        clc
        adc e2
        bcc +
        inc diff + 1 
+       sta diff  
        lsr pixel               ; Inc pixel-x
        bcc loopx
        ror pixel               ; Set pixel for next char
        inc cell
        jsr setChar 
        jmp loopx
end_loopx
        rts  
initLiney
        sec
        lda dx
        tay
        sbc dy
        asl
        sta e1                  ; e1 = 2 * deltaX - 2 * deltaY
        tya
        asl
        sta e2                  ; e2 = 2 * deltaX
        sec
        sbc dy
        bpl +
        dec diff + 1
+       sta diff                ; diff = 2 * deltaX - deltaY
        lda yi
        bpl liney
        jsr swapCoords          ; Draw loop should always be from min to max
liney   
        jsr initCharCoords     
        ldy char_x              
        lda .pixel, y
        sta pixel
        jsr setChar
        ldx line_y1
loopy
        ldy char_y              ; Plot
        lda pixel
        ora (char_ptr), y
        sta (char_ptr), y
        cpx line_y2
        beq end_loopy
        inx
        lda diff + 1
        bmi dmiy 
        clc
        lda xi
        bmi +
        lsr pixel               ; Inc pixel-x
        bcc cont
        ror pixel               ; Set pixel for next char
        inc cell
        jmp cont
+       asl pixel               ; Dec pixel-x
        bcc cont
        rol pixel               ; Set pixel for next char
        dec cell
cont
        lda e1
        beq inc_char_y
        clc
        adc diff
        bpl +
        dec diff + 1
+       sta diff
inc_char_y  
        inc char_y
        lda char_y
        cmp #$8                 ; If char_y > 7, move one row down 
        bmi loopy
        and #$7                 ; char_y range should be 0-7
        sta char_y
        clc
        lda cell
        adc #$10                
        sta cell
        jsr setChar
        jmp loopy
dmiy
        lda diff
        clc
        adc e2
        bcc +
        inc diff + 1 
+       sta diff  
        inc char_y
        lda char_y
        cmp #$8                 ; If char_y > 7, move one row down 
        bmi loopy               
        and #$7
        sta char_y
        clc
        lda cell
        adc #$10
        sta cell
        jsr setChar
        jmp loopy
end_loopy
        rts

*=$1800
        !fill 1024, $0
