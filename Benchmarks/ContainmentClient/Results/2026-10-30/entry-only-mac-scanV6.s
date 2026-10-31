0000000000000cd4 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     cd4:      	sub	sp, sp, #0xa0
     cd8:      	stp	x28, x27, [sp, #0x40]
     cdc:      	stp	x26, x25, [sp, #0x50]
     ce0:      	stp	x24, x23, [sp, #0x60]
     ce4:      	stp	x22, x21, [sp, #0x70]
     ce8:      	stp	x20, x19, [sp, #0x80]
     cec:      	stp	x29, x30, [sp, #0x90]
     cf0:      	add	x29, sp, #0x90
     cf4:      	stp	x1, x2, [sp]
     cf8:      	ldr	x27, [x0, #0x10]
     cfc:      	cbz	x27, 0xda4 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xd0>
     d00:      	mov	x22, #0x0               ; =0
     d04:      	and	w28, w3, #0xff
     d08:      	add	x25, x0, #0x30
     d0c:      	adrp	x23, 0x0 <ltmp0>
		0000000000000d0c:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMd
     d10:      	add	x23, x23, #0x0
		0000000000000d10:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMd
     d14:      	adrp	x24, 0x0 <ltmp0>
		0000000000000d14:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMR
     d18:      	add	x24, x24, #0x0
		0000000000000d18:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V6OGMR
     d1c:      	b	0xd2c <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x58>
     d20:      	add	x25, x25, #0x20
     d24:      	subs	x27, x27, #0x1
     d28:      	b.eq	0xda8 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xd4>
     d2c:      	ldp	x19, x21, [x25, #-0x10]
     d30:      	ldrb	w8, [x25]
     d34:      	stp	x19, x21, [sp, #0x20]
     d38:      	strb	w8, [sp, #0x30]
     d3c:      	cmp	w28, w8
     d40:      	b.lo	0xd20 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x4c>
     d44:      	mov	x0, x23
     d48:      	mov	x1, x24
     d4c:      	bl	0xd4c <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x78>
		0000000000000d4c:  ARM64_RELOC_BRANCH26	___swift_instantiateConcreteTypeFromMangledNameV2
     d50:      	mov	x26, x0
     d54:      	adrp	x0, 0x0 <ltmp0>
		0000000000000d54:  ARM64_RELOC_PAGE21	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGA3AWL
     d58:      	add	x0, x0, #0x0
		0000000000000d58:  ARM64_RELOC_PAGEOFF12	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGA3AWL
     d5c:      	mov	x1, x23
     d60:      	mov	x2, x24
     d64:      	bl	0xd64 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x90>
		0000000000000d64:  ARM64_RELOC_BRANCH26	_$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGA3AWlTm
     d68:      	mov	x1, x0
     d6c:      	add	x8, sp, #0x10
     d70:      	add	x20, sp, #0x20
     d74:      	mov	x0, x26
     d78:      	bl	0xd78 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa4>
		0000000000000d78:  ARM64_RELOC_BRANCH26	_$s4CIDRAAPAAE4mask6Family_7StorageQZvg
     d7c:      	ldp	x9, x8, [sp, #0x10]
     d80:      	ldp	x11, x10, [sp]
     d84:      	and	x9, x9, x11
     d88:      	and	x8, x8, x10
     d8c:      	cmp	x8, x21
     d90:      	ccmp	x9, x19, #0x0, eq
     d94:      	b.ne	0xd20 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x4c>
     d98:      	adds	x22, x22, #0x1
     d9c:      	b.vc	0xd20 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x4c>
     da0:      	brk	#0x1
     da4:      	mov	x22, #0x0               ; =0
     da8:      	mov	x0, x22
     dac:      	ldp	x29, x30, [sp, #0x90]
     db0:      	ldp	x20, x19, [sp, #0x80]
     db4:      	ldp	x22, x21, [sp, #0x70]
     db8:      	ldp	x24, x23, [sp, #0x60]
     dbc:      	ldp	x26, x25, [sp, #0x50]
     dc0:      	ldp	x28, x27, [sp, #0x40]
     dc4:      	add	sp, sp, #0xa0
     dc8:      	ret
