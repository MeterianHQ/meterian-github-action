# Meterian Scanner GitHub Action

Scan for vulnerabilities in your project using the Meterian Scanner GitHub action 

## Inputs

### `cli_args`

**Optional** - Any additional Meterian CLI options. Find out more about these via the [Meterian PDF manual](https://www.meterian.com/documents/meterian-cli-manual.pdf).

## Outputs

### `exit_code`

The exit code representing the client scan outcome:
- +1: failure on the security score
- +2: failure on the stability score
- +4: failure on the licensing score

Find out more in the [Meterian PDF manual](https://www.meterian.com/documents/meterian-cli-manual.pdf).

## How to configure and use the action

- Add an action via the Actions tab in the GitHub interface (see [resource below for help](#github-actions-related-and-other-resources))
- Create or amend an existing workflow (see [Example Workflow](#example-workflow))
- Use the `MeterianHQ/meterian-github-action@master` in the `uses` directive
- Generate the Meterian API token
    - Create an account or log into your account on http://meterian.com
    - Create an new secret API token from the dashboard
- Add the above token as a GitHub secret by the name METERIAN_API_TOKEN
    - Go to the https://github.com/[your-org]/[your-repo]/settings/secrets page and click on the `Add a new Secret` link


### Example workflow

Below is an example workflow using the Meterian Scanner GitHub Action:

```
name: Meterian Scanner workflow

on: push

jobs:
    meterian_scan:
        name: Meterian client scan
        runs-on: ubuntu-latest
        steps: 
          - name: Checkout
            uses: actions/checkout@v2
          - name: Meterian Scanner Action
            id: vuln_scan
            uses: MeterianHQ/meterian-github-action@master
            env:
              METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
            with:
                args: "" ## placeholder for METERIAN_CLI_ARGS

          # Example job step that stops the workflow skipping following steps
          # if the build has a nonzero exit code
          # This step can be personalized to your liking

          - name: Act on scan outcome exit code
            run: |
               exit_code=${{ steps.vuln_scan.outputs.exit_code }}
               [[ $exit_code -ne 0 ]] && exit 1


```

Place it in a `main.yml` file in the `.github/workflows` folder, in the root of your project:

```
.github
└── workflows/
    └── main.yml
```

`METERIAN_API_TOKEN` is expected to be created as a GitHub Secret in the respective GitHub repository.

Or see [sample project: autofix-sample-maven-upgrade](https://raw.githubusercontent.com/MeterianHQ/autofix-sample-maven-upgrade/add-github-meterian-client-action/.github/main.workflow) | [Workflow interface](https://github.com/MeterianHQ/autofix-sample-maven-upgrade/blob/add-github-meterian-client-action/.github/main.workflow) for a similar working example on how to use the above GitHub action in your project.


### GitHub Actions related and other resources

- https://developer.github.com/actions/managing-workflows/
- https://developer.github.com/marketplace
- https://www.youtube.com/watch?v=Tl4mbL45PKU
- https://developer.github.com/actions/managing-workflows/storing-secrets/