00000000000009e4 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
     9e4:      	ldr	x9, [x0, #0x10]
     9e8:      	cbz	x9, 0xa58 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x74>
     9ec:      	mov	x8, x0
     9f0:      	mov	x0, #0x0                ; =0
     9f4:      	ubfx	x10, x1, #32, #8
     9f8:      	add	x8, x8, #0x24
     9fc:      	mov	w11, #-0x1              ; =-1
     a00:      	b	0xa18 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x34>
     a04:      	adds	x0, x0, #0x1
     a08:      	b.vs	0xa64 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x80>
     a0c:      	add	x8, x8, #0x8
     a10:      	subs	x9, x9, #0x1
     a14:      	b.eq	0xa54 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x70>
     a18:      	ldrb	w12, [x8]
     a1c:      	cmp	w12, w10
     a20:      	b.hi	0xa0c <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     a24:      	cmp	w12, #0x20
     a28:      	b.hi	0xa60 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x7c>
     a2c:      	ldur	w13, [x8, #-0x4]
     a30:      	cbz	w12, 0xa4c <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x68>
     a34:      	neg	w12, w12
     a38:      	lsl	w12, w11, w12
     a3c:      	and	w12, w12, w1
     a40:      	cmp	w12, w13
     a44:      	b.eq	0xa04 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
     a48:      	b	0xa0c <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     a4c:      	cbnz	w13, 0xa0c <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
     a50:      	b	0xa04 <_$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
     a54:      	ret
     a58:      	mov	x0, #0x0                ; =0
     a5c:      	ret
     a60:      	brk	#0x1
     a64:      	brk	#0x1
