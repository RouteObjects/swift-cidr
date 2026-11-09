	.build_version macos, 15, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_$s19ConstantAccessProbe10mappedTextySSs6UInt32VF ; -- Begin function $s19ConstantAccessProbe10mappedTextySSs6UInt32VF
	.p2align	2
_$s19ConstantAccessProbe10mappedTextySSs6UInt32VF: ; @"$s19ConstantAccessProbe10mappedTextySSs6UInt32VF"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x22, x21, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w21, -24
	.cfi_offset w22, -32
	mov	w8, w0
	orr	x8, x8, #0xffff00000000
	stp	x8, xzr, [sp, #32]
Lloh0:
	adrp	x1, _$s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_TA@PAGE
Lloh1:
	add	x1, x1, _$s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_TA@PAGEOFF
	add	x2, sp, #16
	mov	w0, #22                         ; =0x16
	mov	x21, #0                         ; =0x0
	bl	_$sSS27unsafeUninitializedCapacity20initializingUTF8WithSSSi_SiSrys5UInt8VGKXEtKcfC
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function $s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_TA
_$s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_TA: ; @"$s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_TA"
	.cfi_startproc
; %bb.0:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	ldp	x2, x3, [x20, #16]
	bl	_$s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_$s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF ; -- Begin function $s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF
	.p2align	2
_$s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF: ; @"$s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF"
; %bb.0:
	eor	x8, x1, x0
	eor	x8, x8, #0x80
	lsr	x9, x1, #56
	cmp	x9, #254
	csel	x0, x8, xzr, hi
	ret
                                        ; -- End function
	.globl	_$s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF ; -- Begin function $s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF
	.p2align	2
_$s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF: ; @"$s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF"
	.cfi_startproc
; %bb.0:
	and	w8, w2, #0xff
	cmp	w8, #128
	b.hi	LBB3_2
; %bb.1:
	stp	x29, x30, [sp, #-16]!           ; 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	bl	_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5
	and	w8, w2, #0xff00
	eor	x9, x0, x1
	and	w10, w2, #0xff
	eor	x9, x9, x10
	cmp	w8, #256
	csel	x0, xzr, x9, eq
	ldp	x29, x30, [sp], #16             ; 16-byte Folded Reload
	ret
LBB3_2:
	; InlineAsm Start
	; InlineAsm End
	brk	#0x1
	.cfi_endproc
                                        ; -- End function
	.globl	_$s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF ; -- Begin function $s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF
	.p2align	2
_$s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF: ; @"$s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF"
; %bb.0:
	mov	x8, #8                          ; =0x8
	movk	x8, #65280, lsl #48
	eor	x0, x0, x8
	ret
                                        ; -- End function
	.private_extern	_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5 ; -- Begin function $s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5
	.globl	_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5
	.weak_def_can_be_hidden	_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5
	.p2align	2
_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5: ; @"$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5"
	.cfi_startproc
; %bb.0:
	and	w9, w2, #0xff
	cmp	w9, #129
	b.hs	LBB5_8
; %bb.1:
	mov	x8, x0
	mov	w9, #0                          ; =0x0
	mov	x0, #0                          ; =0x0
	mov	w10, #-128                      ; =0xffffff80
	mov	x11, #-1                        ; =0xffffffffffffffff
	sub	w10, w10, w2
	mvn	w12, w10
	lsl	x11, x11, x10
	and	x10, x10, #0xff
	tst	x10, #0x40
	csel	x10, xzr, x11, ne
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
	lsr	x12, x13, x12
	orr	x12, x11, x12
	csel	x11, x11, x12, ne
	ands	w14, w2, #0xff
	csel	x12, xzr, x11, eq
	csel	x13, xzr, x10, eq
	mov	w10, #1                         ; =0x1
	cmp	w14, #8
	b.lo	LBB5_5
; %bb.2:
	and	x13, x13, x8
	and	x12, x12, x1
	cmp	x12, x1
	ccmp	x13, x8, #0, eq
	mov	x3, x0
	b.ne	LBB5_7
; %bb.3:
	and	x9, x1, x11
	mov	x10, #-72057594037927936        ; =0xff00000000000000
	bics	xzr, x10, x9
	b.ne	LBB5_6
; %bb.4:
	mov	w10, #0                         ; =0x0
	mov	x0, x8
	mov	x3, x1
	mov	x9, x2
	b	LBB5_7
LBB5_5:
	mov	x3, x0
	b	LBB5_7
LBB5_6:
	mov	x0, #0                          ; =0x0
	mov	x3, #0                          ; =0x0
	mov	w9, #0                          ; =0x0
	mov	w10, #1                         ; =0x1
LBB5_7:
	and	w8, w9, #0xff
	orr	w2, w8, w10, lsl #8
	mov	x1, x3
	ret
LBB5_8:
	; InlineAsm Start
	; InlineAsm End
	brk	#0x1
	.cfi_endproc
                                        ; -- End function
	.private_extern	___swift_reflection_version ; @__swift_reflection_version
	.section	__TEXT,__const
	.globl	___swift_reflection_version
	.weak_definition	___swift_reflection_version
	.p2align	1, 0x0
___swift_reflection_version:
	.short	3                               ; 0x3

	.no_dead_strip	_$s19ConstantAccessProbe10mappedTextySSs6UInt32VF
	.no_dead_strip	_$s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF
	.no_dead_strip	_$s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF
	.no_dead_strip	_$s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF
	.no_dead_strip	___swift_reflection_version
	.linker_option "-lswiftCore"
	.linker_option "-lswift_StringProcessing"
	.linker_option "-lswift_Concurrency"
	.linker_option "-lobjc"
	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	100861760

.subsections_via_symbols
