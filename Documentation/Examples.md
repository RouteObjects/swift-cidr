# Examples: dogfooding `swift-cidr`

Real packages and tools that use `swift-cidr` as currency. These support “expected usage” discussions (for example in the Swift Networking Workgroup) better than toy snippets alone.

For architecture and type rationale, see [DESIGN.md](DESIGN.md).

---

## asroutes

**Repository:** [RouteObjects/asroutes](https://github.com/RouteObjects/asroutes)

**What it does:** CLI and library that query an IRRd service for IRR `route` / `route6` objects by origin Autonomous System.

**What it shows:**

- Control-plane data as **canonical networks**, not interface configs  
- **ASN** next to prefixes  
- Multiplatform server-side Swift (not only client apps)

```swift
// Conceptual: results are network-shaped currency, not host+mask hybrids.
// let networks: [IPv4Network] = ... from IRR lookup for AS701
```

---

## swift-cidr-admission

**Repository:** [RouteObjects/swift-cidr-admission](https://github.com/RouteObjects/swift-cidr-admission)

**What it does:** Framework-neutral allow/deny style policy over address and network values, with optional SwiftNIO-oriented examples.

**What it shows:**

- Containment and policy on **shared currency types**  
- Adapters at the edge; math types stay pure  

---

## cidrwalk

**Repository:** [RouteObjects/cidrwalk](https://github.com/RouteObjects/cidrwalk)

**What it does:** Walks and summarizes address ranges / networks.

**What it shows:**

- Workflows that **start from networks and ranges**, not only endpoints  
- Distinction between address-range thinking and whole-network operations  

---

## cidrmerge

**Repository:** [RouteObjects/cidrmerge](https://github.com/RouteObjects/cidrmerge)

**What it does:** Compiles address and prefix inputs into deterministic, exact
coverage represented as coalesced ranges or canonical networks.

**What it shows:**

- Exact coalescing that does not widen across uncovered addresses
- Conversion between `IPAddressRange` coverage and canonical `IPNetwork` values
- Dogfooding of reusable family-bound math outside a GUI app

```swift
import CIDR

if let first = IPv4AddressRange("192.0.2.0...192.0.2.63"),
   let second = IPv4AddressRange("192.0.2.64...192.0.2.127") {
    let coverage = IPAddressCoverage([second, first])

    print(coverage.ranges.map(\.description))
    // ["192.0.2.0...192.0.2.127"]

    print(coverage.summarizedNetworks().map(\.description))
    // ["192.0.2.0/25"]
}
```

---

## Patterns these examples reinforce

| Pattern | Types typically involved |
|---------|---------------------------|
| Address with prefix context → network | `IPAddress` → `.network` → `IPNetwork` |
| Exact inclusive interval | `IPAddressRange` |
| Normalized exact union + indexed containment | `IPAddressCoverage` |
| Route / registry / policy key | `IPNetwork`, sometimes `AnyIPNetwork` |
| Origin / peer identity | `AutonomousSystemNumber` |
| More-specific selection | `NetworkPrefixRange` (RPSL-style) |
| Mixed-family control-plane sets | `AnyIPNetwork` + family discrimination |

Live multi-family RPKI data (many ASes with both IPv4 and IPv6 prefixes) is available from public feeds such as [Cloudflare’s rpki.json](https://rpki.cloudflare.com/rpki.json)—useful when designing mixed-family boundary types.

---

## In-tree learning samples

Short pedagogical snippets (not full products):

- [CIDR Foundations](Learning/01-cidr-foundations.md)  
- [Subnets, Supernets, and Aggregation](Learning/02-subnet-supernet-aggregation.md)  
- [CIDR Context Use Cases](Learning/03-cidr-context-use-cases.md)  
