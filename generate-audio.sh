#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  generate-audio.sh
#  Reads words.js and generates audio for:
#    1. Each spelling word
#    2. All encouragement phrases (correct + wrong answers)
#
#  PRONUNCIATION DECOUPLING
#  Encouragement phrases use the format:  "DISPLAY TEXT|SPOKEN TEXT"
#  The part before | matches index.html and sets the filename.
#  The part after | is what Serena actually says — edit this to
#  fix pronunciation without breaking anything in the game.
#  If there is no |, the same text is used for both.
#
#  Example — fix "Ludovica" pronunciation:
#    "Fantastic, Ludovica!|Fantastic, Loo-do-VEE-ka!"
#
#  To update a pronunciation:
#    1. Edit the spoken part (after |) in this script
#    2. Delete the old file:  rm audio/encouragement/fantastic_ludovica.mp3
#    3. Re-run:               ./generate-audio.sh
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

VOICE="Serena"    # Run: say -v ? to list all available voices
RATE=160          # Words per minute (175 = normal, lower = clearer)
WORDS_FILE="words.js"
AUDIO_DIR="audio"

# ── Encouragement phrases ─────────────────────────────────────
# Format: "FILENAME_TEXT|SPOKEN_TEXT"
# FILENAME_TEXT must match PROMPTS_RIGHT / PROMPTS_WRONG in index.html exactly.
# Edit only the SPOKEN_TEXT (after |) to adjust pronunciation.
PROMPTS_RIGHT=(
  "Woohoo! Correct!|Woohoo! Correct!"
  "Brilliant spelling!|Brilliant spelling!"
  "You got it!|You got it!"
  "Fantastic, Ludovica!|Fantastic, Loo-do-VEE-ka!"
  "YES! Perfect!|YES! Perfect!"
  "Superstar speller!|Superstar speller!"
  "Incredible!|Incredible!"
  "Nailed it!|Nailed it!"
  "Got it this time!|Got it this time!"
)
PROMPTS_WRONG=(
  "Not quite, listen again!|Not quite, listen again!"
  "Almost! Try again!|Almost! Try again!"
  "Keep trying!|Keep trying!"
  "You are so close!|You are so close!"
  "Listen carefully!|Listen carefully!"
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
    say -v ? | grep -i "en_"
    echo ""
    echo "Update the VOICE= line at the top of this script and try again."
    exit 1
fi

HAS_FFMPEG=false
command -v ffmpeg &> /dev/null && HAS_FFMPEG=true

mkdir -p "$AUDIO_DIR/encouragement"

COUNT=0; SKIPPED=0

# ── Helper: generate one audio file ──────────────────────────
generate() {
  local SPOKEN="$1"
  local OUTPATH="$2"
  local SPEAK_RATE="${3:-$RATE}"

  if [ -f "${OUTPATH}.mp3" ] || [ -f "${OUTPATH}.aiff" ]; then
    echo -e "  ${YELLOW}⏭  Skipped (exists):${NC} ${SPOKEN}"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if $HAS_FFMPEG; then
    local TEMP="/tmp/spelling_$$.aiff"
    say -v "$VOICE" -r "$SPEAK_RATE" -o "$TEMP" "$SPOKEN"
    ffmpeg -i "$TEMP" -codec:a libmp3lame -qscale:a 2 "${OUTPATH}.mp3" \
           -y -loglevel quiet
    rm -f "$TEMP"
    echo -e "  ${GREEN}✅  Generated:${NC} ${SPOKEN}"
  else
    say -v "$VOICE" -r "$SPEAK_RATE" -o "${OUTPATH}.aiff" "$SPOKEN"
    echo -e "  ${GREEN}✅  Generated (aiff):${NC} ${SPOKEN} ${YELLOW}← install ffmpeg for mp3${NC}"
  fi
  COUNT=$((COUNT + 1))
}

# ── Helper: process a "DISPLAY|SPOKEN" phrase entry ──────────
process_phrase() {
  local ENTRY="$1"
  local DIR="$2"
  local RATE_OVERRIDE="$3"

  local DISPLAY_TEXT="${ENTRY%%|*}"
  local SPOKEN_TEXT="${ENTRY##*|}"

  local FILENAME
  FILENAME=$(echo "$DISPLAY_TEXT" | tr '[:upper:]' '[:lower:]' \
             | tr -d "!?'," | tr ' ' '_')

  generate "$SPOKEN_TEXT" "${DIR}/${FILENAME}" "$RATE_OVERRIDE"
}

# ── 1. Spelling words ─────────────────────────────────────────
echo ""
echo "📝 Spelling words:"

WORDS=$(grep -oE "word: *['\"][a-zA-Z '-]+['\"]" "$WORDS_FILE" \
        | grep -oE "['\"][a-zA-Z '-]+['\"]" \
        | tr -d "'" | tr -d '"' | tr '[:upper:]' '[:lower:]')

if [ -z "$WORDS" ]; then
    echo -e "${RED}❌  No words found in ${WORDS_FILE}.${NC}"
    echo "    Make sure entries look like:  word: \"elephant\""
    exit 1
fi

while IFS= read -r WORD; do
  [ -z "$WORD" ] && continue
  FILENAME=$(echo "$WORD" | tr ' ' '_')
  generate "$WORD" "${AUDIO_DIR}/${FILENAME}" 150
done <<< "$WORDS"

# ── 2. Encouragement — correct answers ───────────────────────
echo ""
echo "🎉 Encouragement (correct):"
for ENTRY in "${PROMPTS_RIGHT[@]}"; do
  process_phrase "$ENTRY" "${AUDIO_DIR}/encouragement" 170
done

# ── 3. Encouragement — wrong answers ─────────────────────────
echo ""
echo "💪 Encouragement (try again):"
for ENTRY in "${PROMPTS_WRONG[@]}"; do
  process_phrase "$ENTRY" "${AUDIO_DIR}/encouragement" 165
done

echo ""
echo "────────────────────────────────────────"
echo -e "${GREEN}✅  Done!${NC}  Generated: ${COUNT}  |  Skipped: ${SKIPPED}"
echo ""
echo "Folder structure:"
echo "  audio/"
echo "  ├── elephant.mp3              ← spelling words (regenerated weekly)"
echo "  └── encouragement/"
echo "      ├── woohoo_correct.mp3    ← generated once, never changes"
echo "      └── ..."
echo ""
echo "Commit with:"
echo "  git add . && git commit -m 'Week of $(date +%d\ %b)' && git push"
echo ""
