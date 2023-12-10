import argparse
from bs4 import BeautifulSoup, NavigableString
import json
import markdown2
import os
import re
import requests
from typing import Any, Dict, List, Tuple
from urllib.parse import urlparse


DATABASE_ID = os.environ["DATABASE_ID"]
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
NOTION_TOKEN = os.environ["NOTION_TOKEN"]

GITHUB_HEADERS = {"Authorization": f"token {GITHUB_TOKEN}"}
NOTION_HEADERS = {
    "Authorization": "Bearer " + NOTION_TOKEN,
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28",
}


def truncate_text(text: str, max_length: int = 2000) -> str:
    """Truncate text to a maximum length, so it doesn't exceed max_length of a Notion field."""
    return text if len(text) <= max_length else text[: max_length - 3] + "..."


def markdown_to_html(markdown_text: str) -> str:
    """Convert Markdown text to HTML for better parsing."""
    return markdown2.markdown(markdown_text)


def html_to_notion_blocks(html_content: str) -> List[Any]:
    """Convert HTML content to a list of Notion block structures."""
    soup = BeautifulSoup(html_content, "html.parser")
    blocks = []

    def clean_text(text: str) -> str:
        """Clean and format text by removing unwanted newlines."""
        return text.replace("\r\n", "\n").strip()

    for element in soup.descendants:
        if isinstance(element, NavigableString):
            text = clean_text(str(element))
            if text:  # Add text blocks if not empty
                blocks.append(
                    {
                        "object": "block",
                        "type": "paragraph",
                        "paragraph": {
                            "rich_text": [{"type": "text", "text": {"content": text}}]
                        },
                    }
                )

        elif element.name == "code":  # Handle code blocks
            code_content = clean_text(element.get_text())
            blocks.append(
                {
                    "object": "block",
                    "type": "code",
                    "code": {
                        "rich_text": [
                            {"type": "text", "text": {"content": code_content}}
                        ],
                        "language": "yaml",  # Adjust the language as needed
                    },
                }
            )
        elif element.name == "a":  # Handle links
            url = element.get("href")
            link_text = element.get_text() or url
            blocks.append(
                {
                    "object": "block",
                    "type": "paragraph",
                    "paragraph": {
                        "rich_text": [
                            {
                                "type": "text",
                                "text": {"content": link_text, "link": {"url": url}},
                            }
                        ]
                    },
                }
            )

        elif element.name == "img":  # Handle images
            img_url = element.get("src")
            img_alt_text = element.get("alt", "Image")
            if img_url:  # Ensure the URL is not empty
                blocks.append(
                    {
                        "object": "block",
                        "type": "paragraph",
                        "paragraph": {
                            "rich_text": [
                                {
                                    "type": "text",
                                    "text": {
                                        "content": img_alt_text,
                                        "link": {"url": img_url},
                                    },
                                }
                            ]
                        },
                    }
                )

        elif element.name in ["h1", "h2", "h3", "h4", "h5", "h6"]:  # Handle headings
            heading_type = f"heading_{element.name[-1]}"
            blocks.append(
                {
                    "object": "block",
                    "type": heading_type,
                    heading_type: {
                        "rich_text": [
                            {"type": "text", "text": {"content": element.get_text()}}
                        ]
                    },
                }
            )

        elif element.name == "ul":  # Handle bulleted lists
            for li in element.find_all("li", recursive=False):
                blocks.append(
                    {
                        "object": "block",
                        "type": "bulleted_list_item",
                        "bulleted_list_item": {
                            "rich_text": [
                                {"type": "text", "text": {"content": li.get_text()}}
                            ]
                        },
                    }
                )
        elif element.name == "ol":  # Handle numbered lists
            for li in element.find_all("li", recursive=False):
                blocks.append(
                    {
                        "object": "block",
                        "type": "numbered_list_item",
                        "numbered_list_item": {
                            "rich_text": [
                                {"type": "text", "text": {"content": li.get_text()}}
                            ]
                        },
                    }
                )

    return blocks


def extract_issue_info_from_url(html_url: str) -> Tuple[str, str, str]:
    path_parts = urlparse(html_url).path.split("/")
    owner = path_parts[1]
    repo = path_parts[2]
    issue_number = path_parts[4]
    return owner, repo, issue_number


def fetch_issue_data(owner: str, repo: str, issue_number: str) -> Any:
    api_url = f"https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}"
    response = requests.get(api_url, headers={"Authorization": f"token {GITHUB_TOKEN}"})
    response.raise_for_status()
    return response.json()


def infer_type_from_github_url(html_url: str) -> str:
    """Infer whether a GitHub URL is for a PR or an issue."""
    if "pull" in html_url:
        return "pr"
    elif "issues" in html_url:
        return "issue"
    else:
        raise ValueError(f"Invalid GitHub URL: {html_url}")


