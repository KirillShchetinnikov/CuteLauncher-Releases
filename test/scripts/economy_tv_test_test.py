"""Lifecycle interval checks without running ADB or the controller entry point."""
import ast
import datetime
import pathlib
import unittest

source = pathlib.Path(__file__).resolve().parents[2] / 'scripts/economy-tv-test.py'
tree = ast.parse(source.read_text(encoding='utf-8'))
module = ast.Module(body=[node for node in tree.body if isinstance(node, ast.FunctionDef)
                         and node.name == 'stable_background_samples'], type_ignores=[])
namespace = {'datetime': datetime}
exec(compile(module, str(source), 'exec'), namespace)
select = namespace['stable_background_samples']

def sample(seconds, foreground):
    return {'time': datetime.datetime.fromtimestamp(seconds, datetime.timezone.utc).isoformat(),
            'foreground': foreground}

class BackgroundIntervalTest(unittest.TestCase):
    def test_return_timestamp_near_host_boundary_is_excluded(self):
        hidden = sample(50, False)
        self.assertEqual(select([hidden, sample(89.94, True)], 0, 90), [hidden])

    def test_foreground_inside_stable_interval_is_not_hidden(self):
        resumed = sample(60, True)
        self.assertEqual(select([sample(20, True), resumed], 0, 90), [resumed])

    def test_frozen_process_without_json_is_allowed(self):
        self.assertEqual(select([], 0, 90), [])

if __name__ == '__main__':
    unittest.main()
