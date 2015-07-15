; Pin definitions
CLK                 .set    5       ; PRU1_5 GPIO2_11 P8_42
MIC1                .set    3       ; PRU1_3 GPIO2_9  P8_44
MIC2                .set    1       ; PRU1_1 GPIO2_7  P8_46

; Output clock frequency settings (2 instructions per loop)
CLK_1M              .set    50      ; Half-cycle = 500 ns => fCLK = 1 MHz
CLK_2M4             .set    21      ; Half-cycle = 210 ns => fCLK = 2.38 MHz
CLK_3M072           .set    16      ; Half-cycle = 160 ns => fCLK = 3.125 MHz

CLK_DELAY           .set    CLK_2M4

; Interrupt
PRU_INT_VALID       .set    32
PRU0_PRU1_INTERRUPT .set    1       ; PRU_EVTOUT_
PRU1_PRU0_INTERRUPT .set    2       ; PRU_EVTOUT_
PRU0_ARM_INTERRUPT  .set    3       ; PRU_EVTOUT_0
PRU1_ARM_INTERRUPT  .set    4       ; PRU_EVTOUT_1
ARM_PRU0_INTERRUPT  .set    5       ; PRU_EVTOUT_
ARM_PRU1_INTERRUPT  .set    6       ; PRU_EVTOUT_

; Name PRU register banks
XFR_BANK0           .set    10
XFR_BANK1           .set    11
XFR_BANK2           .set    12
XFR_PRU             .set    14


;*******************
; MEMS ARRAY macros
;*******************
NOP .macro
        MOV r0, r0
    .endm


LBIT    .macro  lbit_reg1, lbit_bit1, lbit_reg2, lbit_bit2
            QBBS    high?, lbit_reg1, lbit_bit1
            CLR     lbit_reg2, lbit_reg2, lbit_bit2
            QBA     end?
high?:      SET     lbit_reg2, lbit_reg2, lbit_bit2
            NOP
end?:
        .endm


MEMS_READ_REG   .macro  mems_read_fullreg_reg
        JAL     r27.w0, mems_read_byte              ; Call mems_read_byte (2 clock)
        MOV     :mems_read_fullreg_reg:.b3, r27.b2  ; Save byte (1 clock)
        LDI32   r29, CLK_DELAY-4                    ; Call wait function (2 clocks)
        JAL     r28.w0, clk_wait

        JAL     r27.w0, mems_read_byte              ; Call mems_read_byte (2 clock)
        MOV     :mems_read_fullreg_reg:.b2, r27.b2  ; Save byte (1 clock)
        LDI32   r29, CLK_DELAY-4                    ; Call wait function (2 clocks)
        JAL     r28.w0, clk_wait

        JAL     r27.w0, mems_read_byte              ; Call mems_read_byte (2 clock)
        MOV     :mems_read_fullreg_reg:.b1, r27.b2  ; Save byte (1 clock)
        LDI32   r29, CLK_DELAY-4                    ; Call wait function (2 clocks)
        JAL     r28.w0, clk_wait

        JAL     r27.w0, mems_read_byte              ; Call mems_read_byte (2 clock)
        MOV     :mems_read_fullreg_reg:.b0, r27.b2  ; Save byte (1 clock)
        LDI32   r29, CLK_DELAY-4                    ; Call wait function (2 clocks)
        JAL     r28.w0, clk_wait
    .endm


; Code starts here
    .text
    .retain
    .retainrefs
    .global         main


;*************************
; MEMS ARRAY main program
;*************************

main:
; Clear clock pin
    SET r30, r30, CLK

; Call wait function
    LDI32       r29, CLK_DELAY
    JAL         r28.w0, clk_wait

