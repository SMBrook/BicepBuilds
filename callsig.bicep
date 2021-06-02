targetScope = 'subscription'

param sigrg string = 'Bicep-SIG-Collaboration'
param uamiName string  = '${'AIBUser'}${utcNow()}'

//Create SIG Resource Group
resource sigresourcegroup 'Microsoft.Resources/resourceGroups@2020-06-01'  = {
  name: sigrg
  location: 'northeurope'
}

//Create WVD SIG and W10 Image
module wvdsig 'wvd-sig-module.bicep' = {
  name: 'wvdsig'
  scope: sigresourcegroup
  params: {
    uamiName: uamiName
       }
}

module wvd 'wvd-image-builder-module.bicep' = {
  name: 'wvdimagebuilder${wvdsig.name}'
  scope: resourceGroup(sigrg)
  params: {
    siglocation: wvdsig.outputs.siginfo
    galleryImageId: wvdsig.outputs.galleryimageId
    userAssignedIdentities: '${wvdsig.outputs.uamioutput}'
      }
    
    }

