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
    [array]::Reverse($ServiceList)
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

function StartRemoteServices {
    param([System.Collections.Specialized.OrderedDictionary]$ServiceList, [string]$passfile, [string]$RemoteUser)
    $SecurePassword = Get-Content $passfile | ConvertTo-SecureString
    $Credential = New-Object System.Management.Automation.PSCredential $RemoteUser, $SecurePassword
    foreach ($Target in $ServiceList.Keys) {
        foreach ($ServiceName in $ServiceList[$Target]) {
            if ((Invoke-Command -ComputerName $Target -Credential $Credential -ScriptBlock { Get-Service $args[0] } -ArgumentList $ServiceName).Status -eq "Stopped") {
                try {
                    WriteLog -Level Info -Message "Starting ${ServiceName} at ${Target}."
                    Invoke-Command -ComputerName $Target -Credential $Credential -ScriptBlock { Start-Service $args[0] } -ArgumentList $ServiceName -ErrorAction Stop 
                    WriteLog -Level Info -Message "Starting ${ServiceName} service at ${Target} finished successfully."
                }
                catch {
                    WriteLog -Level Error -Message "Error detail: ${_}"
                    exit 1
                }
            }
            else {
                WriteLog -Level Info -Message "${ServiceName} at ${Target} already started."
            }
        }
    }
}

function StopRemoteServices {
    param([System.Collections.Specialized.OrderedDictionary]$ServiceList, [string]$passfile, [string]$RemoteUser)
    $SecurePassword = Get-Content $passfile | ConvertTo-SecureString
    $Credential = New-Object System.Management.Automation.PSCredential $RemoteUser, $SecurePassword
    $TargetList = @()
    foreach ($Target in $ServiceList.Keys) {
        $TargetList += $Target
    }
    [array]::Reverse($TargetList)
    foreach ($Target in $TargetList) {
        $ServiceNameList = @()
        foreach ($ServiceName in $ServiceList[$Target]) {
            $ServiceNameList += $ServiceName
        }
        [array]::Reverse($ServiceNameList)
        $ServiceList[$Target] = $ServiceNameList
    }
    foreach ($Target in $TargetList) {
        foreach ($ServiceName in $ServiceList[$Target]) {
            if ((Invoke-Command -ComputerName $Target -Credential $Credential -ScriptBlock { Get-Service $args[0] } -ArgumentList $ServiceName).Status -eq "Running") {
                try {
                    WriteLog -Level Info -Message "Stopping ${ServiceName} at ${Target}."
                    Invoke-Command -ComputerName $Target -Credential $Credential -ScriptBlock { Stop-Service $args[0] } -ArgumentList $ServiceName -ErrorAction Stop 
                    WriteLog -Level Info -Message "Stopping ${ServiceName} service at ${Target} finished successfully."
                }
                catch {
                    WriteLog -Level Error -Message "Error detail: ${_}"
                    exit 1
                }
            }
            else {
                WriteLog -Level Info -Message "${ServiceName} at ${Target} already stopped."
            }
        }
    }
}

function CheckSAPProcessList {
    # $rc=3 : GetProcessList succeeded, all processes running correctly
    # $rc=4 : GetProcessList succeeded, all processes stopped
    param([string]$UsrSap, [string]$SID, [string]$InstanceName)
    $Action = "GetProcessList"
    $Scriptblock = GenerateScriptBlock -UsrSap $UsrSap -SID $SID -Instance $InstanceName -Action $Action
    WriteLog -Level Info -Message "Checking SAP instances (${SID}/${InstanceName})..."
    $rc = ExecuteSapcontrol -script $Scriptblock
    return $rc
}

function StartSAPInstances {
    param([string]$UsrSap, [System.Collections.Specialized.OrderedDictionary]$SAPInstances)
    foreach ($SID in $SAPInstances.Keys) {
        foreach ($InstanceName in $SAPInstances[$SID]) {
            $rc = CheckSAPProcessList -UsrSap $UsrSap -SID $SID -InstanceName $InstanceName
            if ($rc -ne 3) {
                $Action = "StartWait 600 10"
                $Scriptblock = GenerateScriptBlock -UsrSap $UsrSap -SID $SID -Instance $InstanceName -Action $Action
                WriteLog -Level Info -Message "Starting SAP instance (${SID}/${InstanceName})..."
                $rc = ExecuteSapcontrol -script $Scriptblock
                if ($rc -ne 0) {
                    WriteLog -Level Error -Message "Starting SAP (${SID}/${InstanceName}) processes failed."
                    exit 1
                }
                $rc = CheckSAPProcessList -UsrSap $UsrSap -SID $SID -InstanceName $InstanceName
                if ($rc -ne 3) {
                    WriteLog -Level Error -Message "SAP (${SID}/${InstanceName}) processes not started."
                    exit 1
                }
                WriteLog -Level Info -Message "Starting SAP instance (${SID}/${InstanceName}) finished successfully."
            }
            else {
                WriteLog -Level Info -Message "SAP instance (${SID}/${InstanceName}) is already running."
            }
        }
    }
}

function StopSAPInstances {
    param([string]$UsrSap, [System.Collections.Specialized.OrderedDictionary]$SAPInstances)
    $SIDList = @()
    foreach ($SID in $SAPInstances.Keys) {
        $SIDList += $SID
    }
    [array]::Reverse($SIDList)

    foreach ($SID in $SIDList) {
        $InstanceNameList = @()
        foreach ($InstanceName in $SAPInstances[$SID]) {
            $InstanceNameList += $InstanceName
        }
        [array]::Reverse($InstanceNameList)
        $SAPInstances[$SID] = $InstanceNameList
    }

    foreach ($SID in $SIDList) {
        foreach ($InstanceName in $SAPInstances[$SID]) {
            $rc = CheckSAPProcessList -UsrSap $UsrSap -SID $SID -InstanceName $InstanceName
            if ($rc -ne 4) {
                $Action = "StopWait 600 10"
                $Scriptblock = GenerateScriptBlock -UsrSap $UsrSap -SID $SID -Instance $InstanceName -Action $Action
                WriteLog -Level Info -Message "Stopping SAP instance (${SID}/${InstanceName})..."
                $rc = ExecuteSapcontrol -script $Scriptblock
                if ($rc -ne 0) {
                    WriteLog -Level Error -Message "Stopping SAP (${SID}/${InstanceName}) processes failed."
                    exit 1
                }
                $rc = CheckSAPProcessList -UsrSap $UsrSap -SID $SID -InstanceName $InstanceName
                if ($rc -ne 4) {
                    WriteLog -Level Error -Message "SAP (${SID}/${InstanceName}) processes not stopped."
                    exit 1
                }
                WriteLog -Level Info -Message "Stopping SAP instance (${SID}/${InstanceName}) finished successfully."
            }
            else {
                WriteLog -Level Info -Message "SAP instance (${SID}/${InstanceName}) already stopped."
            }
        }
    }
}
