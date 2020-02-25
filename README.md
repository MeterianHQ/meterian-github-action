# Meterian Scanner GitHub Action

This action allows you to scan for vulnerabilities in your project using the Meterian Scanner GitHub action.

## Inputs

### `cli_args`

**Optional** Any additional Meterian CLI options. Find out more about these via the [Meterian PDF manual](https://www.meterian.com/documents/meterian-cli-manual.pdf).


## Usage

### Pre-required configuration

As the Meterian client requires authentication to function, you will need to generate an API token and set a GitHub secret within the repository of the project you wish to scan:

- Generate a Meterian API token
  - Create an account or log into your account on http://meterian.com
  - Create an new secret API token from the dashboard
- Add the above token as a GitHub secret by the name `METERIAN_API_TOKEN`
  - In your repository navigate to the Secrets page ( `Your repository > Settings > Secrets` )
  - Click on the `Add a new Secret`

### Using the action as part of a job

Within your [**workflow**](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions) configure a [**job**](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobs) that uses the Meterian GitHub action:

[**Check-out**](https://github.com/actions/checkout#checkout-v2) your repository so that it's accessible by the workflow.

```yml
# jobs.<job_id>.steps
    - name: Checkout
      uses: actions/checkout@v2
```
Set the Meterian Scanner GitHub action to scan your repository

```yaml    
    - name: Meterian Scanner
      uses: MeterianHQ/meterian-github-action@master
```

In the step of your newly configured job, set the input data ( `cli_args` ) and the environment variable `METERIAN_API_TOKEN`, required for a proper vulnerability scan to take place.

```yaml
      with:
        cli_args: --min-security=85
      env:
        METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
```

<details>
    <summary>Click here to view a complete example workflow</summary>

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
          - name: Meterian Scanner
            uses: MeterianHQ/meterian-github-action@master
            env:
              METERIAN_API_TOKEN: ${{ secrets.METERIAN_API_TOKEN }}
            with:
                cli_args: --min-security=85
```

</details>


## Live examples

- [Java sample project]()
- [Php sample scan]()
- [Ruby sample scan]()
- [Python sample scan]()

**TBU**

<br>
<br>

## GitHub Actions related and other resources

- https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions
- https://developer.github.com/marketplace
- https://www.youtube.com/watch?v=Tl4mbL45PKU
- https://help.github.com/en/actions/configuring-and-managing-workflows/using-variables-and-secrets-in-a-workflow
