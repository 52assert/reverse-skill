#Requires -Version 5.1
# reverse-skill × opencode 一键安装/检查：
#   1) 检查 opencode CLI 是否可用
#   2) 验证项目 opencode.jsonc 配置（skills.paths / MCP）
#   3) 校验 skills/ 下全部 SKILL.md frontmatter（name+description 完整性）
#   4) 可选：全局路由注入（-Global 开关，交互确认）
# 用法：
#   powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/install-opencode.ps1
#   powershell -File skills/scripts/install-opencode.ps1 -Global        # 附带全局注入
param(
    [switch] $Global
)
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$skillsRoot = Split-Path -Parent $scriptDir
$packageRoot = Split-Path -Parent $skillsRoot

$fail = New-Object System.Collections.Generic.List[string]
function Ok([string] $m) { Write-Host ("[OK] {0}" -f $m) -ForegroundColor Green }
function Bad([string] $m) { Write-Host ("[FAIL] {0}" -f $m) -ForegroundColor Red; [void]$fail.Add($m) }

Write-Host "=== reverse-skill × opencode install check ==="

# --- 1) opencode CLI ---
$oc = Get-Command opencode -ErrorAction SilentlyContinue
if ($oc) {
    Ok "opencode CLI found: $($oc.Source)"
} else {
    # CI/服务器环境通常不装 opencode：WARN 不 FAIL（配置与 frontmatter 检查仍然严格）
    Write-Host "[WARN] opencode CLI not on PATH (skip; install from https://opencode.ai to use locally)" -ForegroundColor Yellow
}

# --- 2) opencode.jsonc ---
$configPath = Join-Path $packageRoot 'opencode.jsonc'
if (-not (Test-Path -LiteralPath $configPath)) {
    Bad 'opencode.jsonc missing at package root'
} else {
    # jsonc 支持注释：剥离 // 行注释后校验 JSON（忽略 http:// 里的 //）
    $raw = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    $stripped = [regex]::Replace($raw, '(?m)^\s*//.*$', '')
    try {
        $null = $stripped | ConvertFrom-Json
        Ok 'opencode.jsonc parses (JSON-valid after comment strip)'
    } catch {
        Bad ("opencode.jsonc invalid: {0}" -f $_.Exception.Message)
    }
    if ($raw -match '"paths"\s*:\s*\[[^\]]*"\./skills"') {
        Ok 'skills.paths points to ./skills'
    } else {
        Bad 'skills.paths missing ./skills entry'
    }
}

# --- 3) SKILL.md frontmatter 完整性 ---
$skillFiles = Get-ChildItem -Path $skillsRoot -Recurse -Filter 'SKILL.md' | Where-Object { $_.FullName -notmatch '\\config\\' }
$missingFm = New-Object System.Collections.ArrayList
foreach ($sf in $skillFiles) {
    $head = Get-Content -LiteralPath $sf.FullName -TotalCount 6 -Encoding UTF8
    $joined = $head -join "`n"
    if ($joined -notmatch '^---' -or $joined -notmatch 'name:\s*\S+' -or $joined -notmatch 'description:\s*\S+') {
        [void]$missingFm.Add($sf.FullName.Replace($skillsRoot + '\', 'skills\'))
    }
}
if ($missingFm.Count -eq 0) {
    Ok ("{0} SKILL.md all have valid frontmatter (name+description)" -f $skillFiles.Count)
} else {
    Bad ("SKILL.md missing frontmatter: {0}" -f ($missingFm -join ', '))
}

# --- 4) 可选全局注入 ---
if ($Global) {
    $ans = Read-Host '安装 opencode 全局路由注入? [Y/n]'
    if ($ans -notmatch '^(n|N|no|NO)$') {
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir 'install-global.ps1') -Client opencode
    } else {
        Write-Host '跳过全局注入。' -ForegroundColor Yellow
    }
}

# --- 5) MCP 启用指引 ---
Write-Host ''
Write-Host '=== MCP 启用指引（默认全部关闭） ===' -ForegroundColor Yellow
Write-Host '在 opencode.jsonc 中把需要的服务 enabled 改为 true（先启动对应服务）：'
Write-Host '  jshookmcp        : npx 自动拉取（stdio），改 enabled 即可'
Write-Host '  burpsuite        : Burp 扩展装好后监听 9876'
Write-Host '  anything-analyzer: 项目目录 pnpm dev，监听 23816'
Write-Host '  idapro           : IDA 打开文件后监听 13337'
Write-Host '  ghidra           : GhidraMCP 插件装好后监听 8765'
Write-Host ''
Write-Host '=== 完成后 ===' -ForegroundColor Yellow
Write-Host '重启 opencode 使配置生效；skills/ 下 42 个技能将按需触发。'
if ($fail.Count -gt 0) {
    Write-Host ("检查未通过: {0} 项" -f $fail.Count) -ForegroundColor Red
    exit 1
}
Write-Host 'ALL CHECKS PASSED' -ForegroundColor Green
exit 0
