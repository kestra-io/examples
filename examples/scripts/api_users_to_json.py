import json
import requests

URL = "https://gorest.co.in/public/v2/users"
req = requests.get(url=URL)
res = req.json()

with open("users.json", "w") as f:
    json.dump(res, f)
