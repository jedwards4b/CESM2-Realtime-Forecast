#!/usr/bin/env python3
# coding: utf-8
import sys
_LIBDIR="/glade/u/home/jedwards/.local/lib/python3.6/site-packages/"
sys.path.append(_LIBDIR)

from globus_sdk import *
import json
import os

CLIENT_ID = 'e17ab7ed-dc5e-4faf-95c3-bee6e8f7f479'

def initialize_client():
    client = NativeAppAuthClient(CLIENT_ID)
    client.oauth2_start_flow(refresh_tokens=True)
    return client

def get_globus_auth_data_struct(client, token=None):
    home = os.environ.get("HOME")
    globus_auth_file = os.path.join(home,'.globus','globus.auth-data')
    if os.path.isfile(globus_auth_file):
        with open(globus_auth_file) as auth_file:
            return json.load(auth_file)
    elif token:
        globus_auth_data = token.by_resource_server['auth.globus.org']
        with open(globus_auth_file, 'w') as outfile:
            json.dump(globus_auth_data, outfile)
        return globus_auth_data

    return None

def get_globus_transfer_data_struct(client):
    home = os.environ.get("HOME")
    globus_transfer_file = os.path.join(home,'.globus','globus.transfer-data')
    if os.path.isfile(globus_transfer_file):
        with open(globus_transfer_file) as transfer_file:
            return json.load(transfer_file)
    else:
        globus_transfer_data = token.by_resource_server['transfer.api.globus.org']
        with open(globus_transfer_file, 'w') as outfile:
            json.dump(globus_transfer_data, outfile)
        return globus_transfer_data


def get_globus_token(client):
    authorize_url = client.oauth2_get_authorize_url()
    print('Please go to this URL and login: {0}'.format(authorize_url))
    get_input = getattr(__builtins__, 'raw_input', input)
    auth_code = get_input(
        'Please enter the code you get after login here: ').strip()
    token = client.oauth2_exchange_code_for_tokens(auth_code)
    return token

def get_endpoint_id(transfer_client, endpoint_name):
    endpoint = transfer_client.endpoint_search(endpoint_name)
    return endpoint[0]['id']

def activate_endpoint(transfer_client,endpoint_id):
    transfer_client.endpoint_autoactivate(endpoint_id)


def get_transfer_client(client, transfer_data):
    tc_authorizer = RefreshTokenAuthorizer(transfer_data['refresh_token'], client,
                                           access_token=transfer_data['access_token'],
                                           expires_at=transfer_data['expires_at_seconds'])
    tc = TransferClient(authorizer=tc_authorizer)
    return tc

def get_globus_transfer_object(tc, src_endpoint, dest_endpoint, label):
    return TransferData(transfer_client=tc, source_endpoint=src_endpoint,
                        sync_level=3,destination_endpoint=dest_endpoint,
                        label=label)


def add_to_transfer_request(transfer_data, src_path, dest_path):
    recursive = src_path.endswith(os.sep)
    transfer_data.add_item(src_path, dest_path, recursive=recursive)
    return transfer_data


def complete_transfer_request(transfer_client, transfer_data):
    task_id = transfer_client.submit_transfer(transfer_data)['task_id']
    print("Task ID: {}".format(task_id))
    return transfer_client.task_wait(task_id, timeout=600, polling_interval=10)
