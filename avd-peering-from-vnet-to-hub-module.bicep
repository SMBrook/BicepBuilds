param hubvnetid string
param peeringnamefromavdvnet string

resource avdpeer 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: peeringnamefromavdvnet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubvnetid
    }
  }
}
