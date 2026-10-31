0000000000000000 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
       0:      	pushq	%rbp
       1:      	movq	%rsp, %rbp
       4:      	movq	0x10(%rdi), %rdx
       8:      	testq	%rdx, %rdx
       b:      	je	0x61 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x61>
       d:      	movq	%rsi, %r8
      10:      	shrq	$0x20, %r8
      14:      	xorl	%eax, %eax
      16:      	xorl	%r9d, %r9d
      19:      	jmp	0x2d <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x2d>
      1b:      	nopl	(%rax,%rax)
      20:      	incq	%rax
      23:      	jo	0x67 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x67>
      25:      	incq	%r9
      28:      	cmpq	%r9, %rdx
      2b:      	je	0x5f <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x5f>
      2d:      	movzbl	0x24(%rdi,%r9,8), %ecx
      33:      	cmpb	%r8b, %cl
      36:      	ja	0x25 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x25>
      38:      	cmpb	$0x20, %cl
      3b:      	ja	0x65 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x65>
      3d:      	movl	0x20(%rdi,%r9,8), %r10d
      42:      	testl	%ecx, %ecx
      44:      	je	0x58 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x58>
      46:      	negb	%cl
      48:      	movl	%esi, %r11d
      4b:      	shrl	%cl, %r11d
      4e:      	shll	%cl, %r11d
      51:      	cmpl	%r10d, %r11d
      54:      	je	0x20 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
      56:      	jmp	0x25 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x25>
      58:      	testl	%r10d, %r10d
      5b:      	jne	0x25 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x25>
      5d:      	jmp	0x20 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
      5f:      	popq	%rbp
      60:      	retq
      61:      	xorl	%eax, %eax
      63:      	popq	%rbp
      64:      	retq
      65:      	ud2
      67:      	ud2
      69:      	nopl	(%rax)
