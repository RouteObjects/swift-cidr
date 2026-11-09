	.build_version macos, 15, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_$s19ConstantAccessProbe10mappedTextySSs6UInt32VF ; -- Begin function $s19ConstantAccessProbe10mappedTextySSs6UInt32VF
	.p2align	2
_$s19ConstantAccessProbe10mappedTextySSs6UInt32VF: ; @"$s19ConstantAccessProbe10mappedTextySSs6UInt32VF"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #96
	stp	x22, x21, [sp, #48]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #64]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #80]             ; 16-byte Folded Spill
	add	x29, sp, #80
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
Lloh0:
	adrp	x8, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LL_Wz@GOTPAGE
Lloh1:
	ldr	x8, [x8, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LL_Wz@GOTPAGEOFF]
Lloh2:
	ldr	x8, [x8]
	cmn	x8, #1
	b.ne	LBB0_2
LBB0_1:
	mov	w8, w0
Lloh3:
	adrp	x9, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LLSivpZ@GOTPAGE
Lloh4:
	ldr	x9, [x9, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LLSivpZ@GOTPAGEOFF]
Lloh5:
	ldr	x0, [x9]
	orr	x8, x8, #0xffff00000000
	stp	x8, xzr, [sp, #32]
Lloh6:
	adrp	x1, _$s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_TA@PAGE
Lloh7:
	add	x1, x1, _$s4CIDR2AFO14formatV6MappedySSSgs7UInt128VFZSiSrys5UInt8VGXEfU_TA@PAGEOFF
	add	x2, sp, #16
	mov	x21, #0                         ; =0x0
	bl	_$sSS27unsafeUninitializedCapacity20initializingUTF8WithSSSi_SiSrys5UInt8VGKXEtKcfC
	ldp	x29, x30, [sp, #80]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #64]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #48]             ; 16-byte Folded Reload
	add	sp, sp, #96
	ret
LBB0_2:
Lloh8:
	adrp	x8, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LL_Wz@GOTPAGE
Lloh9:
	ldr	x8, [x8, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LL_Wz@GOTPAGEOFF]
Lloh10:
	adrp	x1, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LL_WZ@GOTPAGE
Lloh11:
	ldr	x1, [x1, _$s4CIDR2AFO44maximumIPv4MappedIPv6AddressLiteralUTF8Count33_E277A4EFCA1AEB3F37C9C76F24BC1321LL_WZ@GOTPAGEOFF]
	mov	x19, x0
	mov	x0, x8
	bl	_swift_once
	mov	x0, x19
	b	LBB0_1
	.loh AdrpLdrGotLdr	Lloh0, Lloh1, Lloh2
	.loh AdrpAdd	Lloh6, Lloh7
	.loh AdrpLdrGotLdr	Lloh3, Lloh4, Lloh5
	.loh AdrpLdrGot	Lloh10, Lloh11
	.loh AdrpLdrGot	Lloh8, Lloh9
	.cfi_endproc
                                        ; -- End function
	.globl	_$s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF ; -- Begin function $s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF
	.p2align	2
_$s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF: ; @"$s19ConstantAccessProbe14multicastGroupys6UInt64Vs7UInt128VF"
	.cfi_startproc
; %bb.0:
Lloh12:
	adrp	x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGE
Lloh13:
	ldr	x8, [x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGEOFF]
Lloh14:
	ldr	x8, [x8]
	cmn	x8, #1
	b.ne	LBB1_3
LBB1_1:
Lloh15:
	adrp	x9, _$s4CIDR2AFO2V6O21multicastAddressSpaceAA9CIDRBlockVyAEGvpZ@GOTPAGE
Lloh16:
	ldr	x9, [x9, _$s4CIDR2AFO2V6O21multicastAddressSpaceAA9CIDRBlockVyAEGvpZ@GOTPAGEOFF]
	ldrb	w8, [x9, #16]
	cmp	w8, #129
	b.hs	LBB1_4
; %bb.2:
	ldp	x9, x10, [x9]
	mov	w11, #128                       ; =0x80
	sub	w11, w11, w8
	mvn	w12, w11
	mov	x13, #9223372036854775807       ; =0x7fffffffffffffff
	lsr	x12, x13, x12
	mov	x13, #-1                        ; =0xffffffffffffffff
	lsl	x13, x13, x11
	orr	x12, x13, x12
	tst	x11, #0x40
	csel	x11, x13, x12, ne
	csel	x12, xzr, x13, ne
	cmp	w8, #0
	csel	x8, xzr, x12, eq
	csel	x11, xzr, x11, eq
	and	x11, x11, x1
	and	x8, x8, x0
	eor	x12, x1, x0
	eor	x12, x12, #0x80
	eor	x8, x8, x9
	eor	x9, x11, x10
	orr	x8, x8, x9
	cmp	x8, #0
	csel	x0, x12, xzr, eq
	ret
LBB1_3:
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
Lloh17:
	adrp	x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGE
Lloh18:
	ldr	x8, [x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGEOFF]
Lloh19:
	adrp	x9, _$s4CIDR2AFO2V6O21multicastAddressSpace_WZ@GOTPAGE
Lloh20:
	ldr	x9, [x9, _$s4CIDR2AFO2V6O21multicastAddressSpace_WZ@GOTPAGEOFF]
	mov	x19, x0
	mov	x0, x8
	mov	x20, x1
	mov	x1, x9
	bl	_swift_once
	mov	x0, x19
	mov	x1, x20
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	b	LBB1_1
LBB1_4:
	; InlineAsm Start
	; InlineAsm End
	brk	#0x1
	.loh AdrpLdrGotLdr	Lloh12, Lloh13, Lloh14
	.loh AdrpLdrGot	Lloh15, Lloh16
	.loh AdrpLdrGot	Lloh19, Lloh20
	.loh AdrpLdrGot	Lloh17, Lloh18
	.cfi_endproc
                                        ; -- End function
	.globl	_$s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF ; -- Begin function $s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF
	.p2align	2
_$s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF: ; @"$s19ConstantAccessProbe14multicastRangeys6UInt64Vs7UInt128V_s5UInt8VtF"
	.cfi_startproc
; %bb.0:
	and	w8, w2, #0xff
	cmp	w8, #128
	b.hi	LBB2_2
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
LBB2_2:
	; InlineAsm Start
	; InlineAsm End
	brk	#0x1
	.cfi_endproc
                                        ; -- End function
	.globl	_$s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF ; -- Begin function $s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF
	.p2align	2
_$s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF: ; @"$s19ConstantAccessProbe18multicastBlockReadys6UInt64VADF"
; %bb.0:
Lloh21:
	adrp	x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGE
Lloh22:
	ldr	x8, [x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGEOFF]
Lloh23:
	ldr	x8, [x8]
	cmn	x8, #1
	b.ne	LBB3_2
LBB3_1:
Lloh24:
	adrp	x8, _$s4CIDR2AFO2V6O21multicastAddressSpaceAA9CIDRBlockVyAEGvpZ@GOTPAGE
Lloh25:
	ldr	x8, [x8, _$s4CIDR2AFO2V6O21multicastAddressSpaceAA9CIDRBlockVyAEGvpZ@GOTPAGEOFF]
	ldp	x9, x10, [x8]
	ldrb	w8, [x8, #16]
	eor	x9, x10, x9
	eor	x8, x0, x8
	eor	x0, x8, x9
	ret
LBB3_2:
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
Lloh26:
	adrp	x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGE
Lloh27:
	ldr	x8, [x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGEOFF]
Lloh28:
	adrp	x1, _$s4CIDR2AFO2V6O21multicastAddressSpace_WZ@GOTPAGE
Lloh29:
	ldr	x1, [x1, _$s4CIDR2AFO2V6O21multicastAddressSpace_WZ@GOTPAGEOFF]
	mov	x19, x0
	mov	x0, x8
	bl	_swift_once
	mov	x0, x19
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	b	LBB3_1
	.loh AdrpLdrGotLdr	Lloh21, Lloh22, Lloh23
	.loh AdrpLdrGot	Lloh24, Lloh25
	.loh AdrpLdrGot	Lloh28, Lloh29
	.loh AdrpLdrGot	Lloh26, Lloh27
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
	.private_extern	_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5 ; -- Begin function $s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5
	.globl	_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5
	.weak_def_can_be_hidden	_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5
	.p2align	2
_$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5: ; @"$s4CIDR21IPMulticastGroupRangeV6prefix0E6LengthACyxGSg7StorageQz_AA06PrefixF0VyxGtcfCAA2AFO2V6O_Tt2g5"
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #80
	stp	x24, x23, [sp, #16]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #32]             ; 16-byte Folded Spill
	stp	x20, x19, [sp, #48]             ; 16-byte Folded Spill
	stp	x29, x30, [sp, #64]             ; 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	and	w19, w2, #0xff
	cmp	w19, #129
	b.hs	LBB5_8
; %bb.1:
	mov	x20, #-1                        ; =0xffffffffffffffff
	mov	w8, #128                        ; =0x80
	sub	w8, w8, w19
	mvn	w9, w8
	lsl	x10, x20, x8
	tst	x8, #0x40
	csel	x8, xzr, x10, ne
	lsr	x23, x20, #1
	lsr	x9, x23, x9
	orr	x9, x10, x9
	csel	x9, x10, x9, ne
	cmp	w19, #0
	csel	x21, xzr, x9, eq
	csel	x22, xzr, x8, eq
	bic	x8, x0, x22
	bic	x9, x1, x21
	orr	x8, x8, x9
	cbnz	x8, LBB5_6
; %bb.2:
Lloh30:
	adrp	x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGE
Lloh31:
	ldr	x8, [x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGEOFF]
Lloh32:
	ldr	x8, [x8]
	cmn	x8, #1
	b.ne	LBB5_9
LBB5_3:
Lloh33:
	adrp	x9, _$s4CIDR2AFO2V6O21multicastAddressSpaceAA9CIDRBlockVyAEGvpZ@GOTPAGE
Lloh34:
	ldr	x9, [x9, _$s4CIDR2AFO2V6O21multicastAddressSpaceAA9CIDRBlockVyAEGvpZ@GOTPAGEOFF]
	ldrb	w8, [x9, #16]
	cmp	w19, w8
	b.lo	LBB5_6
; %bb.4:
	ldp	x10, x9, [x9]
	mov	w11, #128                       ; =0x80
	sub	w11, w11, w8
	mvn	w12, w11
	lsr	x12, x23, x12
	lsl	x13, x20, x11
	orr	x12, x13, x12
	tst	x11, #0x40
	csel	x11, x13, x12, ne
	csel	x12, xzr, x13, ne
	cmp	w8, #0
	csel	x8, xzr, x12, eq
	csel	x11, xzr, x11, eq
	and	x12, x0, x22
	and	x8, x12, x8
	and	x12, x1, x21
	and	x11, x12, x11
	cmp	x11, x9
	ccmp	x8, x10, #0, eq
	b.ne	LBB5_6
; %bb.5:
	mov	w8, #0                          ; =0x0
	b	LBB5_7
LBB5_6:
	mov	x0, #0                          ; =0x0
	mov	x1, #0                          ; =0x0
	mov	w19, #0                         ; =0x0
	mov	w8, #1                          ; =0x1
LBB5_7:
	orr	w2, w19, w8, lsl #8
	ldp	x29, x30, [sp, #64]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #48]             ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #80
	ret
LBB5_8:
	; InlineAsm Start
	; InlineAsm End
	brk	#0x1
LBB5_9:
Lloh35:
	adrp	x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGE
Lloh36:
	ldr	x8, [x8, _$s4CIDR2AFO2V6O21multicastAddressSpace_Wz@GOTPAGEOFF]
Lloh37:
	adrp	x9, _$s4CIDR2AFO2V6O21multicastAddressSpace_WZ@GOTPAGE
Lloh38:
	ldr	x9, [x9, _$s4CIDR2AFO2V6O21multicastAddressSpace_WZ@GOTPAGEOFF]
	stp	x1, x0, [sp]                    ; 16-byte Folded Spill
	mov	x0, x8
	mov	x1, x9
	bl	_swift_once
	ldp	x1, x0, [sp]                    ; 16-byte Folded Reload
	b	LBB5_3
	.loh AdrpLdrGotLdr	Lloh30, Lloh31, Lloh32
	.loh AdrpLdrGot	Lloh33, Lloh34
	.loh AdrpLdrGot	Lloh37, Lloh38
	.loh AdrpLdrGot	Lloh35, Lloh36
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
