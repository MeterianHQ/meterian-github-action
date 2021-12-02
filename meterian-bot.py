import os
import sys
import json
import requests
import pathlib

from github import Github
from github import InputGitAuthor

def replace_if(old, new, condition):
    if condition:
        return new
    else:
        return old

def remove_control_chars(text):
    new_text = ""
    for charr in text:
        new_text+=replace_if(charr, "", ord(charr) <= 32 or ord(charr) == 127)
    return new_text

def sanitize_github_ref(name):
    new_name = ""
    tokens = name.split("/")
    for token in tokens:
        token = replace_if(token, token[1:], token.startswith("."))
        token = replace_if(token, token[0:len(token)-1], token.endswith("."))
        token = replace_if(token, token.replace(".lock", "_lock"), token.endswith(".lock"))
        token = token.replace("..", "_")
        token = token.replace("~", "_")
        token = token.replace("^", "_")
        token = token.replace(":", "_")
        token = token.replace("?", "_")
        token = token.replace("*", "_")
        token = token.replace("[", "_")
        token = token.replace("@{", "_")
        token = token.replace("\\", "_")
        token = remove_control_chars(token)

        if new_name == "":
            new_name = token
        else:
            new_name = replace_if(new_name, "/".join([new_name, token]), token != "")
    return new_name

def to_branch_ref(name):
    ref = "refs/heads/"+sanitize_github_ref(name)
    if ref == "refs/heads/" or ref == "refs/heads/@":
        raise RuntimeError("Invalid ref " + ref + " was generated!")
    return ref

def commit_changes(repo, path, commit_message, new_content, branch, author):

    source = repo.get_branch(os.environ["GITHUB_REF"].replace("refs/heads/",""))

    if any(branch == repo_branch.name for repo_branch in repo.get_branches()):
        gh_contents = repo.get_contents(path, ref=branch)
        raw_content = gh_contents.decoded_content.decode("utf-8")
        if new_content != raw_content:
            repo.update_file(gh_contents.path, commit_message, new_content, gh_contents.sha, branch=branch, committer=author)
            print("New commit added to branch " + branch)
            return True
        else:
            print("No changes to commit to branch " + branch)
            return False
    else:
        try:
            print("Creating new branch " + branch)
            the_ref = to_branch_ref(branch)
            repo.create_git_ref(ref=the_ref, sha=source.commit.sha)
            gh_contents = repo.get_contents(path, ref=branch)
            repo.update_file(gh_contents.path, commit_message, new_content, gh_contents.sha, branch=branch, committer=author)
            return True
        except Exception:
            print("unexpected error occurred while crating new branch " + branch)
            sys.exit(1)

def create_pull(repo, title, body, head, base):
    new_pr = repo.create_pull(title=title, body=body, head=head, base=base)
    if METERIAN_BOT_PR_LABEL not in new_pr.get_labels():
        new_pr.add_to_labels(METERIAN_BOT_PR_LABEL)
    return new_pr


def generate_gh_message(body):
    headers = {"Content-Type": "application/json", "Authorization": "token " + os.environ["METERIAN_API_TOKEN"]}
    response = requests.post("https://services3.qa.meterian.io/api/v1/gitbot/results/parse", data = json.dumps(body), headers = headers)
    if response.status_code == 200:
        return json.loads(response.text)
    else:
        raise Exception("Unexpected error raised while generating GitHub message")

def parse_changes(args):
    changes=[]
    for arg in args:
        if arg != "report.json":
            changes.append(arg)
    return changes

def verify_branch_exclusion_by_env_glob(branch, target_conf_env_var_keyword, message=""):
    if target_conf_env_var_keyword in os.environ:
        try:
            globs = os.environ[target_conf_env_var_keyword].split(" ")
            for glob in globs:
                # **/* is equivalent to ** in GitHub Actions Workflow Syntax documentation
                glob = glob.replace("**", "**/*")
                if not pathlib.PurePath(branch).match(glob):
                    print(message)
                    sys.exit(0)
        except:
            pass

def verify_branch_can_open_pull_requests(branch):
    verify_branch_exclusion_by_env_glob(branch, "INPUT_AUTOFIX_PR_BRANCHES", message="Workflows triggered from branch " + branch + " are prohibited from opening pull requests. Aborting operation.")

def verify_branch_can_open_issues(branch):
    verify_branch_exclusion_by_env_glob(branch, "INPUT_AUTOFIX_ISSUE_BRANCHES", message="Workflows triggered from branch " + branch + " are prohibited from opening issues. Aborting operation.")



meterian_report_file = os.environ["METERIAN_AUTOFIX_REPORT_PATH"]
if os.path.exists(meterian_report_file) is False:
    print(meterian_report_file + "was not found, impossible to load autofix results!")
    sys.exit(1)

