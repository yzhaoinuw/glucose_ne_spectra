#!/usr/bin/env bash
# fetch_missing_tev.sh
#
# Copies the raw TDT files (.tev, some .tsq) that are missing from the glucose
# NE project on BlueHive, from Rebeka's folder on the CTN drive.
#
# Run it from Git Bash (comes with Git for Windows) or WSL on the CTN machine:
#
#   bash fetch_missing_tev.sh -n    # dry run: find the files, check BlueHive, copy nothing
#   bash fetch_missing_tev.sh       # copy for real
#
# Safe to re-run. A file is only given its final name on BlueHive after its
# checksum matches the source, so anything already there is complete and is
# skipped. A copy cut off midway is left as *.part and redone on the next run.
#
# Options:
#   -n         dry run
#   -s DIR     source folder (default: J:\CTN\NedergaardLAB\Personal_folders\Rebeka\Glucose)
#   -u USER    BlueHive user name (default: vuntiet2)
#   -h         show this help

set -uo pipefail

BH_USER=vuntiet2
BH_HOST=bluehive.circ.rochester.edu
PROJECT=/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Yue/GlucoseProjectFiberNE
DEST=$PROJECT/recovered_raw
TANK_PREFIX=EliseFiber1-240321-092235_Subject1-
WIN_SRC='J:\CTN\NedergaardLAB\Personal_folders\Rebeka\Glucose'
MAX_TRIES=3

# BlueHive session folder : recording date-time stamp : missing file types
SESSIONS=(
  "Subject1-240323-171604_evening:240323-171604:tev"
  "Subject2-240321-093251_210324:240321-093251:tev"
  "Subject3-240322-172818_evening:240322-172818:tev"
  "Subject33-240324-093611_morning:240324-093611:tev"
  "Subject33-240324-174256_evening:240324-174256:tev,tsq"
  "Subject5-240326-090337_morning:240326-090337:tev,tsq"
  "Subject5-240326-170315_evening:240326-170315:tev,tsq"
)

DRY=0
SRC=""
while getopts "ns:u:h" opt; do
  case $opt in
    n) DRY=1 ;;
    s) SRC=$OPTARG ;;
    u) BH_USER=$OPTARG ;;
    h) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) exit 2 ;;
  esac
done
TARGET=$BH_USER@$BH_HOST

LOG="fetch_missing_tev_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

