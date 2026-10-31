0000000000000270 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     270:      	pushq	%rbp
     271:      	movq	%rsp, %rbp
     274:      	pushq	%r15
     276:      	pushq	%r14
     278:      	pushq	%r13
     27a:      	pushq	%r12
     27c:      	pushq	%rbx
     27d:      	subq	$0x58, %rsp
     281:      	movl	%ecx, -0x2c(%rbp)
     284:      	movq	%rdx, -0x40(%rbp)
     288:      	movq	%rsi, -0x38(%rbp)
     28c:      	movq	0x10(%rdi), %r15
     290:      	testq	%r15, %r15
     293:      	je	0x317 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa7>
     299:      	movq	%rdi, %r12
     29c:      	leaq	(%rip), %rdi            # 0x2a3 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x33>
		000000000000029f:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL-0x4
     2a3:      	leaq	(%rip), %rsi            # 0x2aa <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x3a>
		00000000000002a6:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD-0x4
     2aa:      	callq	0x490 <$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm>
     2af:      	movq	%rax, %r14
     2b2:      	addq	$0x30, %r12
     2b6:      	xorl	%ebx, %ebx
     2b8:      	leaq	-0x80(%rbp), %r13
     2bc:      	jmp	0x2c9 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x59>
     2be:      	nop
     2c0:      	addq	$0x20, %r12
     2c4:      	decq	%r15
     2c7:      	je	0x319 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa9>
     2c9:      	movups	-0x10(%r12), %xmm0
     2cf:      	movzbl	(%r12), %eax
     2d4:      	movaps	%xmm0, -0x80(%rbp)
     2d8:      	movb	%al, -0x70(%rbp)
     2db:      	movq	-0x40(%rbp), %rax
     2df:      	movq	%rax, -0x58(%rbp)
     2e3:      	movq	-0x38(%rbp), %rax
     2e7:      	movq	%rax, -0x60(%rbp)
     2eb:      	movl	-0x2c(%rbp), %eax
     2ee:      	movb	%al, -0x50(%rbp)
     2f1:      	leaq	(%rip), %rdi            # 0x2f8 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x88>
		00000000000002f4:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD-0x4
     2f8:      	callq	0x2fd <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x8d>
		00000000000002f9:  R_X86_64_PLT32	__swift_instantiateConcreteTypeFromMangledName-0x4
     2fd:      	leaq	-0x60(%rbp), %rdi
     301:      	movq	%rax, %rsi
     304:      	movq	%r14, %rdx
     307:      	callq	0x30c <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x9c>
		0000000000000308:  R_X86_64_PLT32	$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF-0x4
     30c:      	testb	$0x1, %al
     30e:      	je	0x2c0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x50>
     310:      	incq	%rbx
     313:      	jno	0x2c0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x50>
     315:      	ud2
     317:      	xorl	%ebx, %ebx
     319:      	movq	%rbx, %rax
     31c:      	addq	$0x58, %rsp
     320:      	popq	%rbx
     321:      	popq	%r12
     323:      	popq	%r13
     325:      	popq	%r14
     327:      	popq	%r15
     329:      	popq	%rbp
     32a:      	retq
     32b:      	nopl	(%rax,%rax)
