param localVnetName2 string = 'Identity-vnet'
param remoteVnetName2 string = 'bicep-vnet'
param remoteVnetRg2 string = 'AZDemoSB-Bicep-WVD'

resource peer 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${localVnetName2}/peering-to-remote-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg2, 'Microsoft.Network/virtualNetworks', remoteVnetName2)
    }
  }
}