if "GITHUB_TOKEN" in os.environ:
    gh = Github(os.environ["GITHUB_TOKEN"])
    repo = gh.get_repo(os.environ["GITHUB_REPOSITORY"])

    METERIAN_BOT_ISSUE_LABEL = None
    try:
        METERIAN_BOT_ISSUE_LABEL = repo.get_label("meterian-bot-issue")
    except:
        METERIAN_BOT_ISSUE_LABEL = repo.create_label("meterian-bot-issue", "2883fa", "Issue opened to highlight outdated dependencies found by Meterian's analysis")

    METERIAN_BOT_PR_LABEL = None
    try:
        METERIAN_BOT_PR_LABEL = repo.get_label("meterian-bot-pr")
    except:
        METERIAN_BOT_PR_LABEL = repo.create_label("meterian-bot-pr", "2883fa", "Pull requests that update dependency files based on Meterian's analysis")

    GH_AUTHOR = InputGitAuthor(
        "meterian-bot",
        "bot.github@meterian.io"
    )

    # Figure what option to pick for gitbot's message generation based on autofix results
    GIT_BOT_REQUEST_BODY = {
        "report": {},
        "options": {
            "autofix": False,
            "issue": False,
            "report": False
        }
    }

    meterian_report = json.load(open(meterian_report_file))
    if "autofix" in meterian_report:
        GIT_BOT_REQUEST_BODY["options"]["autofix"] = True
    else:
        GIT_BOT_REQUEST_BODY["options"]["issue"] = True
    GIT_BOT_REQUEST_BODY["report"] = meterian_report

    gh_message=None
    try:
        gh_message = generate_gh_message(GIT_BOT_REQUEST_BODY)
    except:
        print("Unexpected error raised while generating GitHub message")
        sys.exit(1)

    base_branch = os.environ["GITHUB_REF"].replace("refs/heads/","")
    if GIT_BOT_REQUEST_BODY["options"]["autofix"] :
        if "refs/tags" in os.environ["GITHUB_REF"]:
            print("Workflows triggered from tags are unsupported. Aborting operation. ")
            sys.exit(1)

        verify_branch_can_open_pull_requests(base_branch)

        print("The manifest file(s) were updated; opening a pull request...")
        changes = parse_changes(sys.argv[1:])
        for relative_file_path in changes:
            absolute_file_path = open(os.environ["GITHUB_WORKSPACE"]+"/"+relative_file_path)
            data = absolute_file_path.read()

            #TODO should be calling gitbot for an updated message tailored to the specific manifest file (especially when multiple)
            #     (having done the appropriate tweaks to the report.json excluding any other change besides the one relative to a given manifest file)
            new_pr_title = gh_message["title"]
            new_pr_body = gh_message["message"] + "\n Test"

            head_branch = "meterian-bot/autofix/" + relative_file_path
            if base_branch != repo.default_branch:
                head_branch = base_branch + "_" + head_branch

            commit_message = "Update " + relative_file_path + " [skip ci]"

            # <head-owner|head-organization>:branch-name
            head_filter = repo.organization.login if repo.organization is not None else repo.owner.login
            head_filter = head_filter + ":" + head_branch

            open_prs = repo.get_pulls(state="open", head=head_filter, base=base_branch)
            if len(open_prs.get_page(0)) > 0:
                pr = open_prs.get_page(0)[0]
                if commit_changes(repo, relative_file_path, commit_message, data, head_branch, GH_AUTHOR):
                    pr.edit(title=new_pr_title, body=new_pr_body)
                    print("Existing pull request was found and updated, review it here:\n" + pr.html_url)
                else:
                    print("Existing pull request was found, review it here:\n" + pr.html_url)
                sys.exit(0)

            closed_prs = repo.get_pulls(state="closed", head=head_filter, base=base_branch)
            for closed_pr in closed_prs:
                if closed_pr.body == new_pr_body and closed_pr.title == new_pr_title:
                    print("No new pull request will be created as an identical pull request has been closed:\n" + closed_pr.html_url)
                    sys.exit(0)

            commit_changes(repo, relative_file_path, commit_message, data, head_branch, GH_AUTHOR)
            new_pr = create_pull(repo, new_pr_title, new_pr_body, head_branch, base_branch)
            print("A new pull request has been opened, review it here:\n" + new_pr.html_url)
    else:
        verify_branch_can_open_issues(base_branch)

        print("No manifest files were updated as result of the autofix, but some problems were detected; Opening an issue to display these...")
        new_issue_title = gh_message["title"]
        new_issue_body = gh_message["message"]
        for issue in repo.get_issues(state="all", labels=[METERIAN_BOT_ISSUE_LABEL]):
            if issue.title == new_issue_title and issue.body == new_issue_body:
                if issue.state == "open":
                    print("The issue has already been opened, view it here:\n" + issue.html_url)
                else:
                    print("The issue already exists and it has been closed, view it here:\n" + issue.html_url)

        new_issue = repo.create_issue(title=new_issue_title, body=new_issue_body, labels=[METERIAN_BOT_ISSUE_LABEL])
        print("A new issue has been opened, view it here:\n" + new_issue.html_url)

else:
    print("GITHUB_TOKEN was not provided, no action can be taken!")