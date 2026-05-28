#!/bin/sh
# entrypoint.sh — generate ices0 XML config from STREAM_* env vars and exec ices0
set -eu

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
STREAM_CONFIG="${STREAM_CONFIG:-/ices/ices.conf}"
STREAM_PLAYLIST="${STREAM_PLAYLIST:-/ices/playlist.txt}"
STREAM_MEDIA_FOLDER="${STREAM_MEDIA_FOLDER:-/media}"
STREAM_HOST="${STREAM_HOST:-localhost}"
STREAM_PORT="${STREAM_PORT:-8000}"
STREAM_PASSWORD="${STREAM_PASSWORD:-hackme}"
STREAM_PROTOCOL="${STREAM_PROTOCOL:-http}"
STREAM_MOUNTPOINT="${STREAM_MOUNTPOINT:-/stream}"
STREAM_NAME="${STREAM_NAME:-ices0 Stream}"
STREAM_GENRE="${STREAM_GENRE:-Various}"
STREAM_DESCRIPTION="${STREAM_DESCRIPTION:-ices0 audio stream}"
STREAM_URL="${STREAM_URL:-}"
STREAM_PRIVATE="${STREAM_PRIVATE:-0}"
STREAM_BITRATE="${STREAM_BITRATE:-320}"
STREAM_REENCODED="${STREAM_REENCODED:-0}"
STREAM_REENCODED_CHANNELS="${STREAM_REENCODED_CHANNELS:-2}"
STREAM_REENCODED_SAMPLERATE="${STREAM_REENCODED_SAMPLERATE:-44100}"
STREAM_RANDOMIZE="${STREAM_RANDOMIZE:-0}"
STREAM_CROSSFADE="${STREAM_CROSSFADE:-2}"
STREAM_MIN_CROSSFADE="${STREAM_MIN_CROSSFADE:-0}"
STREAM_CROSS_MIX="${STREAM_CROSS_MIX:-0}"
STREAM_VERBOSE="${STREAM_VERBOSE:-0}"
STREAM_BACKGROUND="${STREAM_BACKGROUND:-0}"
STREAM_PLAYLIST_TYPE="${STREAM_PLAYLIST_TYPE:-builtin}"
STREAM_INTERPRETER_MODULE="${STREAM_INTERPRETER_MODULE:-ices}"

# ---------------------------------------------------------------------------
# Derived values
# ---------------------------------------------------------------------------
# STREAM_PRIVATE=1 means unlisted (Public=0); STREAM_PRIVATE=0 means listed (Public=1)
if [ "${STREAM_PRIVATE}" = "1" ]; then
    _PUBLIC=0
else
    _PUBLIC=1
fi

# ---------------------------------------------------------------------------
# Playlist
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "${STREAM_CONFIG}")" "$(dirname "${STREAM_PLAYLIST}")"

if [ "${STREAM_PLAYLIST_TYPE}" = "builtin" ] && [ -d "${STREAM_MEDIA_FOLDER}" ]; then
    find "${STREAM_MEDIA_FOLDER}" \( \
        -name '*.mp3' -o \
        -name '*.ogg' -o \
        -name '*.flac' -o \
        -name '*.m4a' -o \
        -name '*.aac' \
    \) | sort > "${STREAM_PLAYLIST}"
    _COUNT=$(wc -l < "${STREAM_PLAYLIST}" | tr -d ' ')
    echo "ices0: playlist generated — ${_COUNT} tracks from ${STREAM_MEDIA_FOLDER}"
fi

# ---------------------------------------------------------------------------
# XML config
# ---------------------------------------------------------------------------
cat > "${STREAM_CONFIG}" <<EOF
<?xml version="1.0"?>
<ices:Configuration xmlns:ices="http://www.icecast.org/projects/ices">
  <Playlist>
    <Randomize>${STREAM_RANDOMIZE}</Randomize>
    <Type>${STREAM_PLAYLIST_TYPE}</Type>
    <File>${STREAM_PLAYLIST}</File>
    <Crossfade>${STREAM_CROSSFADE}</Crossfade>
    <MinCrossfade>${STREAM_MIN_CROSSFADE}</MinCrossfade>
    <CrossMix>${STREAM_CROSS_MIX}</CrossMix>
    <Module>${STREAM_INTERPRETER_MODULE}</Module>
  </Playlist>
  <Execution>
    <Background>${STREAM_BACKGROUND}</Background>
    <Verbose>${STREAM_VERBOSE}</Verbose>
    <Timestamp>0</Timestamp>
    <BaseDirectory>/tmp</BaseDirectory>
  </Execution>
  <Stream>
    <Server>
      <Hostname>${STREAM_HOST}</Hostname>
      <Port>${STREAM_PORT}</Port>
      <Password>${STREAM_PASSWORD}</Password>
      <Protocol>${STREAM_PROTOCOL}</Protocol>
    </Server>
    <Mountpoint>${STREAM_MOUNTPOINT}</Mountpoint>
    <Name>${STREAM_NAME}</Name>
    <Genre>${STREAM_GENRE}</Genre>
    <Description>${STREAM_DESCRIPTION}</Description>
    <URL>${STREAM_URL}</URL>
    <Public>${_PUBLIC}</Public>
    <Encode>
      <Reencode>${STREAM_REENCODED}</Reencode>
      <Channels>${STREAM_REENCODED_CHANNELS}</Channels>
      <Samplerate>${STREAM_REENCODED_SAMPLERATE}</Samplerate>
      <Bitrate>${STREAM_BITRATE}</Bitrate>
    </Encode>
  </Stream>
</ices:Configuration>
EOF

echo "ices0: config written to ${STREAM_CONFIG}"
echo "ices0: connecting to ${STREAM_PROTOCOL}://${STREAM_HOST}:${STREAM_PORT}${STREAM_MOUNTPOINT}"

exec /usr/local/bin/ices0 -c "${STREAM_CONFIG}"
