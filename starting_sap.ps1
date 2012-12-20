<#
Starting SAP systems
Version : 0.1
Prerequisite : performing as user <sid>adm
#>

##### �ϐ���` #####

# �ȉ��̕ϐ����`���Ă�������

# 0:���s���[�U�m�F�Ȃ�, 1:���s���[�U��<sid>adm��cloudinitservice�����m�F����
$checkuser = 1

# SAP�C���X�^���X�����T�[�r�X�ȊO�ŁA�N�����K�v�ȃT�[�r�X
$NonSAPService = @("MSSQLSERVER","SQLSERVERAGENT","SQLWriter","MSSQLFDLauncher")
$SubSAPService = @("SAPHostControl")


# �ȉ��͕ύX���Ȃ��ł�������


# SAP�C���X�^���X�����T�[�r�X���̎擾
$SAPService = get-service -Name "SAP???_??" | % {$_.Name}
# �N������T�[�r�X�̐�
$SAPSrvCount = $SAPService.count
$NonSAPSrvCount = $NonSAPService.count
$SubSAPSrvCount = $SubSAPService.count

# ���̑��̕ϐ���`
$SCRIPT_PATH = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$LOGFILE_PATH = $SCRIPT_PATH + "\log"
$SCRIPT_ID =  $MyInvocation.MyCommand.Name
$LOGFILE = $LOGFILE_PATH + "\" + $SCRIPT_ID.Replace(".ps1",".log")
$HOST_NAME = hostname
# ERROR_LEVEL�̒�`
# 1:������Ă��Ȃ����s���[�U�Ŏ��s���Ă���
# 2:�T�[�r�X�N���Ɏ��s����
# 3:SAP�C���X�^���X�N���Ɏ��s����
$ERROR_LEVEL = 0


##### �֐���` #####

# �T�[�r�X���N������
function StartService ($ServCount, $ServName) {
    for ( $i = 0; $i -lt $ServCount; $i++ ) {
        $Service = Get-Service $($ServName[$i])
        if ( $Service.Status -eq "Running" ) {
            "$($ServName[$i])�T�[�r�X�͊��ɋN�����Ă���̂ŁA�N���������X�L�b�v���܂��B" >> $LOGFILE 2>&1
        } else {
            Start-Service $($ServName[$i]) >> $LOGFILE 2>&1
            $Service = Get-Service $($ServName[$i])
            if ( $Service.Status -ne "Running" ) {
                $ERROR_MSG = "$($ServName[$i])�T�[�r�X�̋N���Ɏ��s���܂����B"
                $ERROR_LEVEL = 2
                break Root
            }
        }
    }
}

# SAP�C���X�^���X���N������
# 30��(1800�b)�o�߂��Ă����S�ɋN�����Ȃ���΁A�^�C���A�E�g�Ƃ��ď�������
function Exec_sapcontrol ($No, $Msg, $wt=1800, $dt=5) {
    "${SAPEXE}\sapcontrol.exe -nr $No -prot PIPE -function StartWait $wt $dt" >> $LOGFILE 2>&1
    & "${SAPEXE}\sapcontrol.exe" -nr $No -prot PIPE -function StartWait $wt $dt >> $LOGFILE 2>&1
    if ( $LASTEXITCODE -ne 0 ) {
        $ERROR_MSG = "${Msg}�C���X�^���X�̋N���Ɏ��s���܂����B"
        $ERROR_LEVEL = 3
        break Root
    }
}


##### SAP�N�������J�n #####

$STEP_NAME = "INIT"

New-Item $LOGFILE_PATH -itemType Directory -Force | Out-Null

$DATE = Get-Date -format G
"****************************************"   >> $LOGFILE 2>&1
"* START        : ${SCRIPT_PATH}\$SCRIPT_ID" >> $LOGFILE 2>&1
"* DATE         : $DATE"                     >> $LOGFILE 2>&1
"* ComputerName : $HOST_NAME"                >> $LOGFILE 2>&1
"****************************************"   >> $LOGFILE 2>&1

