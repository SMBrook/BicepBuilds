param vNet2Name string
param SourcePeeringName string
param allowVirtualNetworkAccess string
param allowForwardedTraffic string
param allowGatewayTransit string
param useRemoteGateways string
param wvdVnetIdsource string = resourceId('Microsoft.Network/virtualNetworks',vNet2Name)

resource VnetPeering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: SourcePeeringName
  properties: {
    allowVirtualNetworkAccess: bool(allowVirtualNetworkAccess)
    allowForwardedTraffic: bool(allowForwardedTraffic)
    allowGatewayTransit: bool(allowGatewayTransit)
    useRemoteGateways: bool(useRemoteGateways)
    remoteVirtualNetwork: {
      id: wvdVnetIdsource
    }
  }
}
