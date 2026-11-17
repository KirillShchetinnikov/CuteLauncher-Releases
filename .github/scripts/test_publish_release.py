import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('publish_release', Path(__file__).with_name('publish_release.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class FakeGitHub:
    def __init__(self):
        self.release = None
        self.commit = 'a' * 40
        self.uploads = []
        self.fail_after = None
        self.published = 0
        self.created_with = None
        self.default = 'main'

    def default_branch(self):
        return self.default

    def tag_commit(self, tag):
        return self.commit

    def find_release(self, tag):
        return copy.deepcopy(self.release)

    def get_release(self, release_id):
        if self.release['id'] != release_id:
            raise ValueError('Draft identity changed')
        return copy.deepcopy(self.release)

    def create(self, data):
        self.created_with = copy.deepcopy(data)
        self.release = dict(data, id=12, assets=[], author={'login': 'github-actions[bot]'})
        self.release.setdefault('target_commitish', self.default)
        return copy.deepcopy(self.release)

    def upload(self, release_id, path):
        if self.fail_after is not None and len(self.uploads) == self.fail_after:
            raise RuntimeError('simulated upload interruption')
        self.uploads.append(path.name)
        self.release['assets'].append({'id': len(self.uploads), 'name': path.name,
                                      'size': path.stat().st_size, 'state': 'uploaded',
                                      'digest': 'sha256:' + module.sha256(path)})

    def publish(self, release_id, data):
        self.published += 1
        self.release.update(data)


class PublishReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        for abi in ('universal', 'armeabi-v7a', 'arm64-v8a', 'x86_64'):
            (self.folder / f'CuteLauncher-1.2.3-{abi}-release.apk').write_bytes(abi.encode())
        self.github = FakeGitHub()

    def publish(self):
        module.publish_release(self.github, 'owner/repo', 'v1.2.3', '1.2.3', '80',
                               'a' * 40, self.folder)

    def test_new_draft_can_be_published_before_it_appears_in_the_release_list(self):
        with patch.object(self.github, 'find_release', return_value=None) as find:
            self.publish()
        find.assert_called_once_with('v1.2.3')
        self.assertEqual(len(self.github.uploads), 4)
        self.assertEqual(self.github.published, 1)

    def test_upload_interruption_resumes_missing_assets_without_replacement(self):
        self.github.fail_after = 2
        with self.assertRaisesRegex(RuntimeError, 'interruption'):
            self.publish()
        self.assertTrue(self.github.release['draft'])
        self.assertEqual(len(self.github.release['assets']), 2)
        self.github.fail_after = None
        self.publish()
        self.assertEqual(len(self.github.uploads), 4)
        self.assertEqual(len(set(self.github.uploads)), 4)
        self.assertFalse(self.github.release['draft'])
        self.assertEqual(self.github.published, 1)
        self.assertNotIn('<!--', self.github.release['body'])
        self.assertIn('CHANGELOG_RU.md', self.github.release['body'])
        self.assertIn('CHANGELOG_EN.md', self.github.release['body'])

    def draft(self):
        self.github.fail_after = 0
        with self.assertRaises(RuntimeError):
            self.publish()
        self.github.fail_after = None

    def test_published_release_is_untouched(self):
        self.publish()
        before = copy.deepcopy(self.github.release)
        with self.assertRaisesRegex(ValueError, 'published'):
            self.publish()
        self.assertEqual(before, self.github.release)
        self.assertEqual(self.github.published, 1)

    def test_unmanaged_draft_and_other_author_are_rejected(self):
        self.draft()
        saved = copy.deepcopy(self.github.release)
        for field, value in [('body', 'someone else draft'),
                             ('author', {'login': 'other-user'}),
                             ('tag_name', 'v1.2.4')]:
            with self.subTest(field=field):
                self.github.release = dict(copy.deepcopy(saved), **{field: value})
                with self.assertRaises(ValueError):
                    self.publish()
                self.assertEqual(self.github.uploads, [])

    def test_create_omits_commitish_and_publishes_with_current_default_branch(self):
        self.github.default = 'trunk'
        self.publish()
        self.assertNotIn('target_commitish', self.github.created_with)
        self.assertEqual(self.github.release['target_commitish'], 'trunk')
        self.assertEqual(self.github.commit, 'a' * 40)

    def test_matching_draft_with_main_target_resumes_by_manifest_and_tag(self):
        self.draft()
        self.github.release['target_commitish'] = 'main'
        self.publish()
        self.assertFalse(self.github.release['draft'])
        self.assertEqual(self.github.commit, 'a' * 40)

    def test_old_sha_target_draft_normalizes_target_in_same_publish_patch(self):
        self.draft()
        self.github.release['target_commitish'] = 'a' * 40
        self.github.default = 'trunk'
        publish = self.github.publish
        patches = []
        def check(release_id, data):
            patches.append(copy.deepcopy(data))
            self.assertEqual(data['target_commitish'], 'trunk')
            self.assertFalse(data['draft'])
            self.assertNotIn(module.MARKER, data['body'])
            publish(release_id, data)
        self.github.publish = check
        self.publish()
        self.assertEqual(len(patches), 1)
        self.assertEqual(self.github.commit, 'a' * 40)

    def test_main_target_does_not_allow_changed_manifest_commit(self):
        self.draft()
        self.github.release['target_commitish'] = 'main'
        self.github.release['body'] = self.github.release['body'].replace('a' * 40, 'b' * 40)
        with self.assertRaisesRegex(ValueError, 'manifest'):
            self.publish()
        self.assertEqual(self.github.uploads, [])
        self.assertEqual(self.github.published, 0)

    def test_main_target_does_not_allow_moved_remote_tag(self):
        self.draft()
        self.github.release['target_commitish'] = 'main'
        self.github.commit = 'b' * 40
        with self.assertRaisesRegex(ValueError, 'commit'):
            self.publish()
        self.assertEqual(self.github.uploads, [])
        self.assertEqual(self.github.published, 0)

    def test_changed_local_apk_or_version_build_does_not_resume(self):
        self.draft()
        next(self.folder.glob('*.apk')).write_bytes(b'other build')
        with self.assertRaisesRegex(ValueError, 'manifest'):
            self.publish()
        self.assertEqual(self.github.uploads, [])

    def test_wrong_extra_duplicate_or_incomplete_remote_asset_is_untouched(self):
        self.draft()
        name = next(self.folder.glob('*.apk')).name
        examples = [
            [{'name': name, 'state': 'uploaded', 'size': 4, 'digest': 'sha256:' + '0' * 64}],
            [{'name': 'foreign.txt', 'state': 'uploaded', 'size': 1, 'digest': 'sha256:' + '0' * 64}],
            [{'name': name, 'state': 'starter', 'size': 0, 'digest': None}],
            [{'name': name}, {'name': name}],
        ]
        for assets in examples:
            with self.subTest(assets=assets):
                self.github.release['assets'] = copy.deepcopy(assets)
                with self.assertRaises(ValueError):
                    self.publish()
                self.assertEqual(self.github.release['assets'], assets)
                self.assertEqual(self.github.uploads, [])

    def test_tag_must_resolve_to_exact_source_commit(self):
        self.github.commit = 'b' * 40
        with self.assertRaisesRegex(ValueError, 'commit'):
            self.publish()
        self.assertIsNone(self.github.release)

    def test_only_exact_four_nonempty_apks_are_accepted(self):
        next(self.folder.glob('*.apk')).unlink()
        with self.assertRaises(ValueError):
            self.publish()
        self.assertIsNone(self.github.release)

    def test_remote_asset_changed_after_upload_prevents_publication(self):
        original_upload = self.github.upload
        def corrupt(release_id, path):
            original_upload(release_id, path)
            self.github.release['assets'][-1]['digest'] = 'sha256:' + '0' * 64
        self.github.upload = corrupt
        with self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(self.github.published, 0)

    def test_failure_before_publish_keeps_marker_for_retry(self):
        publish = self.github.publish
        self.github.publish = lambda *_: (_ for _ in ()).throw(RuntimeError('network'))
        with self.assertRaisesRegex(RuntimeError, 'network'):
            self.publish()
        self.assertTrue(self.github.release['draft'])
        self.assertIn(module.MARKER, self.github.release['body'])
        self.assertEqual(len(self.github.uploads), 4)
        self.github.publish = publish
        self.publish()
        self.assertEqual(len(self.github.uploads), 4)

    def test_concurrent_publication_before_final_read_prevents_patch(self):
        upload = self.github.upload
        def change(release_id, path):
            upload(release_id, path)
            if len(self.github.uploads) == 4:
                self.github.release['draft'] = False
        self.github.upload = change
        with self.assertRaisesRegex(ValueError, 'published'):
            self.publish()
        self.assertEqual(self.github.published, 0)


class GitHubClientTests(unittest.TestCase):
    def test_exact_tag_ref_is_peeled_without_branch_name_resolution(self):
        with patch.object(module.subprocess, 'run') as run:
            run.side_effect = [
                type('Result', (), {'stdout': json.dumps({'object': {'type': 'tag', 'sha': 'b' * 40}})})(),
                type('Result', (), {'stdout': json.dumps({'object': {'type': 'commit', 'sha': 'a' * 40}})})(),
            ]
            self.assertEqual(module.GitHub('owner/repo').tag_commit('v1.2.3+80'), 'a' * 40)
        self.assertIn('repos/owner/repo/git/ref/tags/v1.2.3%2B80', run.call_args_list[0].args[0])

    def test_publish_removes_marker_and_releases_in_one_json_patch(self):
        data = {'draft': False, 'body': 'final RU/EN links', 'make_latest': 'true'}
        with patch.object(module.subprocess, 'run') as run:
            run.return_value.stdout = '{}'
            module.GitHub('owner/repo').publish(12, data)
        command = run.call_args.args[0]
        self.assertEqual(command, ['gh', 'api', 'repos/owner/repo/releases/12',
                                   '--method', 'PATCH', '--input', '-'])
        self.assertEqual(json.loads(run.call_args.kwargs['input']), data)

    def test_paginated_release_and_asset_lists_are_read(self):
        release = {'id': 12, 'tag_name': 'v1.2.3', 'draft': True}
        with patch.object(module.subprocess, 'run') as run:
            run.side_effect = [
                type('Result', (), {'stdout': json.dumps([[], [release]])})(),
                type('Result', (), {'stdout': json.dumps(release)})(),
                type('Result', (), {'stdout': json.dumps([[{'name': 'a.apk'}], [{'name': 'b.apk'}]])})(),
            ]
            github = module.GitHub('owner/repo')
            self.assertEqual(github.find_release('v1.2.3'), release)
            result = github.get_release(release['id'])
        self.assertEqual([a['name'] for a in result['assets']], ['a.apk', 'b.apk'])
        self.assertEqual(run.call_args_list[1].args[0],
                         ['gh', 'api', 'repos/owner/repo/releases/12', '--method', 'GET'])
        self.assertTrue(all('--paginate' in call.args[0] and '--slurp' in call.args[0]
                            for call in (run.call_args_list[0], run.call_args_list[2])))

    def test_draft_read_retries_temporary_http_404(self):
        github = module.GitHub('owner/repo')
        endpoint = 'repos/owner/repo/releases/12'
        missing = module.subprocess.CalledProcessError(1, ['gh'], stderr='gh: Not Found (HTTP 404)\n')
        release = {'id': 12, 'draft': True}
        with patch.object(github, 'api', side_effect=[missing, release, [[]]]) as api, \
                patch.object(module.time, 'sleep') as sleep:
            self.assertEqual(github.get_release(12), {'id': 12, 'draft': True, 'assets': []})
        self.assertEqual([call.args[0] for call in api.call_args_list],
                         [endpoint, endpoint, f'{endpoint}/assets?per_page=100'])
        sleep.assert_called_once_with(1)

    def test_draft_read_stops_after_retry_limit_or_on_other_http_errors(self):
        github = module.GitHub('owner/repo')
        for status, expected_delays in [(404, [1, 2, 4]), (403, [])]:
            with self.subTest(status=status):
                error = module.subprocess.CalledProcessError(1, ['gh'], stderr=f'gh: API error (HTTP {status})\n')
                with patch.object(github, 'api', side_effect=error) as api, \
                        patch.object(module.time, 'sleep') as sleep:
                    with self.assertRaises(module.subprocess.CalledProcessError):
                        github.get_release(12)
                self.assertEqual(api.call_count, len(expected_delays) + 1)
                self.assertEqual([call.args[0] for call in sleep.call_args_list], expected_delays)

    def test_asset_upload_never_clobbers_or_deletes(self):
        with patch.object(module.subprocess, 'run') as run:
            module.GitHub('owner/repo').upload(12, Path('some.apk'))
        command = run.call_args.args[0]
        self.assertIn('https://uploads.github.com/repos/owner/repo/releases/12/assets?name=some.apk', command)
        self.assertEqual(command[command.index('--method') + 1], 'POST')
        self.assertNotIn('--clobber', command)


if __name__ == '__main__':
    unittest.main()
