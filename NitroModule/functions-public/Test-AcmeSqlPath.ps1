Function Test-AcmeSqlPath
{
<#
.SYNOPSIS
Tests if file or directory exists from the perspective of the SQL Server service account

.DESCRIPTION
Uses master.dbo.xp_fileexist to determine if a file or directory exists

.PARAMETER SqlServer
The SQL Server you want to run the test on.

.PARAMETER Path
The Path to tests. Can be a file or directory.

.PARAMETER SqlCredential
Allows you to login to servers using SQL Logins as opposed to Windows Auth/Integrated/Trusted. To use:

$scred = Get-Credential, then pass $scred object to the -SqlCredential parameter.

Windows Authentication will be used if SqlCredential is not specified. SQL Server does not accept Windows
credentials being passed as credentials. To connect as a different Windows user, run PowerShell as that user.

.LINK
https://dbatools.io/Test-AcmeSqlPath

.EXAMPLE
Test-AcmeSqlPath -SqlServer sqlcluster -Path L:\MSAS12.MSSQLSERVER\OLAP

Tests whether the service account running the "sqlcluster" SQL Server isntance can access L:\MSAS12.MSSQLSERVER\OLAP. Logs into sqlcluster using Windows credentials. 

.EXAMPLE
$credential = Get-Credential
Test-AcmeSqlPath -SqlServer sqlcluster -SqlCredential $credential -Path L:\MSAS12.MSSQLSERVER\OLAP

Tests whether the service account running the "sqlcluster" SQL Server isntance can access L:\MSAS12.MSSQLSERVER\OLAP. Logs into sqlcluster using SQL authentication. 
#>
	[CmdletBinding()]
    [OutputType([bool])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("ServerInstance", "SqlInstance")]
		[object]$SqlServer,
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[System.Management.Automation.PSCredential]$SqlCredential
	)

	# Notice this uses Connect-SqlServer which is available as an internal command. 
	
	$server = Connect-SqlServer -SqlServer $SqlServer -SqlCredential $SqlCredential
	$sql = "EXEC master.dbo.xp_fileexist '$path'"
	$fileexist = $server.ConnectionContext.ExecuteWithResults($sql)

	if ($fileexist.tables.rows[0] -eq $true -or $fileexist.tables.rows[1] -eq $true)
	{
		return $true
	}
	else
	{
		return $false
	}
}
