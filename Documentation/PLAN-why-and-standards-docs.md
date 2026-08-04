# Plan: “Why each type” and standards documentation

**Goal:** Make `swift-cidr` self-explanatory for (1) adopters, (2) the Swift Networking Workgroup, and (3) future-you—especially *why* each public type exists, how that maps to IETF/IANA sources, and why the design differs from a single host-oriented `struct CIDR`.

**Context:** After the first public NWG meeting (2026-08-03), active/different prior art and dogfooding (CLI/server libraries) were well received. Follow-up need: document *why* public types exist; for WG exploration of open implementations, also explain important **non-public** helpers.

**Related:** GitHub [issue #10](https://github.com/RouteObjects/swift-cidr/issues/10) (scoped IPv6 / host composition layer); CIPS draft (contextual use of prefixes—package docs stay RFC-grounded and do not depend on an unposted I-D).

**Meeting notes:** [NWG public meeting 2026-08-03 summary](https://forums.swift.org/t/networking-workgroup-public-meeting-monday-august-3-2026-agenda-and-call-for-topics/88623/5).

---

## Post-meeting adjustments (2026-08-03)

Adjustments after Eric’s summarized notes and author participation. **Core plan stays;** these items are additive.

### A. Meeting themes → doc response

| Meeting theme | Plan adjustment |
|---------------|-----------------|
| Subnets / CIDR / prefix length naturally pulled in | DESIGN narrative + type map (already planned) |
| Interfaces + link-local scoped addresses must be addressed | **Document target layering explicitly** (below); issue #10 |
| Progressive disclosure | **New DESIGN section:** common path vs infrastructure path |
| Code examples of expected usage | **New deliverable:** dogfooding / usage examples (below) |
| Prior art: protocols; pure math vs context of use | DESIGN: `protocol CIDR` vs community `struct CIDR`; math vs host/context |
| Experiment in open repos | INTERNALS + easy entry via DESIGN + examples |
| Platform vs modern language features | **Short platform notes** in INTERNALS or DESIGN (below)—not a platform politics proposal |

### B. Layering recommendation (stated in meeting; document in DESIGN)

In the meeting, the recommendation was:

- Keep **swift-cidr (core) = classless address / prefix math only**.
- Put **`IPEndpoint`**, **`Port`**, **interfaces**, and **link-local scoped IPv6** (`addr%zone`, RFC 4007) in **another layer** concerned with **context of use** and host/OS attachment—not in the math core.
- **Recommend the same split for any standard currency design** the NWG explores: do not force socket/interface/scope identity into pure prefix math.

Docs must record this as **target architecture** even before code moves:

```text
swift-cidr (math)     IPAddress, IPNetwork, PrefixLength, blocks, selectors, ASN, MAC families, …
        │
        └── host / context layer (name TBD)
              Port, IPEndpoint, ScopedIPv6, Interface/zone
              (issue #10; IPEndpoint/Port migrate out of math module)
```

Broader “CIDR context use cases” align with the CIPS draft; **package docs stay RFC-grounded** and do not depend on an unposted I-D. Optional “see also” after CIPS is public.

### C. Dogfooding / usage examples (add to deliverables)

NWG asked for **code examples of expected usage**. Document real consumers (not only toy snippets):

| Project | What it shows |
|---------|----------------|
| [asroutes](https://github.com/RouteObjects/asroutes) | Control-plane IRR → **canonical networks** + ASN |
| [swift-cidr-admission](https://github.com/RouteObjects/swift-cidr-admission) | Policy / containment on currency types |
| [cidrwalk](https://github.com/RouteObjects/cidrwalk) | Network/range-oriented workflows |
| [cidrmerge](https://github.com/RouteObjects/cidrmerge) | Aggregation / merge-style network math (**public dogfooding**) |

Add **`Documentation/Examples.md`** (or a DESIGN section “Real usage”) with short descriptions + links + 1–2 code sketches each. README links to it in one line.

### D. Progressive disclosure (add to DESIGN + README one-liner)

| Path | Types (illustrative) |
|------|----------------------|
| **Common / end-host** | `IPv4Address` / `IPv6Address`, later host-layer `Port` / endpoint / scope |
| **Infrastructure** | `PrefixLength`, `IPNetwork`, `CIDRBlock`, `NetworkPrefixRange`, ASN, multicast, `AnyIP*` |

State clearly: **the full surface is depth, not a day-one requirement for every app**—matches NWG progressive disclosure.

### E. Platform & representation notes (INTERNALS or short DESIGN appendix)

Meeting discussed **InlineArray**, deployment targets, SPM breaking changes, conditional compilation.

Document **this package’s choices** (not a WG mandate):

- **InlineArray:** not used today; **not opposed**—open to revisit if availability and ecosystem cost work. Current storage is family-appropriate integer/width-oriented representation chosen for portability and existing generic/mask operations.
- **Span:** experimented with; observed roughly **10–13% performance regression** in measured paths (may be usage/API shape, not Span itself). Stayed with **scoped pointer** write/parse paths for hot formatting/parsing. Treat Span as optional future optimization, not a requirement to rewrite working paths.
- **Takeaway for explorers:** prefer measured hot paths; modern sugar is welcome when it does not regress infrastructure workloads.

Keep this factual and short so NWG can compare approaches without reverse-engineering the repo.

### F. Phasing priority (updated)

| Order | Work | Why (post-meeting) |
|-------|------|---------------------|
| 1 | DESIGN narrative + form table + progressive disclosure + layering | Same language as the meeting |
| 2 | Usage / dogfooding examples (`Examples.md` + cidrmerge et al.) | Explicit NWG interest in usage examples |
| 3 | DocC why/RFC on core public types | IDE + repo explorers |
| 4 | INTERNALS (non-public + platform notes) | Open-implementation play |
| 5 | README lean links | Entry point only |

Implementation of host/context package and scoped IPv6 remains **Phase 5 / separate PRs**—docs-first unchanged.

### G. Still out of scope for this docs plan

- Choosing NWG’s official InlineArray vs integer storage strategy for a future standard  
- Rewriting core to Span in this documentation PR  
- Depending on unpublished CIPS text for package correctness  

---

## 1. Where docs live (recommendation)

| Document | Audience | Contents | Keep thin? |
|----------|----------|----------|------------|
| **README.md** | First visit, forums, SPI | Mission, 5–10 type bullets, **link** to design docs, 3–5 flagship RFCs, Learning links, modules | **Yes** — no full RFC matrix |
| **Documentation/DESIGN.md** (new) | NWG, contributors, serious adopters | Narrative: 4632 core → expanded usage; **type ↔ why ↔ primary RFC** table; form compare table; `protocol CIDR` vs community `struct CIDR`; layering (math vs host/context); progressive disclosure; ASN multi-consumer note | **Primary home for the map** |
| **Documentation/Examples.md** (new) | NWG, adopters | Dogfooding links + short usage sketches (asroutes, admission, cidrwalk, **cidrmerge**, …) | Medium |
| **Documentation/INTERNALS.md** (new) | NWG, contributors | Non-public types/helpers; hot paths; platform/representation notes (InlineArray, Span experiments) | Medium |
| **Documentation/Learning/** | Swift devs new to networking | Keep; add cross-links from DESIGN | Existing |
| **DocC on each public type** | IDE / symbol graph | What / why not neighbor / non-goals / **primary RFC** / one example | Source of truth per symbol |
| **CIPS I-D** | Architecture essay | Broader contextual taxonomy; **cite from DESIGN only after public**; package must stand alone on published RFCs | Separate track |

**Do not** put the full per-type RFC matrix only in README—it will rot and overwhelm.  
**Do** put a short “See DESIGN.md for type ↔ standards map” in README under Standards Grounding.

**Layering note (product + docs):** `Port` / `IPEndpoint` (and future scoped IPv6 / Interface·zone) are **composition / host-attachment**, not pure CIDR math. DESIGN.md documents the **target** boundary even before the package split ships; issue #10 tracks scoped IPv6. IMPLEMENTATION of the split can be a later PR series; this plan is **documentation-first**.

---

## 2. Narrative arc (must appear in DESIGN.md)

1. **RFC 4632** — Classless Inter-domain Routing as an **address assignment and aggregation plan**; native unit is **prefix/network-shaped**.  
2. **Classless / Inter-domain / Routing** — explicit length; multi-AS world; L3 control-plane concepts (not only host presentation).  
3. **Expanded usage after / alongside that plan** — same math in more contexts without a second invented notation:  
   - RPSL prefix operators → `NetworkPrefixRange` (RFC 2622 / 4012)  
   - Registry/delegation-shaped blocks → `CIDRBlock` (RFC 7020 + 4632)  
   - RPKI ROA base + `maxLength` → consumers of `IPNetwork` + `PrefixLength` (RFC 9582 as consumer)  
   - IRR / BGP / policy → networks + **ASN** (not only BGP)  
   - Host + mask config → `IPAddress` + prefix context  
   - Multicast → separate identity types  
4. **Composable types** — discrete roles; `protocol CIDR` shares structure; concrete structs hold meaning.  
5. **Not in core math long-term** — endpoint, port, scoped address (host/context layer).

---

## 3. Content deliverables

### 3.1 `Documentation/DESIGN.md` (new)

Sections:

1. Purpose and non-goals of the package  
2. Narrative: 4632 → expanded prefix usage  
3. **Progressive disclosure** — common path vs infrastructure path  
4. **Type map table** (every **public** currency type):  
   - Type  
   - Why it exists (one sentence)  
   - Why not string / Int / neighbor type  
   - Primary standard(s)  
   - Secondary / consumer standards  
   - Notes (e.g. ASN: BGP **and** RPKI ROA, IRR, RPSL, …)  
5. **Form comparison** — `IPAddress` vs `IPNetwork` vs `CIDRBlock` vs `NetworkPrefixRange`  
6. **`protocol CIDR` vs community `struct CIDR`**  
7. **Layering** — math core vs host/context (endpoint, port, interface, scoped IPv6); recommend same split for standards exploration; issue #10  
8. Modules (`CIDR`, `CIDRPOSIX`, `CIDRNIO`) and adapter non-goals  
9. Pointers to Learning, Examples.md, INTERNALS.md  
10. Optional: link hierarchy diagram (in-repo Mermaid/ASCII)

### 3.2 `Documentation/Examples.md` (new)

- Links + 1–2 sketches: asroutes, swift-cidr-admission, cidrwalk, **cidrmerge**  
- Call out control-plane vs app usage where relevant  
- Supports NWG “gather code examples of expected usage”

### 3.3 `Documentation/INTERNALS.md` (new)

For NWG / contributors:

- Public vs internal API policy  
- Non-public types (e.g. UTF-8 format writers, parse helpers, mask utilities): **why**, hot-path notes, “do not depend on from outside”  
- Family marker implementation sketch (`AF.*`)  
- Performance notes: scoped pointers on hot paths; **Span experiment (~10–13% regression)**—may be usage; left as future revisit; not anti-Span dogma  
- Representation notes: **InlineArray not used, not rejected**—availability/ecosystem tradeoff; open to revisit  
- How adapters reject or omit scope today; where scope will live later (host/context layer)

### 3.4 README.md (edit, keep lean)

- Add under Standards Grounding: link to **DESIGN.md** (“type ↔ standards map”).  
- Link **Examples.md** (dogfooding).  
- One sentence: **ASN** used with BGP, RPKI, IRR, policy—not BGP-only.  
- One sentence: **`protocol CIDR`** vs single hybrid wrapper (link DESIGN).  
- One sentence: endpoint/port/interface/scope as **host/context layer** (link DESIGN + issue #10); math core stays prefix currency.  
- One sentence progressive disclosure (common vs infrastructure types).  
- Do **not** paste full matrix into README.

### 3.5 DocC pass (public types)

For **each public currency type** (and important protocols), ensure DocC answers:

1. What  
2. Why not the neighbor type  
3. What it is **not**  
4. **Primary RFC/registry** (link)  
5. One example  

**ASN-specific:** Document consumers: inter-domain routing (BGP), **RPKI ROA origin**, **IRR** objects, RPSL/policy layers above numeric value—not “BGP only.”

**PrefixLength-specific:** Family bounds; composition into address/network/selectors; control-plane fields such as ROA `maxLength` as a *consumer* of length currency (cite 9582 in DESIGN; optional one line in DocC).

**IPEndpoint / Port:** Non-goals already good; add “belongs with host composition layer; may move package/module (see DESIGN / issue #10).”

### 3.6 Learning guides (light touch)

- `03-cidr-context-use-cases.md`: cross-link DESIGN form table; optional one line that broader “context” architecture is discussed outside the package (CIPS when public).  
- No dependency on unpublished I-D text.

### 3.7 Optional assets

- ASCII/Mermaid hierarchy in DESIGN (types-first; **`protocol CIDR`** called out; full protocol zoo optional).  
- Export PNG via draw.io for forums/slides when needed.

---

## 4. Type ↔ standards table (draft rows to verify on branch)

*Author must walk every row; starter set:*

| Type | Why (draft) | Primary cite | Also / consumers |
|------|-------------|--------------|------------------|
| `AddressFamily` / `AF.*` | IANA family + width as type system | IANA Address Family Numbers | — |
| `IPAddressFamily`, `AF.V4`, `AF.V6` | IP-only refinement | RFC 791, RFC 4291 | RFC 7608 (length range ops) |
| `PrefixLength` | Family-valid length currency | RFC 4632, RFC 4291 | RFC 9582 (`maxLength` consumer) |
| `IPAddress` | Address + prefix context | RFC 4632, RFC 4291 | Interface config practice |
| `IPNetwork` / `IPPrefix` | Canonical network (4632 unit) | **RFC 4632** | BGP/IRR/RPKI *consumers* |
| `CIDR` (protocol) | Shared bits+length across forms | RFC 4632 | Contrast: not `struct CIDR` wrapper |
| `CIDRBlock` | Neutral allocation-shaped block | RFC 4632, **RFC 7020** | RFC 6890 consumer |
| `NetworkPrefixRange` | Prefix selector | **RFC 2622**, RFC 4012 | ROA maxLength related idea (9582) |
| Multicast group/range | Multicast ≠ unicast subnet | RFC 4291, 4607, 6308 | RFC 5771 where useful |
| `AnyIP*` / `AnyPrefixLength` | Mixed-family boundaries | API need | Multi-family ROA sets (9582) |
| `AutonomousSystemNumber` | Inter-domain numeric AS | RFC 1930, **5396**, **6793** | **BGP, RPKI ROA, IRR, RPSL** |
| MAC `AF.MAC48/64` | L2 currency | IANA AF numbers | IEEE as needed |
| `Port` / `IPEndpoint` | Transport composition | Transport / IANA ports ref | **Host layer** (move) |
| Text styles | Presentation | RFC 5952, 4291 | — |

---

## 5. Git workflow (branch off main)

Work in the **swift-cidr** repo (path may be `Example Framework/Packages/swift-cidr` or the GitHub clone).

```bash
cd /path/to/swift-cidr   # or: Example Framework/Packages/swift-cidr if that is the git root

git fetch origin
git checkout main
git pull origin main

# Documentation-only branch
git checkout -b docs/why-types-and-standards

# After commits:
git push -u origin docs/why-types-and-standards
# Open PR → main: "docs: why each type, DESIGN/INTERNALS, DocC RFC cites"
```

**Suggested commit series (small, reviewable):**

1. `docs: add DESIGN.md narrative, progressive disclosure, type↔standards map`  
2. `docs: add Examples.md dogfooding (asroutes, admission, cidrwalk, cidrmerge)`  
3. `docs: add INTERNALS.md (non-public helpers, platform/Span notes)`  
4. `docs: README links and lean standards intro`  
5. `docs: DocC why/RFC pass on public currency types` (can split per file group)  
6. `docs: Learning cross-links; endpoint/host-layer notes`  

**PR description should mention:** NWG meeting 2026-08-03 (document why; usage examples; math vs context layering; help explorers of open implementations); issue #10 for endpoint/scope as **documented intent** (implementation may follow).

**Do not block** this docs PR on implementing scoped IPv6 or the package split—document the target architecture first.

---

## 6. Phased execution

### Phase 0 — Branch and inventory (½ day)

- [ ] Create `docs/why-types-and-standards` from `main`  
- [ ] Inventory all **public** types/protocols/enums (script or DocC)  
- [ ] Inventory **non-public** types worth INTERNALS (formatters, parse helpers, …)  
- [ ] Fill DESIGN table rows; fix any wrong RFC associations (author review of every row)

### Phase 1 — DESIGN.md + README pointer (1 day)

- [ ] Write DESIGN.md (sections in §3.1, including progressive disclosure + layering recommendation)  
- [ ] Emphasize ASN multi-consumer (BGP, RPKI, IRR, …)  
- [ ] Emphasize protocol CIDR vs struct CIDR  
- [ ] Emphasize math-only core vs host/context layer (endpoint, port, interface, scoped IPv6); link issue #10  
- [ ] README: links only; ASN, protocol-vs-struct, progressive disclosure, host-layer one-liners  
- [ ] Commit 1–2

### Phase 2 — Examples.md dogfooding (½ day)

- [ ] asroutes, swift-cidr-admission, cidrwalk, **cidrmerge**  
- [ ] Short sketches + what requirement each illustrates  
- [ ] Commit

### Phase 3 — INTERNALS.md (½–1 day)

- [ ] Non-public why list  
- [ ] Adapter/scope rejection notes  
- [ ] Platform notes: InlineArray (not used, not opposed); Span experiment (~10–13%, scoped pointers retained)  
- [ ] Commit

### Phase 4 — DocC pass (1–2 days)

- [ ] Public currency types: why + primary RFC  
- [ ] ASN / PrefixLength / IPNetwork / IPAddress / CIDRBlock / NetworkPrefixRange first  
- [ ] Then Any*, multicast, text styles, family markers  
- [ ] Endpoint/Port: host/context-layer intent  
- [ ] Commit(s)

### Phase 5 — Learning + polish (½ day)

- [ ] Cross-links  
- [ ] Optional hierarchy Mermaid/ASCII in DESIGN  
- [ ] PR open; request review; merge to main  

### Phase 6 — Follow-ons (separate issues/PRs; not this plan’s merge gate)

- [ ] Implement host/context package / move `IPEndpoint`+`Port` (code)  
- [ ] Scoped IPv6 (issue #10)  
- [ ] After CIPS I-D is public: optional DESIGN “see also” link  

---

## 7. Definition of done

- [ ] DESIGN.md merged with complete public currency type map + narrative + progressive disclosure  
- [ ] DESIGN documents math-only core vs host/context layer (endpoint, port, interface, scoped IPv6) and recommends the same split for standards exploration  
- [ ] Examples.md covers dogfooding including **cidrmerge**  
- [ ] INTERNALS.md covers non-public helpers + platform/Span notes NWG might care about  
- [ ] README points to DESIGN and Examples; stays scannable  
- [ ] DocC on public currency types includes why + primary standard where applicable  
- [ ] ASN documented beyond BGP-only (RPKI, IRR, …)  
- [ ] protocol vs struct CIDR explained once in DESIGN and pointed from README  
- [ ] Host/context layer documented as target architecture (issue #10 linked)  
- [ ] Branch PR reviewed and merged to `main`

---

## 8. Out of scope for this plan

- Implementing scoped IPv6 or package split (track separately)  
- Rewriting benchmarks or API renames  
- Depending on unpublished CIPS text for package correctness  
- Standardizing the full type surface in the Swift stdlib (docs support *requirements discussion* only)

---

## 9. Success metrics (qualitative)

- A NWG member can open DESIGN.md and explain why `IPNetwork` ≠ `IPAddress` ≠ `CIDRBlock` ≠ `NetworkPrefixRange` without a call.  
- A contributor can find why an internal UTF-8 writer exists without reverse-engineering.  
- Forum prior-art answers can link **one** DESIGN section instead of re-deriving the manifesto.

---

*Plan created for post–NWG-meeting documentation work. Execute on branch `docs/why-types-and-standards` off `main`.*
