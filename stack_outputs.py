#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import json
import boto3
import datetime
from botocore.exceptions import BotoCoreError, ClientError

def main():
    try:
        query = json.loads(sys.stdin.read())
        client = boto3.client('cloudformation', region_name=query['region'])
    except (BotoCoreError, ClientError, Exception) as e:
        msg = '{}: {}'.format(type(e).__name__, e)
        sys.stdout.write("{\"Error:\" : \"" + msg + "\"}")
        sys.exit(0)

    try:
        outputs = client.describe_stacks(StackName=query['stack_name'])["Stacks"]
        d = {}
        for o in outputs:
            if 'StackName' in o:
                d['StackName'] = o['StackName']
            if 'Outputs' in o:
                for op in o['Outputs']:
                     d[op['OutputKey']] = op['OutputValue']
        sys.stdout.write(json.dumps(d))
    except (BotoCoreError, ClientError, Exception) as e:
        msg = '{}: {}'.format(type(e).__name__, e)
        sys.stdout.write("{\"Error:\" : \"" + msg + "\"}")

if __name__ == '__main__':
    main()
    sys.exit(0)
