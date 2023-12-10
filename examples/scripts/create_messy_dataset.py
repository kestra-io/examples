from faker import Faker
import pandas as pd
import random

fake = Faker()


def get_age():
    # add some non-numeric "messy" data
    if random.randint(0, 4) == 0:
        return random.choice(["None", "N/A", "???"])
    return random.randint(18, 65)


data = {
    "First Name": [fake.first_name() for _ in range(1000)],
    "Last Name": [fake.last_name() for _ in range(1000)],
    "Age": [get_age() for _ in range(1000)],
    "Email": [fake.email() for _ in range(1000)],
}

df = pd.DataFrame(data)

df.to_csv("data.csv", index=False)
