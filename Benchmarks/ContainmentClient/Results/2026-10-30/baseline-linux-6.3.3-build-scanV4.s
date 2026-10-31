0000000000000000 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
       0:      	sub	sp, sp, #0x60
       4:      	stp	x29, x30, [sp, #0x10]
       8:      	stp	x26, x25, [sp, #0x20]
       c:      	stp	x24, x23, [sp, #0x30]
      10:      	stp	x22, x21, [sp, #0x40]
      14:      	stp	x20, x19, [sp, #0x50]
      18:      	add	x29, sp, #0x10
      1c:      	ldr	x24, [x0, #0x10]
      20:      	cbz	x24, 0xa8 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa8>
      24:      	adrp	x21, 0x0 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>
		0000000000000024:  R_AARCH64_ADR_PREL_PG_HI21	$s4CIDR9IPNetworkVyAA2AFO2V4OGMD
      28:      	add	x21, x21, #0x0
		0000000000000028:  R_AARCH64_ADD_ABS_LO12_NC	$s4CIDR9IPNetworkVyAA2AFO2V4OGMD
      2c:      	mov	x20, x0
      30:      	mov	x19, x1
      34:      	adrp	x0, 0x0 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>
		0000000000000034:  R_AARCH64_ADR_PREL_PG_HI21	$s4CIDR9IPNetworkVyAA2AFO2V4OGACyxGAA8IPPrefixAAWL
      38:      	add	x0, x0, #0x0
		0000000000000038:  R_AARCH64_ADD_ABS_LO12_NC	$s4CIDR9IPNetworkVyAA2AFO2V4OGACyxGAA8IPPrefixAAWL
      3c:      	mov	x1, x21
      40:      	bl	0x4ec <$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm>
      44:      	lsr	x25, x19, #32
      48:      	mov	x23, x0
      4c:      	mov	x22, xzr
      50:      	add	x26, x20, #0x24
      54:      	b	0x64 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x64>
      58:      	subs	x24, x24, #0x1
      5c:      	add	x26, x26, #0x8
      60:      	b.eq	0xac <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xac>
      64:      	ldur	w8, [x26, #-0x4]
      68:      	ldrb	w9, [x26]
      6c:      	mov	x0, x21
      70:      	str	w19, [sp]
      74:      	str	w8, [sp, #0x8]
      78:      	strb	w9, [sp, #0xc]
      7c:      	strb	w25, [sp, #0x4]
      80:      	bl	0x80 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x80>
		0000000000000080:  R_AARCH64_CALL26	__swift_instantiateConcreteTypeFromMangledName
      84:      	mov	x1, x0
      88:      	mov	x0, sp
      8c:      	add	x20, sp, #0x8
      90:      	mov	x2, x23
      94:      	bl	0x94 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x94>
		0000000000000094:  R_AARCH64_CALL26	$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF
      98:      	tbz	w0, #0x0, 0x58 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x58>
      9c:      	adds	x22, x22, #0x1
      a0:      	b.vc	0x58 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x58>
      a4:      	brk	#0x1
      a8:      	mov	x22, xzr
      ac:      	mov	x0, x22
      b0:      	ldp	x20, x19, [sp, #0x50]
      b4:      	ldp	x22, x21, [sp, #0x40]
      b8:      	ldp	x24, x23, [sp, #0x30]
      bc:      	ldp	x26, x25, [sp, #0x20]
      c0:      	ldp	x29, x30, [sp, #0x10]
      c4:      	add	sp, sp, #0x60
      c8:      	ret
