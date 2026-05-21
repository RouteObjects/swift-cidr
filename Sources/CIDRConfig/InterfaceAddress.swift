import CIDR

/// A configured interface address and its subnet context.
///
/// `InterfaceAddress` models an address assigned to an interface together with
/// the prefix length that defines the attached subnet.
///
/// This differs subtly from `IPNetwork`:
///
/// - `IPNetwork` is the subnet boundary itself
/// - `InterfaceAddress` is a host address that exists within a subnet
///
/// The type lives in `CIDRConfig` rather than `CIDR` because interface
/// assignments are configuration semantics layered on top of the CIDR block engine.
public struct InterfaceAddress<Family: AddressFamily>: CIDR, Hashable {
    public let address: Family.Storage
    public let prefixLength: PrefixLength<Family>
    public var block: Family.Storage { address }

    /// Creates an interface address from raw address bits and explicit subnet context.
    public init(address: Family.Storage, prefixLength: PrefixLength<Family>) {
        self.address = address
        self.prefixLength = prefixLength
    }

    /// Creates an interface address from a CIDR-qualified host, preserving the
    /// prefix context already carried by that host value.
    public init(host: IPAddress<Family>) {
        self.address = host.address
        self.prefixLength = host.prefixLength
    }

    /// The configured host address assigned to the interface.
    public var host: IPAddress<Family> {
        IPAddress(address: address, prefixLength: prefixLength)
    }

    /// The subnet containing the configured interface address.
    public var network: IPNetwork<Family> {
        IPNetwork(host: host)
    }
}
