# Login to Azure Subscription
Connect-AzureRmAccount

Write-Output "Failover Operation started at $(Get-Date -Format G)"

# Update following variables with the data required for Failover process
$resourceGroupName = "CosmosDBRG-112871"
$DBName = "testdb-66471"

# Update failoverpolicy to make West US as a write region
$NewfailoverPolicies = @(@{"locationName"="West US"; "failoverPriority"=0}, @{"locationName"="East US"; "failoverPriority"=1} )

Write-Output "Failing over to secondary region Cosmos Database"
Invoke-AzureRmResourceAction `
    -Action failoverPriorityChange `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName `
    -Name $DBName `
    -Parameters @{"failoverPolicies"=$NewfailoverPolicies} `
    -Force

# Add a new locations with priorities
$newLocations = @(@{"locationName"="West US"; 
                 "failoverPriority"=0},
               @{"locationName"="East US"; 
                 "failoverPriority"=1})

# Consistency policy
$consistencyPolicy = @{"defaultConsistencyLevel"="BoundedStaleness";
                       "maxIntervalInSeconds"="360"; 
                       "maxStalenessPrefix"="100000"}

# Updated properties
$updateDBProperties = @{"databaseAccountOfferType"="Standard";
                        "locations"=$newLocations;
                        "consistencyPolicy"=$consistencyPolicy;}

Write-Output "Updating Cosmos Database properties after Failover Operation"
# Update the database with the properties
Set-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName `
    -Name $DBName `
    -PropertyObject $UpdateDBProperties `
    -Force

# Retrieve the primary and secondary account keys
Write-Output "Database Keys after Failover operation"
Invoke-AzureRmResourceAction -Action listKeys `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName `
    -Name $DBName `
    -Force

# Stop logging time
Write-Output "Failover Operation ended at $(Get-Date -Format G)"