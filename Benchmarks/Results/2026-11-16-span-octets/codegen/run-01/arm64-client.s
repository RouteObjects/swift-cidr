	.build_version macos, 15, 0	sdk_version 27, 2
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_$s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF ; -- Begin function $s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF
	.p2align	2
_$s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF: ; @"$s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF"
; %bb.0:
	cmp	x1, #4
	b.ne	LBB0_2
; %bb.1:
	ldr	w8, [x0]
	rev	w8, w8
	and	w9, w2, #0xff
	orr	x0, x8, x9, lsl #32
	ret
LBB0_2:
	mov	x0, #1099511627776              ; =0x10000000000
	ret
                                        ; -- End function
	.globl	_$s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF ; -- Begin function $s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF
	.p2align	2
_$s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF: ; @"$s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF"
; %bb.0:
	cmp	x1, #16
	b.ne	LBB1_2
; %bb.1:
	mov	w8, #0                          ; =0x0
	ldp	x9, x10, [x0]
	rev	x0, x10
	rev	x1, x9
	b	LBB1_3
LBB1_2:
	mov	x0, #0                          ; =0x0
	mov	x1, #0                          ; =0x0
	mov	w2, #0                          ; =0x0
	mov	w8, #1                          ; =0x1
LBB1_3:
	and	w9, w2, #0xff
	orr	w2, w9, w8, lsl #8
	ret
                                        ; -- End function
	.globl	_$s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF ; -- Begin function $s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF
	.p2align	2
_$s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF: ; @"$s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF"
; %bb.0:
	cmp	x1, #4
	b.ne	LBB2_2
; %bb.1:
	ldr	w8, [x0]
	rev	w8, w8
	orr	x0, x8, #0x2000000000
	ret
LBB2_2:
	mov	x0, #1099511627776              ; =0x10000000000
	ret
                                        ; -- End function
	.globl	_$s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF ; -- Begin function $s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF
	.p2align	2
_$s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF: ; @"$s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF"
; %bb.0:
	cmp	x1, #16
	b.ne	LBB3_2
; %bb.1:
	ldp	x9, x10, [x0]
	rev	x0, x10
	rev	x1, x9
	mov	w9, #128                        ; =0x80
	orr	w2, w9, wzr, lsl #8
	ret
LBB3_2:
	mov	x0, #0                          ; =0x0
	mov	x1, #0                          ; =0x0
	mov	w8, #1                          ; =0x1
	orr	w2, wzr, w8, lsl #8
	ret
                                        ; -- End function
	.globl	_$s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF ; -- Begin function $s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF
	.p2align	2
_$s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF: ; @"$s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF"
; %bb.0:
	rev	w8, w0
	and	w9, w1, #0xff
	orr	x0, x8, x9, lsl #32
	ret
                                        ; -- End function
	.globl	_$s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF ; -- Begin function $s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF
	.p2align	2
_$s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF: ; @"$s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF"
; %bb.0:
	rev	x8, x1
	rev	x1, x0
	mov	x0, x8
	ret
                                        ; -- End function
	.private_extern	___swift_reflection_version ; @__swift_reflection_version
	.section	__TEXT,__const
	.globl	___swift_reflection_version
	.weak_definition	___swift_reflection_version
	.p2align	1, 0x0
___swift_reflection_version:
	.short	3                               ; 0x3

	.no_dead_strip	_$s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF
	.no_dead_strip	_$s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF
	.no_dead_strip	_$s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF
	.no_dead_strip	_$s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF
	.no_dead_strip	_$s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF
	.no_dead_strip	_$s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF
	.no_dead_strip	___swift_reflection_version
	.linker_option "-lswiftCore"
	.linker_option "-lswift_StringProcessing"
	.linker_option "-lswift_Concurrency"
	.linker_option "-lobjc"
	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	100927296

.subsections_via_symbols
