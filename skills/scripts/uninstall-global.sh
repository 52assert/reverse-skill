#!/usr/bin/env bash
# reverse-skill 全局路由注入卸载（Linux / macOS 版）
# 用法: bash skills/scripts/uninstall-global.sh [claude|opencode|all]
set -u
CLIENT="${1:-all}"

if [[ "$CLIENT" == "claude" || "$CLIENT" == "all" ]]; then
  if [[ -f "$HOME/.claude/reverse-skill-routing.md" ]]; then
    rm -f "$HOME/.claude/reverse-skill-routing.md"
    echo "OK: removed $HOME/.claude/reverse-skill-routing.md"
  else
    echo "claude: nothing to remove (file absent)"
  fi
fi

if [[ "$CLIENT" == "opencode" || "$CLIENT" == "all" ]]; then
  OC_DIR="$HOME/.config/opencode"
  OC_AGENTS="$OC_DIR/AGENTS.md"
  OC_CONTENT="$OC_DIR/reverse-skill-routing.md"
  if [[ -f "$OC_CONTENT" ]]; then
    rm -f "$OC_CONTENT"
    echo "OK: removed $OC_CONTENT"
  fi
  if [[ -f "$OC_AGENTS" ]]; then
    # 移除 marker 块（含前置空行）
    sed -i -E '/<!-- reverse-skill:start -->/,/<!-- reverse-skill:end -->/d; /^[[:space:]]*$/N;/^\n$/D' "$OC_AGENTS" 2>/dev/null || \
    perl -0pi -e 's/\s*<!-- reverse-skill:start -->.*?<!-- reverse-skill:end -->\n?//s' "$OC_AGENTS"
    echo "OK: removed marker block from $OC_AGENTS"
  else
    echo "opencode: AGENTS.md absent (nothing to remove)"
  fi
fi

echo "=== 卸载完成 ==="
