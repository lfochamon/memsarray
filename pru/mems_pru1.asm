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


;*************
; MEMS macros
;*************
NOP .macro
        MOV r0, r0
    .endm


CLK_WAIT    .macro  clk_wait_delay
                LDI32   r29, spi_wait_delay
                SUB     r29, r29, 1
delay?:         SUB     r29, r29, 1
                QBNE    delay?, r29, 0
            .endm


LBIT    .macro  lbit_reg1, lbit_bit1, lbit_reg2, lbit_bit2
            QBBS    high?, lbit_reg1, lbit_bit1
            CLR     lbit_reg2, lbit_reg2, lbit_bit2
            QBA     end?
high?:      SET     lbit_reg2, lbit_reg2, lbit_bit2
            NOP
end?:
        .endm


MEMS_READ_BYTE  .macro  mems_read_byte_reg, mems_read_byte_finish_early
    SET         r30, r30, CLK                       ; CLK = 1 (1 clock)
    LBIT        r31, MIC1, mems_read_byte_reg, 7    ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, mems_read_byte_reg, 6    ; Load MIC2 data (3 clocks)
    CLK_WAIT    CLK_DELAY-3-3-1                     ; Wait to meet timing
    CLR         r30, r30, CLK                       ; CLK down
    CLK_WAIT    CLK_DELAY-1                         ; Wait to meet timing

    SET         r30, r30, CLK                       ; CLK = 1 (1 clock)
    LBIT        r31, MIC1, mems_read_byte_reg, 5    ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, mems_read_byte_reg, 4    ; Load MIC2 data (3 clocks)
    CLK_WAIT    CLK_DELAY-3-3-1                     ; Wait to meet timing
    CLR         r30, r30, CLK                       ; CLK down
    CLK_WAIT    CLK_DELAY-1                         ; Wait to meet timing

    SET         r30, r30, CLK                       ; CLK = 1 (1 clock)
    LBIT        r31, MIC1, mems_read_byte_reg, 3    ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, mems_read_byte_reg, 2    ; Load MIC2 data (3 clocks)
    CLK_WAIT    CLK_DELAY-3-3-1                     ; Wait to meet timing
    CLR         r30, r30, CLK                       ; CLK down
    CLK_WAIT    CLK_DELAY-1                         ; Wait to meet timing

    SET         r30, r30, CLK                       ; CLK = 1 (1 clock)
    LBIT        r31, MIC1, mems_read_byte_reg, 1    ; Load MIC1 data (3 clocks)
    LBIT        r31, MIC2, mems_read_byte_reg, 0    ; Load MIC2 data (3 clocks)
    CLK_WAIT    CLK_DELAY-3-3-1                     ; Wait to meet timing
    CLR         r30, r30, CLK                       ; CLK down

    CLK_WAIT    CLK_DELAY-1-mems_read_byte_finish_early ; Wait to meet timing
.endm


MEMS_READ_FULLREG   .macro  mems_read_fullreg_reg
    MEMS_READ_BYTE :mems_read_fullreg_reg:.b0, 0
    MEMS_READ_BYTE :mems_read_fullreg_reg:.b1, 0
    MEMS_READ_BYTE :mems_read_fullreg_reg:.b2, 0
    MEMS_READ_BYTE :mems_read_fullreg_reg:.b3, 0
.endm


;*******************
; MEMS main program
;*******************

; Clear clock pin
CLR r30, r30, CLK

; Start of main loop
mainloop:
    MEMS_READ_FULLREG r1
    MEMS_READ_FULLREG r2
    MEMS_READ_FULLREG r3
    MEMS_READ_FULLREG r4
    MEMS_READ_FULLREG r5
    MEMS_READ_FULLREG r6
    MEMS_READ_FULLREG r7
    MEMS_READ_FULLREG r8
    MEMS_READ_FULLREG r9
    MEMS_READ_FULLREG r10
    MEMS_READ_FULLREG r11
    MEMS_READ_FULLREG r12
    MEMS_READ_FULLREG r13
    MEMS_READ_FULLREG r14
    MEMS_READ_FULLREG r15
    MEMS_READ_FULLREG r16
    MEMS_READ_FULLREG r17
    MEMS_READ_FULLREG r18
    MEMS_READ_FULLREG r19
    MEMS_READ_FULLREG r20
    MEMS_READ_FULLREG r21
    MEMS_READ_FULLREG r22
    MEMS_READ_FULLREG r23
    MEMS_READ_FULLREG r24
    MEMS_READ_FULLREG r25
    MEMS_READ_FULLREG r26

    ; REG29 by hand to allow for the data transfer and loop instructions
    MEMS_READ_BYTE r26.b0, 0
    MEMS_READ_BYTE r26.b1, 0
    MEMS_READ_BYTE r26.b2, 0
    MEMS_READ_BYTE r26.b3, 3

    XOUT    XFR_BANK0, &r1, 104                         ; Save to scratch pad
    LDI     r31.b0, PRU_INT_VALID + PRU1_PRU0_INTERRUPT ; Signal PRU0

    JMP mainloop        ; [TODO]: make loop conditional

; Stop PRU
HALT
