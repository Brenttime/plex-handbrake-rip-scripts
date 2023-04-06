# Location of Handbrake - should add to path
cd C:\dev\plex # Hack, need to add handbrake to path

# Disk or ISO for the DVD to rip
$inputDriveLetter = "E:\Video\BERSERK_2016_S1_D1\BERSERK_2016_S1_D1_t00.mkv"

# File Path to Create file in 
$outputFilePath = "D:\BERSERK\" 

# Number of Episodes on Disk
$numEpisodes = 9

# Season Title
$season = "01"

# Output file name of show
$showName = "BERSERK"

# Title's offset for the episode number
$episodeNumberInTitleOffset = 0

# Disk will default this to some part of the Titles
$titleNumber = 1

# Start-Transcript -Append .\last-log.txt

# List of chapters on this disk
$chapterList = (((.\HandbrakeCLI --scan --json -i $inputDriveLetter -t $titleNumber --no-dvdnav | Join-String) -replace '.*JSON Title Set:\s*(.+)' , '$1' | ConvertFrom-JSON).TitleList).ChapterList

# Get the Number Of chapters on this disk
$numChapters = [int]($chapterList.Length)

# Create Dir if it doesn't exist
If(!(test-path -PathType container $outputFilePath))
{
    New-Item $outputFilePath -type Directory | Out-Null
}

# Expected Run Length of an episdoe based on average
$expectedTimeSpan = New-TimeSpan -Minutes 24 -Seconds 20

# Start at chapter 1 then proceed to find the next chapter to start for the following episodes
$currentStartingChapter = 1

# Starting Episode 
$startingEp = 0

# Loop Over the Number of episodes we want to create then determine the chapters that make that episode up, and then rip
For($i = $startingEp; $i -lt $numEpisodes; $i++) 
{
    $currRunLength = New-TimeSpan 

    # By adding Run Length up we should be able to determine, based on an average run length, the chapter an episode ends at
    For($j = $currentStartingChapter - 1; $j -lt $numChapters; $j++) 
    {
        # Running Variable to add timespans of chapters that will be used in an episode
        $currRunLength = $currRunLength.Add((New-TimeSpan -Minutes $chapterList[$j].Duration.Minutes -Seconds $chapterList[$j].Duration.Seconds))
        $episodeTitleNumber = $i + 1 + $episodeNumberInTitleOffset

        # Once Run Length goes over the expected run length then we have our ending chapter and should exit the loop
        if(($currRunLength -gt $expectedTimeSpan) -or ($currRunLength.Add((New-TimeSpan -Minutes $chapterList[$j + 1].Duration.Minutes -Seconds $chapterList[$j + 1].Duration.Seconds)) -gt (New-TimeSpan -Minutes 25)))
        {
            $chpEpisodeEnds = $j + 1

            # Add any chapter that is at the tail end
            if((New-TimeSpan -Minutes $chapterList[$j].Duration.Minutes -Seconds $chapterList[$j].Duration.Seconds) -lt (New-TimeSpan -Seconds 5))
            {
                $chpEpisodeEnds++
            }

            break
        }
        # Set in the case where things don't add up just right towards the end of the disk
        $chpEpisodeEnds = $j + 1
    }

    Write-Host "----------------------------------------episode $episodeTitleNumber is chapters $currentStartingChapter - $chpEpisodeEnds (Out of $numChapters)---------------------------------------------------------"
    $outputAbsolutePath = "$outputFilePath$showName s$season"+ "e$episodeTitleNumber.mp4"

    ## --no-dvdnav  -- used for yu yu hakasho as some titles error out with this on
    .\HandBrakeCLI.exe -t $titleNumber -i $inputDriveLetter -c "$currentStartingChapter-$chpEpisodeEnds" -o $outputAbsolutePath --audio-lang-list "English" -e nvenc_h264 
    
    # Setup For the Next Episode to start at the chapter following this final chapter
    $currentStartingChapter = $chpEpisodeEnds + 1
}

