0000000000000000 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
       0:      	pushq	%rbp
       1:      	movq	%rsp, %rbp
       4:      	pushq	%r15
       6:      	pushq	%r14
       8:      	pushq	%r13
       a:      	pushq	%r12
       c:      	pushq	%rbx
       d:      	subq	$0x28, %rsp
      11:      	movq	0x10(%rdi), %rax
      15:      	movq	%rax, -0x50(%rbp)
      19:      	testq	%rax, %rax
      1c:      	je	0xae <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xae>
      22:      	movq	%rdi, %r14
      25:      	movq	%rsi, -0x48(%rbp)
      29:      	shrq	$0x20, %rsi
      2d:      	movq	%rsi, -0x40(%rbp)
      31:      	leaq	(%rip), %rdi            # 0x38 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x38>
		0000000000000034:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V4OGACyxGAA8IPPrefixAAWL-0x4
      38:      	leaq	(%rip), %rsi            # 0x3f <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x3f>
		000000000000003b:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V4OGMD-0x4
      3f:      	callq	0x490 <$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm>
      44:      	movq	%rax, %r15
      47:      	xorl	%r12d, %r12d
      4a:      	leaq	-0x38(%rbp), %r13
      4e:      	xorl	%ebx, %ebx
      50:      	jmp	0x69 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x69>
      52:      	nopw	%cs:(%rax,%rax)
      60:      	incq	%rbx
      63:      	cmpq	%rbx, -0x50(%rbp)
      67:      	je	0xb1 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xb1>
      69:      	movl	0x20(%r14,%rbx,8), %eax
      6e:      	movzbl	0x24(%r14,%rbx,8), %ecx
      74:      	movl	%eax, -0x38(%rbp)
      77:      	movb	%cl, -0x34(%rbp)
      7a:      	movq	-0x48(%rbp), %rax
      7e:      	movl	%eax, -0x30(%rbp)
      81:      	movq	-0x40(%rbp), %rax
      85:      	movb	%al, -0x2c(%rbp)
      88:      	leaq	(%rip), %rdi            # 0x8f <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x8f>
		000000000000008b:  R_X86_64_PC32	$s4CIDR9IPNetworkVyAA2AFO2V4OGMD-0x4
      8f:      	callq	0x94 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x94>
		0000000000000090:  R_X86_64_PLT32	__swift_instantiateConcreteTypeFromMangledName-0x4
      94:      	leaq	-0x30(%rbp), %rdi
      98:      	movq	%rax, %rsi
      9b:      	movq	%r15, %rdx
      9e:      	callq	0xa3 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa3>
		000000000000009f:  R_X86_64_PLT32	$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF-0x4
      a3:      	testb	$0x1, %al
      a5:      	je	0x60 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x60>
      a7:      	incq	%r12
      aa:      	jno	0x60 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x60>
      ac:      	ud2
      ae:      	xorl	%r12d, %r12d
      b1:      	movq	%r12, %rax
      b4:      	addq	$0x28, %rsp
      b8:      	popq	%rbx
      b9:      	popq	%r12
      bb:      	popq	%r13
      bd:      	popq	%r14
      bf:      	popq	%r15
      c1:      	popq	%rbp
      c2:      	retq
      c3:      	nopw	%cs:(%rax,%rax)
