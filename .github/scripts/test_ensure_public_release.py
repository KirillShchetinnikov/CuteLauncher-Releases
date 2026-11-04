import importlib.util
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    'ensure_public_release', Path(__file__).with_name('ensure_public_release.py'))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class AutomaticReleaseTests(unittest.TestCase):
    def run_info(self, status='in_progress', conclusion=None, tag='v1.6.8'):
        return {'head_branch': tag, 'status': status, 'conclusion': conclusion,
                'html_url': 'https://github.com/example/repo/actions/runs/123'}

    def test_existing_pending_or_successful_build_is_not_duplicated(self):
        for status, conclusion in [('queued', None), ('in_progress', None),
                                   ('completed', 'success')]:
            with self.subTest(status=status), patch.object(release, 'api') as api:
                api.return_value = {'workflow_runs': [self.run_info(status, conclusion)]}
                release.ensure_release('example/repo', 'v1.6.8')
                self.assertEqual(api.call_count, 1)

    def test_delayed_push_event_is_allowed_to_arrive(self):
        with patch.object(release, 'api') as api:
            api.side_effect = [{'workflow_runs': []},
                               {'workflow_runs': [self.run_info()]}]
            pauses = []
            release.ensure_release('example/repo', 'v1.6.8', pause=pauses.append)
            self.assertEqual(pauses, [10])
            self.assertEqual(api.call_count, 2)

    def test_missing_event_and_cancelled_or_failed_runs_are_recovered(self):
        for runs in [[], [self.run_info('completed', 'cancelled')],
                     [self.run_info('completed', 'failure')],
                     [self.run_info(tag='v1.6.7')]]:
            with self.subTest(runs=runs), patch.object(release, 'api') as api:
                api.return_value = {'workflow_runs': runs}
                release.ensure_release('example/repo', 'v1.6.8', attempts=2,
                                       pause=lambda _: None)
                self.assertEqual(api.call_count, 3)
                api.assert_called_with(
                    'repos/example/repo/actions/workflows/public-release.yml/dispatches',
                    '--method', 'POST', '-f', 'ref=v1.6.8')

    def test_api_failure_is_reported_without_attempting_dispatch(self):
        with patch.object(release, 'api') as api:
            api.side_effect = subprocess.CalledProcessError(1, 'gh')
            with self.assertRaises(subprocess.CalledProcessError):
                release.ensure_release('example/repo', 'v1.6.8')
            self.assertEqual(api.call_count, 1)

    def test_branch_cannot_be_released(self):
        with patch.object(release, 'api') as api:
            with self.assertRaises(ValueError):
                release.ensure_release('example/repo', 'main')
            api.assert_not_called()


if __name__ == '__main__':
    unittest.main()