; Start of main loop
mainloop:
    MEMS_READ_REG r1
    MEMS_READ_REG r2
    MEMS_READ_REG r3
    MEMS_READ_REG r4
    MEMS_READ_REG r5
    MEMS_READ_REG r6
    MEMS_READ_REG r7
    MEMS_READ_REG r8
    MEMS_READ_REG r9
    MEMS_READ_REG r10
    MEMS_READ_REG r11
    MEMS_READ_REG r12
    MEMS_READ_REG r13
    MEMS_READ_REG r14
    MEMS_READ_REG r15
    MEMS_READ_REG r16
    MEMS_READ_REG r17
    MEMS_READ_REG r18
    MEMS_READ_REG r19
    MEMS_READ_REG r20
    MEMS_READ_REG r21
    MEMS_READ_REG r22
    MEMS_READ_REG r23
    MEMS_READ_REG r24
    MEMS_READ_REG r25

    ; r26 by hand to allow for the data transfer and loop instructions
    JAL     r27.w0, mems_read_byte      ; Call mems_read_byte (2 clock)
    MOV     r26.b3, r27.b2              ; Save byte (1 clock)
    LDI32   r29, CLK_DELAY-4            ; Call wait function (2 clocks)
    JAL     r28.w0, clk_wait

    JAL     r27.w0, mems_read_byte      ; Call mems_read_byte (2 clock)
    MOV     r26.b2, r27.b2              ; Save byte (1 clock)
    LDI32   r29, CLK_DELAY-4            ; Call wait function (2 clocks)
    JAL     r28.w0, clk_wait

    JAL     r27.w0, mems_read_byte      ; Call mems_read_byte (2 clock)
    MOV     r26.b1, r27.b2              ; Save byte (1 clock)
    LDI32   r29, CLK_DELAY-4            ; Call wait function (2 clocks)
    JAL     r28.w0, clk_wait

    JAL     r27.w0, mems_read_byte      ; Call mems_read_byte (2 clock)
    MOV     r26.b0, r27.b2              ; Save byte (1 clock)

    XOUT    XFR_BANK0, &r1, 104                         ; Save to scratch pad (1 clock)
    LDI     r31.b0, PRU_INT_VALID + PRU1_PRU0_INTERRUPT ; Signal PRU0 (1 clock)

    LDI32   r29, CLK_DELAY-5            ; Call wait function (2 clocks)
    JAL     r28.w0, clk_wait

    JMP mainloop        ; [TODO]: make loop conditional (1 clock)
; End of main loop

; Stop PRU (unreachable)
    HALT

;********************************
; MEMS ARRAY auxiliary functions
;********************************

; r29       loop counter (e.g., 'LDI32 r29, clk_wait_delay-2')
; r28.w0    return address
clk_wait:
    SUB     r29, r29, 1
    QBNE    clk_wait, r29, 0

    JMP r28.w0                  ; Return


; r27.b2    saved byte
; r27.w0    return address
mems_read_byte:
    CLR         r30, r30, CLK               ; CLK = 0 (1 clock)
    LDI32       r29, 2                      ; Wait 35 ns (7 instructions)
    JAL         r28.w0, clk_wait
    LBIT        r31, MIC1, r27.b2, 7        ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, r27.b2, 6        ; Load MIC2 data (3 clocks)
    LDI32       r29, CLK_DELAY-11           ; Call wait function (2 clocks)
    JAL         r28.w0, clk_wait
    NOP
    SET         r30, r30, CLK               ; CLK = 0 (1 clock)
    LDI32       r29, CLK_DELAY-3            ; Call wait function (2 clocks)
    JAL         r28.w0, clk_wait
    NOP

    CLR         r30, r30, CLK               ; CLK = 0 (1 clock)
    LDI32       r29, 2                      ; Wait 35 ns (7 instructions)
    JAL         r28.w0, clk_wait
    LBIT        r31, MIC1, r27.b2, 5        ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, r27.b2, 4        ; Load MIC2 data (3 clocks)
    LDI32       r29, CLK_DELAY-11           ; Call wait function (2 clocks)
    JAL         r28.w0, clk_wait
    NOP
    SET         r30, r30, CLK               ; CLK = 0 (1 clock)
    LDI32       r29, CLK_DELAY-3            ; Call wait function (2 clocks)
    JAL         r28.w0, clk_wait
    NOP

    CLR         r30, r30, CLK               ; CLK = 0 (1 clock)
    LDI32       r29, 2                      ; Wait 35 ns (7 instructions)
    JAL         r28.w0, clk_wait
    LBIT        r31, MIC1, r27.b2, 3        ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, r27.b2, 2        ; Load MIC2 data (3 clocks)
    LDI32       r29, CLK_DELAY-11           ; Call wait function (2 clocks)
    JAL         r28.w0, clk_wait
    NOP
    SET         r30, r30, CLK               ; CLK = 0 (1 clock)
    LDI32       r29, CLK_DELAY-3            ; Call wait function (2 clocks)
    JAL         r28.w0, clk_wait
    NOP

    CLR         r30, r30, CLK               ; CLK = 0 (1 clock)
    LDI32       r29, 2                      ; Wait 35 ns (7 instructions)
    JAL         r28.w0, clk_wait
    LBIT        r31, MIC1, r27.b2, 1        ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, r27.b2, 0        ; Load MIC2 data (3 clocks)
    LDI32       r29, CLK_DELAY-11           ; Call wait function (2 clocks)
    JAL         r28.w0, clk_wait
    SET         r30, r30, CLK               ; CLK = 0 (1 clock)

    JMP         r27.w0                      ; Return (1 clock)
