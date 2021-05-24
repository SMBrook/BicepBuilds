// Define Networkin parameters
param vnetName string
param vnetaddressPrefix string
param subnetPrefix string
param vnetLocation string = 'northeurope'
param subnetName string = 'WVD'

//Create Vnet and Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: vnetLocation
   properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}
