# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The Meterian Scanner GitHub Action: a Docker-based action that runs the Meterian CLI (a Java jar)
against the checked-out repository to scan dependencies for vulnerabilities, and optionally
autofixes manifests and opens PRs/issues.

There is **no application code, no build step and no test suite** — the whole action is three files:
`action.yml`, `Dockerfile`, and two bash scripts (`entrypoint.sh`, `meterian.sh`). Changes are
almost always bash edits.

## Commands

```bash
# Build the action image locally (base image must be pullable)
docker build -t meterian-gha .

# Smoke-run against a project directory (mimics what the runner does)
docker run --rm -v "$PWD":/workspace -w /workspace \
  -e METERIAN_API_TOKEN -e INPUT_CLI_ARGS="--debug" meterian-gha

# Cut a draft GitHub release tagged v$(cat version.txt) on master
METERIAN_GITHUB_TOKEN=... ./release-to-github.sh

# Undo it (deletes the release and the tag)
METERIAN_GITHUB_TOKEN=... ./delete-release-from-github.sh
```

Debugging: passing `--debug` inside `cli_args` turns on `set -x` in both scripts and stops
stderr from the client being discarded. This is the primary debugging lever — there is nothing else.

## Architecture

**Base image does the heavy lifting.** `meterian/cli:latest-gha` supplies the JVM, every language
toolchain, the `meterian-pr` binary (PR/issue creation), a packaged fallback client at
`/tmp/meterian-cli-www.jar`, `/root/version.txt`, and `meterian_github_action.sh` (used by the
"customizable workflow" documented in the README, where users run the image as a job container).
This repo only layers the two scripts on top.

**Inputs arrive as environment variables, not arguments.** `action.yml` declares positional `args`,
but `entrypoint.sh` ignores `$@` entirely and reads the `INPUT_<NAME>` env vars the runner injects
(`INPUT_CLI_ARGS`, `INPUT_OSS`, `INPUT_AUTOFIX_*`). Adding an input means editing `action.yml`
*and* reading the matching `INPUT_*` var in `entrypoint.sh`.

**Two-stage privilege split.** `entrypoint.sh` runs as root: it creates a `meterian` user whose
uid/gid match the workspace owner (so files the scan writes stay owned by the runner), then runs
`meterian.sh` via `su meterian`. Anything needing root (user creation, `chmod` on `/opt/rust`)
belongs in `entrypoint.sh`; anything touching the scanned project belongs in `meterian.sh`.
`PRE_SCAN_SCRIPT`/`POST_SCAN_SCRIPT` also run as `meterian`.

**Client resolution with fallback.** `meterian.sh` downloads the CLI jar from
`${METERIAN_PROTO}://${METERIAN_ENV}.${METERIAN_DOMAIN}/downloads/meterian-cli.jar` (defaults
`https`/`www`/`meterian.io`, overridable to point at a self-hosted instance), then verifies it with
`java -jar ... --version` and copies the packaged jar over it if that fails. Note `isClientFunctioning`
returns the string `"true"` when the client is **broken** — the name reads backwards, the call site
is correct.

**Exit-code preservation.** The client's exit code is the action's exit code, and it encodes the
scan verdict, so it must survive the post-scan work. `entrypoint.sh` brackets the client run with
`set +e`/`set -e`, stores `cliExitCode`, runs post-scan script and `meterian-pr`, and exits with the
stored code. `meterian.sh` must end with the `java` invocation — never append commands after it.

**Autofix argument assembly** (`entrypoint.sh`): `autofix_security`/`autofix_stability` are composed
into a program string `<strategy>+vulns+no-overrides,<strategy>+dated+no-overrides` (trailing comma
trimmed), which becomes `--autofix:<program>`. The autofix flags are only added at all if one of
`autofix_with_pr`/`_issue`/`_report` is `"true"`. PR/issue creation itself happens *after* the scan,
as root, via `meterian-pr . PR|ISSUE <repo> <branch>`; `--report-pdf` is only emitted when
`autofix_with_report` and `autofix_with_pr` are both true, since the PDF is attached to the PR.

**Branch selection.** `BRANCH_FOR_SCAN` is `GITHUB_REF_NAME`, except on `pull_request*` events where
it is `GITHUB_HEAD_REF` — otherwise scans and PRs would target the merge ref. It is passed both to
the client (`--project-branch`) and to `meterian-pr`.

**SCM metadata** is forced by `meterian.sh` by *prepending* `--project-url/--project-branch/--project-commit`
to `METERIAN_CLI_ARGS`, so a user-supplied value in `cli_args` (appended later) still wins.

## Versioning gotcha

`version.txt` in this repo drives only the GitHub release tag (`v<version>`). The version string
*printed at runtime* comes from `/root/version.txt` in the base image — `.dockerignore` excludes
this repo's copy and the Dockerfile never copies it. Bumping `version.txt` therefore also means
updating the `MeterianHQ/meterian-github-action@vX.Y.Z` references throughout `README.md`
(they appear in every example) and coordinating the base image.

## Undocumented env vars worth knowing

Beyond the README table: `ALWAYS_OPEN_PRS` (reopen identical PRs), `PR_MODE` (currently `bysln`,
becomes `--pullreqs:<mode>`), `CLIENT_VM_PARAMS` (extra JVM flags), `CLIENT_CANARY_FLAG=--canary`
(downloads the canary jar from a hardcoded `meterian.com` URL, ignoring `METERIAN_ENV`).
`MGA_{GITHUB,BITBUCKET,GITLAB}_*` credentials are written into `~/.netrc` by `meterian.sh` to let Go
resolve private modules.
