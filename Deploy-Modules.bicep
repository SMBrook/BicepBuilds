targetScope = 'subscription'

//Define WVD deployment parameters
param resourceGroupPrefrix string = 'AZDemoSB-Bicep-WVD'
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
param rgidentity string = 'AzDemoSB-Identity-rg'


//Define Networking deployment parameters
param vnetName string = 'bicep-vnet'
param vnetaddressPrefix string ='10.50.0.0/23'
param subnetPrefix string = '10.50.1.0/24'
param vnetLocation string = 'northeurope'
param subnetName string = 'bicep-subnet'
param vNet1Name string = 'bicep-vnet'
param vNet2Name string = 'Identity-vnet'
param DestinationPeeringName string = 'Testpeer43'
param remoteVnetId string = vNet2Name
param remoteVnetName string = 'Identity-vnet'
param remoteVnetRg string = 'AzDemoSB-Identity-rg'
param identityVnetID string = resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', remoteVnetName)

//Define Azure Files deployment parameters
param storageaccountlocation string = 'northeurope'
param storageaccountName string = 'bicepsaazsmblabs'
param storageaccountkind string = 'FileStorage'
param storgeaccountglobalRedundancy string = 'Premium_LRS'
param fileshareFolderName string = 'profilecontainers'

//Create Resource Groups
resource rgwvd 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name : '${resourceGroupPrefrix}'
  location : 'northeurope'
}

// Identity Existing Sub
resource rgwvdIdentity 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: 'AzDemoSB-Identity-rg'
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

module wvdpeering './wvd-peering-module.bicep' = {
  name: 'wvdpeering1'
  scope: resourceGroup(rgwvd.name)
  params:{
    identityVnetID : identityVnetID
  }
}

module wvdpeeringid './wvd-peering-id-module.bicep' = {
  name: 'wvdpeeringid'
  scope: resourceGroup(rgwvdIdentity.name)
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



