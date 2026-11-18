# macOS ordinary CLI code generation

Both frozen ordinary Release binaries retain the specialized call chain. `ParsedInput.merged` directly calls separate `IPAddressRange<AF.V4>.coalescing` and `IPAddressRange<AF.V6>.coalescing` specializations. Each passes its concrete stable-sort and insertion-sort callbacks to a compiler-merged sort wrapper. The wrapper's V6 demangled name alone does not mean the V4 call uses V6 comparison code. Callback addresses resolve to the corresponding typed implementations.

In candidate C, the coalesced count comparison returns the sorted buffer when unchanged. The reduced-count branch loads empty Array storage, calls the concrete Array buffer allocator with `resultCount` as minimum capacity, copies the coalesced prefix with typed loads/stores, then releases the sorted buffer. IPv4 copies 8-byte elements and IPv6 copies 32-byte elements. The preserved disassembly includes capacity and copy-on-write checks; this is not evidence of zero allocations or a guaranteed allocator capacity.

`summary.json` binds current binary hashes, raw/demangled symbol tables and assembly, exact callback identities, and candidate branch addresses. `B-selected.txt` and `C-selected.txt` retain the relevant functions with line references into full captures. Captures used `xcrun nm -n`, `xcrun otool -tv` and `xcrun otool -tvV`, with `xcrun swift-demangle` for demangled forms. No CLI, benchmark, or profile was executed for this inspection.

These are current Swift 6.4.2 macOS code-generation observations. Live allocation size, retained pages and elapsed time need their separate probes and matched measurements.
