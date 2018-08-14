# Login-AzureRmAccount
Connect-AzureRmAccount

# Start logging time
Write-Output "Process started at $(Get-Date -Format G)"

# Set the resource group name and locations
$primaryresourcegroupname = "myResourceGroup-$(Get-Random)"
$primarylocation = "eastus"
$secondarylocation = "westus"

# Set an admin login and password for your servers
$adminlogin = "ServerAdmin"
$password = 'ChangeYourAdminPassword1'

# Set server names - the logical server names have to be unique in the system
$primaryservername = "primary-server-$(Get-Random)"
$secondaryservername = "secondary-server-$(Get-Random)"

# The sample database name
$databasename = "mySampleDatabase"

# The Failover Group name
$failovergroupname = "sql-sample-ais-flg"

# Client IP Address - Retrieving the public ip address of client from http://ipecho.net/
$startIpAddress = (Invoke-WebRequest -uri "http://ipecho.net/plain").Content
$endIpAddress = (Invoke-WebRequest -uri "http://ipecho.net/plain").Content

# Create two new resource groups
Write-Output "Creating resource group $primaryresourcegroupname"
$primaryresourcegroup = New-AzureRmResourceGroup -Name $primaryresourcegroupname -Location $primarylocation

# Create two new logical servers with a system wide unique server name
Write-Output "Creating primary server $primaryservername"
$primaryserver = New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -Location $primarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

Write-Output "Creating secondary server $secondaryservername"
$secondaryserver = New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroupname `
    -ServerName $secondaryservername `
    -Location $secondarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a blank database with S0 performance level on the primary server
Write-Output "Creating database $databasename"
$database = New-AzureRmSqlDatabase  -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"

# Create Fail Over Group
Write-Output "Creating Failover Group $failovergroupname"
$failoverGroup = New-AzureRMSqlDatabaseFailoverGroup -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername -PartnerServerName $secondaryservername -FailoverGroupName $failovergroupname -FailoverPolicy Automatic -GracePeriodWithDataLossHours 1
$failoverGroupRWEndpoint = $failovergroupname + ".database.windows.net"
$failoverGroupREndpoint = $failovergroupname + ".secondary.database.windows.net";
Write-Output "Failover Read/Write Endpoint: $failoverGroupRWEndpoint"
Write-Output "Failover Readonly Endpoint: $failoverGroupREndpoint"

# Add Database to Fail Over Group
Write-Output "Adding database $databasename to Failover Group $failovergroupname"
$dbInfailoverGroup = Get-AzureRmSqlDatabase -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername -DatabaseName $databasename | Add-AzureRmSqlDatabaseToFailoverGroup -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername -FailoverGroupName $failovergroupname

# Add client system IP address to SQL Servers Firewall Rules
Write-Output "Creating Azure SQL Firewall Rule to allow connections"
New-AzureRmSqlServerFirewallRule -ResourceGroupName $primaryresourcegroupname -ServerName $failoverGroup.ServerName -FirewallRuleName "Rule01" -StartIpAddress $startIpAddress -EndIpAddress $endIpAddress
New-AzureRmSqlServerFirewallRule -ResourceGroupName $primaryresourcegroupname -ServerName $failoverGroup.PartnerServerName -FirewallRuleName "Rule01" -StartIpAddress $startIpAddress -EndIpAddress $endIpAddress

# Create a table in SQL 
Write-Output "Adding Customer table in datbase"
$query1 = "CREATE TABLE Customer(CustomerID varchar(255), Name varchar(255),AccountNumber varchar(10), LastModified datetime);"
$query1Output = Invoke-Sqlcmd -query $query1 -ServerInstance $failoverGroupRWEndpoint -Database $databasename -Username $adminlogin -Password $password  

# Add first record into Customer table
$randomNo = $(Get-Random -Minimum 1 -Maximum 100)
$custid = New-Guid
Write-Output "Adding Customer record into table"
$query2 = "INSERT INTO Customer([CustomerID],[Name],[AccountNumber],[LastModified]) VALUES('Id-$custid','Customer-$randomNo','Account-$randomNo',GETDATE());"
$query2Output = Invoke-Sqlcmd -query $query2 -ServerInstance $failoverGroupRWEndpoint -Database $databasename -Username $adminlogin -Password $password  

# Get records from Customer table - Primary Region
Write-Output "Retrieve Customer records from table (Primary Region)"
$query3 = "SELECT * FROM Customer;"
$query3Output = Invoke-Sqlcmd -query $query3 -ServerInstance $failoverGroupRWEndpoint -Database $databasename -Username $adminlogin -Password $password  
Write-Output $query3Output

# Get records from Customer table - Secondary Region
Write-Output "Retrieve Customer records from table (Secondary Region)"
$query4 = "SELECT * FROM Customer;"
$query4Output = Invoke-Sqlcmd -query $query4 -ServerInstance $failoverGroupREndpoint -Database $databasename -Username $adminlogin -Password $password  
Write-Output $query4Output

# Failover to Secondary Region
Write-Output "Failing over to Secondary Region... It will take couple of mintue to complete the operation."
$failoverGroupModelAfterFailover = Get-AzureRmSqlDatabaseFailoverGroup -ResourceGroupName $primaryresourcegroupname -ServerName $secondaryservername -FailoverGroupName $failovergroupname | Switch-AzureRmSqlDatabaseFailoverGroup -AllowDataLoss
#Write-Output "Failover successful !!!"

# Stop logging time
Write-Output "Process ended at $(Get-Date -Format G)"

# Clean up deployment 
#Remove-AzureRmResourceGroup -ResourceGroupName $primaryresourcegroupname
