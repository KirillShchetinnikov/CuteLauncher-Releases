import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location("measure_ram", pathlib.Path(__file__).parents[1] / "tools/measure_ram.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class MeminfoTests(unittest.TestCase):
    def test_current_report(self):
        self.assertEqual(module.parse_meminfo("TOTAL PSS: 128 TOTAL RSS: 256"), {"pss_bytes": 131072, "rss_bytes": 262144})
    def test_old_report(self):
        self.assertEqual(module.parse_meminfo("    TOTAL   100   90   1\n"), {"pss_bytes": 102400, "rss_bytes": None})
    def test_missing_process(self):
        self.assertEqual(module.parse_meminfo("No process found"), {"pss_bytes": None, "rss_bytes": None})

if __name__ == "__main__": unittest.main()
