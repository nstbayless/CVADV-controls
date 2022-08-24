; z80asm seems to have trouble emitting ld a, ($imm) for some reason.
ldai16: macro addr
    db $FA
    defw addr
endm

ldi16a: macro addr
    db $EA
    defw addr
endm

pushhl: macro value
    ld hl, value
    push hl
endm

; call bank after org, seeks to $ in given bank.
banksk0: macro
    seek $
endm

banksk1: macro
    seek $4000 * (1-1) + $
endm

banksk3: macro
    seek $4000 * (3-1) + $
endm

; belmont action jump table -- $1833

org $1833 + 1*2
banksk0
dw new_belmont_jump_routine

org $1833 + 4*2
banksk0
dw new_belmont_jump_routine

org $197c
old_belmont_jump_routine:

org $1af0
old_belmont_whip_routine:

; push routine address
; a <- bank to switch to
org $2A82
mbc_bank_switch:

org $C418
user_input:

org $C502
belmont_state: ; 0: standing. 1: jump. 2: crouch. 3: rope. 4: whip.

org $C506
belmont_movement: ; bit 1 of this is set when moving. Bit 0 is the movement direction (set if moving left).

org $C50D
belmont_jumpstate: ; $00: on ground. $0A: falling. $0F: rising.

org $C50F
belmont_yvel_sub:

org $C510
belmont_yvel:

org $C514
belmont_pose: ; 1: standing. 2: jump/crouch. 3: whip. 5: crouch-whip.

org $C515
belmont_facing: ; bit 5 of this is the facing (set if right)

; free space
org $7FDD ; $7FBD
banksk1

new_belmont_jump_routine:
    ; check actually jumping
    ldai16 belmont_state
    ld b, a
    ldai16 belmont_jumpstate
    or a
    jr z, new_belmont_jump_routine_return
    
    ; execute jump routine
    pushhl new_belmont_jump_routine_exec
    ld a, $3
    jp mbc_bank_switch

new_belmont_jump_routine_return:
    ; now do normal update routine

    ld a, b
    cp $4
    jp z, old_belmont_whip_routine
    jp old_belmont_jump_routine
    
end_bank1:


; free space in bank 3
org $7d58
banksk3

new_belmont_jump_routine_exec:
    ld hl, belmont_movement
    
    ; read input
    ldai16 user_input
    ld c, a
    res 1, (hl)
    and $3
    jr z, done_hmove

set_hmove:
    set 1, (hl)
    res 0, (hl)
    and $1
    jr nz, set_facing
    set 0, (hl)
    
set_facing:
    ; check not whipping.
    ld a, b ; a <- belmont state
    cp $4
    jr z, done_hmove
    
do_set_facing:
    ; copy bit 0 of belmont_movement to bit 5 of belmont_facing
    bit 0, (hl)
    ld hl, belmont_facing
    set 5, (hl)
    jr z, done_hmove
    res 5, (hl)
    
done_hmove:

if VCANCEL
    vcancel:
        ; v-cancel time
        ld a, c ; a <- user input
        and $10 ; holding jump
        jr nz, done_vcancel
        
        ; check rising
        ldai16 belmont_jumpstate
        cp $F
        jr nz, done_vcancel
        
        ; check velocity >= 1
        ldai16 belmont_yvel
        cp $1
        jr c, done_vcancel
        
        ldai16 belmont_yvel
        ld h, a
        ldai16 belmont_yvel_sub
        ld l, a
        ld de, $FF80
        add hl, de
        ld a, h
        ldi16a belmont_yvel
        ld a, l
        ldi16a belmont_yvel_sub

    done_vcancel:
endif

new_belmont_jump_routine_exec_return:
    pushhl new_belmont_jump_routine_return
    ld a, $1
    jp mbc_bank_switch

end_bank3: