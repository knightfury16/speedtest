#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  Internet Speed Checker — no installs needed
#  Uses only: curl, awk, dd  (pre-installed everywhere)
# ─────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Handle Arguments ──────────────────────────────────
# Default to Cloudflare
DL_URL="https://speed.cloudflare.com/__down?bytes=10000000"
SERVER_NAME="Cloudflare (Anycast)"

# Check if "global" was passed as an argument
if [[ "$1" == "global" ]]; then
  DL_URL="http://speedtest.tele2.net/10MB.zip"
  SERVER_NAME="Tele2 (Sweden)"
fi

hr() { printf '%.0s─' {1..46}; echo; }

# ── Argument Handling & Help ──────────────────────────
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo -e "${BOLD}Usage:${RESET} ./speedtest.sh [option]"
  echo -e "\n${BOLD}Options:${RESET}"
  echo -e "  (none)   Default (Cloudflare / httpbin)"
  echo -e "  global   Tests against Tele2 (Sweden) infrastructure"
  echo -e "  -h       Show this help message"
  exit 0
fi

human_speed() {
  awk -v b="$1" 'BEGIN{
    if      (b >= 1e9) printf "%.2f Gbps", b/1e9
    else if (b >= 1e6) printf "%.2f Mbps", b/1e6
    else if (b >= 1e3) printf "%.2f Kbps", b/1e3
    else               printf "%.0f bps",  b
  }'
}

echo ""
echo -e "${BOLD}${CYAN}  🌐  Internet Speed Test${RESET}"
hr

# ── Latency ──────────────────────────────────────────
echo -e "\n${YELLOW}▶ Measuring latency...${RESET}"
LATENCY=$(curl -o /dev/null -s -w "%{time_connect}" https://www.google.com 2>/dev/null)
if [[ -n "$LATENCY" ]]; then
  MS=$(awk "BEGIN{printf \"%.0f\", $LATENCY * 1000}")
  echo -e "  Ping (connect):  ${GREEN}${MS} ms${RESET}"
else
  MS="N/A"
  echo -e "  Ping: unreachable"
fi

# ── Download ─────────────────────────────────────────
echo -e "\n${YELLOW}▶ Testing download (~10 MB) from ${SERVER_NAME}.${RESET}"
READ=$(curl -L --max-time 30 -o /dev/null -s \
  -w "%{size_download} %{time_total}" \
  "${DL_URL}" 2>/dev/null)

DL_BYTES=$(echo "$READ" | awk '{print $1}')
DL_TIME=$(echo  "$READ" | awk '{print $2}')

if awk "BEGIN{exit !($DL_BYTES > 0 && $DL_TIME > 0)}"; then
  DL_BITS=$(awk "BEGIN{print ($DL_BYTES * 8) / $DL_TIME}")
  DL_SPEED=$(human_speed "$DL_BITS")
  DL_MB=$(awk "BEGIN{printf \"%.2f\", $DL_BYTES/1048576}")
  echo -e "  Download speed:  ${GREEN}${DL_SPEED}${RESET}  (${DL_MB} MB in ${DL_TIME}s)"
else
  DL_SPEED="N/A"
  echo -e "  Download failed — check your connection"
fi

# ── Upload ────────────────────────────────────────────
echo -e "\n${YELLOW}▶ Testing upload (~2 MB)...${RESET}"
TMP=$(mktemp)
dd if=/dev/urandom of="$TMP" bs=1024 count=2048 2>/dev/null

UL_READ=$(curl -s --max-time 20 -o /dev/null \
  -w "%{size_upload} %{time_total}" \
  -X POST "https://httpbin.org/post" \
  -F "data=@${TMP}" 2>/dev/null)
rm -f "$TMP"

UL_BYTES=$(echo "$UL_READ" | awk '{print $1}')
UL_TIME=$(echo  "$UL_READ" | awk '{print $2}')

if awk "BEGIN{exit !($UL_BYTES > 0 && $UL_TIME > 0)}"; then
  UL_BITS=$(awk "BEGIN{print ($UL_BYTES * 8) / $UL_TIME}")
  UL_SPEED=$(human_speed "$UL_BITS")
  UL_MB=$(awk "BEGIN{printf \"%.2f\", $UL_BYTES/1048576}")
  echo -e "  Upload speed:    ${GREEN}${UL_SPEED}${RESET}  (${UL_MB} MB in ${UL_TIME}s)"
else
  UL_SPEED="N/A"
  echo -e "  Upload failed (httpbin may be unavailable)"
fi

# ── Public IP & location ──────────────────────────────
echo -e "\n${YELLOW}▶ Fetching IP info...${RESET}"
GEO=$(curl -s --max-time 5 "https://ipinfo.io/json" 2>/dev/null)
PUBLIC_IP=$(echo "$GEO" | awk -F'"' '/"ip"/{print $4}')
CITY=$(echo     "$GEO" | awk -F'"' '/"city"/{print $4}')
COUNTRY=$(echo  "$GEO" | awk -F'"' '/"country"/{print $4}')
ISP=$(echo      "$GEO" | awk -F'"' '/"org"/{print $4}')

echo -e "  IP: ${GREEN}${PUBLIC_IP:-N/A}${RESET}  •  ${CITY:-?}, ${COUNTRY:-?}  •  ${ISP:-?}"

# ── Summary ───────────────────────────────────────────
echo ""
hr
echo -e "${BOLD}  📊 Results${RESET}"
hr
printf "  %-18s ${GREEN}%s${RESET}\n" "Ping:"     "${MS} ms"
printf "  %-18s ${GREEN}%s${RESET}\n" "Download:" "${DL_SPEED}"
printf "  %-18s ${GREEN}%s${RESET}\n" "Upload:"   "${UL_SPEED}"
printf "  %-18s ${GREEN}%s${RESET}\n" "Public IP:" "${PUBLIC_IP:-N/A}"
printf "  %-18s %s\n"                 "Location:" "${CITY:-?}, ${COUNTRY:-?}"
hr
echo ""
