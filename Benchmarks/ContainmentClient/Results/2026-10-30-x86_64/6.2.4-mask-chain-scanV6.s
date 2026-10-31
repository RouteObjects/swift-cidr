0000000000000230 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     230:      	pushq	%rbp
     231:      	movq	%rsp, %rbp
     234:      	pushq	%r15
     236:      	pushq	%r14
     238:      	pushq	%r13
     23a:      	pushq	%r12
     23c:      	pushq	%rbx
     23d:      	movq	0x10(%rdi), %r9
     241:      	testq	%r9, %r9
     244:      	je	0x2d0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa0>
     24a:      	movl	%ecx, %r8d
     24d:      	addq	$0x30, %rdi
     251:      	xorl	%r10d, %r10d
     254:      	xorl	%eax, %eax
     256:      	jmp	0x26e <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x3e>
     258:      	nopl	(%rax,%rax)
     260:      	incq	%rax
     263:      	jo	0x2df <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xaf>
     265:      	addq	$0x20, %rdi
     269:      	decq	%r9
     26c:      	je	0x2d2 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa2>
     26e:      	movzbl	(%rdi), %ecx
     271:      	cmpb	%r8b, %cl
     274:      	ja	0x265 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x35>
     276:      	cmpb	$-0x80, %cl
     279:      	ja	0x2dd <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xad>
     27b:      	movq	-0x10(%rdi), %r11
     27f:      	movq	-0x8(%rdi), %rbx
     283:      	testb	%cl, %cl
     285:      	je	0x2c9 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x99>
     287:      	negb	%cl
     289:      	movq	%rsi, %r14
     28c:      	shrdq	%cl, %rdx, %r14
     290:      	movq	%rdx, %r15
     293:      	shrq	%cl, %r15
     296:      	testb	$0x40, %cl
     299:      	cmovneq	%r15, %r14
     29d:      	cmovneq	%r10, %r15
     2a1:      	movq	%r14, %r12
     2a4:      	shlq	%cl, %r12
     2a7:      	testb	$0x40, %cl
     2aa:      	movq	%r12, %r13
     2ad:      	cmovneq	%r10, %r13
     2b1:      	shldq	%cl, %r14, %r15
     2b5:      	testb	$0x40, %cl
     2b8:      	cmovneq	%r12, %r15
     2bc:      	xorq	%rbx, %r15
     2bf:      	xorq	%r11, %r13
     2c2:      	orq	%r15, %r13
     2c5:      	je	0x260 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     2c7:      	jmp	0x265 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x35>
     2c9:      	orq	%rbx, %r11
     2cc:      	jne	0x265 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x35>
     2ce:      	jmp	0x260 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     2d0:      	xorl	%eax, %eax
     2d2:      	popq	%rbx
     2d3:      	popq	%r12
     2d5:      	popq	%r13
     2d7:      	popq	%r14
     2d9:      	popq	%r15
     2db:      	popq	%rbp
     2dc:      	retq
     2dd:      	ud2
     2df:      	ud2
     2e1:      	nopw	%cs:(%rax,%rax)
