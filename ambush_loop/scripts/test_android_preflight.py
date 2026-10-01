import subprocess
import unittest
from unittest.mock import patch

from android_preflight import PreflightError, adb_read, inspect_device


class PreflightTests(unittest.TestCase):
    def run_gate(self, devices="phone device", model="V2266A", installed="package:/data/app/base.apk",
                 details="  versionCode=80 minSdk=24\n  versionName=0.6.30-font-cache-diag\n", serial=None):
        calls = []

        def read(adb, args):
            calls.append(args)
            if args == ["devices", "-l"]:
                return "List of devices attached\n" + devices
            if args[3:] == ["getprop", "ro.product.model"]:
                return model
            if args[3:5] == ["pm", "path"]:
                return installed
            if args[3:5] == ["dumpsys", "package"]:
                return details
            self.fail("Unexpected device operation: " + repr(args))

        return inspect_device("adb", serial=serial, read=read), calls

    def test_expected_identity(self):
        result, calls = self.run_gate()
        self.assertTrue(result["ready"])
        self.assertEqual(len(calls), 4)
        self.assertNotIn("serial", result)

    def test_no_device(self):
        result, calls = self.run_gate(devices="")
        self.assertFalse(result["ready"])
        self.assertEqual(len(calls), 1)

    def test_multiple_devices_require_selection(self):
        result, calls = self.run_gate(devices="phone device\nwifi device")
        self.assertEqual(result["reason"], "select_one_device")
        self.assertEqual(len(calls), 1)
        self.assertTrue(self.run_gate(devices="phone device\nwifi device", serial="wifi")[0]["ready"])

    def test_unauthorized_and_offline(self):
        for state in ("unauthorized", "offline"):
            with self.subTest(state=state):
                result, calls = self.run_gate(devices="phone " + state)
                self.assertEqual(result["reason"], "device_not_authorized")
                self.assertEqual(len(calls), 1)

    def test_wrong_phone(self):
        result, calls = self.run_gate(model="AAP-AN00")
        self.assertEqual(result["reason"], "wrong_model")
        self.assertEqual(len(calls), 2)

    def test_absent_package(self):
        self.assertEqual(self.run_gate(installed="")[0]["reason"], "package_missing")

    def test_wrong_or_incomplete_version(self):
        for details in ("versionCode=78\nversionName=0.6.29", "versionCode=80",
                        "versionCode=80\nversionName=other", ""):
            with self.subTest(details=details):
                self.assertFalse(self.run_gate(details=details)[0]["ready"])

    def test_explicit_serial_must_exist(self):
        self.assertFalse(self.run_gate(serial="missing")[0]["ready"])

    def test_subprocess_is_bounded_and_nonzero_rejected(self):
        with patch("android_preflight.subprocess.run", return_value=subprocess.CompletedProcess([], 1, "", "err")) as run:
            with self.assertRaises(PreflightError):
                adb_read("adb", ["devices", "-l"])
            self.assertEqual(run.call_args.kwargs["timeout"], 15)

    def test_timeout_is_not_a_pass(self):
        with patch("android_preflight.subprocess.run", side_effect=subprocess.TimeoutExpired("adb", 15)):
            with self.assertRaises(PreflightError):
                adb_read("adb", ["devices", "-l"])


if __name__ == "__main__":
    unittest.main()
