param baseName string = 'msi-test'

var identityName_var = '${baseName}-bootstrap'
var bootstrapRoleAssignmentId_var = guid('${resourceGroup().id}contributor')
var contributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

resource identityName 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName_var
  location: resourceGroup().location
}

resource bootstrapRoleAssignmentId 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: bootstrapRoleAssignmentId_var
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: reference(identityName.id, '2018-11-30').principalId
    principalType: 'ServicePrincipal'
  }
}