00000000000002a0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     2a0:      	sub	sp, sp, #0xa0
     2a4:      	stp	x29, x30, [sp, #0x40]
     2a8:      	str	x27, [sp, #0x50]
     2ac:      	stp	x26, x25, [sp, #0x60]
     2b0:      	stp	x24, x23, [sp, #0x70]
     2b4:      	stp	x22, x21, [sp, #0x80]
     2b8:      	stp	x20, x19, [sp, #0x90]
     2bc:      	add	x29, sp, #0x40
     2c0:      	ldr	x26, [x0, #0x10]
     2c4:      	cbz	x26, 0x350 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xb0>
     2c8:      	adrp	x23, 0x0 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>
		00000000000002c8:  R_AARCH64_ADR_PREL_PG_HI21	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD
     2cc:      	add	x23, x23, #0x0
		00000000000002cc:  R_AARCH64_ADD_ABS_LO12_NC	$s4CIDR9IPNetworkVyAA2AFO2V6OGMD
     2d0:      	mov	x20, x0
     2d4:      	adrp	x0, 0x0 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>
		00000000000002d4:  R_AARCH64_ADR_PREL_PG_HI21	$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL
     2d8:      	add	x0, x0, #0x0
		00000000000002d8:  R_AARCH64_ADD_ABS_LO12_NC	$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWL
     2dc:      	mov	x1, x23
     2e0:      	mov	w19, w4
     2e4:      	mov	x21, x3
     2e8:      	mov	x22, x2
     2ec:      	bl	0x6f8 <$s4CIDR9IPNetworkVyAA2AFO2V6OGACyxGAA8IPPrefixAAWlTm>
     2f0:      	mov	x25, x0
     2f4:      	mov	x24, xzr
     2f8:      	add	x27, x20, #0x30
     2fc:      	b	0x30c <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x6c>
     300:      	subs	x26, x26, #0x1
     304:      	add	x27, x27, #0x20
     308:      	b.eq	0x354 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xb4>
     30c:      	ldp	x9, x8, [x27, #-0x10]
     310:      	mov	x0, x23
     314:      	ldrb	w10, [x27]
     318:      	stp	x22, x21, [sp]
     31c:      	strb	w19, [sp, #0x10]
     320:      	stp	x9, x8, [sp, #0x20]
     324:      	strb	w10, [sp, #0x30]
     328:      	bl	0x328 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x88>
		0000000000000328:  R_AARCH64_CALL26	__swift_instantiateConcreteTypeFromMangledName
     32c:      	mov	x1, x0
     330:      	mov	x0, sp
     334:      	add	x20, sp, #0x20
     338:      	mov	x2, x25
     33c:      	bl	0x33c <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x9c>
		000000000000033c:  R_AARCH64_CALL26	$s4CIDR8IPPrefixPAAE8contains7addressSbAA9IPAddressVy6FamilyQzG_tF
     340:      	tbz	w0, #0x0, 0x300 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x60>
     344:      	adds	x24, x24, #0x1
     348:      	b.vc	0x300 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x60>
     34c:      	brk	#0x1
     350:      	mov	x24, xzr
     354:      	mov	x0, x24
     358:      	ldp	x20, x19, [sp, #0x90]
     35c:      	ldp	x22, x21, [sp, #0x80]
     360:      	ldr	x27, [sp, #0x50]
     364:      	ldp	x24, x23, [sp, #0x70]
     368:      	ldp	x26, x25, [sp, #0x60]
     36c:      	ldp	x29, x30, [sp, #0x40]
     370:      	add	sp, sp, #0xa0
     374:      	ret
