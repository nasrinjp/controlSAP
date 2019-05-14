# Common config
$LOG_DIR = "C:\work\logs\"
$LOG_EXTENSION = ".log"
$UsrSap = "C:\usr\sap"

# Local instance config
$ServiceList = @("MSSQLSERVER", "SQLSERVERAGENT", "SQLWriter", "MSSQLFDLauncher", "SQLTELEMETRY", "SAPHostControl", "SAPSID_00", "SAPDAA_98")
$SAPInstances = [ordered]@{SID = "DVEBMGS00"; DAA = "SMDA98" }

# Remote instance config
#$RemoteServiceList = [ordered]@{"servername" = "servicename" }
#$RemoteUser = "servername\Administrator"
#$passfile = "C:\Users\Administrator\securepass.txt"

# Creating passfile
#$Credential = Get-Credential
#$Credential.Password | ConvertFrom-SecureString | Set-Content C:\Users\Administrator\securepass.txt