# SAP�̃C���X�^���X�ԍ���SID�𒊏o����
# SIDs[$i] = SID , $***No = �C���X�^���X�ԍ�
# AdmUser = <sid>adm �� cloudinitservice ������
$SIDs = get-childitem HKLM:\SOFTWARE\SAP | ? {$_.property -eq "AdmUser"} | % {$_.Name}
$regpath = $SIDs -replace "HKEY_LOCAL_MACHINE\\","HKLM:"
$AdmUser = get-itemproperty $regpath | % {$_.AdmUser}
$AdmUser += $(hostname) + "\cloudinitservice"
$SIDsCount = $SIDs.Count
for ( $i = 0; $i -lt $SIDsCount; $i++ ) {
    $SIDs[$i] = $SIDs[$i].SubString($SIDs[$i].Length-3,3)
    $SCSname = Get-ChildItem ( join-path "\\localhost\sapmnt\" $SIDs[$i] ) | ? {$_.Name -like "*SCS*"} | % {$_.Name}
    if ( $SCSname -ne $null ) {
        $SCSNo =  $SCSname.SubString($SCSname.Length-2,2)
        $SCSMsg = "SCS"
    }
    $CIname = Get-ChildItem ( join-path "\\localhost\sapmnt\" $SIDs[$i] ) | ? {$_.Name -like "DVEBMGS*"} | % {$_.Name}
    if ( $CIname -ne $null ) {
        $CINo =  $CIname.SubString($CIname.Length-2,2)
        $CIMsg = "�Z���g����"
        # CI��sapcontrol���g���̂ŁA���̃p�X��$SAPEXE�ɓ���Ă����B
        $SAPEXE = "\\localhost\sapmnt\" + $SIDs[$i] + "\SYS\exe\uc\NTAMD64"
    }
    $DAAname = Get-ChildItem ( join-path "\\localhost\sapmnt\" $SIDs[$i] ) | ? {$_.Name -like "SMDA*"} | % {$_.Name}
    if ( $DAAname -ne $null ) {
        $DAANo =  $DAAname.SubString($DAAname.Length-2,2)
        $DAAMsg = "DAA"
    }
}

:Root While(1) {

    if ( $checkuser -eq 1 ) {
        if ( $AdmUser -notcontains $(whoami) ) {
            $ERROR_MSG = "���̃X�N���v�g�́A�ȉ��̂����ꂩ�̃��[�U�Ŏ��s����K�v������܂��B���O�I���������čĎ��s���Ă��������B$AdmUser" >> $LOGFILE 2>&1
            $ERROR_LEVEL = 1
            break Root
        }
        "���s���[�U�m�FOK�B" >> $LOGFILE 2>&1
    } else {
        "���s���[�U�m�F���X�L�b�v���܂��B" >> $LOGFILE 2>&1
    }

    cd $LOGFILE_PATH

    $STEP_NAME = "START_NonSAPService"
    if ( $NonSAPSrvCount -gt 0 ) {
        StartService $NonSAPSrvCount $NonSAPService
    }
    
    $STEP_NAME = "START_SAPService (exclude instance service)"
    if ( $SubSAPSrvCount -gt 0 ) {
        StartService $SubSAPSrvCount $SubSAPService
    }

    $STEP_NAME = "START_SAPService"
    if ( $SAPSrvCount -gt 0 ) {
        StartService $SAPSrvCount $SAPService
    }

# �T�[�r�X�N���シ����SAP�C���X�^���X�N������Ǝ��s���鎞������̂�3�b���x�ҋ@����
    ping -n 3 localhost | Out-Null

    $STEP_NAME = "START_SAPInstances"

    if ( $SCSNo -ne $null ) {
        Exec_sapcontrol $SCSNo $SCSMsg
    }
    if ( $CINo -ne $null ) {
        Exec_sapcontrol $CINo $CIMsg
    }
    if ( $DAANo -ne $null ) {
        Exec_sapcontrol $DAANo $DAAMsg
    }
   
    break Root
} # Root-End


##### �I������ #####

# ����I���̏ꍇ
$DATE = Get-Date -format G
if ( $ERROR_LEVEL -eq 0 ) {
    "****************************************"   >> $LOGFILE 2>&1
    "* NORMAL END   : ${SCRIPT_PATH}\$SCRIPT_ID" >> $LOGFILE 2>&1
    "* DATE         : $DATE"                     >> $LOGFILE 2>&1
    "* ComputerName : $HOST_NAME"                >> $LOGFILE 2>&1
    "****************************************"   >> $LOGFILE 2>&1

} else {

# �ُ�I���̏ꍇ
    "****************************************"   >> $LOGFILE 2>&1
    "* ERROR END    : ${SCRIPT_PATH}\$SCRIPT_ID" >> $LOGFILE 2>&1
    "* DATE         : $DATE"                     >> $LOGFILE 2>&1
    "* ComputerName : $HOST_NAME"                >> $LOGFILE 2>&1
    "* ERROR STEP   : $STEP_NAME"                >> $LOGFILE 2>&1
    "* ERROR LEVEL  : $ERROR_LEVEL"              >> $LOGFILE 2>&1
    "* ERROR MESSAGE: $ERROR_MSG"                >> $LOGFILE 2>&1
    "****************************************"   >> $LOGFILE 2>&1
}

exit $ERROR_LEVEL
