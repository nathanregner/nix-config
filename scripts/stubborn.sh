#!/usr/bin/env bash

trap 'echo " [Ignored Signal]"' 1 2 15

echo "PID $$"

while true; do
  sleep 1
done
