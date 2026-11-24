#!/usr/bin/env python3
"""Select app tests from PR paths and write GitHub Actions outputs."""
import json
import os
import subprocess


def main():
    with open(os.environ['GITHUB_EVENT_PATH']) as source:
        event = json.load(source)
    apps = ['apple', 'android', 'cross']
    if 'pull_request' in event:
        pr = event['pull_request']
        changed = subprocess.check_output([
            'git', 'diff', '--name-only', '-z', '--no-renames',
            pr['base']['sha'] + '...' + pr['head']['sha'],
        ]).decode().split('\0')
        apps = [app for app in apps
                if any(path.startswith('app-' + app + '/') for path in changed)]
    with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
        for app in ['apple', 'android', 'cross']:
            print(app + '=' + str(app in apps).lower(), file=output)


if __name__ == '__main__':
    main()
