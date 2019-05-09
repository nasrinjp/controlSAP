# Define valiables
$LOG_DIR = "C:\work\logs\"
$LOG_EXTENSION = ".log"
$UsrSap = "C:\usr\sap"
$ServiceList = @("MSSQLSERVER", "SQLSERVERAGENT", "MSSQLFDLauncher", "SQLWriter")
$SAPInstances = [ordered]@{SID = "ASCS01", "DVEBMGS00" }

# Main
## Load modules
. "C:\work\modules\logger.ps1"
. "C:\work\modules\control_processes.ps1"

## Define $LogFile for logger
$CommandName = $(Get-Item $PSCommandPath).BaseName
$LogFile = GenerateLogFilePath -Logdir $LOG_DIR -Logext $LOG_EXTENSION -Command $CommandName

## Starting services
StartServices -ServiceList $ServiceList

## Wait 5 seconds
Start-Sleep -s 5

## Starting SAP instances
StartSAPInstances -UsrSap $UsrSap -SAPInstances $SAPInstances
