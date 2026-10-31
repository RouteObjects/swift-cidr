0000000000000ccc <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     ccc:      	sub	sp, sp, #0xa0
     cd0:      	stp	x28, x27, [sp, #0x40]
     cd4:      	stp	x26, x25, [sp, #0x50]
     cd8:      	stp	x24, x23, [sp, #0x60]
     cdc:      	stp	x22, x21, [sp, #0x70]
     ce0:      	stp	x20, x19, [sp, #0x80]
     ce4:      	stp	x29, x30, [sp, #0x90]
     ce8:      	add	x29, sp, #0x90
     cec:      	ldr	x27, [x0, #0x10]
     cf0:      	cbz	x27, 0xd8c <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xc0>
     cf4:      	mov	x19, x3
     cf8:      	mov	x21, x2
     cfc:      	mov	x22, x1
     d00:      	mov	x20, x0
     d04:      	adrp	x0, 0x0 <ltmp0>
		0000000000000d04:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL
     d08:      	add	x0, x0, #0x0
		0000000000000d08:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL
     d0c:      	adrp	x23, 0x0 <ltmp0>
		0000000000000d0c:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMd
     d10:      	add	x23, x23, #0x0
		0000000000000d10:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMd
     d14:      	adrp	x24, 0x0 <ltmp0>
		0000000000000d14:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMR
     d18:      	add	x24, x24, #0x0
		0000000000000d18:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMR
     d1c:      	mov	x1, x23
     d20:      	mov	x2, x24
     d24:      	bl	0xd24 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x58>
		0000000000000d24:  ARM64_RELOC_BRANCH26	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm
     d28:      	mov	x26, x0
     d2c:      	mov	x25, #0x0               ; =0
     d30:      	add	x28, x20, #0x30
     d34:      	b	0xd44 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x78>
     d38:      	add	x28, x28, #0x20
     d3c:      	subs	x27, x27, #0x1
     d40:      	b.eq	0xd90 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xc4>
     d44:      	ldp	x8, x9, [x28, #-0x10]
     d48:      	ldrb	w10, [x28]
     d4c:      	stp	x8, x9, [sp, #0x20]
     d50:      	strb	w10, [sp, #0x30]
     d54:      	stp	x22, x21, [sp]
     d58:      	strb	w19, [sp, #0x10]
     d5c:      	mov	x0, x23
     d60:      	mov	x1, x24
     d64:      	bl	0xd64 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x98>
		0000000000000d64:  ARM64_RELOC_BRANCH26	___swift_instantiateConcreteTypeFromMangledNameV2
     d68:      	mov	x1, x0
     d6c:      	mov	x0, sp
     d70:      	add	x20, sp, #0x20
     d74:      	mov	x2, x26
     d78:      	bl	0xd78 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xac>
		0000000000000d78:  ARM64_RELOC_BRANCH26	_$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF
     d7c:      	tbz	w0, #0x0, 0xd38 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x6c>
     d80:      	adds	x25, x25, #0x1
     d84:      	b.vc	0xd38 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x6c>
     d88:      	brk	#0x1
     d8c:      	mov	x25, #0x0               ; =0
     d90:      	mov	x0, x25
     d94:      	ldp	x29, x30, [sp, #0x90]
     d98:      	ldp	x20, x19, [sp, #0x80]
     d9c:      	ldp	x22, x21, [sp, #0x70]
     da0:      	ldp	x24, x23, [sp, #0x60]
     da4:      	ldp	x26, x25, [sp, #0x50]
     da8:      	ldp	x28, x27, [sp, #0x40]
     dac:      	add	sp, sp, #0xa0
     db0:      	ret
