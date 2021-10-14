import os
import sys

from github import Github
from github import InputGitAuthor

if len(sys.argv[1:]) == 0:
    sys.exit()

if "GITHUB_TOKEN" in os.environ:
    def push(path, message, content, branch):
        author = InputGitAuthor(
            os.environ["GITHUB_ACTOR"],
            "bot.github@meterian.io"
        )

        source = repo.get_branch(os.environ["GITHUB_REF"].replace("refs/heads/",""))
        repo.create_git_ref(ref=f"refs/heads/{branch}", sha=source.commit.sha)  # Create new branch from master
        contents = repo.get_contents(path, ref=branch)  # Retrieve old file to get its SHA and path
        repo.update_file(contents.path, message, content, contents.sha, branch=branch, author=author)  # Add, commit and push branch

    gh = Github(os.environ["GITHUB_TOKEN"])
    repo = gh.get_repo(os.environ["GITHUB_REPOSITORY"])

    for modified_manifest in sys.argv[1:]:
        file_path = modified_manifest

        file = open(os.environ["GITHUB_WORKSPACE"]+"/"+file_path)
        data = file.read()  # Get raw string data

        push(file_path, "Updated README [skip ci]", data, "meterian-scan/autofix/some-dependency-1.0.2")

        body="# Bump some-dependency from 1.0.2 to 1.0.5\n`some-dependency` was upgraded to latest safe version 1.0.5."
        
        head = "meterian-scan/autofix/some-dependency-1.0.2"
        base = os.environ["GITHUB_REF"].replace("refs/heads/","")
        repo.create_pull(title="Bump some-dependency from 1.0.2 to 1.0.5", body=body, head=head, base=base)
else:
    print("The pull request cannot be created, GITHUB_TOKEN was not provided!")