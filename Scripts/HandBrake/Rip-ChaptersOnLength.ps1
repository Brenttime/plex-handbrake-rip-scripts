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
    return (((handbrake --scan --json -i $InputDriveLetter -t 0 | Join-String) -replace '.*JSON Title Set:\s*(.+)' , '$1' | ConvertFrom-JSON).TitleList)
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

# Number of Episodes in Each Title
$numEpisodes = 3

# Season Title
$season = "01"

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

For($i = 0; $i -lt $numberOfTitles; $i++)
{
    $currentTitle = $titleList[$i].Index
    $chapterList = Get-ChapterList -TitleNumber $currentTitle -InputDriveLetter $inputDriveLetter
    $numChapters = $chapterList.Length
    
    # Start at chapter 1 then proceed to find the next chapter to start for the following episodes
    $currentStartingChapter = 1

    # Loop Over the Number of episodes we want to create then determine the chapters that make that episode up, and then rip
    For($j = $startingEp; $j -lt $numEpisodes; $j++) 
    {
        $currRunLength = New-TimeSpan 

        # By adding Run Length up we should be able to determine, based on an average run length, the chapter an episode ends at
        For($k = $currentStartingChapter - 1; $k -lt $numChapters; $k++) 
        {
            # Running Variable to add timespans of chapters that will be used in an episode
            $currRunLength = $currRunLength.Add((New-TimeSpan -Minutes $chapterList[$k].Duration.Minutes -Seconds $chapterList[$k].Duration.Seconds))
            $episodeTitleNumber = $j + 1 + $episodeNumberInTitleOffset

            # Once Run Length goes over the expected run length then we have our ending chapter and should exit the loop
            if(
                ($currRunLength -gt $expectedTimeSpan) -or 
                ($currRunLength.Add((New-TimeSpan -Minutes $chapterList[$k + 1].Duration.Minutes -Seconds $chapterList[$k + 1].Duration.Seconds)) -gt (New-TimeSpan -Minutes 25)))
            {
                $chpEpisodeEnds = $k + 1

                # Add any chapter that is at the tail end
                if((New-TimeSpan -Minutes $chapterList[$k].Duration.Minutes -Seconds $chapterList[$k].Duration.Seconds) -lt (New-TimeSpan -Seconds 5))
                {
                    $chpEpisodeEnds++
                }

                break
            }
            # Set in the case where things don't add up just right towards the end of the disk
            $chpEpisodeEnds = $k + 1
        }

        Write-Host "----------------------------------------episode $episodeTitleNumber is chapters $currentStartingChapter - $chpEpisodeEnds (Out of $numChapters)---------------------------------------------------------"
        $outputAbsolutePath = "$outputFilePath$showName Title $currentTitle"+ "e$episodeTitleNumber.mp4"

        ## --no-dvdnav  -- used for yu yu hakasho as some titles error out with this on
        handbrake -t $currentTitle -i $inputDriveLetter -c "$currentStartingChapter-$chpEpisodeEnds" -o $outputAbsolutePath  -f av_mp4 --audio-lang-list "English" -e nvenc_h264 --aencoder ca_aac --mixdown 7point1 --auto-anamorphic --keep-display-aspect --no-comb-detect --no-deinterlace --no-decomb --no-detelecine --no-hqdn3d --no-nlmeans --no-unsharp --no-lapsharp --no-deblock --no-grayscale --subtitle scan --subtitle-force -q 24.0 --vfr --native-language "eng" --no-dvdnav  
        
        # Setup For the Next Episode to start at the chapter following this final chapter
        $currentStartingChapter = $chpEpisodeEnds + 1
    }
}

