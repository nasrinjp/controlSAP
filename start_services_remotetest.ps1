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
StartRemoteServices -ServiceList $RemoteServiceList -passfile $passfile -RemoteUser $RemoteUser
