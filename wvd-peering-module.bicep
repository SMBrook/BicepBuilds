param localVnetName string = 'bicep-vnet'
param identityVnetID string

resource peerid 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${localVnetName}/peering-to-remote-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: identityVnetID
    }
  }
}
