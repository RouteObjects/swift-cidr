0000000000000210 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     210:      	pushq	%rbp
     211:      	movq	%rsp, %rbp
     214:      	pushq	%r15
     216:      	pushq	%r14
     218:      	pushq	%r13
     21a:      	pushq	%r12
     21c:      	pushq	%rbx
     21d:      	movq	0x10(%rdi), %r9
     221:      	testq	%r9, %r9
     224:      	je	0x2ba <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xaa>
     22a:      	movl	%ecx, %r8d
     22d:      	addq	$0x30, %rdi
     231:      	xorl	%r10d, %r10d
     234:      	xorl	%eax, %eax
     236:      	jmp	0x252 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x42>
     238:      	nopl	(%rax,%rax)
     240:      	incq	%rax
     243:      	jo	0x2c9 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xb9>
     249:      	addq	$0x20, %rdi
     24d:      	decq	%r9
     250:      	je	0x2bc <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xac>
     252:      	movzbl	(%rdi), %r14d
     256:      	cmpb	%r14b, %r8b
     259:      	jb	0x249 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x39>
     25b:      	cmpb	$-0x80, %r14b
     25f:      	ja	0x2c7 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xb7>
     261:      	movq	-0x10(%rdi), %r11
     265:      	movq	-0x8(%rdi), %rbx
     269:      	testq	%r14, %r14
     26c:      	je	0x2b3 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa3>
     26e:      	movb	$-0x80, %cl
     270:      	subb	%r14b, %cl
     273:      	movq	%rsi, %r14
     276:      	shrdq	%cl, %rdx, %r14
     27a:      	movq	%rdx, %r15
     27d:      	shrq	%cl, %r15
     280:      	testb	$0x40, %cl
     283:      	cmovneq	%r15, %r14
     287:      	cmovneq	%r10, %r15
     28b:      	movq	%r14, %r12
     28e:      	shlq	%cl, %r12
     291:      	testb	$0x40, %cl
     294:      	movq	%r12, %r13
     297:      	cmovneq	%r10, %r13
     29b:      	shldq	%cl, %r14, %r15
     29f:      	testb	$0x40, %cl
     2a2:      	cmovneq	%r12, %r15
     2a6:      	xorq	%rbx, %r15
     2a9:      	xorq	%r11, %r13
     2ac:      	orq	%r15, %r13
     2af:      	je	0x240 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     2b1:      	jmp	0x249 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x39>
     2b3:      	orq	%rbx, %r11
     2b6:      	jne	0x249 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x39>
     2b8:      	jmp	0x240 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     2ba:      	xorl	%eax, %eax
     2bc:      	popq	%rbx
     2bd:      	popq	%r12
     2bf:      	popq	%r13
     2c1:      	popq	%r14
     2c3:      	popq	%r15
     2c5:      	popq	%rbp
     2c6:      	retq
     2c7:      	ud2
     2c9:      	ud2
     2cb:      	nopl	(%rax,%rax)
