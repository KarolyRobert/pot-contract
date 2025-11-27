#!/bin/bash

#kill $(ps aux | grep -oP '^\S+\s+\K\S+(?=.*\bflow emulator\b)')

kill $(ps aux | grep "[f]low emulator" | awk '{print $2}')