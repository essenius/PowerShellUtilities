# Copyright 2024 Rik Essenius
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

# Backup GnuCash files (including logs) and clean up the backup folder:
# * copy data file, backup files and log files of the last 7 days
# * remove all log files older than 30 days
# * Per day before the 30 day cutoff, delete all files but the latest one. 
# Intent is that this is run from a weekly cron job or scheduled task

# Define the source and destination directories
$sourceDir = "C:\Data\Finance"
$destinationDir = "X:\home\finance"
$gnucashFile = "Gnucash.gnucash"

# Warn if GnuCash is running
$lockFile = Join-Path -Path $sourceDir -ChildPath ( "$($gnucashFile).LCK")
if (Test-Path -Path $lockFile) {
    Write-Host "GnuCash is active. Trying to backup anyway"
}

# Get the current date and subtract 7 days to get the cutoff date for backup (we run this script every week)
$cutoffDate = (Get-Date).AddDays(-7)

# Get all files in the source directory that were modified after the cutoff and are not lock files
$filesToCopy = Get-ChildItem -Path $sourceDir -File | Where-Object { $_.LastWriteTime -gt $cutoffDate -and $_.Extension -ne ".LCK" }

# Copy each file to the destination directory
foreach ($file in $filesToCopy) {
    $destPath = Join-Path -Path $destinationDir -ChildPath $file.FullName.Substring($sourceDir.Length)
    Write-Host $destPath
    Copy-Item -Path $file.FullName -Destination $destPath -Force
}

# The delete cutoff is 30 days ago
$deleteCutoff = (Get-Date).AddDays(-30)

# Delete all log files from before the delete cutoff
$deleteTemplate = Join-Path -Path $destinationDir -ChildPath "${gnucashFile}.*.log"
$filesToDelete = Get-ChildItem -Path $deleteTemplate -File | Where-Object {$_.LastWriteTime -lt $deleteCutoff }
foreach ($file in $filesToDelete) {
    Write-Host "Deleting $file"
    Remove-Item -Path $file
}

# Clean up the backup files from before the delete cutoff
$deleteTemplate = Join-Path -Path $destinationDir -ChildPath "${gnucashFile}.*.gnucash"
$filesToDelete = Get-ChildItem -Path $deleteTemplate -File | Where-Object {$_.LastWriteTime -lt $deleteCutoff }

# Per day before the cutoff date, keep the last backup file. Delete the rest
$dateFormat = "yyyy-MM-dd"
$index = 0
while($index -lt $filesToDelete.Count) {
    # prepare the date for the next iteration
    $indexDate = $filesToDelete[$index].LastWriteTime.ToString($dateFormat)
    Write-Host "New indexDate = $indexDate at index $index"
    
    # Loop to find the range of files with the same date
    $startIndex = $index
    while ($index -lt $filesToDelete.Count -and $filesToDelete[$index].LastWriteTime.ToString($dateFormat) -eq $indexDate) {
        $index++
    }

    # Delete all but the last file within the range
    for ($deleteIndex = $startIndex; $deleteIndex -lt $index - 1; $deleteIndex++) {
        Write-Host "Deleting $($filesToDelete[$deleteIndex].Name) at index $deleteIndex"
        Remove-Item -Path $filesToDelete[$deleteIndex]
    }

    Write-Host "Keeping $($filesToDelete[$index - 1].Name) at index $($index - 1)"
}

