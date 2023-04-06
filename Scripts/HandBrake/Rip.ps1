# Location of Handbrake - should add to path
cd C:\dev\plex

$inputDriveLetter = "E:\Video\cowboy\Cowboy Bebop Disc 1_t00.mkv"
$outputFilePath = "D:\cowboy\Disk1\" 
$season = "01"

# Disk will default this to some part of the Titles
$titleNumber = 1

# Number of Episodes on Disk
$numEpisodes = 1

# Get number of chpaters for each episode
$episodeDivder = 4

# Create Dir if it doesn't exist
If(!(test-path -PathType container $outputFilePath))
{
      New-Item -ItemType Directory -Path $outputFilePath
}

$startingEp = 1
$chapterOffset = 2

For($i = $startingEp; $i -cle $numEpisodes; $i++) 
{
    $chapter = ( ($i * $episodeDivder) ) + 1 + $chapterOffset
    
    $chpEpisodeEnds = ($chapter + ($episodeDivder - 1))
    
    Write-Host "----------------------------------------episode $i is chapters $chapter - $chpEpisodeEnds (Out of $numChapters)---------------------------------------------------------"

    $outputAbsolutePath = $outputFilePath + "CowBoy Beebop s" + $season + "e" + ($i + 1) +".mp4"
    
    .\HandBrakeCLI.exe -t $titleNumber -i $inputDriveLetter -c "$chapter-$chpEpisodeEnds" -o $outputAbsolutePath --audio-lang-list "English" | out-null 
}
