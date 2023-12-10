import pandas as pd

df = pd.read_csv("data.csv")

# Replace non-numeric age values with NaN
df["Age"] = pd.to_numeric(df["Age"], errors="coerce")

# mean imputation: fill NaN values with the mean age
mean_age = int(df["Age"].mean())
print(f"Filling NULL values with mean: {mean_age}")
df["Age"] = df["Age"].fillna(mean_age)
df.to_csv("clean_dataset.csv", index=False)
