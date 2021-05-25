targetScope = 'subscription'

//Define WVD deployment parameters
param resourceGroupPrefrix string = 'AZDemosSB-Bicep-WVD2'
param hostpoolName string = 'myBicepHostpool'
param hostpoolFriendlyName string = 'My Bicep deployed Hostpool'
param appgroupName string = 'myBicepAppGroup'
param appgroupNameFriendlyName string = 'My Bicep deployed Appgroup'
param workspaceName string = 'myBicepWorkspace'
param workspaceNameFriendlyName string = 'My Bicep deployed Workspace'
param preferredAppGroupType string = 'Desktop'
param wvdbackplanelocation string = 'eastus'
param hostPoolType string = 'pooled'
param loadBalancerType string = 'BreadthFirst'
param logAnalyticsWorkspaceName string = 'AZDemosSBLAWorkspace'

//Define Networking deployment parameters
param vnetName string = 'bicep-vnet'
param vnetaddressPrefix string ='10.50.0.0/23'
param subnetPrefix string = '10.50.1.0/24'
param vnetLocation string = 'northeurope'
param subnetName string = 'bicep-subnet'
param vNet1Name string = 'bicep-vnet'
param vNet2Name string = 'Identity-vnet'
param SourcePeeringName string = 'BiceptoIdentity'
param DestinationPeeringName string = 'IdentitytoBicep'
param allowVirtualNetworkAccess string = 'true'
param allowForwardedTraffic string = 'false'
param allowGatewayTransit string = 'false'
param useRemoteGateways string = 'false'
param remoteVnetId string = vNet2Name
param wvdVnetIdsource string = resourceId('Microsoft.Network/virtualNetworks',vNet2Name)
param wvdVnetId string = resourceId('Microsoft.Network/virtualNetworks',vNet1Name)

//Define Azure Files deployment parameters
param storageaccountlocation string = 'northeurope'
param storageaccountName string = 'bicepsaazsmblabs153'
param storageaccountkind string = 'FileStorage'
param storgeaccountglobalRedundancy string = 'Premium_LRS'
param fileshareFolderName string = 'profilecontainers'

//Create Resource Groups
resource rgwvd 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name : '${resourceGroupPrefrix}'
  location : 'northeurope'
}

//Create WVD backplane objects and configure Log Analytics Diagnostics Settings
module wvdbackplane 'wvd-backplane-module.bicep' = {
  name: 'wvdbackplane'
  scope: resourceGroup(rgwvd.name)
  params: {
    hostpoolName: hostpoolName
    hostpoolFriendlyName: hostpoolFriendlyName
    appgroupName: appgroupName
    appgroupNameFriendlyName: appgroupNameFriendlyName
    workspaceName: workspaceName
    workspaceNameFriendlyName: workspaceNameFriendlyName
    preferredAppGroupType: preferredAppGroupType
    applicationgrouptype: preferredAppGroupType
    wvdbackplanelocation: wvdbackplanelocation
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsResourceGroup : rgwvd.name
    wvdBackplaneResourceGroup : rgwvd.name
  }
}

//Create WVD Network and Subnet
module wvdnetwork './wvd-network-module.bicep' = {
  name: 'wvdnetwork'
  scope: resourceGroup(rgwvd.name)
  params: {
    vnetName : vnetName
    vnetaddressPrefix : vnetaddressPrefix
    subnetPrefix : subnetPrefix
    vnetLocation : vnetLocation
    subnetName : subnetName
  }
}

//Create Peering to Identity Subnet
module wvdpeering1 './wvd-peering-source.bicep' = {
  name: SourcePeeringName
  scope: resourceGroup(rgwvd.name)
  params: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  remoteVirtualNetwork: {
      id: wvdVnetIdsource
    }
  }
}

// Create Peering from Identity Subnet
module wvdpeering2 './wvd-peering-destination.bicep' = {
  name: DestinationPeeringName
  scope: resourceGroup(rgwvd.name)
  params: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  remoteVirtualNetwork: {
      id: wvdVnetIdsource
    }
  }
}




//Create WVD Azure File Services and FileShare`
module wvdFileServices './wvd-fileservices-module.bicep' = {
  name: 'wvdFileServices'
  scope: resourceGroup(rgwvd.name)
  params: {
    storageaccountlocation : storageaccountlocation
    storageaccountName : storageaccountName
    storageaccountkind : storageaccountkind
    storgeaccountglobalRedundancy : storgeaccountglobalRedundancy
    fileshareFolderName : fileshareFolderName
  }
}



