import os
import sys
import json
import requests
import pathlib

from github import Github
from github import InputGitAuthor
from github import GithubException

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

def create_branch(repo, branch):
    source = repo.get_branch(os.environ["GITHUB_REF"].replace("refs/heads/",""))

    if any(branch == repo_branch.name for repo_branch in repo.get_branches()):
        print("Branch " + branch + " already exists")
        return True
    else:
        try:
            print("Creating new branch " + branch)
            repo.create_git_ref(ref=as_branch_ref(branch), sha=source.commit.sha)
            return True
        except GithubException as gex:
            print("Unable to create branch "+ branch + " on Github\n"+ str(gex))
            return False
        except Exception:
            print("Unexpected error occurred while crating new branch " + branch)
            return False

def commit_changes_to_file(repo, path, commit_message, new_content, branch, author):
    if any(branch == repo_branch.name for repo_branch in repo.get_branches()):
        try:
            gh_contents = repo.get_contents(path, ref=branch)
        except GithubException as ex:
            if "404" in str(ex) or "not found" in str(ex).lower():
                repo.create_file(path, commit_message, new_content, branch=branch, committer=author)
                print("Successfully added " + path + " on branch " + branch)
                return True
            else:
                print("Unable to add " + path + " to branch " + branch +" on Github\n"+ str(ex))
                return False
        except Exception:
            print("Unexpected error occurred while getting contents for " + path + " on branch " + branch)
            return False

        raw_content = gh_contents.decoded_content
        if new_content != raw_content:
            try:
                repo.update_file(gh_contents.path, commit_message, new_content, gh_contents.sha, branch=branch, committer=author)
                print("Successfully committed changes to " + path + " on branch " + branch)
                return True
            except GithubException as gex:
                print("Unable to commit changes to " + path + " on branch " + branch + " on Github\n"+ str(gex))
                return False
            except Exception:
                print("Unexpected error occurred while committing changes to " + path + " on branch " + branch)
                return False
        else:
            print("No changes to commit to branch " + branch)
            return False
    else:
        print("Branch " + branch + " does not exist, create it first before attempting to commit changes to it.")
        return False

def create_pull(repo, title, body, head, base):
    new_pr = repo.create_pull(title=title, body=body, head=head, base=base)
    if METERIAN_BOT_PR_LABEL not in new_pr.get_labels():
        new_pr.add_to_labels(METERIAN_BOT_PR_LABEL)
    return new_pr

def generate_gh_message(body):
    headers = {"Content-Type": "application/json"}
    response = requests.post("https://services3.www.meterian.io/api/v1/gitbot/results/parse", data = json.dumps(body), headers = headers)
    if response.status_code == 200:
        return json.loads(response.text)
    else:
        print("Unexpected error raised while generating GitHub message")
        sys.exit(1)

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
        except SystemExit:
            sys.exit(0)
        except:
            pass

def verify_branch_can_open_pull_requests(branch):
    verify_branch_exclusion_by_env_glob(branch, "INPUT_AUTOFIX_PR_BRANCHES", message="Workflows triggered from branch " + branch + " are prohibited from opening pull requests. Aborting operation.")

def verify_branch_can_open_issues(branch):
    verify_branch_exclusion_by_env_glob(branch, "INPUT_AUTOFIX_ISSUE_BRANCHES", message="Workflows triggered from branch " + branch + " are prohibited from opening issues. Aborting operation.")

def as_branch_name(branch_ref):
    return branch_ref.replace("refs/heads/", "")

def as_branch_ref(branch_name):
    return "refs/heads/" + branch_name

def create_new_branch_name(repo, postfix):
    tmp_branch_name = "meterian-bot/autofix/" + postfix
    base_branch = as_branch_name(os.environ["GITHUB_REF"])
    if base_branch != repo.default_branch:
        tmp_branch_name = base_branch + "_" + tmp_branch_name

    try:
        new_branch_ref = to_branch_ref(tmp_branch_name)
        return as_branch_name(new_branch_ref)
    except RuntimeError as re:
        print("Unable to create new branch name. " + str(re))

    return None

