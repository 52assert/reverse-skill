#Requires -Version 5.1
# reverse-skill 全局路由注入（显式 opt-in）。
# 设计原则：
#   - 不修改用户已有 CLAUDE.md / AGENTS.md 原文（避免供应链式静默篡改）
#   - Claude Code  → 写入独立文件 ~/.claude/reverse-skill-routing.md
#   - opencode     → 在 ~/.config/opencode/AGENTS.md 追加一行 @ 引用（带 marker，可干净移除）
# 用法：
#   powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/install-global.ps1
#   powershell -File skills/scripts/install-global.ps1 -Client claude    # 只装 Claude
#   powershell -File skills/scripts/install-global.ps1 -Client opencode  # 只装 opencode
#   powershell -File skills/scripts/install-global.ps1 -Yes              # 跳过交互确认
param(
    [ValidateSet('claude', 'opencode', 'all')]
    [string] $Client = 'all',
    [switch] $Yes
)
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$skillsRoot = Split-Path -Parent $scriptDir
$packageRoot = Split-Path -Parent $skillsRoot

$template = Join-Path $skillsRoot 'config\global-routing-template.md'
if (-not (Test-Path -LiteralPath $template)) {
    Write-Host ("ERROR: template missing: {0}" -f $template) -ForegroundColor Red
    exit 2
}
$content = (Get-Content -LiteralPath $template -Raw -Encoding UTF8) -replace '<SKILL_ROOT>', $packageRoot

$doClaude = ($Client -in @('claude', 'all'))
$doOpencode = ($Client -in @('opencode', 'all'))

if (-not $Yes) {
    $summary = @(
        "将安装全局路由规则到：",
        ("  Claude Code: ~/.claude/reverse-skill-routing.md   [独立文件，不碰 CLAUDE.md] {0}" -f $(if ($doClaude) { '<<<' } else { '(skip)' })),
        ("  opencode:    ~/.config/opencode/AGENTS.md 追加 @ 引用（marker 可移除） {0}" -f $(if ($doOpencode) { '<<<' } else { '(skip)' }))
    )
    $summary | ForEach-Object { Write-Host $_ }
    $ans = Read-Host '确认写入全局配置? [Y/n]'
    if ($ans -match '^(n|N|no|NO)$') {
        Write-Host '已取消，未做任何修改。' -ForegroundColor Yellow
        exit 0
    }
}

$installed = New-Object System.Collections.Generic.List[string]

# --- Claude Code：独立文件 ---
if ($doClaude) {
    $claudeDir = Join-Path $HOME '.claude'
    $claudeFile = Join-Path $claudeDir 'reverse-skill-routing.md'
    if (-not (Test-Path -LiteralPath $claudeDir)) {
        New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($claudeFile, $content, $utf8)
    Write-Host ("OK: wrote {0}" -f $claudeFile) -ForegroundColor Green
    Write-Host "    Claude Code 会读取 ~/.claude/ 下的说明文件；若未生效，可在 CLAUDE.md 中手写一行：@" -ForegroundColor DarkGray
    [void]$installed.Add($claudeFile)
} else {
    Write-Host 'Claude Code: skipped' -ForegroundColor DarkGray
}

# --- opencode：AGENTS.md 追加 @ 引用（marker 标记，可干净卸载） ---
if ($doOpencode) {
    $ocDir = Join-Path $HOME '.config\opencode'
    $ocAgents = Join-Path $ocDir 'AGENTS.md'
    $markerStart = '<!-- reverse-skill:start -->'
    $markerEnd = '<!-- reverse-skill:end -->'
    $opencodeBlock = @(
        $markerStart,
        "# reverse-skill routing (installed by install-global.ps1)",
        ("@ {0}" -f (Join-Path $HOME '.config\opencode\reverse-skill-routing.md')),
        $markerEnd
    ) -join [Environment]::NewLine

    # 独立内容文件（opencode @ 引用目标）
    $ocContentFile = Join-Path $ocDir 'reverse-skill-routing.md'
    if (-not (Test-Path -LiteralPath $ocDir)) {
        New-Item -ItemType Directory -Force -Path $ocDir | Out-Null
    }
    [System.IO.File]::WriteAllText($ocContentFile, $content, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host ("OK: wrote content {0}" -f $ocContentFile) -ForegroundColor Green

    # AGENTS.md：存在则按 marker 块替换，不存在则新建
    $existing = ''
    if (Test-Path -LiteralPath $ocAgents) { $existing = [System.IO.File]::ReadAllText($ocAgents) }
    if ($existing -match [regex]::Escape($markerStart)) {
        $existing = [regex]::Replace($existing, "(?s)$([regex]::Escape($markerStart)).*?$([regex]::Escape($markerEnd))", $opencodeBlock)
    } else {
        $sep = if ($existing.Trim()) { [Environment]::NewLine + [Environment]::NewLine } else { '' }
        $existing = $existing.TrimEnd() + $sep + $opencodeBlock + [Environment]::NewLine
    }
    [System.IO.File]::WriteAllText($ocAgents, $existing, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host ("OK: updated {0}" -f $ocAgents) -ForegroundColor Green
    [void]$installed.Add($ocAgents)
} else {
    Write-Host 'opencode: skipped' -ForegroundColor DarkGray
}

Write-Host ''
Write-Host '=== 安装完成 ===' -ForegroundColor Green
Write-Host '卸载命令（完全移除，零残留）：' -ForegroundColor Yellow
Write-Host ("  powershell -NoProfile -ExecutionPolicy Bypass -File `"{0}\skills\scripts\uninstall-global.ps1`"" -f $packageRoot)
if ($installed.Count -eq 0) {
    Write-Host '（未安装任何客户端）' -ForegroundColor DarkGray
}
