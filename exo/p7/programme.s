# Compiled on godbolt.org: RISC-V (32-bits) gcc (trunk), -O0 -march=rv32im -mabi=ilp32
.Ltext0:
factorielle:
.LFB0:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        li      a5,1
        sw      a5,-20(s0)
.LBB2:
        li      a5,2
        sw      a5,-24(s0)
        j       .L2
.L3:
        lw      a4,-20(s0)
        lw      a5,-24(s0)
        mul     a5,a4,a5
        sw      a5,-20(s0)
        lw      a5,-24(s0)
        addi    a5,a5,1
        sw      a5,-24(s0)
.L2:
        lw      a4,-24(s0)
        lw      a5,-36(s0)
        ble     a4,a5,.L3
.LBE2:
        lw      a5,-20(s0)
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
.LFE0:
pgcd:
.LFB1:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        j       .L6
.L7:
.LBB3:
        lw      a4,-36(s0)
        lw      a5,-40(s0)
        rem     a5,a4,a5
        sw      a5,-20(s0)
        lw      a5,-40(s0)
        sw      a5,-36(s0)
        lw      a5,-20(s0)
        sw      a5,-40(s0)
.L6:
.LBE3:
        lw      a5,-40(s0)
        bne     a5,zero,.L7
        lw      a5,-36(s0)
        mv      a0,a5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
.LFE1:
main:
.LFB2:
        addi    sp,sp,-80
        sw      ra,76(sp)
        sw      s0,72(sp)
        sw      s1,68(sp)
        addi    s0,sp,80
        sw      zero,-20(s0)
.LBB4:
        sw      zero,-24(s0)
        j       .L10
.L11:
        lw      a5,-24(s0)
        mul     a4,a5,a5
        lw      a3,-24(s0)
        addi    a5,s0,-68
        slli    a3,a3,2
        add     a5,a3,a5
        sw      a4,0(a5)
        lw      a5,-24(s0)
        addi    a5,a5,1
        sw      a5,-24(s0)
.L10:
        lw      a4,-24(s0)
        li      a5,9
        ble     a4,a5,.L11
.LBE4:
.LBB5:
        sw      zero,-28(s0)
        j       .L12
.L13:
        lw      a4,-28(s0)
        addi    a5,s0,-68
        slli    a4,a4,2
        add     a5,a4,a5
        lw      a5,0(a5)
        lw      a4,-20(s0)
        add     a5,a4,a5
        sw      a5,-20(s0)
        lw      a5,-28(s0)
        addi    a5,a5,1
        sw      a5,-28(s0)
.L12:
        lw      a4,-28(s0)
        li      a5,9
        ble     a4,a5,.L13
.LBE5:
        li      a0,6
        call    factorielle
        mv      a4,a0
        lw      a5,-20(s0)
        add     s1,a4,a5
        li      a1,462
        li      a0,1071
        call    pgcd
        mv      a5,a0
        add     a5,s1,a5
        mv      a0,a5
        lw      ra,76(sp)
        lw      s0,72(sp)
        lw      s1,68(sp)
        addi    sp,sp,80
        jr      ra
.LFE2:
.Letext0:
.Ldebug_info0:
.Ldebug_abbrev0:
.Ldebug_line0:
.LASF3:
.LASF4:
.LASF7:
.LASF8:
.LASF6:
.LASF5:
.LASF2:
.LASF0:
.LASF1:
