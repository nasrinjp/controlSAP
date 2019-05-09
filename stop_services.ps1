# Define valiables
$LOG_DIR = "C:\work\logs\"
$LOG_EXTENSION = ".log"
$UsrSap = "C:\usr\sap"
$ServiceList = @("SQLWriter", "MSSQLFDLauncher", "SQLSERVERAGENT", "MSSQLSERVER")
$SAPInstances = [ordered]@{E67 = "DVEBMGS00", "ASCS01" }

# Main
## Load modules
. "C:\work\module\logger.ps1"
. "C:\work\module\control_processes.ps1"

## Define $LogFile for logger
$CommandName = $(Get-Item $PSCommandPath).BaseName
$LogFile = GenerateLogFilePath -Logdir $LOG_DIR -Logext $LOG_EXTENSION -Command $CommandName

## Stopping SAP instances
StopSAPInstances -UsrSap $UsrSap -SAPInstances $SAPInstances

## Wait 5 seconds
Start-Sleep -s 5

## Stopping services
StopServices -ServiceList $ServiceList
