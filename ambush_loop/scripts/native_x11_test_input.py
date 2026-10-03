"""Native mouse input for the guarded viewport test on a private X11 display."""
import ctypes
import os
import re
import sys
from pathlib import Path

run_id = os.environ.get("AMBUSH_TEST_RUN_ID", "")
data_root = Path(os.environ.get("AMBUSH_TEST_DATA_ROOT", ""))
test_display = os.environ.get("AMBUSH_TEST_X11_DISPLAY", "")
if (not re.fullmatch(r"[0-9a-f]{32}", run_id)
        or data_root.name != "data" or data_root.parent.name != run_id
        or data_root.parent.parent.name != "ambush_test_runs"
        or not test_display or os.environ.get("DISPLAY") != test_display):
    raise SystemExit("native input requires isolated storage and an explicit private test display")
if len(sys.argv) != 4:
    raise SystemExit("expected physical screen x, y, and mouse button")
x, y, button = map(int, sys.argv[1:])
if button not in (1, 4, 5):
    raise SystemExit("unsupported test mouse button")
x11 = ctypes.CDLL("libX11.so.6")
xtst = ctypes.CDLL("libXtst.so.6")
x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XSync.argtypes = [ctypes.c_void_p, ctypes.c_int]
x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
xtst.XTestFakeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
xtst.XTestFakeButtonEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
display = x11.XOpenDisplay(test_display.encode())
if not display:
    raise SystemExit("private X11 display is unavailable")
try:
    xtst.XTestFakeMotionEvent(display, -1, x, y, 0)
    xtst.XTestFakeButtonEvent(display, button, 1, 0)
    xtst.XTestFakeButtonEvent(display, button, 0, 0)
    x11.XSync(display, 0)
finally:
    x11.XCloseDisplay(display)
