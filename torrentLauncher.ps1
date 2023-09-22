param([Parameter(Mandatory=$true)][AllowNull()][AllowEmptyString()][string]$Arguments)

<#
 # Utility Functions Declaration
#>

function Alert ([String]$message)
{
   $signature = @'
    [DllImport("user32.dll", SetLastError=true)]
    public static extern int MessageBoxTimeout(IntPtr hwnd, String text, String title, uint type, Int16 wLanguageId, Int32 milliseconds);
    [Flags] 
     public enum MessageBoxOptions : uint
     {
          OkOnly         = 0x000000,
          OkCancel       = 0x000001,
          AbortRetryIgnore   = 0x000002,
          YesNoCancel    = 0x000003,
          YesNo          = 0x000004,
          RetryCancel    = 0x000005,
          CancelTryContinue  = 0x000006,
          IconHand       = 0x000010,
          IconQuestion       = 0x000020,
          IconExclamation    = 0x000030,
          IconAsterisk       = 0x000040,
          UserIcon       = 0x000080,
          IconWarning    = IconExclamation,
          IconError      = IconHand,
          IconInformation    = IconAsterisk,
          IconStop       = IconHand,
          DefButton1     = 0x000000,
          DefButton2     = 0x000100,
          DefButton3     = 0x000200,
          DefButton4     = 0x000300,
          ApplicationModal   = 0x000000,
          SystemModal    = 0x001000,
          TaskModal      = 0x002000,
          Help           = 0x004000,
          NoFocus        = 0x008000,
          SetForeground      = 0x010000,
          DefaultDesktopOnly = 0x020000,
          Topmost        = 0x040000,
          Right          = 0x080000,
          RTLReading     = 0x100000
     }
'@

$type = Add-Type -MemberDefinition $signature -Name Win32Utils -Namespace MessageBoxTimeout -PassThru

[MessageBoxTimeout.Win32Utils]::MessageBoxTimeout(((Get-Process -Id $pid).MainWindowHandle),"$message","Alert",[MessageBoxTimeout.Win32Utils+MessageBoxOptions]::OKOnly+[MessageBoxTimeout.Win32Utils+MessageBoxOptions]::IconAsterisk,0,9000) 
}


<#
 # Start Up variable declaration
#>
$PathToExec = 'C:\Program Files\qBittorrent\qbittorrent.exe'
$VPNConnected = $false
#[regex]$rx = "(?<urlpart0>udp|http|https)?(?<urlpart1>\:\/\/|AFF)?(?<urlpart2>[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5})((?<urlpart3>:|A)(?<urlpart4>[0-9]{1,5}))?(?<urlpart5>\/|F)?(?<urlpart6>.*)?$"
#
#  Better regex    (?<fullurl>(?<urlpart0>udp|http|https)(?<urlpart1>\:\/\/|AFF)(?<urlpart2>[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5})((?<urlpart3>:?)(?<urlpart4>[0-9]{1,5}))?((?<urlpart5>\/|F)?(?<urlpart6>.*))?$)

# Example -> $Arguments = 'magnet:?xt=urn:btih:A6RWDRLFCEGNWNX3XCZIFB23RQ632R6A&tr=http://nyaa.tracker.wf:7777/announce&tr=udp://tracker.coppersurfer.tk:6969/announce&tr=udp://tracker.internetwarriors.net:1337/announce&tr=udp://tracker.leechersparadise.org:6969/announce&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://open.stealth.si:80/announce&tr=udp://p4p.arenabg.com:1337/announce&tr=udp://mgtracker.org:6969/announce&tr=udp://tracker.tiny-vps.com:6969/announce&tr=udp://peerfect.org:6969/announce&tr=http://share.camoe.cn:8080/announce&tr=http://t.nyaatracker.com:80/announce&tr=https://open.kickasstracker.com:443/announce'
# $Arguments = "E:\Users\chefh\Downloads\[HorribleSubs] Boku no Hero Academia - 51 [1080p].mkv.torrent"
# $ret=Alert("$Arguments")
 
# Preform URL Fix on Arguments

#write-host $arguments

