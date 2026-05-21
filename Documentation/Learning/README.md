# Learning Guides

These guides explain the networking terminology behind `swift-cidr` and why the
library uses distinct types for addresses, networks, neutral CIDR blocks, and
multicast group ranges.

`swift-cidr` is a CIDR math library. It deliberately keeps operational context
separate from the core math so the same slash notation can be used correctly in
different networking domains.

## Guides

- [CIDR Foundations](01-cidr-foundations.md)
- [Subnets, Supernets, and Aggregation](02-subnet-supernet-aggregation.md)
- [CIDR Context Use Cases](03-cidr-context-use-cases.md)

## Reading Order

Start with CIDR foundations if you are new to the package. If you already know
CIDR but want to understand the type design, read the context use-cases guide
first.

The code snippets are plain Swift examples. They can be copied into a Swift
file, Swift package test, or Xcode playground, but the package source does not
depend on Xcode playground support.
