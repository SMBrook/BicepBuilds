param DestinationPeeringName string
param vNet1Name string
param allowVirtualNetworkAccess string
param allowForwardedTraffic string
param allowGatewayTransit string
param useRemoteGateways string
param wvdVnetId string

resource VnetPeering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: DestinationPeeringName
  properties: {
    allowVirtualNetworkAccess: bool(allowVirtualNetworkAccess)
    allowForwardedTraffic: bool(allowForwardedTraffic)
    allowGatewayTransit: bool(allowGatewayTransit)
    useRemoteGateways: bool(useRemoteGateways)
  remoteVirtualNetwork: {
      id: wvdVnetId
    }
  }
}