if ($Arguments -ilike '*magnet?*') 
{
    <#$ArgParts = $Arguments -split '&'
    $FixedArgParts = @()

    foreach($Part in $ArgParts)
    {
        if ($Part.StartsWith('tr='))
        {
            [regex]$rxint = $rx

            # Trim the tr=
            $Url = $Part.Substring(3,$Part.Length-3)

            # Match Various Parts of URL
            $m = $rxint.Match($url)

            $urlpart0 = $m.Groups['urlpart0'].Value
            $urlpart2 = $m.Groups['urlpart2'].Value
            $urlpart3 = $m.Groups['urlpart3'].value
            if ($urlpart3 -ne "") { $urlpart3 = ':' }
            $urlpart4 = $m.Groups['urlpart4'].Value
            $urlpart5 = $m.Groups['urlpart5'].Value
            if ($urlpart5 -ne "") { $urlpart5 = '/' }
            $urlpart6 = $m.Groups['urlpart6'].Value

            # Creating Fixed URL
            $NewUrl = $urlpart0 + '://' + $urlpart2 + $urlpart3 + $urlpart4 + $urlpart5 + $urlpart6

            # Adding back to lst
            $NewPart = "tr=" + $NewUrl
            $FixedArgParts += $NewPart
        }
        else
        {
            $FixedArgParts += $Part
        }
    }
    $Arguments = [String]::Join('&',$FixedArgParts)#>
	$Arguments = [System.Net.WebUtility]::UrlDecode($Arguments)
}

<#
 # Test VPN and Reconnect if needed using TaskScheduler to Start/Stop torGuard
#>

$connected=$null
$connected=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Select ServiceName, IPAddress, Description | where {$_.Description -like '*TAP*' -OR $_.ServiceName -like '*wintun*' -OR $_.ServiceName -like '*WireGuard*'}
if (!$connected)
{
	Write-Host "Launching TorGuard"
    $TGtask=$null
    $TGtask=Get-ScheduledTask | where {$_ -like '*TorGuard*'}
    if (!$TGtask)
    {
        Write-Debug "No Scheduler Task found"
        $VPNConnected = $false
    }
    else
    {
        if ($TGtask.State -ne 'Running')
        {
            $TGtask | Start-ScheduledTask
            Start-Sleep -s 12
        }
        else
        {
            $TGtask | Stop-ScheduledTask
            Start-Sleep -s 4

            if ($TGapp=Get-Process | where {$_ -like '*TorGuard*'}) 
            {
                $TGapp | Stop-Process
                Start-Sleep -s 4
            }

            $TGtask | Start-ScheduledTask
            Start-Sleep -s 12
        }

        $connected=$null
        $connected=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Select ServiceName, IPAddress, Description | where {$_.Description -like '*TAP*' -OR $_.ServiceName -like '*wintun*' -OR $_.ServiceName -like '*WireGuard*'}
        if (!$connected)
        {
            Write-Error "Re/Connection Failed"
            $VPNConnected = $false
        }
        else
        {
            $VPNConnected = $true
        }
    }
}
else
{
	Write-Host "TorGuard Already Connected"
    $VPNConnected = $true
}    



<#
 # Starts Torrent App with/out a Argument declaring what to Download
#>

Write-Host "Launching qBittorent"
if ($VPNConnected)
{
        if ((($Arguments -ilike '*.torrent*') -or ($Arguments -ilike '*magnet:?*')))
        {
            # Write-Host "Path 1 - $Arguments"
            ##  This works!!!! ->  $ArgumentsList="`""+$Arguments+"`""

            $ArgumentsList=@("`""+$Arguments+"`"")
			$ArgumentsList+='--no-splash'
			#  $ArgumentsList+='--save-path="E:\Torrents\Finished Downloads"'
			$ArgumentsList+='--add-paused=false'
			$ArgumentsList+='--sequential'
			$ArgumentsList+='--first-and-last'
			$ArgumentsList+='--skip-dialog=true'
            #Write-Host "Path 1 - $ArgumentsList" 
			#"Path 1 - $ArgumentsList" | out-file -filepath c:\share\out.txt
			# Pause
            Start-Process -FilePath $PathToExec -ArgumentList $ArgumentsList  
        }
        else
        {
            # Write-Host "Path 2"
            # Pause
            Start-Process -FilePath $PathToExec
        }
}
else
{
    $ret=Alert("VPN Service cannot be connected to!  Cannot Start Torrent App.")
}


<#
 # This script will do the following:
 #     1.) Check if TorGuard VPN is Connected
 #          - If so, Continue on
 #          - If not, Check if TorGuard is Running (But not Connected)
 #              - If so, 
 #                  - Stop TorGuard then Start TorGuard
 #                  - Continue on
 #              - If not, Start TorGuard and Continue on.
 #              - Recheck if now Connected to VPN
 #                  - If so, Continue on
 #                  - If not, VPN Connection failure - Exit
 #     2.) Start Torrent with Optional Argument
 #
 #     *** Note ***   TorGuard is launched from a Scheduled Task
 #     *** Note ***   .torrent file and magnet link launch a helper batch file
 #     *** Note ***   The batch file's only job is to launch this PowerShell script.
#>
