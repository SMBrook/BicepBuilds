targetScope = 'subscription'

param sigName string = 'wvdbicepsig'
param sigLocation string = 'northeurope'
param sigrg string = 'Bicep-SIG-Collaboration'
param uamiName string = '${'AIBUser'}${utcNow()}'

//Get SIG Resource Group Details
resource sigresourcegroup 'Microsoft.Resources/resourceGroups@2020-06-01' existing = {
  name: sigrg
  scope: subscription()
}

//Create WVD SIG and W10 Image
module wvdsig 'wvd-sig-module.bicep' = {
  name: 'wvdsig'
  scope: sigresourcegroup
  params: {
    uamiName: uamiName
    sigName: sigName
    sigLocation: sigLocation
      }
}

