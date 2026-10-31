0000000000000290 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     290:      	pushq	%rbp
     291:      	movq	%rsp, %rbp
     294:      	pushq	%r15
     296:      	pushq	%r14
     298:      	pushq	%r13
     29a:      	pushq	%r12
     29c:      	pushq	%rbx
     29d:      	subq	$0x58, %rsp
     2a1:      	movl	%ecx, -0x2c(%rbp)
     2a4:      	movq	%rdx, -0x40(%rbp)
     2a8:      	movq	%rsi, -0x38(%rbp)
     2ac:      	movq	0x10(%rdi), %r15
     2b0:      	testq	%r15, %r15
     2b3:      	je	0x337 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa7>
     2b9:      	movq	%rdi, %r12
     2bc:      	leaq	(%rip), %rdi            # 0x2c3 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x33>
		00000000000002bf:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL-0x4
     2c3:      	leaq	(%rip), %rsi            # 0x2ca <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x3a>
		00000000000002c6:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD-0x4
     2ca:      	callq	0x6d0 <$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm>
     2cf:      	movq	%rax, %r14
     2d2:      	addq	$0x30, %r12
     2d6:      	xorl	%ebx, %ebx
     2d8:      	leaq	-0x80(%rbp), %r13
     2dc:      	jmp	0x2e9 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x59>
     2de:      	nop
     2e0:      	addq	$0x20, %r12
     2e4:      	decq	%r15
     2e7:      	je	0x339 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa9>
     2e9:      	movups	-0x10(%r12), %xmm0
     2ef:      	movzbl	(%r12), %eax
     2f4:      	movaps	%xmm0, -0x80(%rbp)
     2f8:      	movb	%al, -0x70(%rbp)
     2fb:      	movq	-0x40(%rbp), %rax
     2ff:      	movq	%rax, -0x58(%rbp)
     303:      	movq	-0x38(%rbp), %rax
     307:      	movq	%rax, -0x60(%rbp)
     30b:      	movl	-0x2c(%rbp), %eax
     30e:      	movb	%al, -0x50(%rbp)
     311:      	leaq	(%rip), %rdi            # 0x318 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x88>
		0000000000000314:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD-0x4
     318:      	callq	0x31d <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x8d>
		0000000000000319:  R_X86_64_PLT32	__swift_instantiateConcreteTypeFromMangledName-0x4
     31d:      	leaq	-0x60(%rbp), %rdi
     321:      	movq	%rax, %rsi
     324:      	movq	%r14, %rdx
     327:      	callq	0x32c <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x9c>
		0000000000000328:  R_X86_64_PLT32	$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF-0x4
     32c:      	testb	$0x1, %al
     32e:      	je	0x2e0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x50>
     330:      	incq	%rbx
     333:      	jno	0x2e0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x50>
     335:      	ud2
     337:      	xorl	%ebx, %ebx
     339:      	movq	%rbx, %rax
     33c:      	addq	$0x58, %rsp
     340:      	popq	%rbx
     341:      	popq	%r12
     343:      	popq	%r13
     345:      	popq	%r14
     347:      	popq	%r15
     349:      	popq	%rbp
     34a:      	retq
     34b:      	nopl	(%rax,%rax)