def get_review_details(html_url: str) -> Tuple[str, List[str]]:
    # example: ['kestra-io', 'kestra', 'pulls', '2602']
    org, repo_name, _, pr_number = html_url.split("/")[3:]
    reviews_url = (
        f"https://api.github.com/repos/{org}/{repo_name}/pulls/{pr_number}/reviews"
    )
    reviews_response = requests.get(reviews_url, headers=GITHUB_HEADERS)
    reviews = reviews_response.json()

    reviewers = list(set(review["user"]["login"] for review in reviews))

    # Sort reviews by 'submitted_at' to get the latest review first
    sorted_reviews = sorted(reviews, key=lambda x: x["submitted_at"], reverse=True)

    # Determine the final state of the PR
    final_state = "OPEN"
    for review in sorted_reviews:
        if review["state"] in ["APPROVED", "CHANGES_REQUESTED"]:
            final_state = review["state"]
            break

    return final_state, reviewers


def extract_issue_links(body_text: str, github_url: str, user_login: str) -> str:
    """
    Extract issue links from the PR body text.
    :param body_text: Text of the GitHub PR body
    :param github_url: URL of the GitHub PR
    :param user_login: GitHub login of the user who created the issue or PR
    :return: filtered list of issue links
    """
    # Skip extraction if the user is dependabot[bot]
    if user_login == "dependabot[bot]":
        return ""

    # Extract the repository base URL from github_url - removes the last two segments (e.g., 'pull/593')
    repo_base_url = "/".join(github_url.split("/")[:-2])

    # Pattern to match full GitHub issue URLs
    full_url_pattern = r"https://github\.com/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/issues/\d+"
    full_url_matches = re.findall(full_url_pattern, body_text)

    # Pattern to match issue numbers (e.g., #123)
    hashtag_pattern = r"#(\d+)"
    hashtag_matches = re.findall(hashtag_pattern, body_text)

    # Construct full URLs for hashtag matches
    hashtag_url_matches = [
        f"{repo_base_url}/issues/{match}" for match in hashtag_matches
    ]

    # Combine and return all matches
    all_matches = full_url_matches + hashtag_url_matches
    return "\n".join(all_matches)


def extract_repo_name(html_url: str) -> str:
    """
    Extract the repository name (excluding organization) from a GitHub HTML URL.
    Works for URLs pointing to issues and pull requests.
    """
    parts = html_url.split("/")
    # The repository name is the fifth element in the URL
    if len(parts) >= 5 and parts[2] == "github.com":
        return parts[4]
    else:
        raise ValueError(f"Invalid GitHub HTML URL: {html_url}")


def get_comments(comments_url: str) -> List[Dict[str, Any]]:
    """Fetch comments for a GitHub issue or pull request."""
    response = requests.get(comments_url, headers=GITHUB_HEADERS)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Failed to fetch comments: {response.status_code}")
        return []


def create_comment_blocks(comments: List[Dict[str, Any]]) -> List[str]:
    """Create Notion blocks for GitHub comments, skip comments from bots in docs."""
    comment_blocks = []
    for comment in comments:
        user_login = comment["user"]["login"]
        # Skip comments from vercel[bot] and cloudflare-pages[bot]
        if user_login not in ["vercel[bot]", "cloudflare-pages[bot]"]:
            comment_body = comment["body"][:2000]  # Limit the length if necessary
            comment_date = comment["created_at"]
            formatted_comment = (
                f"{user_login} commented on {comment_date}: {comment_body}"
            )
            comment_blocks.append(formatted_comment)
    return comment_blocks


def find_page_id_by_gh_url(html_url: str) -> Any | None:
    query_payload = {
        "filter": {"or": [{"property": "URL", "url": {"equals": html_url}}]}
    }
    search_url = f"https://api.notion.com/v1/databases/{DATABASE_ID}/query"
    try:
        response_ = requests.post(
            search_url, headers=NOTION_HEADERS, json=query_payload
        )
        results = response_.json().get("results", [])
        for result in results:
            # Ensure the returned page URL exactly matches the GitHub URL
            page_url = result["properties"]["URL"].get("url")
            if page_url == html_url:
                return result["id"]
    except Exception as e:
        print(f"Failed to find page for GitHub page {html_url}: {e}")
        return None
    return None


