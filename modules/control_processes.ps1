function GenerateScriptBlock {
    param([string]$UsrSap, [string]$SID, [string]$Instance, [string]$Action)
    $SapcontrolPath = "${UsrSap}\${SID}\${InstanceName}\exe\sapcontrol.exe"
    $InstanceNo = $InstanceName.Substring($InstanceName.Length - 2, 2)
    $Scriptblock = "$SapcontrolPath -prot PIPE -nr $InstanceNo -function $Action"
    return $Scriptblock
}

function ExecuteSapcontrol {
    param([string]$scriptsource)
    try {
        $Script = [Scriptblock]::Create($scriptsource)
        $Return = Invoke-Command -ScriptBlock { & $args[0] } -ArgumentList $script -ErrorAction Stop
        $rc = $LASTEXITCODE
        WriteArrayLogs -LogMessages $Return
        return $rc
    }
    catch {
        WriteLog -Level Error -Message "Error detail: ${_}"
        exit 1
    }
}

function StartServices {
    param([array]$ServiceList)
    foreach ($ServiceName in $ServiceList) {
        if ((Get-Service -Name $ServiceName).Status -eq "Stopped") {
            try {
                WriteLog -Level Info -Message "Starting ${ServiceName}."
                Start-Service $ServiceName -ErrorAction Stop
                WriteLog -Level Info -Message "Starting ${ServiceName} service finished successfully."
            }
            catch {
                WriteLog -Level Error -Message "Error detail: ${_}"
                exit 1
            }
        }
        else {
            WriteLog -Level Info -Message "${ServiceName} already started."
        }
    }
}

function StopServices {
    param([array]$ServiceList)
    foreach ($ServiceName in $ServiceList) {
        if ((Get-Service -Name $ServiceName).Status -eq "Running") {
            try {
                WriteLog -Level Info -Message "Stopping ${ServiceName}."
                Stop-Service $ServiceName -ErrorAction Stop
                WriteLog -Level Info -Message "Stopping ${ServiceName} service finished successfully."
            }
            catch {
                WriteLog -Level Error -Message "Error detail: ${_}"
                exit 1
            }
        }
        else {
            WriteLog -Level Info -Message "${ServiceName} already stopped."
        }
    }
}

function StartSAPInstances {
    param([string]$UsrSap, [hashtable]$SAPInstances)
    foreach ($SID in $SAPInstances.Keys) {
        foreach ($InstanceName in $SAPInstances[$SID]) {
            $Action = "StartWait 600 10"
            $Scriptblock = GenerateScriptBlock -UsrSap $UsrSap -SID $SID -Instance $InstanceName -Action $Action
            WriteLog -Level Info -Message "Starting SAP instances (${SID}/${InstanceName})..."
            $rc = ExecuteSapcontrol -script $Scriptblock
            if ($rc -ne 0) {
                WriteLog -Level Error -Message "Starting SAP (${SID}/${InstanceName}) processes failed."
                exit 1
            }
            $Action = "GetProcessList"
            $Scriptblock = GenerateScriptBlock -UsrSap $UsrSap -SID $SID -Instance $InstanceName -Action $Action
            WriteLog -Level Info -Message "Checking SAP instances (${SID}/${InstanceName})..."
            $rc = ExecuteSapcontrol -script $Scriptblock
            if ($rc -ne 3) {
                WriteLog -Level Error -Message "SAP (${SID}/${InstanceName}) processes not started."
                exit 1
            }
            WriteLog -Level Info -Message "Starting SAP instances (${SID}/${InstanceName}) finished successfully."
        }
    }
}

function StopSAPInstances {
    param([string]$UsrSap, [hashtable]$SAPInstances)
    foreach ($SID in $SAPInstances.Keys) {
        foreach ($InstanceName in $SAPInstances[$SID]) {
            $Action = "StopWait 600 10"
            $Scriptblock = GenerateScriptBlock -UsrSap $UsrSap -SID $SID -Instance $InstanceName -Action $Action
            WriteLog -Level Info -Message "Stopping SAP instances (${SID}/${InstanceName})..."
            $rc = ExecuteSapcontrol -script $Scriptblock
            if ($rc -ne 0) {
                WriteLog -Level Error -Message "Stopping SAP (${SID}/${InstanceName}) processes failed."
                exit 1
            }
            $Action = "GetProcessList"
            $Scriptblock = GenerateScriptBlock -UsrSap $UsrSap -SID $SID -Instance $InstanceName -Action $Action
            WriteLog -Level Info -Message "Checking SAP instances (${SID}/${InstanceName})..."
            $rc = ExecuteSapcontrol -script $Scriptblock
            if ($rc -ne 4) {
                WriteLog -Level Error -Message "SAP (${SID}/${InstanceName}) processes not stopped."
                exit 1
            }
            WriteLog -Level Info -Message "Stopping SAP instances (${SID}/${InstanceName}) finished successfully."
        }
    }
}
