#Function that logs a message to a text file
function LogMessage {
    param([string]$Message, [string]$LogFile)
    ((Get-Date -Format "yyyy/MM/dd HH:mm:ss.fff").ToString() + " - " + $Message) >> $LogFile;
}

#Function that deletes log file if it exists
function DeleteLogFile {
    param([string]$LogFile)
    #Delete log file if it exists
    if (Test-Path $LogFile) {
        Remove-Item $LogFile
    }
}

function WriteLog {
    param([ValidateSet("Info", "Error")]$Level, [string]$Message) 
    LogMessage -Message "[${Level}] ${Message}" -LogFile $LogFile
}

function WriteArrayLogs {
    param([array]$LogMessages)
    foreach ($text in $LogMessages) {
        if ($text -ne "") {
            WriteLog -Level Info -Message $text
        }
    }
}

function GenerateLogFilePath {
    param([string]$Logdir, [string]$Logext, [string]$Command)
    $yyyymm = Get-Date -DisplayHint DateTime -Format "yyyyMM"
    $LogFile = $Logdir + $Command + "_" + $yyyymm + $Logext
    return $LogFile
}