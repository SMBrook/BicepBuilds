param identityVnetID string
param peeringnamefromwvdvnet string

resource peerid 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: peeringnamefromwvdvnet
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
