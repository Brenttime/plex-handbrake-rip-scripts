function Get-NumberOfChapters {
    param(
        $InputDriveLetter,
        $TitleNumber
    )
    return [int]((((.\HandbrakeCLI --scan --json -i $InputDriveLetter -t $TitleNumber --no-dvdnav | Join-String) -replace '.*JSON Title Set:\s*(.+)' , '$1' | ConvertFrom-JSON).TitleList).ChapterList.Length)
} 

function Get-NumberOfTitles {
    param(
        $InputDriveLetter
    )
    return [int]((((.\HandbrakeCLI --scan --json -i $InputDriveLetter -t 0 | Join-String) -replace '.*JSON Title Set:\s*(.+)' , '$1' | ConvertFrom-JSON).TitleList).Length)
} 

function Get-DiskName {
    param(
        $InputDriveLetter
    )
    if($InputDriveLetter.EndsWith(".iso")) {
        return [string]([System.IO.Path]::GetFileNameWithoutExtension($InputDriveLetter))
    }
    else {
        return [string] ((Get-WMIObject -Class Win32_CDROMDrive -Property *) | Where-Object Drive -eq $inputDriveLetter.replace('\', '')).VolumeName
    }
}

# Location of Handbrake - should add to path
cd C:\dev\plex

# Worst case this can be turned on to log to a file in user absence
# Start-Transcript -Append .\last-log.txt

$nameOfShow = ""

$inputDriveLetter = "F:\"
$diskName = Get-DiskName $inputDriveLetter
$outputFilePath = "D:\$nameOfShow\$diskName\"

# Create Dir if it doesn't exist
If(!(test-path -PathType container $outputFilePath))
{
      New-Item -ItemType Directory -Path $outputFilePath
}

$numberOfTitles = Get-NumberOfTitles -InputDriveLetter $inputDriveLetter

For($i = 1; $i -le $numberOfTitles; $i++)
{
    $numberOfChapters = Get-NumberOfChapters -InputDriveLetter $inputDriveLetter -TitleNumber $i
    $outputAbsolutePath = $outputFilePath + $nameOfShow + $i +".mp4"
    
    Write-Host "----------------------------------------title $i chapters $numberOfChapters---------------------------------------------------------"
    Write-Host " .\HandBrakeCLI.exe -t $i -i $inputDriveLetter -c 1-$numberOfChapters -o $outputAbsolutePath --audio-lang-list English --ab 192 --all-subtitles -e nvenc_h265 --no-dvdnav  "
        
    .\HandBrakeCLI.exe -t $i -i $inputDriveLetter -c "1-$numberOfChapters" -o $outputAbsolutePath --audio-lang-list "English" --ab 192  --all-subtitles -e nvenc_h265 --no-dvdnav  
}


