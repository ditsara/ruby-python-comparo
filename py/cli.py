#!/usr/bin/env python

import os
import sys
import requests
import urllib.parse
import json
import argparse

CONFIG = {
        'id_len': 6,
        'title_len': 60,
        'debug': False,
        'gitlab_url': os.getenv('GITLAB_API_URL', 'http://gitlab.com'),
        'gitlab_key': os.getenv('GITLAB_API_KEY')
        }

parser = argparse.ArgumentParser(description="Usage: cli.py [options]")
parser_l_help = "filter by label(s) (separate each with a comma)"
parser.add_argument('-l', '--labels', help=parser_l_help)
options = parser.parse_args()

def api_get(path, params={}, headers={}):
    auth_header = {'Private-Token': CONFIG['gitlab_key']}
    response = requests.get(
            urllib.parse.urljoin(CONFIG['gitlab_url'], path),
            params=params,
            headers={ **headers, **auth_header }
            )
    return response

def main(argv):
    params = {'scope': 'assigned-to-me', 'labels': options.labels }
    response = api_get('/api/v4/issues', params=params)

    parsed_json = json.loads(response.text)
    for issue in parsed_json:
        tpl_str = "%-{}s\t%-{}s".format(CONFIG['id_len'], CONFIG['title_len'])
        line = tpl_str % (issue['id'], issue['title'][0:CONFIG['title_len']])
        print(line)

if __name__ == "__main__":
    main(sys.argv)
