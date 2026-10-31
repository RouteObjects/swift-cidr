0000000000000a34 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     a34:      	sub	sp, sp, #0x70
     a38:      	stp	x28, x27, [sp, #0x10]
     a3c:      	stp	x26, x25, [sp, #0x20]
     a40:      	stp	x24, x23, [sp, #0x30]
     a44:      	stp	x22, x21, [sp, #0x40]
     a48:      	stp	x20, x19, [sp, #0x50]
     a4c:      	stp	x29, x30, [sp, #0x60]
     a50:      	add	x29, sp, #0x60
     a54:      	ldr	x26, [x0, #0x10]
     a58:      	cbz	x26, 0xaf8 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xc4>
     a5c:      	mov	x19, x1
     a60:      	mov	x21, #0x0               ; =0
     a64:      	ubfx	x27, x1, #32, #8
     a68:      	add	x28, x0, #0x24
     a6c:      	adrp	x22, 0x0 <ltmp0>
		0000000000000a6c:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMd
     a70:      	add	x22, x22, #0x0
		0000000000000a70:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMd
     a74:      	adrp	x23, 0x0 <ltmp0>
		0000000000000a74:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMR
     a78:      	add	x23, x23, #0x0
		0000000000000a78:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V4OGMR
     a7c:      	b	0xa8c <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x58>
     a80:      	add	x28, x28, #0x8
     a84:      	subs	x26, x26, #0x1
     a88:      	b.eq	0xafc <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xc8>
     a8c:      	ldur	w24, [x28, #-0x4]
     a90:      	ldrb	w8, [x28]
     a94:      	str	w24, [sp, #0x8]
     a98:      	strb	w8, [sp, #0xc]
     a9c:      	cmp	w8, w27
     aa0:      	b.hi	0xa80 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x4c>
     aa4:      	mov	x0, x22
     aa8:      	mov	x1, x23
     aac:      	bl	0xaac <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x78>
		0000000000000aac:  ARM64_RELOC_BRANCH26	___swift_instantiateConcreteTypeFromMangledNameV2
     ab0:      	mov	x25, x0
     ab4:      	adrp	x0, 0x0 <ltmp0>
		0000000000000ab4:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V4OGACyxGA3AWL
     ab8:      	add	x0, x0, #0x0
		0000000000000ab8:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V4OGACyxGA3AWL
     abc:      	mov	x1, x22
     ac0:      	mov	x2, x23
     ac4:      	bl	0xac4 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x90>
		0000000000000ac4:  ARM64_RELOC_BRANCH26	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGA3AWlTm
     ac8:      	mov	x1, x0
     acc:      	add	x8, sp, #0x4
     ad0:      	add	x20, sp, #0x8
     ad4:      	mov	x0, x25
     ad8:      	bl	0xad8 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa4>
		0000000000000ad8:  ARM64_RELOC_BRANCH26	_$s4CIDRAAPAAE4mask6Family_7StorageQZvg
     adc:      	ldr	w8, [sp, #0x4]
     ae0:      	and	w8, w8, w19
     ae4:      	cmp	w8, w24
     ae8:      	b.ne	0xa80 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x4c>
     aec:      	adds	x21, x21, #0x1
     af0:      	b.vc	0xa80 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x4c>
     af4:      	brk	#0x1
     af8:      	mov	x21, #0x0               ; =0
     afc:      	mov	x0, x21
     b00:      	ldp	x29, x30, [sp, #0x60]
     b04:      	ldp	x20, x19, [sp, #0x50]
     b08:      	ldp	x22, x21, [sp, #0x40]
     b0c:      	ldp	x24, x23, [sp, #0x30]
     b10:      	ldp	x26, x25, [sp, #0x20]
     b14:      	ldp	x28, x27, [sp, #0x10]
     b18:      	add	sp, sp, #0x70
     b1c:      	ret
