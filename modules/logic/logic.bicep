param location string
param prefix string
param logAnalyticsWorkspaceId string

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${prefix}-vm-monitor'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                vmName: {
                  type: 'string'
                }
                status: {
                  type: 'string'
                }
                timestamp: {
                  type: 'string'
                }
              }
            }
          }
        }
      }
      actions: {
        Send_Data: {
          type: 'ApiConnection'
          inputs: {
            body: {
              VMName: '@{triggerBody().vmName}'
              Status: '@{triggerBody().status}'
              TimeGenerated: '@{triggerBody().timestamp}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureloganalyticsdatacollector\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/api/logs'
          }
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          azureloganalyticsdatacollector: {
            connectionId: resourceId('Microsoft.Web/connections', '${prefix}-la-connection')
            connectionName: '${prefix}-la-connection'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureloganalyticsdatacollector')
          }
        }
      }
    }
  }
}

resource logAnalyticsConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: '${prefix}-la-connection'
  location: location
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureloganalyticsdatacollector')
    }
    parameterValues: {
      workspaceId: reference(logAnalyticsWorkspaceId, '2020-08-01').customerId
      workspaceKey: listKeys(logAnalyticsWorkspaceId, '2020-08-01').primarySharedKey
    }
    displayName: 'Log Analytics Data Collector'
  }
}

output logicAppName string = logicApp.name 


