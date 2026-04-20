#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  generate-audio.sh
#  Reads words.js and generates audio for:
#    1. Each spelling word
#    2. All encouragement phrases (correct + wrong answers)
#    3. The "Got it this time!" second-attempt phrase
#
#  Run this from the spelling-challenge folder each week after
#  updating words.js. Encouragement files only generate once
#  (they never change) and are skipped on subsequent runs.
#
#  Usage:
#    chmod +x generate-audio.sh   (first time only)
#    ./generate-audio.sh
#
#  Requirements:
#    - macOS (uses the built-in `say` command)
#    - ffmpeg — install with: brew install ffmpeg
#      Without ffmpeg the script outputs .aiff files which also
#      work in Safari/Chrome.
# ─────────────────────────────────────────────────────────────

VOICE="Serena"    # Change to any voice from: say -v ?
RATE=160          # Words per minute (175 = normal, lower = clearer)
WORDS_FILE="words.js"
AUDIO_DIR="audio"

# ── Encouragement phrases ─────────────────────────────────────
# These must exactly match PROMPTS_RIGHT and PROMPTS_WRONG
# in index.html, minus the emojis.
PROMPTS_RIGHT=(
  "Woohoo! Correct!"
  "Brilliant spelling!"
  "You got it!"
  "Fantastic, Ludovica!"
  "YES! Perfect!"
  "Superstar speller!"
  "Incredible!"
  "Nailed it!"
  "Got it this time!"
)
PROMPTS_WRONG=(
  "Not quite, listen again!"
  "Almost! Try again!"
  "Keep trying!"
  "You are so close!"
  "Listen carefully!"
)
# ─────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "🔊 Spelling Challenge — Audio Generator"
echo "────────────────────────────────────────"

if ! command -v say &> /dev/null; then
    echo -e "${RED}❌  'say' not found. This script requires macOS.${NC}"; exit 1
fi
if ! say -v ? | grep -qi "^${VOICE}"; then
    echo -e "${YELLOW}⚠️  Voice '${VOICE}' not found. Available English voices:${NC}"
    say -v ? | grep -i "en_"; exit 1
fi

HAS_FFMPEG=false
command -v ffmpeg &> /dev/null && HAS_FFMPEG=true

mkdir -p "$AUDIO_DIR/encouragement"

COUNT=0; SKIPPED=0

# ── Helper: generate one file ─────────────────────────────────
generate() {
  local TEXT="$1"
  local OUTPATH="$2"
  local SPEAK_RATE="${3:-$RATE}"

  if [ -f "${OUTPATH}.mp3" ] || [ -f "${OUTPATH}.aiff" ]; then
    echo -e "  ${YELLOW}⏭  Skipped:${NC} ${TEXT}"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if $HAS_FFMPEG; then
    local TEMP="/tmp/spelling_$$.aiff"
    say -v "$VOICE" -r "$SPEAK_RATE" -o "$TEMP" "$TEXT"
    ffmpeg -i "$TEMP" -codec:a libmp3lame -qscale:a 2 "${OUTPATH}.mp3" -y -loglevel quiet
    rm -f "$TEMP"
    echo -e "  ${GREEN}✅  Generated:${NC} ${TEXT}"
  else
    say -v "$VOICE" -r "$SPEAK_RATE" -o "${OUTPATH}.aiff" "$TEXT"
    echo -e "  ${GREEN}✅  Generated (aiff):${NC} ${TEXT}"
  fi
  COUNT=$((COUNT + 1))
}

# ── 1. Spelling words ─────────────────────────────────────────
echo ""
echo "📝 Spelling words:"
WORDS=$(grep -oE "word: *['\"][a-zA-Z '-]+['\"]" "$WORDS_FILE" \
        | grep -oE "['\"][a-zA-Z '-]+['\"]" \
        | tr -d "'" | tr -d '"' | tr '[:upper:]' '[:lower:]')

if [ -z "$WORDS" ]; then
    echo -e "${RED}❌  No words found in ${WORDS_FILE}.${NC}"; exit 1
fi

while IFS= read -r WORD; do
  [ -z "$WORD" ] && continue
  FILENAME=$(echo "$WORD" | tr ' ' '_')
  generate "$WORD" "${AUDIO_DIR}/${FILENAME}" 150
done <<< "$WORDS"

# ── 2. Encouragement — correct answers ───────────────────────
echo ""
echo "🎉 Encouragement (correct):"
for PHRASE in "${PROMPTS_RIGHT[@]}"; do
  # Filename: lowercase, strip punctuation, spaces to underscores
  FILENAME=$(echo "$PHRASE" | tr '[:upper:]' '[:lower:]' \
             | tr -d "!?'," | tr ' ' '_')
  generate "$PHRASE" "${AUDIO_DIR}/encouragement/${FILENAME}" 170
done

# ── 3. Encouragement — wrong answers ─────────────────────────
echo ""
echo "💪 Encouragement (try again):"
for PHRASE in "${PROMPTS_WRONG[@]}"; do
  FILENAME=$(echo "$PHRASE" | tr '[:upper:]' '[:lower:]' \
             | tr -d "!?'," | tr ' ' '_')
  generate "$PHRASE" "${AUDIO_DIR}/encouragement/${FILENAME}" 165
done

echo ""
echo "────────────────────────────────────────"
echo -e "${GREEN}✅  Done!${NC}  Generated: ${COUNT}  |  Skipped: ${SKIPPED}"
echo ""
echo "Audio folder structure:"
echo "  audio/"
echo "  ├── elephant.mp3        ← spelling words"
echo "  └── encouragement/"
echo "      ├── woohoo_correct.mp3"
echo "      └── ..."
echo ""
echo "Commit everything with:  git add . && git commit -m 'Week of $(date +%d\ %b)' && git push"
echo ""
