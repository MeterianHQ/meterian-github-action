# Meterian Scanner GitHub Action

Scan for vulnerabilities in your project using the Meterian Scanner GitHub action 


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
workflow "Meterian Scanner workflow" {
    on = "push"
    resolves = ["Meterian Scanner Action"]
}

action "Meterian Scanner Action" {
    uses = "MeterianHQ/meterian-github-action@master"
    secrets = ["METERIAN_API_TOKEN"]
    args = "" ## placeholder for METERIAN_CLI_ARGS
}
```

Place it in a `main.workflow` file in the `.github` folder, in the root of your project:

```
.github
└── main.workflow
```

`METERIAN_API_TOKEN` is expected to be created as a GitHub Secret in the respespective GitHub repository.

Or see [sample project: autofix-sample-maven-upgrade](https://raw.githubusercontent.com/MeterianHQ/autofix-sample-maven-upgrade/add-github-meterian-client-action/.github/main.workflow) | [Workflow interface](https://github.com/MeterianHQ/autofix-sample-maven-upgrade/blob/add-github-meterian-client-action/.github/main.workflow) for a similar working example on how to use the above GitHub action in your project.


### GitHub Actions related and other resources

- https://developer.github.com/actions/managing-workflows/
- https://developer.github.com/marketplace
- https://www.youtube.com/watch?v=Tl4mbL45PKU
- https://developer.github.com/actions/managing-workflows/storing-secrets/