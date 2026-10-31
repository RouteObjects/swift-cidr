0000000000000258 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     258:      	ldr	x9, [x0, #0x10]
     25c:      	cbz	x9, 0x2f4 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x9c>
     260:      	mov	x8, x0
     264:      	mov	x0, xzr
     268:      	mov	x10, #0x7fffffffffffffff // =9223372036854775807
     26c:      	add	x8, x8, #0x30
     270:      	mov	x11, #-0x1              // =-1
     274:      	b	0x28c <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x34>
     278:      	adds	x0, x0, #0x1
     27c:      	b.vs	0x300 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa8>
     280:      	subs	x9, x9, #0x1
     284:      	add	x8, x8, #0x20
     288:      	b.eq	0x2f0 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x98>
     28c:      	ldrb	w14, [x8]
     290:      	cmp	w14, w4, uxtb
     294:      	b.hi	0x280 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     298:      	cmp	w14, #0x80
     29c:      	b.hi	0x2fc <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa4>
     2a0:      	ldp	x13, x12, [x8, #-0x10]
     2a4:      	cbz	w14, 0x2e4 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x8c>
     2a8:      	neg	w15, w14
     2ac:      	sub	w14, w14, #0x1
     2b0:      	and	w15, w15, #0x7f
     2b4:      	lsr	x14, x10, x14
     2b8:      	lsl	x16, x11, x15
     2bc:      	tst	x15, #0x40
     2c0:      	orr	x14, x16, x14
     2c4:      	csel	x15, xzr, x16, ne
     2c8:      	csel	x14, x16, x14, ne
     2cc:      	and	x15, x15, x2
     2d0:      	and	x14, x14, x3
     2d4:      	cmp	x14, x12
     2d8:      	ccmp	x15, x13, #0x0, eq
     2dc:      	b.eq	0x278 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
     2e0:      	b	0x280 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     2e4:      	orr	x12, x13, x12
     2e8:      	cbnz	x12, 0x280 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     2ec:      	b	0x278 <$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
     2f0:      	ret
     2f4:      	mov	x0, xzr
     2f8:      	ret
     2fc:      	brk	#0x1
     300:      	brk	#0x1
