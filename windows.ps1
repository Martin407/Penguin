## uac
reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 4

reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v CachedLogonsCount /t REG_SZ /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-TCP" /v UserAuthentication /t REG_DWORD /d "1" /f
net stop TermService; net start TermService

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol


Get-ScheduledTask | Stop-ScheduledTask
Get-ScheduledTask | Disable-ScheduledTask
Get-ScheduledJob | Disable-ScheduledJob
Get-Job | Stop-Job

$wmi = (Get-WMIObject -Namespace root\Subscription -Class CommandLineEventConsumer -Filter "name like '%'")
$wmi | remove-wmiobject


# AD
$pass = Read-Host -AsSecureString
$excluded = @("wdagutility")
get-aduser -filter * | % { 
    if($_.name -notin $excluded) {
        set-localuser -name $_.name -password $pass
    }
}
clear-variable pass

# Server
$pass = Read-Host -AsSecureString
$excluded = @("wdagutility")
get-localuser | % { 
    if($_.name -notin $excluded -and $_.name -notlike "*$") { 
        set-localuser -name $_.name -password $pass 
    } 
}
clear-variable pass

## ps transcripts
New-Item -Path $profile.AllUsersCurrentHost -Type File -Force
$content = @'
$path       = "C:\Windows\Logs\"
$username   = $env:USERNAME
$hostname   = hostname
$datetime   = Get-Date -f 'MM/dd-HH:mm:ss'
$filename   = "transcript-${username}-${hostname}-${datetime}.txt"
$Transcript = Join-Path -Path $path -ChildPath $filename
Start-Transcript
'@
set-content -path $profile.AllUsersCurrentHost -value $content -force

