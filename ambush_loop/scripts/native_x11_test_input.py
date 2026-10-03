"""Native mouse and limited UI keys for guarded tests on a private X11 display."""
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
key_event = len(sys.argv) == 3 and sys.argv[1] == "key"
if key_event:
    key_name = sys.argv[2]
    if key_name not in {"Escape", "Tab", "Return", "Up", "Down", "m"}:
        raise SystemExit("unsupported test UI key")
else:
    if len(sys.argv) != 4:
        raise SystemExit("expected physical screen x/y/button or an allowed UI key")
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
x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
x11.XStringToKeysym.restype = ctypes.c_ulong
x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x11.XKeysymToKeycode.restype = ctypes.c_uint
xtst.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
display = x11.XOpenDisplay(test_display.encode())
if not display:
    raise SystemExit("private X11 display is unavailable")
try:
    if key_event:
        code = x11.XKeysymToKeycode(display, x11.XStringToKeysym(key_name.encode("ascii")))
        if not code:
            raise SystemExit("private display has no requested UI keycode")
        xtst.XTestFakeKeyEvent(display, code, 1, 0)
        xtst.XTestFakeKeyEvent(display, code, 0, 0)
    else:
        xtst.XTestFakeMotionEvent(display, -1, x, y, 0)
        xtst.XTestFakeButtonEvent(display, button, 1, 0)
        xtst.XTestFakeButtonEvent(display, button, 0, 0)
    x11.XSync(display, 0)
finally:
    x11.XCloseDisplay(display)
