@description('<USER ASSIGNED IDENTITY NAME>')
param resourceName string

resource resourceName_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: resourceName
  location: resourceGroup().location
}

output identityName string = resourceName