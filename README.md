# Meterian Scanner GitHub Action

The Meterian Scanner GitHub action allows you to automatically scan for vulnerabilities right in your repository as part of your software development workflows.

A list of supported languages can be found [here](https://docs.meterian.io/languages-support/languages-intro).

## Usage

### Pre-required configuration

As the Meterian client requires authentication to function, you will need to generate an API token and set a GitHub secret within the repository of the project you wish to scan:

- Generate a Meterian API token
  - Create an account or log into your account on https://meterian.com
  - Create an new secret API token from the dashboard
- Add the above token as a GitHub secret by the name `METERIAN_API_TOKEN`
  - In your repository navigate to the Secrets page ( `Your repository > Settings > Secrets` )
  - Click on the `Add a new Secret`

### Inputs

#### `cli_args`

**Optional** Any additional Meterian CLI options. Find out more about these in the [Meterian documentation](https://docs.meterian.io/).

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
            uses: MeterianHQ/meterian-github-action@v1.0.3
            env:
              METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
```
Save this in a `main.yml` file in the `.github/workflows` folder, in the root of your project:
```
.github
└── workflows
    └── main.yml
```

### Integrating the action with an existing workflow

Within your workflow, create a job step that uses the Meterian GitHub action

```yaml   
# jobs.<job_id>.steps 
    - name: Meterian Scanner
      uses: MeterianHQ/meterian-github-action@v1.0.3
      env:
        METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
```
Optionally specify a client input argument
```yml
      with:
        cli_args: --min-security=85
```
**Note:** the above snippet assumes that you are already [checking-out](https://github.com/actions/checkout#checkout-v2) your repository. 

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

<br>

## GitHub Actions related and other resources

- https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions
- https://developer.github.com/marketplace
- https://www.youtube.com/watch?v=Tl4mbL45PKU
- https://help.github.com/en/actions/configuring-and-managing-workflows/using-variables-and-secrets-in-a-workflow
