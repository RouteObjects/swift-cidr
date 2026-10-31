0000000000000c1c <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     c1c:      	ldr	x9, [x0, #0x10]
     c20:      	cbz	x9, 0xcbc <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa0>
     c24:      	mov	x8, x0
     c28:      	mov	x0, #0x0                ; =0
     c2c:      	and	w10, w3, #0xff
     c30:      	add	x8, x8, #0x30
     c34:      	mov	w11, #0x80              ; =128
     c38:      	mov	x12, #-0x1              ; =-1
     c3c:      	mov	x13, #0x7fffffffffffffff ; =9223372036854775807
     c40:      	b	0xc58 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x3c>
     c44:      	adds	x0, x0, #0x1
     c48:      	b.vs	0xcc8 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xac>
     c4c:      	add	x8, x8, #0x20
     c50:      	subs	x9, x9, #0x1
     c54:      	b.eq	0xcb8 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x9c>
     c58:      	ldrb	w16, [x8]
     c5c:      	cmp	w10, w16
     c60:      	b.lo	0xc4c <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     c64:      	cmp	w16, #0x80
     c68:      	b.hi	0xcc4 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0xa8>
     c6c:      	ldp	x15, x14, [x8, #-0x10]
     c70:      	cbz	w16, 0xcac <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x90>
     c74:      	sub	x16, x11, x16
     c78:      	mvn	w17, w16
     c7c:      	lsl	x3, x12, x16
     c80:      	lsr	x17, x13, x17
     c84:      	orr	x17, x3, x17
     c88:      	tst	x16, #0x40
     c8c:      	csel	x16, x3, x17, ne
     c90:      	csel	x17, xzr, x3, ne
     c94:      	and	x17, x17, x1
     c98:      	and	x16, x16, x2
     c9c:      	cmp	x16, x14
     ca0:      	ccmp	x17, x15, #0x0, eq
     ca4:      	b.eq	0xc44 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     ca8:      	b	0xc4c <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     cac:      	orr	x14, x15, x14
     cb0:      	cbnz	x14, 0xc4c <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x30>
     cb4:      	b	0xc44 <_$s17ContainmentClient6scanV6ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     cb8:      	ret
     cbc:      	mov	x0, #0x0                ; =0
     cc0:      	ret
     cc4:      	brk	#0x1
     cc8:      	brk	#0x1
