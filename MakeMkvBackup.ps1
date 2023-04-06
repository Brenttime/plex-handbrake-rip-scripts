cd "C:\Program Files (x86)\MakeMKV\"

$output = "E:\Video\backup\Pokemon"

$diskNumber = 0

# .\makemkvcon mkv disc:0 all $output

.\makemkvcon -r --cache=1 info disc:$diskNumber

.\makemkvcon backup --decrypt --cache=16 --noscan -r --progress=-same disc:$diskNumber $output

# Location of Handbrake - should add to path
cd C:\dev\plex # Hack, need to add handbrake to path