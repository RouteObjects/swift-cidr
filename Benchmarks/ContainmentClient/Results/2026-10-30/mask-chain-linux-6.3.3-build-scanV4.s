0000000000000000 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF>:
       0:      	ldr	x9, [x0, #0x10]
       4:      	cbz	x9, 0x74 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x74>
       8:      	mov	x8, x0
       c:      	ubfx	x10, x1, #32, #8
      10:      	mov	x0, xzr
      14:      	add	x8, x8, #0x24
      18:      	mov	w11, #-0x1              // =-1
      1c:      	b	0x34 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x34>
      20:      	adds	x0, x0, #0x1
      24:      	b.vs	0x80 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x80>
      28:      	subs	x9, x9, #0x1
      2c:      	add	x8, x8, #0x8
      30:      	b.eq	0x70 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x70>
      34:      	ldrb	w12, [x8]
      38:      	cmp	w12, w10
      3c:      	b.hi	0x28 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
      40:      	cmp	w12, #0x20
      44:      	b.hi	0x7c <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x7c>
      48:      	ldur	w13, [x8, #-0x4]
      4c:      	cbz	w12, 0x68 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x68>
      50:      	neg	w12, w12
      54:      	lsl	w12, w11, w12
      58:      	and	w12, w12, w1
      5c:      	cmp	w12, w13
      60:      	b.eq	0x20 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
      64:      	b	0x28 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
      68:      	cbnz	w13, 0x28 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x28>
      6c:      	b	0x20 <$s17ContainmentClient6scanV4ySiSay4CIDR9IPNetworkVyAC2AFO0D0OGG_AC9IPAddressVyAIGtF+0x20>
      70:      	ret
      74:      	mov	x0, xzr
      78:      	ret
      7c:      	brk	#0x1
      80:      	brk	#0x1
