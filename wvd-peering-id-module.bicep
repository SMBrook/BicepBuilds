param localVnetName2 string = 'Identity-vnet'
param wvdvnetID string

resource peer 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${localVnetName2}/peering-to-remote-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: wvdvnetID
    }
  }
}
