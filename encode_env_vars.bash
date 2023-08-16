while IFS='=' read -r key value; do
    echo "SECRET_$key=$(echo -n "$value" | base64)";
done < .env > .env_encoded

echo "SECRET_GCP_CREDS=$(base64 --input=credentials.json)" >> .env_encoded

# .env file must end with an empty line
