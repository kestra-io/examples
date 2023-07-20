import json
import os
import pandas as pd
from sqlalchemy import create_engine

username = os.environ["DB_USERNAME"]
password = os.environ["DB_PASSWORD"]
host = os.environ["DB_HOST"]
port = os.environ["DB_PORT"]

with open("users.json", "r") as f:
    users = json.load(f)

df_users = pd.DataFrame(users)
df_users["inserted_from"] = "kestra"

engine = create_engine(f"postgresql://{username}:{password}@{host}:{port}")

df_users.to_sql("users", engine, if_exists="append", index=False)