def create_or_update_notion_page(html_url: str) -> None:
    """Create a new page in Notion for the given GitHub issue or PR."""
    owner, repo, issue_number = extract_issue_info_from_url(html_url)
    item = fetch_issue_data(owner, repo, issue_number)

    # Check if the pull request or issue is from dependabot and return immediately if so
    user_login = item["user"]["login"]
    if user_login == "dependabot[bot]":
        print(f"Skipping dependabot PR/issue: {html_url}.")
        return
    label_names = [label["name"] for label in item["labels"]]
    html_url = item["html_url"]
    type_ = infer_type_from_github_url(html_url)
    issue_body = item["body"] if item["body"] is not None else ""
    title = truncate_text(item["title"] if item["title"] is not None else "")
    body = truncate_text(issue_body)
    page_emoji = "✨" if type_ == "issue" else "📝"

    # For both issues and PRs, format assignees as a list of dictionaries
    if type_ == "pr":
        user_login = item["user"]["login"]
        assignees = [{"name": user_login}]
        # Skip PR body from dependabot[bot] if it somehow gets through (it shouldn't)
        if user_login == "dependabot[bot]":
            return
        review_state, reviewers = get_review_details(html_url)
        linked_issues = extract_issue_links(issue_body, html_url, user_login)
    else:
        assignees = [{"name": assignee["login"]} for assignee in item["assignees"]]
        linked_issues = ""
        review_state = "N/A"
        reviewers = []

    data = {
        "parent": {"database_id": DATABASE_ID},
        "properties": {
            "Title": {"title": [{"text": {"content": title}}]},
            "github_id": {"number": item["id"]},
            "Nr": {"number": item["number"]},
            "URL": {"url": html_url},
            "State": {"select": {"name": item["state"]}},
            "Author": {"select": {"name": item["user"]["login"]}},
            "Type": {"select": {"name": type_}},
            "Repository": {"select": {"name": extract_repo_name(html_url)}},
            "Labels": {"multi_select": [{"name": label} for label in label_names]},
            "Assignees": {"multi_select": assignees},
            "Description": {"rich_text": [{"text": {"content": body}}]},
            "Reviewers": {
                "multi_select": [{"name": reviewer} for reviewer in reviewers]
            },
            "Review State": {"select": {"name": review_state}},
            "Linked issues": {"rich_text": [{"text": {"content": linked_issues}}]},
            "Created At": {"date": {"start": item["created_at"], "end": None}},
            "Updated At": {"date": {"start": item["updated_at"], "end": None}},
            # "Linked PRs": {"rich_text": [{"text": {"content": ""}}]},
        },
    }
    if item.get("closed_at"):
        data["properties"]["Closed At"] = {
            "date": {"start": item["closed_at"], "end": None}
        }

    # fetch milestone if exists
    if item.get("milestone"):
        data["properties"]["Milestone"] = {
            "select": {"name": item["milestone"]["title"]}
        }
    comments_url = item["comments_url"]
    comments = get_comments(comments_url)
    if comments:
        comment_blocks = create_comment_blocks(comments)
        comments_text = json.dumps(comment_blocks)
        comments_text = truncate_text(comments_text)

        # Only add 'Comments' property if comments exist
        data["properties"]["Comments"] = {
            "rich_text": [{"text": {"content": comments_text}}]
        }

    existing_page_id = find_page_id_by_gh_url(html_url)
    if existing_page_id:
        print(f"✅ Page {html_url} exists. Updating it.")
        # Update only the necessary fields, especially the state
        del data["properties"]["github_id"]
        del data["properties"]["Nr"]
        del data["properties"]["URL"]
        del data["properties"]["Author"]
        del data["properties"]["Type"]
        del data["properties"]["Repository"]
        del data["properties"]["Created At"]
        response = requests.patch(
            f"https://api.notion.com/v1/pages/{existing_page_id}",
            headers=NOTION_HEADERS,
            json=data,
        )
    else:
        print(f"✨ Creating a new page for {html_url}")
        data["parent"] = {"database_id": DATABASE_ID}
        data["icon"] = {"emoji": page_emoji}
        issue_body = item["body"] if item["body"] is not None else ""
        body = markdown_to_html(issue_body)
        notion_blocks = html_to_notion_blocks(body)
        data["children"] = notion_blocks

        response = requests.post(
            "https://api.notion.com/v1/pages",
            headers=NOTION_HEADERS,
            json=data,
        )
    code = response.status_code

    if code != 200:
        print(f"Retrying insert or update {html_url} based on error: {response.text}")
        if data.get("children"):
            del data["children"]  # errors are usually when the body is too long
        response = requests.post(
            "https://api.notion.com/v1/pages",
            headers=NOTION_HEADERS,
            json=data,
        )
        code = response.status_code

    if code == 200:
        print(f"Successfully processed {html_url}.")
    else:
        failed_insert = {
            "title": title,
            "url": html_url,
            "status_code": code,
            "reason": response.text,
        }
        print(f"Failed to insert {type_} to Notion: {failed_insert}")


def main():
    parser = argparse.ArgumentParser(
        description="Update Notion page with GitHub issue details."
    )
    parser.add_argument("github_url", help="URL of the GitHub issue")

    args = parser.parse_args()
    create_or_update_notion_page(args.github_url)


if __name__ == "__main__":
    main()
