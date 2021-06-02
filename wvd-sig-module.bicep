param roleNameGalleryImage string = '${'BicepAIB'}${utcNow()}'
param uamiName string = '${'AIBUser'}${utcNow()}'
param uamiId string = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', uamiName)
param roleName string = '${'AIBRoleForSIG'}${utcNow()}'
param sigName string
param sigLocation string

//Create Shared Image Gallery
resource wvdsig 'Microsoft.Compute/galleries@2020-09-30' = {
  name: sigName
  location: sigLocation
}

// Create User-Assigned Managed Identity

resource managedidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uamiName
  location: resourceGroup().location
}

//create role definition
resource gallerydef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleNameGalleryImage)
  properties: {
    roleName: '${roleName}${sigName}'
    description: 'Custom role for network read'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/read'
          'Microsoft.Compute/images/delete'
        ]
      }
    ]
    assignableScopes: [
      resourceGroup().id
    ]
  }
}

output uamioutput string = uamiId

// create role assignment
resource galleryassignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, gallerydef.id, managedidentity.id)
  properties: {
   roleDefinitionId: gallerydef.id
    principalId: managedidentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
