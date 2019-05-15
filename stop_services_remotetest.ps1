# Define valiables
. (Join-Path $PSScriptRoot config.ps1)

# Main
## Load modules
. (Join-Path $PSScriptRoot modules\logger.ps1)
. (Join-Path $PSScriptRoot modules\control_processes.ps1)

## Define $LogFile for logger
$CommandName = $(Get-Item $PSCommandPath).BaseName
$LogFile = GenerateLogFilePath -Logdir $LOG_DIR -Logext $LOG_EXTENSION -Command $CommandName

## Starting services
StopRemoteServices -ServiceList $RemoteServiceList -passfile $passfile -RemoteUser $RemoteUser
