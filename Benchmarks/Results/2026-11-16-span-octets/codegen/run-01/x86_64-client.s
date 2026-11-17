	.build_version macos, 15, 0	sdk_version 27, 2
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_$s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF ## -- Begin function $s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF
	.p2align	4
_$s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF: ## @"$s10SpanClient04ipv4A0_12prefixLengths6UInt32V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V4OGtF"
## %bb.0:
	cmpq	$4, %rsi
	jne	LBB0_1
## %bb.3:
	pushq	%rbp
	movq	%rsp, %rbp
	movl	(%rdi), %eax
	bswapl	%eax
	movzbl	%dl, %ecx
	shlq	$32, %rcx
	orq	%rcx, %rax
	popq	%rbp
	retq
LBB0_1:
	movabsq	$1099511627776, %rax            ## imm = 0x10000000000
	retq
                                        ## -- End function
	.globl	_$s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF ## -- Begin function $s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF
	.p2align	4
_$s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF: ## @"$s10SpanClient04ipv6A0_12prefixLengths7UInt128V7address_s5UInt8VACtSgs0A0VyAHG_4CIDR06PrefixE0VyAM2AFO2V6OGtF"
## %bb.0:
	cmpq	$16, %rsi
	jne	LBB1_1
## %bb.3:
	pushq	%rbp
	movq	%rsp, %rbp
	movl	%edx, %ecx
	movq	8(%rdi), %rax
	bswapq	%rax
	movq	(%rdi), %rdx
	bswapq	%rdx
	movzbl	%cl, %ecx
	popq	%rbp
	jmp	LBB1_2
LBB1_1:
	movw	$256, %cx                       ## imm = 0x100
	xorl	%eax, %eax
	xorl	%edx, %edx
LBB1_2:
	movzwl	%cx, %ecx
	xorl	%esi, %esi
	cmpl	$256, %ecx                      ## imm = 0x100
	cmovaeq	%rsi, %rax
	cmovaeq	%rsi, %rdx
	movzbl	%cl, %esi
	movl	$256, %ecx                      ## imm = 0x100
	cmovbl	%esi, %ecx
                                        ## kill: def $cx killed $cx killed $ecx
	retq
                                        ## -- End function
	.globl	_$s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF ## -- Begin function $s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF
	.p2align	4
_$s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF: ## @"$s10SpanClient04ipv4A7Defaultys6UInt32V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF"
## %bb.0:
	cmpq	$4, %rsi
	jne	LBB2_1
## %bb.3:
	pushq	%rbp
	movq	%rsp, %rbp
	movl	(%rdi), %ecx
	bswapl	%ecx
	movabsq	$137438953472, %rax             ## imm = 0x2000000000
	orq	%rcx, %rax
	popq	%rbp
	retq
LBB2_1:
	movabsq	$1099511627776, %rax            ## imm = 0x10000000000
	retq
                                        ## -- End function
	.globl	_$s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF ## -- Begin function $s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF
	.p2align	4
_$s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF: ## @"$s10SpanClient04ipv6A7Defaultys7UInt128V7address_s5UInt8V12prefixLengthtSgs0A0VyAGGF"
## %bb.0:
	cmpq	$16, %rsi
	jne	LBB3_1
## %bb.3:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	8(%rdi), %rax
	bswapq	%rax
	movq	(%rdi), %rdx
	bswapq	%rdx
	movw	$128, %cx
	popq	%rbp
	retq
LBB3_1:
	movw	$256, %cx                       ## imm = 0x100
	xorl	%edx, %edx
	xorl	%eax, %eax
	retq
                                        ## -- End function
	.globl	_$s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF ## -- Begin function $s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF
	.p2align	4
_$s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF: ## @"$s10SpanClient10ipv4Inline_12prefixLengths6UInt32V7address_s5UInt8VACts0D5ArrayVy$3_AHG_4CIDR06PrefixF0VyAL2AFO2V4OGtF"
## %bb.0:
	pushq	%rbp
	movq	%rsp, %rbp
                                        ## kill: def $edi killed $edi def $rdi
	bswapl	%edi
	movzbl	%sil, %eax
	shlq	$32, %rax
	orq	%rdi, %rax
	popq	%rbp
	retq
                                        ## -- End function
	.globl	_$s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF ## -- Begin function $s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF
	.p2align	4
_$s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF: ## @"$s10SpanClient10ipv6Inline_12prefixLengths7UInt128V7address_s5UInt8VACts0D5ArrayVy$15_AHG_4CIDR06PrefixF0VyAL2AFO2V6OGtF"
## %bb.0:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	%rsi, %rax
	bswapq	%rax
	bswapq	%rdi
	movl	%edx, %ecx
	movq	%rdi, %rdx
                                        ## kill: def $cl killed $cl killed $ecx
	popq	%rbp
	retq
                                        ## -- End function
	.private_extern	___swift_reflection_version ## @__swift_reflection_version
	.section	__TEXT,__const
	.globl	___swift_reflection_version
	.weak_definition	___swift_reflection_version
	.p2align	1, 0x0
___swift_reflection_version:
	.short	3                               ## 0x3

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
