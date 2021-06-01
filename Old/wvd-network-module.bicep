// Define Networking parameters
param vnetName string
param vnetaddressPrefix string
param subnetPrefix string
param vnetLocation string
param subnetName string
param dnsservers string
param sasubnetName string
param sasubnetPrefix string

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
    dhcpOptions: {
      dnsServers: [
        dnsservers
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: sasubnetName
        properties: {
          addressPrefix: sasubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
   }
}
output vnet1id string = vnet.id
output subnetId string = vnet.properties.subnets[1].id
