# Define valiables
. "D:\UTY\config.ps1"

# Main
## Load modules
. "D:\UTY\modules\logger.ps1"
. "D:\UTY\modules\control_processes.ps1"

## Define $LogFile for logger
$CommandName = $(Get-Item $PSCommandPath).BaseName
$LogFile = GenerateLogFilePath -Logdir $LOG_DIR -Logext $LOG_EXTENSION -Command $CommandName

## Starting services
StopRemoteServices -ServiceList $RemoteServiceList -passfile $passfile -RemoteUser $RemoteUser