def search_issues(gh, repo_name, keyword):
    all = gh.search_issues(query='repo:' + repo_name + ' type:issue ' + keyword + ' in:title')
    return all

print()

# Check for the presence of the report.json and exit if is not the case
meterian_report_file = os.environ["METERIAN_AUTOFIX_JSON_REPORT_PATH"]
if os.path.exists(meterian_report_file) is False:
    print(meterian_report_file + " was not found, impossible to load autofix results!")
    sys.exit(1)

# Check whether the workflow was triggered from a tag and exit if it's the case
if "refs/tags" in os.environ["GITHUB_REF"]:
    print("Workflows triggered from tags are unsupported. Aborting operation. ")
    sys.exit(1)

OPEN_PR = False
if "INPUT_AUTOFIX_WITH_PR" in os.environ:
    if os.environ["INPUT_AUTOFIX_WITH_PR"].title() == "True":
        OPEN_PR = True
OPEN_ISSUE = False
if "INPUT_AUTOFIX_WITH_ISSUE" in os.environ:
    if os.environ["INPUT_AUTOFIX_WITH_ISSUE"].title() == "True":
        OPEN_ISSUE = True
OPEN_PR_WITH_REPORT = False
if "INPUT_AUTOFIX_WITH_REPORT" in os.environ:
    if os.environ["INPUT_AUTOFIX_WITH_REPORT"].title() == "True":
        OPEN_PR_WITH_REPORT = True

