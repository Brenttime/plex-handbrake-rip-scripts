set-Alias makemkvcon "C:\Program Files (x86)\MakeMKV\makemkvcon.exe"

function Get-DiskName {
    param(
        $DiskNumber
    )
    $diskInfo = makemkvcon -r info disc | select-string -Pattern "DRV:$DiskNumber" 
    $diskName = (($diskInfo -Split ',')[-2] -replace '"', "")
    return [string] ($diskName)
}

$diskNumber = 0
$diskName = Get-DiskName $diskNumber 

$outputPath = "E:\Video\backup\$diskName"

# Create Dir if it doesn't exist
If(!(test-path -PathType container $outputPath))
{
    New-Item $outputPath -type Directory | Out-Null
}

makemkvcon mkv disc:$diskNumber all $outputPath --robot