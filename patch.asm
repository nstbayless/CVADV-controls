INERTIA_MIN: equ $40
INERTIA_ZERO: equ $80
INERTIA_MAX: equ $C0

; this is the acceleration.
INERTIA_ADJUST: equ $8

; z80asm seems to have trouble emitting ld a, ($imm) for some reason.
ldai16: macro addr
    db $FA
    defw addr
endm

_djnz: macro addr
    dec b
    jr nz, addr
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

org $173C
belmont_default_speed:

org $1833 + 1*2
banksk0
dw new_belmont_jump_routine

org $1833 + 4*2
banksk0
dw new_belmont_jump_routine

org $17e1
banksk0
if INERTIA
    call belmont_update_intercept
endif

org $1823
belmont_update_pretable:

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

org $C508
belmont_speed:

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

org $CFF0
belmont_inertia: ; hopefully we can use this freely.

; free space
org $7FBD
banksk1

new_belmont_jump_routine:
    ; check actually jumping
    ldai16 belmont_state
    ld b, a
    ldai16 belmont_jumpstate
    or a
    jr z, new_belmont_jump_routine_return
    
if INERTIA
    ldai16 belmont_default_speed
    ld e, a
    ; ldai16 belmont_default_speed+1
    ; ld d, a
    ld d, $0
endif
    
    ; execute jump routine
    ld hl, new_belmont_jump_routine_exec
jp_mbc_bank_switch3:
    push hl
    ld a, $3
    jp mbc_bank_switch

new_belmont_jump_routine_return:
    ; now do normal update routine

    ld a, b
    cp $4
    jp z, old_belmont_whip_routine
    jp old_belmont_jump_routine
    
if INERTIA
    belmont_update_intercept:
        ldai16 belmont_default_speed
        ldi16a belmont_speed
        
        call  belmont_update_pretable
        
        ldai16 belmont_jumpstate
        or a
        ret nz
        ld hl, belmont_update_intercept_exec
        jr jp_mbc_bank_switch3
endif
    
end_bank1:


; free space in bank 3
org $7d54
banksk3

if INERTIA
    belmont_update_intercept_exec:
        call get_desired_inertia
        ldi16a belmont_inertia
        ld a, $1
        jp mbc_bank_switch

    get_desired_inertia:
        ld hl, belmont_movement
        ld a, INERTIA_ZERO
        bit 1, (hl)
        ret z
        ld a, INERTIA_MAX
        bit 0, (hl)
        ret z
        ld a, INERTIA_MIN
        ret
endif

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

if INERTIA
        push bc
    inertia:
        ; b <- desired velocity
        ld hl, belmont_movement
        ld b, INERTIA_ZERO
        bit 1, (hl)
        jr z, inertia_adjust
        ld b, INERTIA_MAX
        bit 0, (hl)
        jr z, inertia_adjust
        ld b, INERTIA_MIN
        
    inertia_adjust:
        ldai16 belmont_inertia
        ld c, a
        
        sub b
        cp INERTIA_ADJUST+1
        jr c, inertia_direct
        cp $FF-INERTIA_ADJUST+1
        jr nc, inertia_direct
        cp $80
        jr c, inertia_decrease
    
    inertia_increase:
        ld a, INERTIA_ADJUST
        add c
        jr apply_inertia
    
    inertia_decrease:
        ld a, $FF-INERTIA_ADJUST+1
        add c
        jr apply_inertia
    
    inertia_direct:
        ld a, b
    
    apply_inertia:
        ldi16a belmont_inertia
        
        ; now multiply the inertia factor into the speed
        sub INERTIA_ZERO
        
        call c, inertia_negate
        
        call Mul8
        
        ; multiply by 4, since inertia ranges from -$40 to $40 rather than -$100 to $100
        sla l
        rl h
        sla l
        rl h
        
        ld a, h
        jr nc, no_sign_flip
        
    sign_flip:
        cpl
        inc a
        
    no_sign_flip:
        ldi16a belmont_speed
        
    correct_hdir:
        ldai16 belmont_inertia
        ld hl, belmont_movement
        set 0, (hl)
        set 1, (hl)
        cp INERTIA_ZERO
        jr z, zero_inertia
        jr c, end_inertia
        res 0, (hl)
        jr end_inertia
        
    zero_inertia:
        res 1, (hl)
        
    end_inertia:
        pop bc
endif

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

if INERTIA
    ; https://tutorials.eeems.ca/Z80ASM/part4.htm

    Mul8:                              ; this routine performs the operation HL=DE*A
        ld hl,0                        ; HL is used to accumulate the result
        ld b,8                         ; the multiplier (A) is 8 bits wide
    Mul8Loop:
        rrca                           ; putting the next bit into the carry
        jp nc,Mul8Skip                 ; if zero, we skip the addition (jp is used for speed)
        add hl,de                      ; adding to the product if necessary
    Mul8Skip:
        sla e                          ; calculating the next auxiliary product by shifting
        rl d                           ; DE one bit leftwards (refer to the shift instructions!)
        _djnz Mul8Loop
        ret
        
    inertia_negate:
        cpl
        inc a
        push af
        ld a, e
        cpl
        ld l, a
        ld a, d
        cpl
        ld h, a
        inc hl
        ld d, h
        ld e, l
        pop af
        ret
endif

end_bank3: