# Define valiables
. (Join-Path $PSScriptRoot config.ps1)

# Main
## Load modules
. (Join-Path $PSScriptRoot modules\logger.ps1)
. (Join-Path $PSScriptRoot modules\control_processes.ps1)

## Define $LogFile for logger
$CommandName = $(Get-Item $PSCommandPath).BaseName
$LogFile = GenerateLogFilePath -Logdir $LOG_DIR -Logext $LOG_EXTENSION -Command $CommandName

## Stopping SAP instances
StopSAPInstances -UsrSap $UsrSap -SAPInstances $SAPInstances

## Wait 5 seconds
Start-Sleep -s 5

## Stopping services
StopServices -ServiceList $ServiceList

## Shutdown
Stop-Computer -Force
