#!/usr/bin/env python3
import json
import requests
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Set target array address
target = "10.21.204.131"

# API version to use
# TO-DO: dynamically get the latest version
latest_api_version = "2.45"

# Authenticate and get x-auth-token
session = requests.Session()
login_url = f'https://{target}/api/{latest_api_version}/login'
session.headers.update({
    "api-token": "366a220f-c563-f660-54d0-a48532628005"
})

response = session.post(login_url, verify=False)
x_auth_token = response.headers.get("x-auth-token")
if x_auth_token:
    session.headers.update({"x-auth-token": x_auth_token})
else:
    print("Error: x-auth-token not found in response headers.")
print(x_auth_token)

# Get fleet info
fleets_url = f'https://{target}/api/{latest_api_version}/fleets'
fleets_response = session.get(fleets_url, verify=False)
fleets_json = fleets_response.json()
fleet_name = fleets_json['items'][0]['name']
print (f"Selected fleet: {fleet_name}")

# Get fleet members
members_url = f"https://{target}/api/{latest_api_version}/fleets/members?fleet_name={fleet_name}"
fleets_response_members = session.get(members_url, verify=False)
VAR1 = fleets_response_members.json()
VAR_RESULTS = [item['member']['name'] for item in VAR1['items']]
print(f"Fleet members: {VAR_RESULTS}")

# Enumerate all volumes in the fleet with pagination
print("\nEnumerating volumes in the fleet:")
limit = 10 # Adjust as needed
continuation_token = None
all_volumes = []
volumes_base_url = f"https://{target}/api/{latest_api_version}/volumes?context_names={','.join(VAR_RESULTS)}"

while True:
    params = {'limit': limit}
    if continuation_token:
        params['continuation_token'] = continuation_token
    volumes_response = session.get(volumes_base_url, params=params, verify=False)
    volumes_json = volumes_response.json()
    all_volumes.extend(volumes_json.get('items', []))
    continuation_token = volumes_response.headers.get('x-next-token')
    if not continuation_token:
        break

print(f"Total volumes found: {len(all_volumes)}")
print(json.dumps(all_volumes, indent=2))

# Enumerate hosts in the fleet with pagination
print("\nEnumerating hosts in the fleet:")
limit = 10 # Adjust as needed
continuation_token = None
all_hosts = []
hosts_base_url = f"https://{target}/api/{latest_api_version}/hosts?context_names={','.join(VAR_RESULTS)}"

while True:
    params = {'limit': limit}
    if continuation_token:
        params['continuation_token'] = continuation_token
    hosts_response = session.get(hosts_base_url, params=params, verify=False)
    hosts_json = hosts_response.json()
    all_hosts.extend(hosts_json.get('items', []))
    continuation_token = hosts_response.headers.get('x-next-token')
    if not continuation_token:
        break

print(f"Total hosts found: {len(all_hosts)}")
print(json.dumps(all_hosts, indent=2))

# Select a member array (not the target)
member_array = next((name for name in VAR_RESULTS if name != target), None)
if not member_array:
    print("No other member array found in the fleet.")
    exit(1)
print(f"Selected member array for operations: {member_array}")

# Create a new host on the member array
host_name = "demo-host-01"
host_iqn = "iqn.2025-08.com.fleetdemo:host01"
host_payload = {
    "names": host_name,
    "iqn": [host_iqn],
    "context": {
        "name": member_array
    }
}
hosts_url = f"https://{target}/api/{latest_api_version}/hosts"
host_resp = session.post(hosts_url, json=host_payload, verify=False)
print(f"Host creation response: {host_resp.json()}")

# Create a new volume on the member array
volume_name = "APIDemo-vol1"
volume_payload = {
    "names": volume_name,
    "provisioned": 10737418240,  # 10 GB in bytes
    "context": {
        "name": member_array
    }
}
volumes_url = f"https://{target}/api/{latest_api_version}/volumes"
volume_resp = session.post(volumes_url, json=volume_payload, verify=False)
print(f"Volume creation response: {volume_resp.json()}")

# Connect the volume to the host
connect_payload = {
    "volume_names": volume_name,
    "context_names":member_array,
    "host_names": host_name,
}
connections_url = f"https://{target}/api/{latest_api_version}/connections"
connect_resp = session.post(connections_url, json=connect_payload, verify=False)
print(f"Connection response: {connect_resp.json()}")
