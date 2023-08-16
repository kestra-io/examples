from faker import Faker
import datetime
import csv

fake = Faker()

employees = []

for _ in range(500):
    first_name = fake.first_name()
    last_name = fake.last_name()
    email = f'{first_name.lower()}.{last_name.lower()}@kestra.io'
    street_address = fake.street_address()
    city = fake.city()
    start_date = fake.date_between(datetime.date(2022, 1, 30), datetime.date(2023, 8, 1))

    employee = {
        "FIRST_NAME": first_name,
        "LAST_NAME": last_name,
        "EMAIL": email,
        "STREETADDRESS": street_address,
        "CITY": city,
        "START_DATE": start_date
    }

    employees.append(employee)

keys = employees[0].keys()

with open('employees00.csv', 'w', newline='') as output_file:
    dict_writer = csv.DictWriter(output_file, keys)
    dict_writer.writeheader()
    dict_writer.writerows(employees)
