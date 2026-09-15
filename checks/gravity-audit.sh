#!/usr/bin/env bash
# gravity-audit.sh — Engineering Gravity 条目中"机器能守"子集的存量扫描
#
# 用法:   checks/gravity-audit.sh [目标目录]     # 默认当前目录
# 豁免:   命中行(或配方检查的文件)内写 gravity-ok: 理由  即跳过
# 退出码: 有 ERROR 命中时非零, 适合做 CI gate; WARN/INFO 不阻断
# 范围:   这里只收录可低误报 grep 的条目; 标 [人审项] 的经验仍靠 review 对照 lessons/
#
# 兼容 macOS bash 3.2 / BSD grep。

set -u

TARGET="${1:-.}"
ERRORS=0
WARNS=0
INFOS=0

EX=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist
    --exclude-dir=build --exclude-dir=.next --exclude-dir=coverage
    --exclude-dir=out --exclude-dir=.turbo)

# scan <LEVEL> <id> <ERE 模式> <逗号分隔扩展名> <消息 (含 lessons 章节与来源哈希)>
scan() {
  local level="$1" id="$2" pattern="$3" includes="$4" msg="$5"
  local inc=() e hits n
  local OIFS="$IFS"; IFS=','
  for e in $includes; do inc+=("--include=*.$e"); done
  IFS="$OIFS"
  hits=$(grep -RInE "${EX[@]}" "${inc[@]}" "$pattern" "$TARGET" 2>/dev/null | grep -v 'gravity-ok' || true)
  [ -z "$hits" ] && return 0
  n=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
  echo ""
  echo "[$level] $id ($n 处) — $msg"
  printf '%s\n' "$hits" | head -15 | sed 's/^/    /'
  [ "$n" -gt 15 ] && echo "    ... 其余 $((n - 15)) 处省略"
  case "$level" in
    ERROR) ERRORS=$((ERRORS + n)) ;;
    WARN)  WARNS=$((WARNS + n)) ;;
    *)     INFOS=$((INFOS + n)) ;;
  esac
}

# pair_scan <LEVEL> <id> <主模式> <同文件次模式> <扩展名> <消息>
# 配方型检查: 两个特征出现在同一文件即命中 (文件级)。
pair_scan() {
  local level="$1" id="$2" p1="$3" p2="$4" ext="$5" msg="$6"
  local files f bad="" n=0
  files=$(grep -RIlE "${EX[@]}" --include="*.$ext" "$p1" "$TARGET" 2>/dev/null || true)
  [ -z "$files" ] && return 0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    grep -q 'gravity-ok' "$f" && continue
    if grep -qE "$p2" "$f"; then bad="$bad    $f"$'\n'; n=$((n + 1)); fi
  done <<EOF
$files
EOF
  [ "$n" -eq 0 ] && return 0
  echo ""
  echo "[$level] $id ($n 个文件) — $msg"
  printf '%s' "$bad"
  case "$level" in
    ERROR) ERRORS=$((ERRORS + n)) ;;
    WARN)  WARNS=$((WARNS + n)) ;;
    *)     INFOS=$((INFOS + n)) ;;
  esac
}

# anti_pair_scan: 有 p1 但同文件缺 p2 即命中。
anti_pair_scan() {
  local level="$1" id="$2" p1="$3" p2="$4" ext="$5" msg="$6"
  local files f bad="" n=0
  files=$(grep -RIlE "${EX[@]}" --include="*.$ext" "$p1" "$TARGET" 2>/dev/null || true)
  [ -z "$files" ] && return 0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    grep -q 'gravity-ok' "$f" && continue
    if ! grep -qE "$p2" "$f"; then bad="$bad    $f"$'\n'; n=$((n + 1)); fi
  done <<EOF
$files
EOF
  [ "$n" -eq 0 ] && return 0
  echo ""
  echo "[$level] $id ($n 个文件) — $msg"
  printf '%s' "$bad"
  case "$level" in
    ERROR) ERRORS=$((ERRORS + n)) ;;
    WARN)  WARNS=$((WARNS + n)) ;;
    *)     INFOS=$((INFOS + n)) ;;
  esac
}

echo "== gravity-audit: $TARGET =="

