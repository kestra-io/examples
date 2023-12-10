import argparse
import requests
from datetime import datetime, timedelta
from typing import List, Any
from kestra import Kestra
import os

DATABASE_ID = os.environ["DATABASE_ID"]
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
NOTION_TOKEN = os.environ["NOTION_TOKEN"]

GITHUB_HEADERS = {"Authorization": f"token {GITHUB_TOKEN}"}
NOTION_HEADERS = {
    "Authorization": "Bearer " + NOTION_TOKEN,
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28",
}


def _get_issue_number_from_url(html_url):
    return html_url.split("/")[-1]


def _get_repo_from_url(html_url):
    return html_url.split("/")[-3]


class NotionPage:
    def __init__(self):
        self.database_id = DATABASE_ID
        self.github_headers = GITHUB_HEADERS
        self.milestone_title = None
        self.html_url = None
        self.title = None
        self.assignees = None
        self.labels = None

    def get_or_create_gh_milestone_number(self, repo: str) -> str | None:
        milestone_number = None
        milestones_url = f"https://api.github.com/repos/kestra-io/{repo}/milestones"
        if self.milestone_title:
            response = requests.get(milestones_url, headers=self.github_headers)
            if response.status_code == 200:  # milestone exists
                for existing_milestone in response.json():
                    if existing_milestone["title"] == self.milestone_title:
                        milestone_number = existing_milestone["number"]
                        break
            # Create milestone and get its number
            if milestone_number is None:
                response = requests.post(
                    milestones_url,
                    json={"title": self.milestone_title},
                    headers=self.github_headers,
                )
                if response.status_code == 201:  # milestone created
                    milestone_number = response.json()["number"]
                else:
                    print(
                        f"Failed to create milestone for {repo}. Error: {response.json()}."
                    )
                    return
        return milestone_number

    def update_github_issue(self, page: dict):
        properties = page["properties"]
        self.title = properties["Title"]["title"][0]["text"]["content"]
        self.labels = [label["name"] for label in properties["Labels"]["multi_select"]]
        self.milestone_title = (
            properties["Milestone"]["select"]["name"]
            if properties["Milestone"]["select"]
            else None
        )
        self.assignees = [
            assignee["name"]
            for assignee in properties["Assignees"]["multi_select"]
            if assignee != "dependabot[bot]"
        ]
        self.html_url = properties["URL"]["url"]
        repo = _get_repo_from_url(self.html_url)
        issue_number = _get_issue_number_from_url(self.html_url)
        issue_url = (
            f"https://api.github.com/repos/kestra-io/{repo}/issues/{issue_number}"
        )
        milestone_number = self.get_or_create_gh_milestone_number(repo)

        # Prepare data for issue update
        data = {"title": self.title}
        if self.assignees:
            data["assignees"] = self.assignees
        if self.labels:
            data["labels"] = self.labels
        if milestone_number is not None:
            data["milestone"] = milestone_number

        response = requests.patch(issue_url, json=data, headers=self.github_headers)
        if response.status_code in [200, 201, 204]:
            print(f"Updated GitHub issue/PR: {self.html_url}")
            Kestra.outputs({f"{repo}-{issue_number}": self.html_url})
        else:
            try:
                error_message = response.json()
            except ValueError:
                error_message = "No JSON response available"
            print(f"Failed to update issue for {issue_url}. Error: {error_message}.")


def get_notion_pages(
    minutes_ago: int = 2, last_checked: datetime = None
) -> List[Any] | None:
    if last_checked is None:
        last_checked = datetime.utcnow() - timedelta(minutes=minutes_ago)
    time_ago_iso = last_checked.isoformat() + "Z"

    all_pages = []
    start_cursor = None

    while True:
        query_url = f"https://api.notion.com/v1/databases/{DATABASE_ID}/query"
        query_payload = {
            "filter": {
                "and": [
                    {
                        "timestamp": "last_edited_time",
                        "last_edited_time": {"after": time_ago_iso},
                    },
                    {"property": "State", "select": {"equals": "open"}},
                    {"property": "Type", "select": {"equals": "issue"}},
                ]
            }
        }

        if start_cursor is not None:
            query_payload["start_cursor"] = start_cursor

        response = requests.post(query_url, json=query_payload, headers=NOTION_HEADERS)
        if response.status_code != 200:
            print(f"Failed to query Notion. Status code: {response.status_code}")
            print(f"Response: {response.json()}")
            return None

        data = response.json()
        all_pages.extend(data.get("results", []))

        if not data.get("has_more", False):
            break

        start_cursor = data.get("next_cursor")

    print(f"{len(all_pages)} Notion page(s) changed since {time_ago_iso}")
    return all_pages


def main():
    parser = argparse.ArgumentParser(
        description="Fetch Notion pages modified in the specified time frame."
    )
    parser.add_argument(
        "-m",
        "--minutes",
        type=int,
        default=2,
        help="Number of minutes ago to check for modified Notion pages. Default is 2 minutes.",
    )
    args = parser.parse_args()

    pages = get_notion_pages(minutes_ago=args.minutes)
    if pages:
        for page in pages:
            notion_page = NotionPage()
            notion_page.update_github_issue(page)


if __name__ == "__main__":
    main()
