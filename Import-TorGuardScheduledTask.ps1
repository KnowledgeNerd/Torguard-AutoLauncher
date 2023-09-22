

# Define the XML task settings
$TaskXML = [System.IO.File]::ReadAllText("C:\Program Files\qBittorrent\TaskScheduler - TorGuard.xml")

# Get the current user's domain and username
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Register the task using the XML
Register-ScheduledTask -TaskName "TaskScheduler - TorGuard" -TaskPath "\" -Xml $TaskXML -User "$CurrentUser"