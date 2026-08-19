#!/bin/sh
# Fake reviewdog installer: installs a mock reviewdog binary
BINDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -b) BINDIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done
mkdir -p "$BINDIR"
cat > "$BINDIR/reviewdog" << 'RDEOF'
#!/bin/sh
# Mock reviewdog: log args and consume stdin
echo "reviewdog args: $*" >> /tmp/reviewdog-calls.log
cat > /dev/null
exit 0
RDEOF
chmod +x "$BINDIR/reviewdog"
