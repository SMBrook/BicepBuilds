@allowed([
  'true'
  'false'
])
@description('Configure vNet peering between WVD vNet and Hub/Identity vNet - True/False')
param configurepeering bool
@description('Enter no values if not configuring Peering')
param hubvnet string
@description('Enter no values if not configuring Peering')
param hubrg string

//Get Existing Hub Resource Group Details
resource rghub 'Microsoft.Resources/resourceGroups@2020-06-01' existing = if (configurepeering == 'true') {
  name: hubrg
  scope: subscription()
}

//Get Existing Hub VNet Details
resource identityvnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = if (configurepeering == 'true') {
  name: hubvnet
  scope: rghub
}

