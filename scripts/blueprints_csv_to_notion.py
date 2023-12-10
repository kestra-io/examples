import argparse
from ast import literal_eval
import requests
import json
import csv
import os

NOTION_TOKEN = os.environ["NOTION_TOKEN"]
DATABASE_ID = os.environ["DATABASE_ID"]

headers = {
    "Authorization": "Bearer " + NOTION_TOKEN,
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28",
}

failed = []


def evaluate_string_as_list(string):
    try:
        # Use literal_eval to safely evaluate the string as a Python literal
        return literal_eval(string.replace('""', '"'))
    except ValueError:
        return []


def find_page_id(service_id):
    query_payload = {
        "filter": {"or": [{"property": "ID", "number": {"equals": service_id}}]}
    }
    search_url = f"https://api.notion.com/v1/databases/{DATABASE_ID}/query"
    try:
        response_ = requests.post(search_url, headers=headers, json=query_payload)
        results = response_.json().get("results", [])
        if results:
            return results[0]["id"]
    except Exception as e:
        print(f"Failed to find page for flow {service_id}: {e}")
        return None
    return None


def update_notion_page(page_id, data_) -> requests.Response:
    response_ = requests.patch(
        f"https://api.notion.com/v1/pages/{page_id}", headers=headers, json=data_
    )
    return response_


def main(blueprints_csv_path: str) -> None:
    with open(blueprints_csv_path, "r") as csvfile:
        csvreader = csv.DictReader(csvfile)

        for row in csvreader:
            id_ = int(row["id"])
            title = row["title"]
            desc = row["description"]
            flow_code = row["flow"]
            tag_names = row["tags"].split(",")
            included_tasks = evaluate_string_as_list(row["included_tasks"])
            print(f"processing Flow ID: {id_} and title {title}")
            data = {
                "properties": {
                    "title": {"title": [{"text": {"content": title}}]},
                    "ID": {"number": id_},
                    "Strapi": {
                        "url": f"https://strapi.kestra.io/admin/content-manager/collectionType/api::blueprint.blueprint/{id_}"
                    },
                    "Demo": {
                        "url": f"https://demo.kestra.io/ui/blueprints/community/{id_}"
                    },
                    "Local": {"url": f"http://localhost:8080/ui/blueprints/{id_}"},
                    "EC2": {"url": f"http://18.159.167.89:8080/ui/blueprints/{id_}"},
                    "Tags": {"multi_select": [{"name": tag} for tag in tag_names]},
                    "Tasks": {
                        "multi_select": [{"name": task} for task in included_tasks]
                    },
                    "Description": {"rich_text": [{"text": {"content": desc}}]},
                    "Flow": {
                        "rich_text": [
                            {"text": {"content": json.dumps(flow_code[:2000])}}
                        ]
                    },
                    "LastUpdated": {"date": {"start": row["updated_at"], "end": None}},
                }
            }
            print(f"Checking if page exists for flow {id_}")
            existing_page_id = find_page_id(id_)

            try:
                if existing_page_id:
                    print(f"✅ Page {existing_page_id} already exists for flow {id_}")
                    response = update_notion_page(existing_page_id, data)
                else:
                    print(f"✨Creating a new page for flow {id_}")
                    data["parent"] = {"database_id": DATABASE_ID}
                    data["icon"] = {"emoji": "✨"}
                    data["children"] = [
                        {
                            "object": "block",
                            "type": "paragraph",
                            "paragraph": {
                                "rich_text": [
                                    {
                                        "type": "text",
                                        "text": {
                                            "content": row["description"],
                                        },
                                    }
                                ]
                            },
                        },
                        {
                            "object": "block",
                            "type": "code",
                            "code": {
                                "rich_text": [
                                    {
                                        "type": "text",
                                        "text": {
                                            "content": flow_code[:2000],
                                        },
                                    }
                                ],
                                "language": "yaml",
                            },
                        },
                    ]

                    response = requests.post(
                        "https://api.notion.com/v1/pages", headers=headers, json=data
                    )
                code = response.status_code
                print("Status code:", code)
                if code != 200:
                    print("Response:", response.text)
                    print("Retrying without adding Flow and page content")
                    del data["properties"]["Flow"]
                    response = requests.post(
                        "https://api.notion.com/v1/pages", headers=headers, json=data
                    )
            except Exception as e:
                print(f"Failed to add flow {id_} and title {title}: {e}")
                this_flow = dict(id=id_, title=title, status_code=code, reason=e)
                failed.append(this_flow)

    print(f"Failed flows: {failed}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Take the CSV file path and iterate over the rows"
    )
    parser.add_argument("blueprints_csv_path", type=str, help="Path to the CSV file")
    args = parser.parse_args()
    main(args.blueprints_csv_path)
