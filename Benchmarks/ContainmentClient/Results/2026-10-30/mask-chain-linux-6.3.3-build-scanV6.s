0000000000000238 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     238:      	ldr	x9, [x0, #0x10]
     23c:      	cbz	x9, 0x2d8 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa0>
     240:      	mov	x8, x0
     244:      	mov	x0, xzr
     248:      	and	w10, w4, #0xff
     24c:      	add	x8, x8, #0x30
     250:      	mov	w11, #0x80              // =128
     254:      	mov	x12, #-0x1              // =-1
     258:      	mov	x13, #0x7fffffffffffffff // =9223372036854775807
     25c:      	b	0x274 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x3c>
     260:      	adds	x0, x0, #0x1
     264:      	b.vs	0x2e4 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xac>
     268:      	subs	x9, x9, #0x1
     26c:      	add	x8, x8, #0x20
     270:      	b.eq	0x2d4 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x9c>
     274:      	ldrb	w16, [x8]
     278:      	cmp	w10, w16
     27c:      	b.lo	0x268 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     280:      	cmp	w16, #0x80
     284:      	b.hi	0x2e0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa8>
     288:      	ldp	x15, x14, [x8, #-0x10]
     28c:      	cbz	w16, 0x2c8 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x90>
     290:      	sub	x16, x11, x16
     294:      	mvn	w17, w16
     298:      	lsl	x18, x12, x16
     29c:      	tst	x16, #0x40
     2a0:      	lsr	x17, x13, x17
     2a4:      	orr	x17, x18, x17
     2a8:      	csel	x16, x18, x17, ne
     2ac:      	csel	x17, xzr, x18, ne
     2b0:      	and	x16, x16, x3
     2b4:      	and	x17, x17, x2
     2b8:      	cmp	x16, x14
     2bc:      	ccmp	x17, x15, #0x0, eq
     2c0:      	b.eq	0x260 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     2c4:      	b	0x268 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     2c8:      	orr	x14, x15, x14
     2cc:      	cbnz	x14, 0x268 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     2d0:      	b	0x260 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     2d4:      	ret
     2d8:      	mov	x0, xzr
     2dc:      	ret
     2e0:      	brk	#0x1
     2e4:      	brk	#0x1
