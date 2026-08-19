#!/bin/sh
# Fake reviewdog install script
# Parses -b <bindir> and <version> arguments and creates a fake reviewdog binary

BINDIR=""
VERSION=""

while [ $# -gt 0 ]; do
  case "$1" in
    -b)
      BINDIR="$2"
      shift 2
      ;;
    -s)
      shift
      ;;
    --)
      shift
      ;;
    v*)
      VERSION="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$BINDIR" ]; then
  BINDIR="/usr/local/bin"
fi

mkdir -p "$BINDIR"

cat > "$BINDIR/reviewdog" << 'REVIEWDOG_EOF'
#!/bin/sh
# Fake reviewdog binary - reads stdin, exits 0
cat > /dev/null
exit 0
REVIEWDOG_EOF

chmod +x "$BINDIR/reviewdog"
echo "Installed fake reviewdog to $BINDIR/reviewdog"
