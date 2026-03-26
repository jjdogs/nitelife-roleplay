# autopush.ps1 — Auto-push changes to GitHub for NiteLife Roleplay

$serverPath = "A:\NiteLife\txData\Qbox_B544D5.base"
$logFile = "$serverPath\autopush.log"

Set-Location $serverPath

$status = git status --porcelain
if ($status) {
    git add .
    git commit -m "Auto-push: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git push origin main
    Add-Content $logFile "$(Get-Date): Changes pushed"
} else {
    Add-Content $logFile "$(Get-Date): No changes to push"
}