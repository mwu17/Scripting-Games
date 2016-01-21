# Tested version: v5

<#
.Synopsis
   Get Servers up time
.DESCRIPTION
   2016-January Scripting Games Puzzle:
   Server uptime function:
    1. Support pipeline input so that you can pipe computer names directly to it.
    2. Process multiple computer names at once time and output each computer’s stats with each one being a single object.
    3. It should not try to query computers that are offline. If an offline computer is found, it should write a warning to the console yet still output an object but with Status of OFFLINE.
    4. If the function is not able to find the uptime it should show ERROR in the Status field.
    5. If the function is able to get the uptime, it should show ‘OK’ in the Status field.
    6. It should include the time the server started up and the uptime in days (rounded to 1/10 of a day)
    7. If no ComputerName is passed, it should default to the local computer.
    8. The function should show a MightNeedPatched property of $true ONLY if it has been up for more than 30 days (rounded to 1/10 of a month).  If it has been up for less than 30 days, MightNeedPatched should be $false.
.EXAMPLE
PS C:\> Get-Uptime


ComputerName     : DC1
StartTime        : 1/15/2016 12:04:43 PM
Uptime(Days)     : 6
Status           : OK
MightNeedPatched : False
.EXAMPLE
PS C:\> Get-Uptime -computerName "DC1","W7-TEST" | Format-Table -AutoSize

ComputerName StartTime             Uptime(Days) Status  MightNeedPatched
------------ ---------             ------------ ------  ----------------
DC1          1/15/2016 12:04:43 PM            6 OK                 False
W7-TEST                                       6 OFFLINE            False
.EXAMPLE
PS C:\> $list = "DC1","W7-TEST"

PS C:\> $list | Get-Uptime | Format-Table -AutoSize

ComputerName StartTime             Uptime(Days) Status  MightNeedPatched
------------ ---------             ------------ ------  ----------------
DC1          1/15/2016 12:04:43 PM            6 OK                 False
W7-TEST                                       6 OFFLINE            False



#>
function Get-Uptime
{
    [CmdletBinding()]
    Param
    (
        # Computer name parameter
        [Parameter(Position=0,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)
                   ]  
        [ValidateNotNullorEmpty()]    
        [string[]]$computerName = $env:COMPUTERNAME


    )

    Begin
    {
    }
    Process
    {


        foreach($computer in $computerName){
            $LastBootTime = $null
            $sysuptimeDays = $null          
            
            if(Test-Connection $computer -count 1 -Quiet){

                try{
                    $wmi = Get-WmiObject -Class Win32_OperatingSystem -computername $computer -ErrorAction SilentlyContinue
                    $LastBootTime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
                    $sysuptime = (Get-Date) – $LastBootTime
                    $sysuptimeDays = $sysuptime.Days
                    $status = "OK"

                    # Check Might Need Patched property
                    if($sysuptime.days -ge 30){$mightNeedPatched = $true}
                    else{$mightNeedPatched = $false}
                }

                catch{
                    $status = "ERROR"
                }

                
            }
            else{
                $status = "OFFLINE"
            }

            # Save data in the object
                $obj = [pscustomobject][ordered]@{
                    ComputerName = $computer
                    StartTime = $LastBootTime
                    'Uptime(Days)' = $sysuptime.Days
                    Status = $status
                    MightNeedPatched = $mightNeedPatched
                    }
                
                $obj
                
        }

    }
    End
    {
    }
}