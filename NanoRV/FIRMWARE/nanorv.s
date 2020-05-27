#################################################################################

# Mapped IO constants
	
.equ IO_BASE,      0x1000   # Base address of memory-mapped IO
.equ IO_LEDS,      0        # 4 LSBs mapped to D1,D2,D3,D4
.equ IO_OLED_CNTL, 4        # OLED display control.
                            #  wr: 01: reset low 11: reset high 00: normal operation
                            #  rd:  0: ready  1: busy
.equ IO_OLED_CMD,  8        # OLED display command. Only 8 LSBs used.
.equ IO_OLED_DATA, 12       # OLED display data. Only 8 LSBs used.
.equ IO_UART_RX_CNTL, 16    # USB UART RX control. read: LSB bit 1 if data ready
.equ IO_UART_RX_DATA, 20    # USB UART RX data (read)
.equ IO_UART_TX_CNTL, 24    # USB UART TX control. read: LSB bit 1 if busy
.equ IO_UART_TX_DATA, 28    # USB UART TX data (write)

#################################################################################

# Macros to send commands to the OLED driver (wrappers around OLEDx functions)
	
.macro OLED0 cmd
	li a0,\cmd
	call oled0
.endm

.macro OLED1 cmd,arg1
	li a0,\cmd
	li a1,\arg1
	call oled1
.endm

.macro OLED2 cmd,arg1,arg2
	li a0,\cmd
	li a1,\arg1
	li a2,\arg2
	call oled2
.endm

.macro OLED3 cmd,arg1,arg2,arg3
	li a0,\cmd
	li a1,\arg1
	li a2,\arg2
	li a3,\arg3	
	call oled3
.endm

#################################################################################

        li gp,0x1000 # base address of memory-mapped IO
	li sp,0x1000 # initial stack pointer, stack goes downwards
	j _start

#################################################################################

# NanoRv support library

# multiplication, source in a0 and a1, result in a0	
__mulsi3:	
__muldi3:
  mv     a2, a0
  li     a0, 0
.L1:
  andi   a3, a1, 1
  beqz   a3, .L2
  add    a0, a0, a2
.L2:
  srli   a1, a1, 1
  slli   a2, a2, 1
  bnez   a1, .L1
  ret
	
	
#################################################################################	

# NanoRv OLED display support

#################################################################################
	
# initialize oled display
oled_init:
	add sp,sp,-4
        sw ra, 0(sp)	
	# Initialization sequence / RESET
	li a0,5
	sw a0,IO_LEDS(gp)
        li a0,1                      # reset low during 0.5 s
	sw a0,IO_OLED_CNTL(gp)
	call wait
	li a0,10
	sw a0,IO_LEDS(gp)
        li a0,3                      # reset high during 0.5 s
	sw a0,IO_OLED_CNTL(gp)
	call wait
	li a0,15
	sw a0,IO_LEDS(gp)
        li a0,0                      # normal operation
	sw a0,4(gp)
	call oled_wait
	# Initialization sequence / configuration
	# Note: takes a lot of space, could be stored in an array of bytes
	# if ROM space gets crowded
	OLED1 0xfd, 0x12             # unlock driver
	OLED1 0xfd, 0xb1             # unlock commands
	OLED0 0xae                   # display off
	OLED0 0xa4                   # display mode off
	OLED2 0x15,0x00,0x7f         # column address
	OLED2 0x75,0x00,0x7f         # row address
	OLED1 0xb3,0xf1              # front clock divider (see section 8.5 of manual)
	OLED1 0xca, 0x7f             # multiplex
	OLED1 0xa0, 0x74             # remap, data format, increment
	OLED1 0xa1, 0x00             # display start line
	OLED1 0xa2, 0x00             # display offset
	OLED1 0xab, 0x01             # VDD regulator ON
	OLED3 0xb4, 0xa0, 0xb5, 0x55 # segment voltage ref pins
	OLED3 0xc1, 0xc8, 0x80, 0xc0 # contrast current for colors A,B,C
	OLED1 0xc7, 0x0f             # master contrast current
	OLED1 0xb1, 0x32             # length of segments 1 and 2 waveforms
	OLED3 0xb2, 0xa4, 0x00, 0x00 # display enhancement
	OLED1 0xbb, 0x17             # first pre-charge voltage phase 2
	OLED1 0xb6, 0x01             # second pre-charge period (see table 9-1 of manual)
	OLED1 0xbe, 0x05             # Vcomh voltage
	OLED0 0xa6                   # display on
	OLED0 0xaf                   # display mode on
	lw ra, 0(sp)
	add sp,sp,4
	ret
	
# Oled display command, 0 argument, command in a0	
oled0:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	lw ra, 0(sp)
	add sp,sp,4
	ret

# Oled display command, 1 argument, command in a0, arg in a1	
oled1:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	sw a1, IO_OLED_DATA(gp)
	call oled_wait
	lw ra, 0(sp)
	add sp,sp,4
	ret

# Oled display command, 2 arguments, command in a0, args in a1,a2
oled2:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	sw a1, IO_OLED_DATA(gp)
	call oled_wait
	sw a2, IO_OLED_DATA(gp)
	call oled_wait
	lw ra, 0(sp)	
        add sp,sp,4
	ret

# Oled display command, 3 arguments, command in a0, args in a1,a2,a3
oled3:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	sw a1, IO_OLED_DATA(gp)
	call oled_wait
	sw a2, IO_OLED_DATA(gp)
	call oled_wait
	sw a3, IO_OLED_DATA(gp)
	call oled_wait
	lw ra, 0(sp)
	add sp,sp,4
	ret

# Wait for a while	
wait:	li t0,0x100000
waitl:	add t0,t0,-1
	bnez t0,waitl
	ret

# Wait for Oled driver	
oled_wait:
	lw   t0,IO_OLED_CNTL(gp) # (non-zero = busy)
	bnez t0,oled_wait
	ret
	