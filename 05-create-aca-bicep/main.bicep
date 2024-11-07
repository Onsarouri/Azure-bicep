@description('Specifies the name of the container app environment')
param containerAppEnvName string = 'env-${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the log analytics workspace')
param logAnalyticsName string = 'log-${uniqueString(resourceGroup().id)}'

@description('Specifies the location of all resources')
param location string = resourceGroup().location

@description('Specifies the docker container image to deploy')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Specifies the container Port')
param targetPort int = 80

@description('Number of CPU cores the container can use, with a max of two decimals')
@allowed([
  '0.5'
  '1'
  '2'
])
param cpuCores string = '0.5'

@description('Amount of memory in GB allocated to the container, up to 4GB, with max of two decimals')
@allowed([
  '0.5'
  '1'
  '1.5'
  '2'
  '2.5'
  '3'
  '3.5'
  '4'
])
param memorySize string = '1'

@description('Min number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplicas int = 1

@description('Max number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplicas int = 3

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: containerAppEnvName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarysharedKey
      }
    }
  }
}

@description('Specifies the name of the container app')
param containerAppName string = 'mycontainerapp'

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      revisionSuffix: 'firstRevision'
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: json(cpuCores)
            memory: '${memorySize}GB'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn
