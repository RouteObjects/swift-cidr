0000000000000280 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     280:      	sub	sp, sp, #0xa0
     284:      	stp	x29, x30, [sp, #0x40]
     288:      	str	x27, [sp, #0x50]
     28c:      	stp	x26, x25, [sp, #0x60]
     290:      	stp	x24, x23, [sp, #0x70]
     294:      	stp	x22, x21, [sp, #0x80]
     298:      	stp	x20, x19, [sp, #0x90]
     29c:      	add	x29, sp, #0x40
     2a0:      	ldr	x26, [x0, #0x10]
     2a4:      	cbz	x26, 0x330 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xb0>
     2a8:      	adrp	x23, 0x0 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>
		00000000000002a8:  R_AARCH64_ADR_PREL_PG_HI21	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD
     2ac:      	add	x23, x23, #0x0
		00000000000002ac:  R_AARCH64_ADD_ABS_LO12_NC	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD
     2b0:      	mov	x20, x0
     2b4:      	adrp	x0, 0x0 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>
		00000000000002b4:  R_AARCH64_ADR_PREL_PG_HI21	$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL
     2b8:      	add	x0, x0, #0x0
		00000000000002b8:  R_AARCH64_ADD_ABS_LO12_NC	$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL
     2bc:      	mov	x1, x23
     2c0:      	mov	w19, w4
     2c4:      	mov	x21, x3
     2c8:      	mov	x22, x2
     2cc:      	bl	0x4ec <$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm>
     2d0:      	mov	x25, x0
     2d4:      	mov	x24, xzr
     2d8:      	add	x27, x20, #0x30
     2dc:      	b	0x2ec <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x6c>
     2e0:      	subs	x26, x26, #0x1
     2e4:      	add	x27, x27, #0x20
     2e8:      	b.eq	0x334 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xb4>
     2ec:      	ldp	x9, x8, [x27, #-0x10]
     2f0:      	mov	x0, x23
     2f4:      	ldrb	w10, [x27]
     2f8:      	stp	x22, x21, [sp]
     2fc:      	strb	w19, [sp, #0x10]
     300:      	stp	x9, x8, [sp, #0x20]
     304:      	strb	w10, [sp, #0x30]
     308:      	bl	0x308 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x88>
		0000000000000308:  R_AARCH64_CALL26	__swift_instantiateConcreteTypeFromMangledName
     30c:      	mov	x1, x0
     310:      	mov	x0, sp
     314:      	add	x20, sp, #0x20
     318:      	mov	x2, x25
     31c:      	bl	0x31c <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x9c>
		000000000000031c:  R_AARCH64_CALL26	$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF
     320:      	tbz	w0, #0x0, 0x2e0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x60>
     324:      	adds	x24, x24, #0x1
     328:      	b.vc	0x2e0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x60>
     32c:      	brk	#0x1
     330:      	mov	x24, xzr
     334:      	mov	x0, x24
     338:      	ldp	x20, x19, [sp, #0x90]
     33c:      	ldp	x22, x21, [sp, #0x80]
     340:      	ldr	x27, [sp, #0x50]
     344:      	ldp	x24, x23, [sp, #0x70]
     348:      	ldp	x26, x25, [sp, #0x60]
     34c:      	ldp	x29, x30, [sp, #0x40]
     350:      	add	sp, sp, #0xa0
     354:      	ret
