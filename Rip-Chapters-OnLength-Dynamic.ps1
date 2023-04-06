# Location of Handbrake - should add to path
cd C:\dev\plex # Hack, need to add handbrake to path
set-Alias handbrake $pwd\HandBrakeCLI.exe

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

function Get-TitleList {
    param(
        $InputDriveLetter
    )
    return (((handbrake --scan --json -i $InputDriveLetter -t 0 | Join-String) -replace '.*JSON Title Set:\s*(.+)' , '$1' | ConvertFrom-JSON).TitleList) | out-null
} 

function Get-ChapterList {
    param(
        $InputDriveLetter,
        $TitleNumber
    )
    return ((((handbrake --scan --json -i $InputDriveLetter -t $TitleNumber --no-dvdnav | Join-String) -replace '.*JSON Title Set:\s*(.+)' , '$1' | ConvertFrom-JSON).TitleList).ChapterList) 
} 

function Get-NumberOfTitles {
    param(
        $InputDriveLetter
    )
    return [int]((Get-TitleList $InputDriveLetter).Length)
} 

function Get-NumberOfChapters {
    param(
        $InputDriveLetter,
        $TitleNumber
    )
    return [int]((Get-ChapterList $InputDriveLetter $TitleNumber).Length)
} 

# Worst case this can be turned on to log to a file in user absence
# Start-Transcript -Append .\last-log.txt

# Disk or ISO for the DVD to rip
$InputDriveLetter = "D:\MakeMkv\Pokemon Orange Islands Disc 1.iso"

# Output file name of show
$showName = "Pokemon Orange Islands"

# Title's offset for the episode number
$episodeNumberInTitleOffset = 0

# Expected Run Length of an episdoe based on average
$expectedTimeSpan = New-TimeSpan -Minutes 21 -Seconds 40

# File Path to Create file in 
$diskName = Get-DiskName $InputDriveLetter
$outputFilePath = "D:\$showName\$diskName\" 

# Create Dir if it doesn't exist
If(!(test-path -PathType container $outputFilePath))
{
    New-Item $outputFilePath -type Directory | Out-Null
}

# Starting Episode - (0 indexed)
$startingEp = 0

# Get Number of Titles for Disk
$numberOfTitles = Get-NumberOfTitles -InputDriveLetter $inputDriveLetter
$titleList = Get-TitleList -InputDriveLetter $inputDriveLetter

# Start at chapter 1 then proceed to find the next chapter to start for the following episodes
$currentStartingChapter = 1

$FullChapterList = Get-TitleList -InputDriveLetter $inputDriveLetter | select ChapterList, Index
$episodeNumber =  1
$j = 0
$Episodes = []

# Loop Over the Number of episodes we want to create then determine the chapters that make that episode up, and then rip
While(j < $FullChapterList.length)
{
    $currRunLength = New-TimeSpan 
    
    $episode = [PSCustomObject]@{Chapters = [$currentStartingChapter], 'Titles' = [$FullChapterList[$j]]}

    # By adding Run Length up we should be able to determine, based on an average run length, the chapter an episode ends at
    While(
        ($currRunLength -gt $expectedTimeSpan) -or 
        ($currRunLength.Add((New-TimeSpan -Minutes $chapterList[$k + 1].Duration.Minutes -Seconds $chapterList[$k + 1].Duration.Seconds)) -gt (New-TimeSpan -Minutes 25))
    )
    {        
        if($currentStartingChapter > $chapterList.Length)
        {
            $j++
        }
        
        $chapterList = $FullChapterList[$j].ChapterList
        
        # Running Variable to add timespans of chapters that will be used in an episode
        $currRunLength = $currRunLength.Add((New-TimeSpan -Minutes $chapterList[$currentStartingChapter].Duration.Minutes -Seconds $chapterList[$currentStartingChapter].Duration.Seconds))
        
        $currentChapter++

    }

    $Episodes.Add()

    Write-Host "----------------------------------------episode $episodeTitleNumber is chapters $currentStartingChapter - $chpEpisodeEnds (Out of $($FullChapterList.Length))---------------------------------------------------------"
    # Setup For the Next Episode to start at the chapter following this final chapter
    #$currentStartingChapter = $chpEpisodeEnds + 1
}


#$outputAbsolutePath = "$outputFilePath$showName Title $currentTitle"+ "e$episodeTitleNumber.mp4"

## --no-dvdnav  -- used for yu yu hakasho as some titles error out with this on
#handbrake -t $currentTitle -i $inputDriveLetter -c "$currentStartingChapter-$chpEpisodeEnds" -o $outputAbsolutePath  -f av_mp4 --audio-lang-list "English" -e nvenc_h264 --aencoder ca_aac --mixdown 7point1 --auto-anamorphic --keep-display-aspect --no-comb-detect --no-deinterlace --no-decomb --no-detelecine --no-hqdn3d --no-nlmeans --no-unsharp --no-lapsharp --no-deblock --no-grayscale --subtitle scan --subtitle-force -q 24.0 --vfr --native-language "eng" --no-dvdnav  