if "GITHUB_TOKEN" in os.environ:
    # Authenticate through GH API and load the given repository
    gh = Github(os.environ["GITHUB_TOKEN"])
    repo = gh.get_repo(os.environ["GITHUB_REPOSITORY"])

    # Form labels for issues and pull requests
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

    # Setup meterian-bot as Github author
    GH_AUTHOR = InputGitAuthor(
        "meterian-bot",
        "bot.github@meterian.io"
    )

    # Preparing gitbot's request body
    GIT_BOT_REQUEST_BODY = {
        "report": {},
        "options": {
            "autofix": OPEN_PR,
            "issue": OPEN_ISSUE,
            "report": OPEN_PR_WITH_REPORT
        }
    }

    # Load Meterian report
    meterian_report = json.load(open(meterian_report_file))

    meterian_report_pdf=None
    if OPEN_PR_WITH_REPORT:
        meterian_report_pdf = os.environ["METERIAN_AUTOFIX_PDF_REPORT_PATH"]
        OPEN_PR_WITH_REPORT = os.path.exists(meterian_report_pdf)
        if OPEN_PR_WITH_REPORT is False:
            print("The PDF report was not found, it won't be included in the PR")

    if OPEN_PR or OPEN_PR_WITH_REPORT:
        GIT_BOT_REQUEST_BODY = {
            "report": {},
            "options": {
                "autofix": OPEN_PR,
                "issue": False,
                "report": OPEN_PR_WITH_REPORT
            }
        }
        GIT_BOT_REQUEST_BODY["report"] = meterian_report
        gh_message = generate_gh_message(GIT_BOT_REQUEST_BODY)

        print()

        if "autofix" not in meterian_report:
            print("No changes were made in your repository therefore no pull requests will be opened.")
        else:
            print("Changes were made in your repository following the autofix; attempting to open a pull request...")
            base_branch = as_branch_name(os.environ["GITHUB_REF"])

            changes = parse_changes(sys.argv[1:])
            for relative_file_path in changes:
                # Skip report.json and report.pdf if they are in the list of changes
                if os.path.basename(relative_file_path) == "report.json" or os.path.basename(relative_file_path) == "report.pdf":
                    continue

                print("Creating branch for changes on file " + relative_file_path)

                head_branch = create_new_branch_name(repo, relative_file_path)
                if head_branch is None:
                    continue

                # Attempt to create new branch
                if not create_branch(repo, head_branch):
                    continue

                new_pr_title = gh_message["title"]
                new_pr_body = gh_message["message"]

                commit_message = "Update " + relative_file_path + " [skip ci]"

                absolute_file_path = open(os.environ["GITHUB_WORKSPACE"]+"/"+relative_file_path, "rb")
                data = absolute_file_path.read()

                # <head-owner|head-organization>:branch-name
                head_filter = repo.organization.login if repo.organization is not None else repo.owner.login
                head_filter = head_filter + ":" + head_branch

                open_prs = repo.get_pulls(state="open", head=head_filter, base=base_branch)
                if len(open_prs.get_page(0)) > 0:
                    pr = open_prs.get_page(0)[0]
                    updates_were_performed = commit_changes_to_file(repo, relative_file_path, commit_message, data, head_branch, GH_AUTHOR)
                    if OPEN_PR_WITH_REPORT:
                        data = open(meterian_report_pdf, "rb").read()
                        commit_verb = "Update" if "report.pdf" in changes else "Add"
                        updates_were_performed |= commit_changes_to_file(repo, "report.pdf", commit_verb + " PDF report [skip ci]", data, head_branch, GH_AUTHOR)
                    if updates_were_performed:
                        pr.edit(title=new_pr_title, body=new_pr_body)
                        print("Existing pull request was found and updated, review it here:\n" + pr.html_url)
                    else:
                        print("Existing pull request was found, review it here:\n" + pr.html_url)
                    continue

                closed_prs = repo.get_pulls(state="closed", head=head_filter, base=base_branch)
                for closed_pr in closed_prs:
                    if closed_pr.body == new_pr_body and closed_pr.title == new_pr_title:
                        print("No new pull request will be created as an identical pull request has been closed:\n" + closed_pr.html_url)
                        continue

                changes_committed = commit_changes_to_file(repo, relative_file_path, commit_message, data, head_branch, GH_AUTHOR)
                if OPEN_PR_WITH_REPORT:
                    commit_verb = "Update" if "report.pdf" in changes else "Add"
                    data = open(meterian_report_pdf).read()
                    changes_committed |= commit_changes_to_file(repo, "report.pdf", commit_verb + " PDF report [skip ci]", data, head_branch, GH_AUTHOR)
                if changes_committed:
                    new_pr = create_pull(repo, new_pr_title, new_pr_body, head_branch, base_branch)
                    print("A new pull request has been opened, review it here:\n" + new_pr.html_url)

    if OPEN_ISSUE:
        GIT_BOT_REQUEST_BODY = {
            "report": {},
            "options": {
                "autofix": False,
                "issue": OPEN_ISSUE,
                "report": False
            }
        }
        GIT_BOT_REQUEST_BODY["report"] = meterian_report
        gh_message = generate_gh_message(GIT_BOT_REQUEST_BODY)

        print()

        if gh_message["title"] == "":
            print("No problems were detected in your repository therefore no issues will be opened.")
        else:
            print("Some problems were detected in your repository; opening an issue to display these...")

            if repo.has_issues: # checks whether the repo has actually got issues enabled
                new_issue_title = gh_message["title"]
                new_issue_body = gh_message["message"]

                issues = search_issues(gh, os.environ["GITHUB_REPOSITORY"], new_issue_title)
                for issue in issues:
                    if METERIAN_BOT_ISSUE_LABEL in issue.labels and issue.title == new_issue_title and issue.body == new_issue_body:
                        if issue.state == "open":
                            print("The issue has already been opened, view it here:\n" + issue.html_url)
                        else:
                            print("The issue already exists and it has been closed, view it here:\n" + issue.html_url)
                        sys.exit(0)

                new_issue = repo.create_issue(title=new_issue_title, body=new_issue_body, labels=[METERIAN_BOT_ISSUE_LABEL])
                print("A new issue has been opened, view it here:\n" + new_issue.html_url)
            else:
                print("This repository does not have issues enabled, no issues will be opened")