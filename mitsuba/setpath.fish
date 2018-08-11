#!/usr/local/bin/fish

set MITSUBA_DIR (dirname (status --current-filename))

if [ (uname) = "Darwin" ]
    set -x PATH "$MITSUBA_DIR/Mitsuba.app/Contents/MacOS" $PATH
else
    set -x PATH "$MITSUBA_DIR/dist" $PATH
    set -x LD_LIBRARY_PATH "$MITSUBA_DIR/dist" $LD_LIBRARY_PATH
end
