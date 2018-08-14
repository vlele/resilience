$adminlogin = "ServerAdmin"
$password = 'ChangeYourAdminPassword1'
$failoverGroupRWEndpoint = "sql-sample-ais-flg.database.windows.net"
$failoverGroupREndpoint = "sql-sample-ais-flg.secondary.database.windows.net"
$databasename = "mySampleDatabase"
$randomNo = $(Get-Random -Minimum 1 -Maximum 100)
$custid = New-Guid

# Add second record into Customer table
Write-Output "Adding second Customer record into table"
$query5 = "INSERT INTO Customer([CustomerID],[Name],[AccountNumber],[LastModified]) VALUES('Id-$custid','Customer-$randomNo','Account-$randomNo',GETDATE());"
$query5Output = Invoke-Sqlcmd -query $query5 -ServerInstance $failoverGroupRWEndpoint -Database $databasename -Username $adminlogin -Password $password

# Get records from Customer table - Primary Region
Write-Output "Retrieve Customer records from table (Primary Region)"
$query6 = "SELECT * FROM Customer;"
$query6Output = Invoke-Sqlcmd -query $query6 -ServerInstance $failoverGroupRWEndpoint -Database $databasename -Username $adminlogin -Password $password  
Write-Output $query6Output

# Get records from Customer table - Secondary Region
Write-Output " "
Write-Output "Retrieve Customer records from table (Secondary Region)"
$query7 = "SELECT * FROM Customer;"
$query7Output = Invoke-Sqlcmd -query $query7 -ServerInstance $failoverGroupREndpoint -Database $databasename -Username $adminlogin -Password $password  
Write-Output $query7Output