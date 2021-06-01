targetScope = 'subscription'


param sigrg string = 'Bicep-SIG-Collaboration'


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
       }
}

