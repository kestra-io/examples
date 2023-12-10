import io
import os
import tempfile
import zipfile
import pandas as pd
import requests

# import awswrangler as wr


def extract() -> pd.DataFrame:
    url = "https://wri-dataportal-prod.s3.amazonaws.com/manual/global_power_plant_database_v_1_3.zip"
    cols = ["country", "primary_fuel", "capacity_mw"]
    response = requests.get(url)
    if response.status_code == 200:
        with zipfile.ZipFile(io.BytesIO(response.content)) as zfile:
            with tempfile.TemporaryDirectory() as tempdir:
                zfile.extractall(tempdir)
                path = os.path.join(tempdir, "global_power_plant_database.csv")
                df = pd.read_csv(path, usecols=cols)
                return df.drop_duplicates()


def transform_mean_capacity_per_country(df: pd.DataFrame) -> pd.DataFrame:
    return df.groupby(["country", "primary_fuel"]).mean()


def transform_total_capacity_worldwide(df: pd.DataFrame) -> pd.DataFrame:
    return df[["primary_fuel", "capacity_mw"]].groupby(["primary_fuel"]).sum()


def load_to_data_lake(df: pd.DataFrame, dataset_name: str) -> None:
    """
    For reproducibility on your end, we'll just print the command to load the data to the data lake.
    """
    command = f"""
    wr.s3.to_parquet(
        df,
        index=True,
        dataset=True,
        mode="overwrite",
        database="default",
        table=f"{dataset_name}",
        path=f"s3://data-lake-silver/{dataset_name}/",
    )
    """
    print(command)


def run_etl():
    raw_data = extract()
    mean_capacity_per_country = transform_mean_capacity_per_country(raw_data)
    total_capacity_worldwide = transform_total_capacity_worldwide(raw_data)
    load_to_data_lake(mean_capacity_per_country, "mean_capacity_per_country")
    load_to_data_lake(total_capacity_worldwide, "total_capacity_worldwide")
    print(mean_capacity_per_country)
    print(total_capacity_worldwide)


if __name__ == "__main__":
    run_etl()
