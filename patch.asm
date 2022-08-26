INERTIA_MIN: equ $40
INERTIA_ZERO: equ $80
INERTIA_MAX: equ $C0

; this is the acceleration.
INERTIA_ADJUST: equ $8

; this can be any power of 2. Lower is faster.
BLINK_RATE: equ $2

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

banksk4: macro
    seek $4000 * (4-1) + $
endm

banksk5: macro
    seek $4000 * (5-1) + $
endm

; belmont action jump table -- $1833

if rom_type == rom_us
    bankskA: macro
        banksk0
    endm
    
    bankB: equ 1
    bankskB: macro
        banksk1
    endm
    
    bankC: equ 3
    bankskC: macro
        banksk3
    endm
    
    org $0A00
    oam_update_callsite:
    
    org $15A4
    oam_update:
    
    org $173C
    belmont_default_speed:

    org $1833
    belmont_jump_table:
    
    org $1823
    belmont_update_pretable:

    org $197c
    old_belmont_jump_routine:

    org $1af0
    old_belmont_whip_routine:
    
    org $161A
    draw_routine_intercept:
    
    ; push routine address
    ; a <- bank to switch to
    org $2A82
    mbc_bank_switch:
endif

if rom_type == rom_jp
    bankskA: macro
        banksk0
    endm
    
    bankB: equ 1
    bankskB: macro
        banksk1
    endm
    
    bankC: equ 3
    bankskC: macro
        banksk3
    endm
    
    org $0A00
    oam_update_callsite:
    
    org $156D
    oam_update:
    
    org $1705
    belmont_default_speed:
    
    org $17fc
    belmont_jump_table:
    
    org $17ec
    belmont_update_pretable:

    org $1945
    old_belmont_jump_routine:

    org $1ab9
    old_belmont_whip_routine:
    
    ; push routine address
    ; a <- bank to switch to
    org $2A4B
    mbc_bank_switch:
endif

if rom_type == rom_kgbc1eu
    bankskA: macro
        banksk4
    endm
    
    bankB: equ 4
    bankskB: macro
        banksk4
    endm
    
    bankC: equ 5
    bankskC: macro
        banksk5
    endm
    
    org $4637
    oam_update_callsite:
    
    org $4A99
    oam_update:
    
    org $4C39
    belmont_default_speed:
    
    org $4DC2
    belmont_jump_table:
    
    org $4Db2
    belmont_update_pretable:

    org $4f0b
    old_belmont_jump_routine:

    org $507f
    old_belmont_whip_routine:
    
    ; push routine address
    ; a <- bank to switch to
    org $0A64
    mbc_bank_switch:
endif

org belmont_jump_table + 1*2
bankskA
dw new_belmont_jump_routine

org belmont_jump_table + 4*2
bankskA
dw new_belmont_jump_routine

if BLINKING
org oam_update_callsite
bankskA
call oam_update_intercept
endif

if INERTIA
    if rom_type == rom_us
        org $17e1
    endif
    if rom_type == rom_jp
        org $17aa
    endif
    bankskA
    if rom_type == rom_kgbc1eu
        org $4d70
        bankskB
    endif
    
    call belmont_update_intercept
endif

org $C418
user_input:

org $C423
belmont_iframes:

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

org $C512
belmont_ypos:

org $C514
belmont_pose: ; 1: standing. 2: jump/crouch. 3: whip. 5: crouch-whip.

org $C515
belmont_facing: ; bit 5 of this is the facing (set if right)

org $CFF0
belmont_inertia: ; hopefully we can use this freely.

; free space
org $7FBD
bankskB

new_belmont_jump_routine:
    
if INERTIA
    ldai16 belmont_default_speed
    ld e, a
    ldai16 belmont_default_speed+3
    ld d, a
endif
    
    ; execute jump routine
    ld hl, new_belmont_jump_routine_exec
jp_mbc_bank_switch3:
    push hl
    ld a, bankC
    jp mbc_bank_switch
    
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

if BLINKING
oam_update_intercept:
    ldai16 belmont_ypos
    push af
    
    ldai16 belmont_iframes
    and BLINK_RATE
    jr z, _do_call_oam
    ld a, $FF
    ldi16a belmont_ypos
    
_do_call_oam:
    call oam_update
    
    pop af
    ldi16a belmont_ypos
    ret
endif
    
end_bank1:


; free space in bank 3
org $7d54
bankskC

if INERTIA
    belmont_update_intercept_exec:
    
        ; skip this if in rising knockback.
        ldai16 belmont_pose
        cp $7
        jr z, _do
        
        ldai16 belmont_jumpstate
        cp $F
        jr z, belmont_update_intercept_exec_return
        
    _do:
        call get_desired_inertia
        ldi16a belmont_inertia
        
    belmont_update_intercept_exec_return:
        ld a, bankB
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

    ldai16 belmont_state
    ld b, a

    ; check actually jumping
    ldai16 belmont_jumpstate
    ld h, a
    or a
    jp z, new_belmont_jump_routine_exec_return

knockback_check:
    ; don't do special jump routine if knockback and rising.
    ldai16 belmont_pose
    cp $7
    jr nz, skip_knockback_check
    
    ld a, h; a <- belmont jumpstate
    cp $F
    jp z, new_belmont_jump_routine_exec_return
    
skip_knockback_check:

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
    
    ; check not in knockback
    ldai16 belmont_pose
    cp $7
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
        or a
        call z, reset_belmont_inertia
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
    ld a, b
    cp $4
    jr nz, new_belmont_jump_routine_exec_return_jump
    
new_belmont_jump_routine_exec_return_whip:
    pushhl old_belmont_whip_routine
    jr jp_mbc_bank_switchB
    
new_belmont_jump_routine_exec_return_jump:
    pushhl old_belmont_jump_routine
    
jp_mbc_bank_switchB:
    ld a, bankB
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
            
    reset_belmont_inertia:
        ld a, INERTIA_ZERO
        ldi16a belmont_inertia
        ret
endif

end_bank3: