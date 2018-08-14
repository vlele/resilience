# Login to Azure Subscription
Connect-AzureRmAccount

# Start logging time
Write-Output "Cosmos DB Creation Process started at $(Get-Date -Format G)"

# Set the Azure resource group name and location
$resourceGroupName = "CosmosDBRG-112871"
$resourceGroupLocation = "East US"

# Database name
$DBName = "testdb-66471"

# Distribution locations
$locations = @(@{"locationName"="East US"; 
                 "failoverPriority"=0},
               @{"locationName"="West US"; 
                 "failoverPriority"=1})

# Create the resource group
Write-Output "Creating resource group $resourceGroupName at location $resourceGroupLocation"
New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -Force

# Consistency policy
$consistencyPolicy = @{"defaultConsistencyLevel"="BoundedStaleness";
                       "maxIntervalInSeconds"="360"; 
                       "maxStalenessPrefix"="100000"}

# DB properties without firewall configuration
# DB properties
$DBProperties = @{"databaseAccountOfferType"="Standard"; 
                   "locations"=$locations; 
                   "consistencyPolicy"=$consistencyPolicy;}

# Create the database
Write-Output "Creating Cosmos DB with name $DBName. This will take couple of minutes."
New-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
                    -ApiVersion "2015-04-08" `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -Name $DBName `
                    -PropertyObject $DBProperties `
                    -Force

# Add additional properties
#$updateDBProperties = @{"databaseAccountOfferType"="Standard";}

# Update the database with the properties
#Write-Output "Updating $DBName with $updateeDBProperties properties"
#Set-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
#    -ApiVersion "2015-04-08" `
#    -ResourceGroupName $resourceGroupName `
#    -Name $DBName `
#    -PropertyObject $updateDBProperties `
#    -Force

# Retrieve the primary and secondary account keys
Write-Output "Database Keys (Primary and Secondary)"
Invoke-AzureRmResourceAction -Action listKeys `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName `
    -Name $DBName `
    -Force
    
# Stop logging time
Write-Output "Cosmos DB Creation Process ended at $(Get-Date -Format G)"