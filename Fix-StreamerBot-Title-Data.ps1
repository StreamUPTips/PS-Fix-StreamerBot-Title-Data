$streamDeckPath = Join-Path -Path $env:APPDATA -ChildPath "Elgato\StreamDeck"
$streamDeckProfilePath = Join-Path -Path $streamDeckPath -ChildPath "ProfilesV2"

Write-Host "#########################################################################################"
Write-Host "This Powershell script will update the StreamerBot Actions in your StreamDeck Profiles"
Write-Host "The script has been made to copy the button name to the new title field in the StreamDeck Application"
Write-Host ""
Write-Host "Make sure you close the Elgato Stream Deck application before continuing!"
Write-Host "A backup will be made in the $streamDeckPath if something goes wrong"
Write-Host ""
Write-Host "Made by Silverlink (https://streamup.tips) inspired by Troyhammaren"
Write-Host "#########################################################################################"
Write-Warning "Press Enter to continue or close this Window if you want to cancel"
Read-Host -Prompt "Press Enter to Continue"

if (!(Test-Path -Path $streamDeckProfilePath)) {
    Write-Warning "$streamDeckPath not found! Stopping"
    Read-Host -Prompt "Press Enter or close this window to continue"
    exit
}

$currentDate = Get-Date -Format "yyyyMMddHHmmss"
$backupPath = Join-Path -Path $streamDeckPath -ChildPath "$currentDate ProfilesV2"

Write-Host "Creating backup directory called '$currentDate ProfilesV2' in $streamDeckPath"
Copy-Item $streamDeckProfilePath -Recurse -Filter *.* -Destination $backupPath

$jsonFiles = Get-ChildItem -Path $streamDeckProfilePath -Filter "*.json" -Recurse

foreach ($jsonFile in $jsonFiles) {
    $jsonData = Get-Content -Path $jsonFile.FullName | ConvertFrom-Json
    $fileEdited = $false
    if (!($jsonData.Controllers)){
        Write-Host "Not the expected type of file. Continuing to the next file!"
        continue
    }

    foreach ($dataValue in $jsonData.Controllers.Actions.PSObject.Properties.Value) {
        if ($dataValue.UUID -ne "bot.streamer.streamdeck.action") {continue}
        if (!($dataValue.States.Title) -or $dataValue.States.Title -eq "") {
            Write-Host "StreamerBot action found, but no data is found in the Title."
            Write-Host "It's either already good or the data was never there. Skipping..."
            continue
        }

        $buttonTitle = $dataValue.States.Title
        $buttonImage = $dataValue.States.Image
        $buttonTitleString = $buttonTitle -replace "\n", " "
        
        Write-Host "Found button '$buttonTitleString'"

        # Replacing States because powershell didn't want to overwrite it the normal way
        $states = @(
            @{"Image"=$buttonImage;"Title"=""}
        )

        $dataValue.States = $states

        # Creating new title object
        Write-Host "Setting button title on the right property"
        if (!($dataValue.Settings.title)) {
            # Some older buttons don't have the right properties, so we add them.
            $dataValue.Settings | Add-Member -Name "title" -MemberType NoteProperty -Value @{"0" = $buttonTitle}
        } else {
            $dataValue.Settings.title = "" | Select-Object "0"
            $dataValue.Settings.title.0 = $buttonTitle
        }
        
        Write-Host "Done with $buttonTitleString"
        $fileEdited = $true
    }

    if ($fileEdited) {
        Write-Host "Writing Data back to file"
        ConvertTo-Json -InputObject $jsonData -Depth 10 -Compress | Set-Content -Path $jsonFile.FullName
    }    
}
Write-Host "Done with files in $streamDeckProfilePath"
Read-Host -Prompt "Press Enter or close this window to continue"