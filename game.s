.data

.balign 4
w: .word 0
h: .word 0
T: .word 0


.text
.global start
.global run

start:
        ldr  r3, addr_of_w
        str  r0, [r3]
        ldr  r3, addr_of_h
        str  r1, [r3]
        ldr  r3, addr_of_T
        str  r2, [r3]

        bx lr

/* number of steps in r0 */
run:
        push {r4-r11,lr}

        ldr r1, addr_of_T        @ T in r1
        ldr r1, [r1]
        ldr r2, addr_of_w        @ w in r2
        ldr r2, [r2]
        ldr r3, addr_of_h        @ h in r3
        ldr r3, [r3]

step:                            @ loop over steps (r0)
        bl evolve_all
        bl shift_all

        subs r0, r0, #1          @ step counter
        bne step                 @ steps > 0

        pop {r4-r11,pc}

evolve_all:
        push {lr}
        eor r4, r4               @ initialize height counter (y)
e1:                              @ loop over height
        eor r5, r5               @ initialize width counter (x)
e2:                              @ loop over width
        bl evolve

        add r5, r5, #1           @ width counter (x)
        cmp r5, r2               @ x < w
        blt e2

        add r4, r4, #1           @ height counter (y)
        cmp r4, r3               @ y < h
        blt e1

        pop {pc}

shift_all:
        push {lr}
        eor r4, r4               @ initialize height counter (y)
s1:                              @ loop over height
        eor r5, r5               @ initialize width counter (x)
s2:                              @ loop over width
        bl shift

        add r5, r5, #1           @ width counter (x)
        cmp r5, r2               @ x < w
        blt s2

        add r4, r4, #1           @ height counter (y)
        cmp r4, r3               @ y < h
        blt s1

        pop {pc}

evolve:
        push {lr}

        mla r11, r2, r4, r5      @ r11 = y * w + x (my position)
        ldrb r6, [r1, r11]       @ my value in r6
        and r6, r6, #1           @ r6 = my_value & 1 (1 if I'm alive)
        neg r6, r6               @ alive: -1, if dead: 0; this is neighbour counter

        mov r7, r4               @ y1 = y
        sub r7, #1               @ y1 = y - 1 (l1 counter)
l1:
        mov r8, r5               @ x1 = x
        subs r8, #1              @ x1 = x - 1 (l2 counter)
l2:
        cmp r8, #0
        blt l2_done              @ x1 < 0

        cmp r8, r2               @ x1 >= w
        bge l2_done

        cmp r7, #0               @ y1 < 0
        blt l2_done

        cmp r7, r3               @ y1 >= h
        bge l2_done

        mla r9, r2, r7, r8       @ r9 now stores w*y1 + x1 (position of the neighbour)

        ldrb r10, [r1, r9]       @ get the neighbour's state
        ands r10, r10, #1        @ check if neighbour is alive
        beq l2_done              @ don't increment if neighbour is dead
        add r6, r6, #1
l2_done:
        add r8, r8, #1           @ l2
        mov r9, r5               @ r9 = x
        add r9, r9, #1           @ r9 = x + 1 (bound)
        cmp r8, r9               @ x1 <= x + 1
        ble l2

        add r7, r7, #1           @ l1
        mov r9, r4               @ r9 = y
        add r9, r9, #1           @ r9 = y + 1 (bound)
        cmp r7, r9               @ y1 <= y + 1
        ble l1
test:
        cmp r6, #3               @ n == 3
        beq revive

        cmp r6, #2               @ n == 2...
        bne evolve_done

        ldr r6, [r1, r11]        @ my value in r6
        ands r6, r6, #1          @ ...and I'm alive
        beq evolve_done
revive:
        ldrb r6, [r1, r11]       @ my value in r6
        orr r6, r6, #2           @ x |= (1 << 1)
        strb r6, [r1, r11]
evolve_done:
        pop {pc}

shift:
        push {lr}

        mla r11, r2, r4, r5     @ r11 = y * w + x (position)

        ldrb r6, [r1, r11]      @ r6 = *(T + position)
        lsr r6, #1              @ discard old state
        strb r6, [r1, r11]      @ update cell value

        pop {pc}


addr_of_w : .word w
addr_of_h : .word h
addr_of_T : .word T

.end
