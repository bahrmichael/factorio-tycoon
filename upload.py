import sys
import requests
from os import getenv

MOD_PORTAL_URL = "https://mods.factorio.com"
INIT_UPLOAD_URL = f"{MOD_PORTAL_URL}/api/v2/mods/releases/init_upload"

apikey = getenv("MOD_UPLOAD_API_KEY")
modname = getenv("MOD_UPLOAD_NAME")
zipfilepath = getenv("MOD_UPLOAD_FILE")

request_body = data={"mod":modname}
request_headers = {"Authorization": f"Bearer {apikey}"}

response = requests.post(
	INIT_UPLOAD_URL,
	data=request_body,
	headers=request_headers)

if not response.ok:	
	print(f"init_upload failed: {response.text}")
	sys.exit(1)

upload_url = response.json()["upload_url"]

with open(zipfilepath, "rb") as f:	
	request_body = {"file": f}	
	response = requests.post(upload_url, files=request_body)

if not response.ok:	
	print(f"upload failed: {response.text}")	
	sys.exit(1)

print(f"upload successful: {response.text}")