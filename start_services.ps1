# Define valiables
. "C:\work\config.ps1"

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