# ---- 逻辑陷阱 ----
scan ERROR includes-empty-string \
  "includes\(''\)|includes\(\"\"\)" ts,tsx,js,jsx \
  "includes('') 恒真, 过滤条件空串要先短路 (2.2, B 7d996cb)"

scan WARN jsx-length-and \
  "\{[^{}]*\.length &&" tsx,jsx \
  "JSX 里 {arr.length && ...} 在 0 时渲染字面 0 — 用 arr.length > 0 (1.9, B f4a6ab7)"

scan WARN empty-catch \
  "catch\s*(\([^)]*\))?\s*\{\s*\}" ts,tsx,js,jsx \
  "空 catch 静默吞错, 失败必须可见 (1.1); 也会吞框架控制流异常如 NEXT_REDIRECT (2.6, B f0b41f2)"

# ---- XSS 面 ----
scan WARN raw-innerhtml \
  "\.innerHTML\s*=" ts,tsx,js,jsx \
  "innerHTML 拼接是 XSS 面 — 用 textContent/DOM API (3.6, f54ce53)"

anti_pair_scan WARN unsanitized-dangerous-html \
  "dangerouslySetInnerHTML" "DOMPurify|sanitize" tsx \
  "dangerouslySetInnerHTML 无 sanitize 痕迹 — 先过 DOMPurify (3.6, B 4939965)"

# ---- CSS ----
scan WARN css-global-smooth-scroll \
  "scroll-behavior:\s*smooth" css,scss,less \
  "全局 smooth 会劫持路由回顶成慢动作, 只给页内锚点场景 (1.4, B 639d48d)"

scan WARN css-text-transform-case \
  "text-transform:\s*(uppercase|capitalize)" css,scss,less,tsx \
  "展示层擅自改写品牌/人名大小写 (1.7, B 49fa974)"

# ---- React 列表 key ----
scan WARN key-from-index \
  "key=\{(index|idx|i)\}" tsx,jsx \
  "index 作 key, 删行/重排会串显 — 用稳定业务键 (1.5, 77e975c)"

scan WARN rowkey-from-index \
  "rowKey=\{[^}]*(index|idx)" tsx,jsx \
  "rowKey 用 index, 删行串显 (1.5, 77e975c)"

# ---- antd 配方 ----
pair_scan WARN antd-destroyonhidden-setfields \
  "destroyOnHidden|destroyOnClose" "setFieldsValue" tsx \
  "destroyOnHidden + setFieldsValue 同文件: 打开前写值会写进未挂载实例全丢 — 核对已用 key + initialValues (2.1, b0746c7)"

anti_pair_scan WARN antd-showsearch-no-filterprop \
  "showSearch" "optionFilterProp|filterOption" tsx \
  "showSearch 且未配 optionFilterProp: value 是数字 id 时输文字全滤空 (2.1, a505791)"

# ---- e2e / 测试 ----
scan ERROR e2e-networkidle \
  "networkidle" ts,js \
  "networkidle 在 SSE/长连接页必超时 — 用 selector/content waits (5.4, B d9fa440)"

scan WARN e2e-fixed-sleep \
  "waitForTimeout\(" ts,js \
  "固定 sleep 是 flaky 源 — 改条件等待 (5.3)"

# ---- ORM ----
scan INFO prisma-findfirst \
  "findFirst\(" ts \
  "无排序 findFirst 多行命中时结果非确定 — 逐处确认唯一 where 或显式 orderBy (3.3, B 91c7f69)"

# ---- 可选: SQL ANSI 纪律 (换库留后路的项目才开) ----
if [ "${GRAVITY_SQL_ANSI:-0}" = "1" ]; then
  scan ERROR sql-pg-dialect \
    "ILIKE|ON CONFLICT|RETURNING|::[a-z]+|jsonb" ts,sql \
    "PG 方言 (SQL 可移植纪律, 3.4)"
fi

echo ""
echo "== 汇总: ERROR $ERRORS / WARN $WARNS / INFO $INFOS =="
echo "   命中要么改对, 要么行内加 'gravity-ok: 理由'; 无豁免理由的 ERROR = 违规。"
echo "   本脚本只覆盖机器能守的子集, [人审项] 经验见 lessons/。"

[ "$ERRORS" -gt 0 ] && exit 1
exit 0
