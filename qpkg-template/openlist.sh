#!/bin/sh
case "$1" in
  start)
    /share/openlist/openlist &
    ;;
  stop)
    pkill openlist
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
esac
exit 0