"""Confirm tag delivery started a public build; recover a missing push event."""
import argparse
import json
import re
import subprocess
import time


def api(path, *arguments):
    result = subprocess.run(['gh', 'api', path, *arguments],
                            capture_output=True, text=True, check=True)
    return json.loads(result.stdout) if result.stdout.strip() else None


def ensure_release(repository, tag, attempts=7, pause=time.sleep):
    if not re.fullmatch(r'v\d+\.\d+\.\d+(?:-test\.\d+)?(?:\+\d+)?', tag):
        raise ValueError('Expected a version tag')
    endpoint = f'repos/{repository}/actions/workflows/public-release.yml'
    # Push events can arrive after the source publication job finishes. A
    # running/successful build is sufficient; cancelled or failed runs can retry.
    for attempt in range(attempts):
        result = api(f'{endpoint}/runs?branch={tag.replace("+", "%2B")}&per_page=100')
        for run in result['workflow_runs']:
            if run['head_branch'] == tag and (
                    run['status'] != 'completed' or run['conclusion'] == 'success'):
                print(f'Public release already started: {run["html_url"]}')
                return
        if attempt + 1 < attempts:
            pause(10)
    # An API dispatch is part of the automatic private release workflow, not a
    # separate local publication. It also works when an existing tag is retried.
    api(f'{endpoint}/dispatches', '--method', 'POST', '-f', f'ref={tag}')
    print(f'Automatically requested public release for {tag}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repository')
    parser.add_argument('tag')
    args = parser.parse_args()
    ensure_release(args.repository, args.tag)
