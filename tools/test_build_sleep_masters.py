import importlib.util
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).with_name("build_sleep_masters.py")
SPEC = importlib.util.spec_from_file_location("build_sleep_masters", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class SleepMasterBuilderTest(unittest.TestCase):
    def test_repeated_sections_become_progressively_quieter(self) -> None:
        gains = [MODULE._gain_for_repeat(index) for index in range(12)]
        self.assertEqual(gains[0], 1.0)
        self.assertTrue(all(left > right for left, right in zip(gains, gains[1:])))

    def test_repeat_gain_keeps_a_quiet_floor(self) -> None:
        self.assertEqual(MODULE._gain_for_repeat(1000), MODULE.MINIMUM_REPEAT_GAIN)


if __name__ == "__main__":
    unittest.main()
