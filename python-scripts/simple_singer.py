import singer
import urllib.request
import json


schema = {
    "properties": {
        "id": {"type": "string"},
        "employee_name": {"type": "string"},
        "employee_salary": {"type": "string"},
        "employee_age": {"type": "string"},
        "profile_image": {"type": "string"},
    }
}

# Here we make the HTTP request and parse the response
with urllib.request.urlopen(
    "http://dummy.restapiexample.com/api/v1/employees"
) as response:
    emp_data = json.loads(response.read().decode("utf-8"))

singer.write_schema(
    "employees", schema, "id"
)  # writes the schema of the employees stream
singer.write_records(
    "employees", records=emp_data["data"]
)  # write records to that stream


import requests

def get_data_from_api():
    url = "https://dummy.restapiexample.com/api/v1/employees"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        return data
    else:
        return None

data = get_data_from_api()

if data is not None:
    print(data)
else:
    print('Failed to get data from API')
