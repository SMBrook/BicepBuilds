targetScope = 'subscription'

//Define WVD deployment parameters
param resourceGroupPrefrix string = 'NINJA-WE-P-RG-WVD-BICEP-WVD-'
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
param logAnalyticsWorkspaceName string = 'myNinjaBicepLAWorkspace'

//Define Networking deployment parameters
param vnetName string = 'bicep-vnet'
param vnetaddressPrefix string = '10.0.0.0/15'
param subnetPrefix string = '10.0.1.0/24'
param vnetLocation string = 'westeurope'
param subnetName string = 'bicep-subnet'

//Define Azure Files deployment parameters
param storageaccountlocation string = 'westeurope'
param storageaccountName string = 'bicepsa'
param storageaccountkind string = 'FileStorage'
param storgeaccountglobalRedundancy string = 'Premium_LRS'
param fileshareFolderName string = 'profilecontainers'

//Set Peering Hub RG and VNet target parameters
param hubrg string = 'ExistingHubName' //Enter the name of the existing Hub/Identity vNet Resource Group 
param hubvnet string = 'ExistingHubvNetName' //Enter the name of the existing Hub vNet name

//Get Existing Hub Resource Group Details
resource hubresourcegroup 'Microsoft.Resources/resourceGroups@2020-06-01' existing = {
  name: hubrg
  scope: subscription()
}

//Get Existing Hub VNet Details
resource hubsourcevnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: hubvnet
  scope: hubresourcegroup
}

//Create Resource Groups
resource rgwvd 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${resourceGroupPrefrix}BACKPLANE'
  location: 'westeurope'
}
resource rgnetw 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${resourceGroupPrefrix}NETWORK'
  location: 'westeurope'
}
resource rgfs 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${resourceGroupPrefrix}FILESERVICES'
  location: 'westeurope'
}
resource rdmon 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${resourceGroupPrefrix}MONITOR'
  location: 'westeurope'
}

//Create WVD backplane objects and configure Log Analytics Diagnostics Settings
module wvdbackplane './wvd-backplane-module.bicep' = {
  name: 'wvdbackplane'
  scope: rgwvd
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
    logAnalyticsResourceGroup: rdmon.name
    wvdBackplaneResourceGroup: rgwvd.name
  }
}

//Create WVD Netwerk and Subnet
module wvdnetwork './wvd-network-module.bicep' = {
  name: 'wvdnetwork'
  scope: rgnetw
  params: {
    vnetName: vnetName
    vnetaddressPrefix: vnetaddressPrefix
    subnetPrefix: subnetPrefix
    vnetLocation: vnetLocation
    subnetName: subnetName
  }
}

//Create WVD Azure File Services and FileShare`
module wvdFileServices './wvd-fileservices-module.bicep' = {
  name: 'wvdFileServices'
  scope: rgfs
  params: {
    storageaccountlocation: storageaccountlocation
    storageaccountName: storageaccountName
    storageaccountkind: storageaccountkind
    storgeaccountglobalRedundancy: storgeaccountglobalRedundancy
    fileshareFolderName: fileshareFolderName
  }
}

//Create Private Endpoint for file storage
module pep './wvd-fileservices-privateendpoint-module.bicep' = {
  name: 'privateEndpoint'
  scope: rgnetw
  params: {
    location: vnetLocation
    privateEndpointName: 'pep-sto'
    storageAccountId: wvdFileServices.outputs.storageAccountId
    vnetId: wvdnetwork.outputs.vnetId
    subnetId: wvdnetwork.outputs.subnetId
  }
}

//Create Peering from WVD vNet to Hub vNet
module wvdpeering './wvd-peering-from-vnet-to-hub-module.bicep' = {
  name: '${wvdnetwork.name}peerto${hubsourcevnet.name}'
  scope: rgnetw
  params:{
    peeringnamefromwvdvnet : '${vnetName}/${vnetName}-to-${hubsourcevnet.name}'
    hubvnetid : hubsourcevnet.id
  }
}

//Create Peering from Hub vNet to WVD vNet
module hubpeering './wvd-peering-from-hub-to-vnet-module.bicep' = {
  name: '${hubsourcevnet.name}peerto${wvdnetwork.name}'
  scope: hubresourcegroup
  params:{
    peeringnamefromhubvnet : '${hubsourcevnet.name}/${hubsourcevnet.name}-to-${vnetName}'
    wvdvnetid : wvdnetwork.outputs.vnetId
  }
}