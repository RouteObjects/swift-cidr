0000000000000a34 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     a34:      	sub	sp, sp, #0x70
     a38:      	stp	x28, x27, [sp, #0x10]
     a3c:      	stp	x26, x25, [sp, #0x20]
     a40:      	stp	x24, x23, [sp, #0x30]
     a44:      	stp	x22, x21, [sp, #0x40]
     a48:      	stp	x20, x19, [sp, #0x50]
     a4c:      	stp	x29, x30, [sp, #0x60]
     a50:      	add	x29, sp, #0x60
     a54:      	ldr	x25, [x0, #0x10]
     a58:      	cbz	x25, 0xaf0 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xbc>
     a5c:      	mov	x19, x1
     a60:      	mov	x20, x0
     a64:      	adrp	x0, 0x0 <ltmp0>
		0000000000000a64:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V4OGACyxGAA8IPPrefixAAWL
     a68:      	add	x0, x0, #0x0
		0000000000000a68:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V4OGACyxGAA8IPPrefixAAWL
     a6c:      	adrp	x21, 0x0 <ltmp0>
		0000000000000a6c:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMd
     a70:      	add	x21, x21, #0x0
		0000000000000a70:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMd
     a74:      	adrp	x22, 0x0 <ltmp0>
		0000000000000a74:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMR
     a78:      	add	x22, x22, #0x0
		0000000000000a78:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMR
     a7c:      	mov	x1, x21
     a80:      	mov	x2, x22
     a84:      	bl	0xa84 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x50>
		0000000000000a84:  ARM64_RELOC_BRANCH26	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm
     a88:      	mov	x24, x0
     a8c:      	mov	x23, #0x0               ; =0
     a90:      	add	x26, x20, #0x24
     a94:      	lsr	x27, x19, #32
     a98:      	b	0xaa8 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x74>
     a9c:      	add	x26, x26, #0x8
     aa0:      	subs	x25, x25, #0x1
     aa4:      	b.eq	0xaf4 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xc0>
     aa8:      	ldur	w8, [x26, #-0x4]
     aac:      	ldrb	w9, [x26]
     ab0:      	str	w8, [sp, #0x8]
     ab4:      	strb	w9, [sp, #0xc]
     ab8:      	str	w19, [sp]
     abc:      	strb	w27, [sp, #0x4]
     ac0:      	mov	x0, x21
     ac4:      	mov	x1, x22
     ac8:      	bl	0xac8 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x94>
		0000000000000ac8:  ARM64_RELOC_BRANCH26	___swift_instantiateConcreteTypeFromMangledNameV2
     acc:      	mov	x1, x0
     ad0:      	mov	x0, sp
     ad4:      	add	x20, sp, #0x8
     ad8:      	mov	x2, x24
     adc:      	bl	0xadc <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa8>
		0000000000000adc:  ARM64_RELOC_BRANCH26	_$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF
     ae0:      	tbz	w0, #0x0, 0xa9c <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x68>
     ae4:      	adds	x23, x23, #0x1
     ae8:      	b.vc	0xa9c <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x68>
     aec:      	brk	#0x1
     af0:      	mov	x23, #0x0               ; =0
     af4:      	mov	x0, x23
     af8:      	ldp	x29, x30, [sp, #0x60]
     afc:      	ldp	x20, x19, [sp, #0x50]
     b00:      	ldp	x22, x21, [sp, #0x40]
     b04:      	ldp	x24, x23, [sp, #0x30]
     b08:      	ldp	x26, x25, [sp, #0x20]
     b0c:      	ldp	x28, x27, [sp, #0x10]
     b10:      	add	sp, sp, #0x70
     b14:      	ret
