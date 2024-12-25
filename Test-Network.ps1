#requires -modules NetAdapter, NetTCPIP, CimCmdLets, DnsClient
[CmdletBinding()]
param (    
)

#region Layer 1: Network
Write-Verbose 'Layer 1: Network'
Write-Verbose '    Get network adapters'
Get-NetAdapter

Write-Verbose '    Get network adapter status'
$netAdapter = Get-NetAdapter | Where-Object { $PSItem.Status -eq 'Up' }
$netAdapter | Format-List `
    Name, InterfaceAlias, InterfaceIndex, InterfaceDescription, MacAddress, Status, LinkSpeed, MediaType, MediaConnectionState
#endregion Layer 1: Network

#region Layer 2: Ethernet
Write-Verbose 'Layer 2: Ethernet'
Write-Verbose '    Get network adapter statistics'
$netAdapter |
Get-NetAdapterStatistics |
Format-List `
    Name, InterfaceAlias, InterfaceDescription, OutboundDiscardedPackets, OutboundPacketErrors, ReceivedDiscardedPackets, ReceivedPacketErrors
#endregion Layer 2: Ethernet

#region Layer 3: IP
Write-Verbose 'Layer 3: IP'
Write-Verbose '    Get network adapter IP configuration'
$netIPConfiguration = $netAdapter | Get-NetIPConfiguration
$netIPConfiguration

Write-Verbose `
    '    Get network adapter IP configuration details, including DHCP information'
Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
Where-Object { $PSItem.InterfaceIndex -in $netAdapter.InterfaceIndex } |
Select-Object `
    InterfaceIndex, Description, IPAddress, IPSubnet, DHCPEnabled, DHCPServer, DHCPLeaseObtained, DNSServerSearchOrder, DHCPLeaseExpires

Write-Verbose '    Test network connection to localhost'
Test-NetConnection –ComputerName 127.0.0.1

Write-Verbose '    Test network connection to local IP addresses'
$netIPConfiguration.IPv4Address.IPAddress |
ForEach-Object { Test-NetConnection –ComputerName $PSItem }

Write-Verbose `
    '    Test network connection to next hops (default gateways/routers)'
$netIPConfiguration.IPv4DefaultGateway.NextHop |
ForEach-Object { Test-NetConnection –ComputerName $PSItem } |
Format-Table InterfaceAlias, SourceAddress, RemoteAddress, PingSucceeded, @{
    label = 'RoundtripTime'
    expression = { $PSItem.PingReplyDetails.RoundTripTime }
}

Write-Verbose '    Test network connection to public IP address (Google DNS)'
Test-NetConnection -ComputerName 8.8.8.8
#endregion Layer 3: IP

#region Layer 4: TCP
Write-Verbose 'Layer 4: TCP'
Write-Verbose '    Test network connection to DNS servers'
$netIPConfiguration.DNSServer.ServerAddresses |
Select-Object -Unique |
ForEach-Object { Test-NetConnection -ComputerName $PSItem -Port 53 }
#endregion Layer 4: TCP

#Layer 7: DNS
Write-Verbose 'Layer 7: DNS'
Write-Verbose '    Resolve DNS name'
Resolve-DnsName -Name google.com

#Layer 7: HTTP
Write-Verbose 'Layer 7: HTTP'
Write-Verbose '    Test network connection to Google website'
Test-NetConnection –ComputerName google.com –Port 443