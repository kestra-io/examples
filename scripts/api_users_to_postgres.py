import pandas as pd
import requests
from sqlalchemy import create_engine

URL = "https://gorest.co.in/public/v2/users"
req = requests.get(url=URL)
res = req.json()

df_users = pd.DataFrame(res)
df_users['inserted_from'] = 'kestra'
df_users.head()

password = "{{secret('DB_PASSWORD')}}"
host = "host.docker.internal"

engine = create_engine(
    f"postgresql://postgres:{password}@{host}:5432"
)

df_users.to_sql("my_users", engine, if_exists="append", index=False)
df_users.to_csv("{{outputDir}}/users.csv", index=False)
