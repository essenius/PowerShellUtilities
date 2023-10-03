# This function updates timestamps of files that are older than the specified number of months in a specified folder tree.
# This can be e.g. useful to prevent files from being deleted if a company has a non-records disposal policy.

function Update-Timestamps{

   param([string]$folder, [int]$months)
    $files = Get-ChildItem -path "$folder" -Recurse | where-object { ($_.LastWriteTimeUtc -lt (Get-Date).AddMonths(-$months))}
    "$(Get-Date -Format 'yyyy-MM-dd'): Found $($files.Count) files to renew for $folder" >> renew.txt
    $updated = ""
    foreach ($file in $files) { 
        if ($file.CreationTimeUtc -gt $file.LastWriteTime) {
            $file.CreationTimeUtc = $file.LastWriteTimeUtc
            $updated = " (updated)";
        }
        "  $($file.FullName); Created: $($file.CreationTimeUtc.toString("s"))$updated; Modified: $($file.LastWriteTimeUtc.toString("s"))" >> renew.txt
        $file.LastWriteTimeUtc = (Get-Date)
    }
}