say()  { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*"; exit 1; }

# ---------------------------------------------------------------- setup ----

for tool in ssh scp sha256sum find stat; do
  command -v "$tool" >/dev/null || die "'$tool' not found. Run this from Git Bash or WSL."
done

# Turn the Windows path into one this shell understands.
to_unix_path() {
  if command -v cygpath >/dev/null; then cygpath -u "$1"           # Git Bash / Cygwin
  elif command -v wslpath >/dev/null; then wslpath -u "$1"         # WSL
  else printf '%s\n' "$1"
  fi
}
if [ -z "$SRC" ]; then SRC=$WIN_SRC; fi
case $SRC in [A-Za-z]:\\*|[A-Za-z]:/*) SRC=$(to_unix_path "$SRC") ;; esac
if [ ! -d "$SRC" ]; then
  say "Can't open the source folder: $SRC"
  if command -v wslpath >/dev/null; then
    say "In WSL, a network drive must be mounted first:"
    say "  sudo mkdir -p /mnt/j && sudo mount -t drvfs J: /mnt/j"
  fi
  die "source folder not found"
fi

say "Source:      $SRC"
say "Destination: $TARGET:$DEST"
say "Log file:    $LOG"
[ $DRY = 1 ] && say "DRY RUN: nothing will be copied."
say ""

# Reuse one login for every ssh/scp step when the local ssh supports it
# (works in WSL; Git Bash usually can't, and then you log in at each step).
SSH_OPTS=(-o ServerAliveInterval=30 -o ServerAliveCountMax=10)
CM_OPTS=(-o "ControlPath=$HOME/.ssh/cm-glucose-%C")
mkdir -p "$HOME/.ssh"
say "Logging in to BlueHive..."
if ssh "${SSH_OPTS[@]}" "${CM_OPTS[@]}" -o ControlMaster=yes -o ControlPersist=60m -fN "$TARGET" \
   && ssh "${CM_OPTS[@]}" -O check "$TARGET" 2>/dev/null; then
  SSH_OPTS+=("${CM_OPTS[@]}")
  trap 'ssh "${CM_OPTS[@]}" -O exit "$TARGET" 2>/dev/null' EXIT
  say "Connected. That login will be reused for every step."
else
  say "Can't reuse the login on this machine; you may be asked to log in at each step."
fi
say ""

rsh() { ssh "${SSH_OPTS[@]}" "$TARGET" "$@"; }
rcp() { scp "${SSH_OPTS[@]}" "$1" "$TARGET:$2"; }
sha() { sha256sum "$1" | cut -d' ' -f1; }

# ------------------------------------------------ what's on BlueHive now ----

# Reports, per session, the checksum of BlueHive's .Tdx (used to confirm a
# source file belongs to the same recording) and whether each missing file is
# already there. Creates the destination folders unless this is a dry run.
read -r -d '' REMOTE_STATE <<'EOF'
umask 007
proj=$1; dest=$2; prefix=$3; dry=$4; shift 4
cd "$proj" || { echo "ERR cannot open $proj"; exit 3; }
[ "$dry" = 1 ] || mkdir -p "$dest" || { echo "ERR cannot create $dest"; exit 3; }
for spec in "$@"; do
  IFS=: read -r ses stamp exts <<<"$spec"
  base=$prefix$stamp
  if [ -f "$ses/$base.Tdx" ]; then
    echo "TDX $ses $(sha256sum "$ses/$base.Tdx" | cut -d' ' -f1)"
  else
    echo "TDX $ses none"
  fi
  [ "$dry" = 1 ] || mkdir -p "$dest/$ses"
  for e in ${exts//,/ }; do
    if [ -f "$ses/$base.$e" ]; then
      echo "HAVE $ses $e orig $(stat -c %s "$ses/$base.$e")"
    elif [ -f "$dest/$ses/$base.$e" ]; then
      echo "HAVE $ses $e done $(stat -c %s "$dest/$ses/$base.$e")"
    else
      echo "HAVE $ses $e none -1"
    fi
  done
done
echo END
EOF

say "Checking what's already on BlueHive..."
state=$(rsh "bash -s -- $PROJECT $DEST $TANK_PREFIX $DRY ${SESSIONS[*]}" <<<"$REMOTE_STATE") \
  || die "couldn't check BlueHive (see messages above)"
grep -q '^END$' <<<"$state" || die "BlueHive check didn't finish: $state"

declare -A REF_TDX HAVE_KIND HAVE_SIZE
while read -r tag a b c d; do
  case $tag in
    TDX)  REF_TDX[$a]=$b ;;
    HAVE) HAVE_KIND[$a.$b]=$c; HAVE_SIZE[$a.$b]=$d ;;
  esac
done <<<"$state"

# ------------------------------------------------- find source files ----

say "Listing TDT files under the source folder (can take a few minutes on a network drive)..."
INDEX=$(mktemp)
find "$SRC" -type f \( -iname '*.tev' -o -iname '*.tsq' \) 2>/dev/null >"$INDEX"
say "Found $(wc -l <"$INDEX") .tev/.tsq files."
say ""

declare -A TDX_CACHE
# Prints: match | mismatch | notdx | noref
tank_check() {
  local dir=$1 stamp=$2 ses=$3 tdx
  [ "${REF_TDX[$ses]:-none}" = none ] && { echo noref; return; }
  if [ -z "${TDX_CACHE[$dir]+x}" ]; then
    tdx=$(find "$dir" -maxdepth 1 -type f -iname "*${stamp}*.tdx" 2>/dev/null | head -n 1)
    if [ -n "$tdx" ]; then TDX_CACHE[$dir]=$(sha "$tdx"); else TDX_CACHE[$dir]=none; fi
  fi
  if [ "${TDX_CACHE[$dir]}" = none ]; then echo notdx
  elif [ "${TDX_CACHE[$dir]}" = "${REF_TDX[$ses]}" ]; then echo match
  else echo mismatch
  fi
}

# Sets PICKED to the source file for one session/type, or returns 1.
pick_source() {
  local ses=$1 stamp=$2 ext=$3 f st
  local -a good=() unsure=() bad=()
  while IFS= read -r f; do
    case $(basename "$f") in *"$stamp"*) ;; *) continue ;; esac
    case ${f,,} in *."$ext") ;; *) continue ;; esac
    st=$(tank_check "$(dirname "$f")" "$stamp" "$ses")
    case $st in
      match) good+=("$f") ;;
      mismatch) bad+=("$f") ;;
      *) unsure+=("$f") ;;
    esac
  done < <(grep -F -- "$stamp" "$INDEX")

  for f in ${bad[@]+"${bad[@]}"}; do
    warn "skipping $f: its folder's .Tdx differs from BlueHive's, so it's a different recording"
  done
  if [ ${#good[@]} -ge 1 ]; then
    local size0 s
    size0=$(stat -c %s "${good[0]}")
    for f in "${good[@]:1}"; do
      s=$(stat -c %s "$f")
      if [ "$s" != "$size0" ]; then
        warn "several copies of this file differ in size; copy one by hand after checking:"
        printf '    %s\n' "${good[@]}"
        return 1
      fi
    done
    PICKED=${good[0]}
    return 0
  fi
  if [ ${#unsure[@]} -eq 1 ]; then
    warn "no .Tdx next to ${unsure[0]} to confirm it's the same recording; using it anyway (name matches)"
    PICKED=${unsure[0]}
    return 0
  fi
  if [ ${#unsure[@]} -gt 1 ]; then
    warn "several candidates and none can be confirmed:"
    printf '    %s\n' "${unsure[@]}"
  else
    warn "not found under $SRC"
  fi
  return 1
}

# ------------------------------------------------------------ copying ----

read -r -d '' REMOTE_VERIFY <<'EOF'
umask 007
cd "$1" || { echo "ERR cannot open $1"; exit 3; }
f=$2; want=$3
got=$(sha256sum "$f.part" 2>/dev/null | cut -d' ' -f1)
if [ -n "$got" ] && [ "$got" = "$want" ]; then
  mv -f "$f.part" "$f" && chmod g+rw "$f" && echo "$want  $f" >>SHA256SUMS && echo OK
else
  rm -f "$f.part"
  echo "BAD ${got:-no-file}"
fi
EOF

copy_one() {
  local src=$1 ddir=$2 name=$3 want try out
  say "  hashing source (reads the whole file once)..."
  want=$(sha "$src") || { warn "couldn't read $src"; return 1; }
  for ((try = 1; try <= MAX_TRIES; try++)); do
    say "  copying (try $try of $MAX_TRIES)..."
    if rcp "$src" "$ddir/$name.part"; then
      out=$(rsh "bash -s -- $ddir $name $want" <<<"$REMOTE_VERIFY")
      if grep -q '^OK$' <<<"$out"; then say "  done, checksum matches."; return 0; fi
      warn "checksum check on BlueHive failed ($(grep -E '^(BAD|ERR)' <<<"$out"))"
    else
      warn "copy interrupted"
    fi
    sleep 10
  done
  return 1
}

n_copied=0 n_skipped=0 n_would=0
problems=()
for spec in "${SESSIONS[@]}"; do
  IFS=: read -r ses stamp exts <<<"$spec"
  for ext in ${exts//,/ }; do
    key=$ses.$ext
    name=$TANK_PREFIX$stamp.$ext
    say "[$ses] $name"

    if [ "${HAVE_KIND[$key]}" = orig ]; then
      say "  already in the recording folder on BlueHive; skipping."
      n_skipped=$((n_skipped + 1)); continue
    fi

    if ! pick_source "$ses" "$stamp" "$ext"; then
      problems+=("$ses $ext: no usable source file"); continue
    fi
    size=$(stat -c %s "$PICKED")
    say "  source: $PICKED ($((size / 1048576)) MB)"
    if [ "$(basename "$PICKED")" != "$name" ]; then
      say "  (source name differs; it'll be saved under the BlueHive name above)"
    fi

    if [ "${HAVE_KIND[$key]}" = done ]; then
      if [ "${HAVE_SIZE[$key]}" = "$size" ]; then
        say "  already copied and checked; skipping."
        n_skipped=$((n_skipped + 1))
      else
        warn "a file is already on BlueHive but its size differs (${HAVE_SIZE[$key]} vs $size); leaving it alone"
        problems+=("$ses $ext: size differs from the copy already on BlueHive")
      fi
      continue
    fi

    if [ $DRY = 1 ]; then
      say "  would copy."
      n_would=$((n_would + 1)); continue
    fi
    if copy_one "$PICKED" "$DEST/$ses" "$name"; then
      n_copied=$((n_copied + 1))
    else
      problems+=("$ses $ext: copy failed after $MAX_TRIES tries")
    fi
  done
done
rm -f "$INDEX"

say ""
say "================ summary ================"
say "copied:            $n_copied"
say "already there:     $n_skipped"
[ $DRY = 1 ] && say "would copy:        $n_would"
if [ ${#problems[@]} -gt 0 ]; then
  say "problems:          ${#problems[@]}"
  printf '  - %s\n' "${problems[@]}"
  say "Re-run the script to retry; finished files are skipped."
  say "Please send $LOG to Yue."
  exit 1
fi
if [ $DRY = 1 ]; then say "Dry run finished. If it looks right, run again without -n."; else say "All done. Please send $LOG to Yue."; fi
