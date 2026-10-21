import importlib.util
import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('publish_source', ROOT / 'scripts/publish-source.py')
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class PublicSourceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.source = Path(self.temporary.name) / 'private'
        self.public = Path(self.temporary.name) / 'public'
        for directory in (self.source, self.public):
            directory.mkdir()
            publisher.git(directory, 'init', '-b', 'main')
            publisher.git(directory, 'config', 'user.name', 'Test')
            publisher.git(directory, 'config', 'user.email', 'test@example.invalid')
            publisher.git(directory, 'config', 'core.autocrlf', 'false')
        for name in publisher.REQUIRED:
            self.write(name, 'project source\n')
        self.write('pubspec.yaml', 'name: cutelauncher\nversion: 1.0.24+73\n')
        self.write('AGENTS.md', 'PRIVATE AGENT RULES\n')
        self.write('docs/agents/WORKFLOW_RU.md', 'PRIVATE WORKFLOW\n')
        self.write('.github/workflows/private.yml', 'PRIVATE WORKFLOW SECRET NAME\n')
        self.write('internal/private.md', 'PRIVATE UNKNOWN TOP LEVEL\n')
        self.write('.local/signing/private.p12', 'PRIVATE KEY MATERIAL\n')
        self.write('scripts/check.sh', '#!/bin/sh\nexit 0\n')
        self.write('drift_schemas/schema.json', '{}\n')
        self.write('.gitignore', '*.py\ndrift_schemas/\n')
        self.commit(self.source, 'PRIVATE COMMIT MESSAGE')
        (self.source / 'scripts/check.sh').chmod(0o755)
        publisher.git(self.source, 'update-index', '--chmod=+x', 'scripts/check.sh')
        self.commit(self.source, 'PRIVATE EXECUTABLE CHANGE')
        (self.public / 'README.md').write_text('Existing release repository\n')
        self.commit(self.public, 'Existing public history')
        self.public_initial = self.head(self.public)

    def write(self, name, text):
        path = self.source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')

    def commit(self, directory, message):
        publisher.git(directory, 'add', '-f', '--all')
        publisher.git(directory, 'commit', '--allow-empty', '-m', message)

    def head(self, directory):
        return publisher.git(directory, 'rev-parse', 'HEAD').stdout.strip()

    def publish(self, tag=''):
        return publisher.snapshot(self.source, 'HEAD', self.public, tag)

    def test_public_snapshot_retains_source_and_not_private_objects_or_history(self):
        private_commit = self.head(self.source).decode()
        self.publish()
        paths = publisher.git(self.public, 'ls-files').stdout.decode().splitlines()
        self.assertTrue(publisher.REQUIRED <= set(paths))
        self.assertIn('drift_schemas/schema.json', paths)
        for name in ('AGENTS.md', 'docs/agents/WORKFLOW_RU.md', '.local/signing/private.p12',
                     '.github/workflows/private.yml', 'internal/private.md'):
            self.assertNotIn(name, paths)
        self.assertEqual(publisher.git(self.public, 'rev-parse', 'HEAD^').stdout.strip(), self.public_initial)
        self.assertNotEqual(publisher.git(self.public, 'cat-file', '-e', private_commit, check=False).returncode, 0)
        history = publisher.git(self.public, 'log', '--format=%B').stdout.decode()
        self.assertNotIn('PRIVATE COMMIT MESSAGE', history)
        self.assertIn(private_commit, history)
        self.assertEqual(publisher.git(self.public, 'show', 'HEAD:LICENSE').stdout,
                         publisher.git(self.source, 'show', 'HEAD:LICENSE').stdout)
        mode = publisher.git(self.public, 'ls-tree', 'HEAD', 'scripts/check.sh').stdout
        # Git on Windows defaults to core.filemode=false. The exporter must
        # preserve executable bits explicitly when staging, regardless of host.
        self.assertTrue(mode.startswith(b'100755'))

    def test_repeat_and_agent_only_commits_do_not_add_public_commits(self):
        self.publish()
        initial = self.head(self.public)
        self.publish()
        self.write('AGENTS.md', 'CHANGED PRIVATE RULES\n')
        self.commit(self.source, 'PRIVATE AGENT UPDATE')
        self.publish()
        self.assertEqual(initial, self.head(self.public))
        self.assertFalse(publisher.git(self.public, 'status', '--porcelain').stdout)

    def test_windows_git_line_ending_conversion_does_not_change_exported_blobs(self):
        publisher.git(self.source, 'config', 'core.autocrlf', 'true')
        self.publish()
        self.assertEqual(publisher.git(self.source, 'show', 'HEAD:LICENSE').stdout,
                         publisher.git(self.public, 'show', 'HEAD:LICENSE').stdout)

    def test_changes_and_deletions_are_reflected_without_importing_private_parent(self):
        self.write('lib/obsolete.dart', 'old\n')
        self.publish()
        # Uncommitted private additions are not exported.
        self.assertFalse((self.public / 'lib/obsolete.dart').exists())
        self.commit(self.source, 'Private addition')
        self.publish()
        initial = self.head(self.public)
        (self.source / 'lib/obsolete.dart').unlink()
        self.write('lib/main.dart', 'changed\n')
        self.commit(self.source, 'Private replacement')
        self.publish()
        self.assertFalse((self.public / 'lib/obsolete.dart').exists())
        self.assertEqual((self.public / 'lib/main.dart').read_text(), 'changed\n')
        self.assertEqual(publisher.git(self.public, 'rev-parse', 'HEAD^').stdout.strip(), initial)

    def test_secrets_fail_before_public_checkout_changes(self):
        for name in ('android/release.p12', 'assets/private.pem', 'scripts/.env.production',
                     'android/local.properties', 'android/app/google_play_api_key.json'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                publisher.public_path(name)
        self.write('android/release.p12', 'DO NOT PUBLISH\n')
        self.commit(self.source, 'Private signing mistake')
        with self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(self.head(self.public), self.public_initial)
        self.assertFalse(publisher.git(self.public, 'status', '--porcelain').stdout)

    def test_nested_agent_rules_and_unsafe_paths(self):
        for name in ('lib/AGENTS.md', 'docs/agents/private.md', 'scripts/.codex/config.toml',
                     'docs/AGENTS.override.md', 'test/CLAUDE.md'):
            self.assertFalse(publisher.public_path(name))
        for name in ('../outside', '/outside', 'docs/../../outside', 'docs\\outside'):
            with self.assertRaises(ValueError):
                publisher.public_path(name)

    def test_public_english_readme_is_included_but_agent_translations_are_private(self):
        self.assertTrue(publisher.public_path('README_EN.md'))
        for name in ('AGENTS_EN.md', 'docs/agents/WORKFLOW_EN.md', 'lib/AGENTS_EN.md'):
            self.assertFalse(publisher.public_path(name))

    def test_only_user_documentation_is_published(self):
        for name in publisher.PUBLIC_DOCS | publisher.PUBLIC_DOC_ASSETS:
            self.assertTrue(publisher.public_path(name), name)
        for name in ('docs/ARCHITECTURE_RU.md', 'docs/TESTING_RU.md',
                     'docs/DEVELOPMENT_RU.md', 'docs/APK_RELEASES_RU.md',
                     'docs/UI_GUIDE_RU.md', 'docs/ROADMAP_RU.md',
                     'docs/COMPATIBILITY_RU.md', 'docs/new-private-document.md',
                     'docs/design-gallery.html', 'docs/assets/acceptance-2026-10-05-ram.png',
                     'docs/measurements/raw.csv', 'test/design/UPDATES.md',
                     'test/design/fonts/README.md',
                     'docs/images/concepts/cutelauncher-icon-concepts-house-study.png',
                     'docs/images/concepts/cutelauncher-icon-selected.png',
                     'docs/images/concepts/cutelauncher-tv-banner-selected.png'):
            self.assertFalse(publisher.public_path(name), name)

    def test_credentials_in_allowed_files_fail_before_changing_public_checkout(self):
        self.write('lib/credential.txt', 'ghp_' + 'A' * 40)
        self.commit(self.source, 'Accidental credential')
        with self.assertRaises(ValueError):
            self.publish()
        self.assertEqual(self.head(self.public), self.public_initial)
        self.assertFalse(publisher.git(self.public, 'status', '--porcelain').stdout)

    def test_existing_public_release_tag_with_other_source_is_rejected(self):
        tag = 'v1.0.24+73'
        publisher.git(self.source, 'tag', tag)
        publisher.git(self.public, 'tag', tag)
        previous = publisher.git(self.public, 'rev-parse', f'refs/tags/{tag}').stdout
        with self.assertRaises(ValueError):
            self.publish(tag)
        self.assertEqual(previous, publisher.git(self.public, 'rev-parse', f'refs/tags/{tag}').stdout)

    def test_public_dummy_key_exception_is_pinned_to_exact_content(self):
        name = 'test/fixtures/cloud/test_key.txt'
        self.write(name, 'ghp_' + 'A' * 40)
        self.commit(self.source, 'Public test fixture')
        content = publisher.git(self.source, 'show', f'HEAD:{name}').stdout
        with patch.dict(publisher.PUBLIC_TEST_FIXTURES,
                        {name: hashlib.sha256(content).hexdigest()}, clear=True):
            self.publish()
            previous = self.head(self.public)
            self.write(name, 'ghp_' + 'B' * 40)
            self.commit(self.source, 'Unexpected fixture replacement')
            with self.assertRaises(ValueError):
                self.publish()
            self.assertEqual(self.head(self.public), previous)

    def test_release_tag_matches_source_and_existing_tags_are_never_replaced(self):
        tag = 'v1.0.24+73'
        publisher.git(self.source, 'tag', tag)
        self.publish(tag)
        public_tag = publisher.git(self.public, 'rev-parse', f'refs/tags/{tag}').stdout
        self.publish(tag)
        self.assertEqual(public_tag, publisher.git(self.public, 'rev-parse', f'refs/tags/{tag}').stdout)
        with self.assertRaises(ValueError):
            self.publish('v1.0.25+74')
        self.write('lib/main.dart', 'different release code\n')
        self.commit(self.source, 'Changed code')
        # The private tag still points to the previous source commit.
        with self.assertRaises(ValueError):
            self.publish(tag)
        self.assertEqual(public_tag, publisher.git(self.public, 'rev-parse', f'refs/tags/{tag}').stdout)

    def test_dirty_or_private_destination_is_rejected(self):
        (self.public / 'untracked').write_text('keep me')
        with self.assertRaises(ValueError):
            self.publish()
        with self.assertRaises(ValueError):
            publisher.snapshot(self.source, 'HEAD', self.source)

    def test_symlink_is_rejected(self):
        blob = subprocess.run(['git', '-C', str(self.source), 'hash-object', '-w', '--stdin'],
                              input=b'../../private', capture_output=True, check=True).stdout.decode().strip()
        publisher.git(self.source, 'update-index', '--add', '--cacheinfo', f'120000,{blob},scripts/link')
        publisher.git(self.source, 'commit', '-m', 'Private symlink')
        with self.assertRaises(ValueError):
            self.publish()


if __name__ == '__main__':
    unittest.main()
