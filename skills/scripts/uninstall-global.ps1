#Requires -Version 5.1
# reverse-skill 全局路由注入卸载：删除独立文件 + 移除 opencode AGENTS.md marker 块。
# 用法：
#   powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/uninstall-global.ps1
param(
    [ValidateSet('claude', 'opencode', 'all')]
    [string] $Client = 'all'
)
$ErrorActionPreference = 'Continue'

$doClaude = ($Client -in @('claude', 'all'))
$doOpencode = ($Client -in @('opencode', 'all'))

if ($doClaude) {
    $claudeFile = Join-Path $HOME '.claude\reverse-skill-routing.md'
    if (Test-Path -LiteralPath $claudeFile) {
        Remove-Item -Force -LiteralPath $claudeFile
        Write-Host ("OK: removed {0}" -f $claudeFile) -ForegroundColor Green
    } else {
        Write-Host 'claude: nothing to remove (file absent)' -ForegroundColor DarkGray
    }
}

if ($doOpencode) {
    $ocDir = Join-Path $HOME '.config\opencode'
    $ocAgents = Join-Path $ocDir 'AGENTS.md'
    $ocContent = Join-Path $ocDir 'reverse-skill-routing.md'
    $markerStart = '<!-- reverse-skill:start -->'
    $markerEnd = '<!-- reverse-skill:end -->'

    if (Test-Path -LiteralPath $ocContent) {
        Remove-Item -Force -LiteralPath $ocContent
        Write-Host ("OK: removed {0}" -f $ocContent) -ForegroundColor Green
    }
    if (Test-Path -LiteralPath $ocAgents) {
        $existing = [System.IO.File]::ReadAllText($ocAgents)
        if ($existing -match [regex]::Escape($markerStart)) {
            $existing = [regex]::Replace($existing, "(?s)\s*$([regex]::Escape($markerStart)).*?$([regex]::Escape($markerEnd))", '')
            [System.IO.File]::WriteAllText($ocAgents, $existing, (New-Object System.Text.UTF8Encoding($true)))
            Write-Host ("OK: removed marker block from {0}" -f $ocAgents) -ForegroundColor Green
        } else {
            Write-Host 'opencode: AGENTS.md has no reverse-skill marker (clean)' -ForegroundColor DarkGray
        }
    } else {
        Write-Host 'opencode: AGENTS.md absent (nothing to remove)' -ForegroundColor DarkGray
    }
}

Write-Host '=== 卸载完成 ===' -ForegroundColor Green
