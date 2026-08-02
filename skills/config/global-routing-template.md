# reverse-skill 全局路由规则（独立注入文件）

> 本文件由 `install-global.ps1` 生成，**独立存放**，不修改你的 `CLAUDE.md` / `AGENTS.md` 原文。
> 卸载：运行 `uninstall-global.ps1`（或直接删除本文件）即可完全移除，零残留。
> `<SKILL_ROOT>` 已替换为实际安装路径：<SKILL_ROOT>

---

## 触发关键词（中英双语 / Trigger Keywords）

以下任意关键词命中时，将任务路由到 reverse-skill 技能包：

- APK, Android reverse, 反编译, jadx, apktool, Frida, Hook
- binary analysis, 二进制分析, IDA, radare2, r2, disassembly, 反汇编, reverse engineering, 逆向工程
- frontend signature, 前端签名, JS reverse, JS 逆向, jshookmcp, CDP, SourceMap
- packet capture, 抓包, HTTP capture, anything-analyzer
- CTF, Pwn, web pentest, Web 渗透, exploit, 漏洞利用, privilege escalation, 提权
- penetration testing, 渗透测试, red team, 红队, Nmap, Nuclei, SQLMap, FFUF, Hashcat, Metasploit, BurpSuite
- SRC, Bug Bounty, WAF bypass, IDOR, 越权
- LLM security, Prompt injection, Agent security, garak, PyRIT
- EDR bypass, 免杀, AV bypass, direct syscall
- firmware, IoT, binwalk, embedded
- internal network, 内网渗透, lateral movement, domain penetration, BloodHound
- API security, 供应链安全, supply chain, YARA, malware analysis, 恶意软件分析
- iOS reverse, 游戏逆向, game reverse, anti-cheat, pwn, ROP, kernel pwn
- .NET, C#, dnSpy, de4dot, 脱混淆, dotnet
- 证书校验, certificate pinning, root 检测, smali, 重打包

## 触发后执行（精简版 / Post-Trigger）

```
0. 读 <SKILL_ROOT>/skills/field-journal/precedent-auth.md（授权预声明）
1. 读 <SKILL_ROOT>/skills/MASTER-ROUTING.md 或运行 master-route.ps1 -Hint "<任务>" 定 PRIMARY
2. 歧义时读 <SKILL_ROOT>/skills/routing.md 全矩阵
3. case-init.ps1 / scope.md（ops/scope-contract.md）——auth.status=granted + network_profile 就绪前禁止对目标 ACT
4. ACT：打开 PRIMARY 的 SKILL.md；工具路径只认 tool-index.md；缺工具用 bootstrap-reverse 脚本安装
5. 结论走 Evidence→Finding→Path；任务结束写 field-journal + docs-generator 报告
```

## 核心规则（精简版 / Core Rules）

- **必须**：任何操作前读 precedent-auth.md
- **必须**：case scope（case-init / ops/scope-contract）就绪前禁止对目标 ACT；auth.status=granted + network_profile 齐备
- **必须**：缺工具 → bootstrap 自动安装，**禁止猜路径**（tool-index.md 为准）
- **必须**：完成后执行 Completion Checklist（报告 / 图表 / journal / 索引更新）
- **注意**：本包面向授权范围内的逆向/渗透工作（自有系统 / SRC 授权 / CTF 靶场）。涉及真实第三方目标时，请自行确认法律与授权边界。

## 卸载

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<SKILL_ROOT>/skills/scripts/uninstall-global.ps1"
```

```bash
bash <SKILL_ROOT>/skills/scripts/uninstall-global.sh
```
