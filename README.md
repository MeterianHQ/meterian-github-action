# Meterian Scanner GitHub Action

The Meterian Scanner GitHub action allows you to automatically scan for vulnerabilities right in your repository as part of your software development workflows.

A list of supported languages can be found [here](https://docs.meterian.io/languages-support/languages-intro).

## Usage

### Pre-required configuration

For usage on closed source repositories you require an authentication API token from Meterian which is only available for paid plans.

Once registered to Meterian with an eligible plan, you can generate an API token and set it as GitHub secret within the repository you wish to scan:

- Generate a Meterian API token
  - Create an account or log into your account on https://meterian.com
  - Create an new secret API token from the dashboard
- Add the above token as a GitHub secret by the name `METERIAN_API_TOKEN`
  - In your repository navigate to the Secrets page ( `Your repository > Settings > Secrets` )
  - Click on the `Add a new Secret`

### Inputs

#### `cli_args`

**Optional** Any additional Meterian CLI options. Find out more about these in the [Meterian documentation](https://docs.meterian.io/).

#### `oss`

**Optional** The Open Source Software flag. When set to `true` a project is scanned as Open Source Software and will not require authentication.

#### `autofix_security`

**Optional** The strategy to use to update vulnerable dependencies. When provided, vulnerable dependencies versions in the project manifest file(s) will be automatically updated according to the given strategy. Find more on the available strategies in [the dedicated workflow section](#Autofix-workflow).

#### `autofix_stability`

**Optional** The strategy to use to update outdated dependencies. When provided, outdated dependencies versions in the project manifest file(s) will be automatically updated according to the given strategy. Find more on the available strategies in [the dedicated workflow section](#Autofix-workflow).

#### `autofix_with_pr`

**Optional** The flag to instruct the action on whether a pull request should be opened as a result of the autofix. When set to `true` a pull request containing the changes applied by the autofix will be opened. 

#### `autofix_with_issue`

**Optional** The flag to instruct the action on whether an issue should be opened as a result of the autofix. When set to `true` an issue will be opened to display unsolved problems within your repository.

#### `autofix_with_report`

**Optional** The flag to instruct the action on whether a pull request also including a PDF report should be opened as a result of the autofix.


### General example workflow

If you don't have an existing [**workflow**](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions) within your repository, you can hit the ground running by using the following snippet

```yaml
#main.yml

name: Meterian Scanner workflow

on: push

jobs:
    meterian_scan:
        name: Meterian client scan
        runs-on: ubuntu-latest
        steps: 
          - name: Checkout
            uses: actions/checkout@v2
          - name: Meterian Scanner
            uses: MeterianHQ/meterian-github-action@v1.0.9
            env:
              METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
```
Save this in a `main.yml` file in the `.github/workflows` folder, in the root of your project:
```
.github
└── workflows
    └── main.yml
```

### Open source repositories workflow

If the project you are planning to scan is open source, you can simply use this example which won't require you to setup and specify an authentication token

```yaml
#main.yml

name: Meterian Scanner workflow

on: push

jobs:
    meterian_scan:
        name: Meterian client scan
        runs-on: ubuntu-latest
        steps:
          - name: Checkout
            uses: actions/checkout@v2
          - name: Meterian Scanner
            uses: MeterianHQ/meterian-github-action@v1.0.9
            with:
              oss: true
```

### Autofix workflow

Through the autofix feature it is possible to have vulnerable or outdated dependencies definitions within the project's manifest file(s) automatically fixed. Fixes apply by updating the given dependency version number according to the chosen strategy. Here is a list of available strategies:

- safe: update the dependency version number only with patch versions updates
- conservative: update the dependency version number with either minor or patch versions updates
- aggressive: update the dependency version number with either major, minor or path versions updates

A workflow that uses the autofix requires the `GITHUB_TOKEN` environment variable set to ${{ github.token }} and should have at least one of the `autofix_with_*` flags set otherwise no result will be displayed in the form of issue or pull request (should there be problems that need to be reported in your repository):
```yaml
#main.yml

name: Meterian Scanner workflow

on: push

jobs:
    meterian_scan:
        name: Meterian client scan
        runs-on: ubuntu-latest
        steps: 
          - name: Checkout
            uses: actions/checkout@v2
          - name: Meterian Scanner
            uses: MeterianHQ/meterian-github-action@v1.0.9
            env:
              METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
              GITHUB_TOKEN: ${{ github.token }}
            with:
              autofix_security: conservative
              autofix_stability: safe
              autofix_with_pr: true
```
The workflow above will cause the Meterian Github action to scan your repository and perform the autofix fixing any vulnerable dependency with either the latest safe patch or minor version update, and fixing any outdated dependency with the latest safe patch version update where applicable. Following the fixes if changes have been made within the repo as instructed by the `autofix_with_pr` flag, a pull request will be opened detailing on these changes.

**Note**: as of now the autofix will only work on the following manifest files:
- pom.xml (Java, maven)
- composer.json (PHP, composer)
- Gemfile, Gemfile.lock (Ruby, bundle)
- Pipfile, Pipfile.lock (Python, pipenv)
- package.json, package-lock.json (NodeJs, npm)

### Integrating the action with an existing workflow

Within your workflow, create a job step that uses the Meterian GitHub action

```yaml   
# jobs.<job_id>.steps 
    - name: Meterian Scanner
      uses: MeterianHQ/meterian-github-action@v1.0.9
      env:
        METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
```
Optionally specify a client input argument
```yml
      with:
        cli_args: --min-security=85
```
**Note:** the above snippet assumes that you are already [checking-out](https://github.com/actions/checkout#checkout-v2) your repository. 

### Configure the action to support Go private modules

When scanning a Go project, to enable private modules to be resolved you need to define the following environment variables in your workflow according to which code hosting site they are hosted on (supported code hosting sites are: GitHub, BitBucket and GitLab):

| Environment variable | Description |
|----------------------|:-----------:|
| MGA_GITHUB_USER | You GitHub username |
| MGA_GITHUB_TOKEN (*) | Valid [GitHub access token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) |
| MGA_BITBUCKET_USER | Your BitBucket username |
| MGA_BITBUCKET_APP_PASSWORD (*) | Valid [BitBucket application password](https://confluence.atlassian.com/bitbucket/app-passwords-828781300.html) |
| MGA_GITLAB_USER | Your GitLab username |
| MGA_GITLAB_TOKEN (*) | Valid [GitLab access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) |
| GOPRIVATE | Comma-separated list of glob patterns ([in the syntax of Go's path.Match](https://golang.org/pkg/path/filepath/#Match)) of module path prefixes. Find out more [here](https://golang.org/cmd/go/#hdr-Module_configuration_for_non_public_modules) |

*(\*) must be defined as secret just as `METERIAN_API_TOKEN` is defined*

An example workflow looks like the following:

```yaml
name: Meterian Scanner workflow

on: push

jobs:
    meterian_scan:
        name: Meterian client scan
        runs-on: ubuntu-latest
        steps: 
          - name: Checkout
            uses: actions/checkout@v2
          - name: Scan project with the Meterian client
            uses: MeterianHQ/meterian-github-action@v1.0.9
            env:
                METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
                MGA_GITHUB_USER: joe-bloggs123
                MGA_GITHUB_TOKEN: ${{ secrets.MGA_GITHUB_TOKEN }}
                GOPRIVATE: "github.com/MyOrgName"
```
The above `GOPRIVATE` causes the `go` command to treat as private any module with a path prefix matching the provided pattern (e.g. github.com/MyOrgName/xyzzy)

In case you had other private modules hosted on say BitBucket here's how the above example changes:

```yaml
name: Meterian Scanner workflow

on: push

jobs:
    meterian_scan:
        name: Meterian client scan
        runs-on: ubuntu-latest
        steps: 
          - name: Checkout
            uses: actions/checkout@v2
          - name: Scan project with the Meterian client
            uses: MeterianHQ/meterian-github-action@v1.0.9
            env:
                METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
                MGA_GITHUB_USER: joe-bloggs123
                MGA_GITHUB_TOKEN: ${{ secrets.MGA_GITHUB_TOKEN }}
                MGA_BITBUCKET_USER: john-doe456
                MGA_BITBUCKET_APP_PASSWORD: ${{ secrets.MGA_BITBUCKET_APP_PASSWORD }}
                GOPRIVATE: "github.com/MyOrgName,bitbucket.org/MyOrgName"
```

## Examples

- [Java sample project](https://github.com/MeterianHQ/java-sample-project/blob/master/.github/workflows/main.yml)
- [Php sample project](https://github.com/MeterianHQ/php-sample-project/blob/master/.github/workflows/main.yml)
- [Dotnet sample project](https://github.com/MeterianHQ/dotnet-sample-project/blob/master/.github/workflows/main.yml)
- [Ruby sample project](https://github.com/MeterianHQ/ruby-sample-project/blob/master/.github/workflows/main.yml)
- [Python sample project](https://github.com/MeterianHQ/python-sample-project/blob/master/.github/workflows/main.yml)
- [Node.js sample project](https://github.com/MeterianHQ/node-sample-project/blob/master/.github/workflows/main.yml)
- [Go sample project](https://github.com/MeterianHQ/go-sample-project/blob/master/.github/workflows/main.yml)
- [Swift sample project](https://github.com/MeterianHQ/swift-sample-project/blob/master/.github/workflows/main.yml)
- [Scala sample project](https://github.com/MeterianHQ/scala-sample-project/blob/master/.github/workflows/main.yml)
- [Rust sample project](https://github.com/MeterianHQ/rust-sample-project/blob/master/.github/workflows/main.yml)
- [Elixir sample project](https://github.com/MeterianHQ/elixir-sample-project/blob/main/.github/workflows/main.yml)
- [Perl sample project](https://github.com/MeterianHQ/perl-sample-project/blob/main/.github/workflows/main.yml)
- [C++ sample project](https://github.com/MeterianHQ/cpp-sample-project/blob/master/.github/workflows/main.yml)
- [R sample project](https://github.com/MeterianHQ/r-sample-project/blob/master/.github/workflows/main.yml)

<br>

## GitHub Actions related and other resources

- https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions
- https://developer.github.com/marketplace
- https://www.youtube.com/watch?v=Tl4mbL45PKU
- https://help.github.com/en/actions/configuring-and-managing-workflows/using-variables-and-secrets-in-a-workflow
