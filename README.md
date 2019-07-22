# Meterian Scanner GitHub Action

Scan for vulnerabilities in your project using the Meterian Scanner GitHub action 

## How to configure and use the action

- Via the GitHub interface add action via the Action tab
- Create or amend an existing workflow
- Enter MeterianHq/meterian-scanner-action@master
- Add a secret Meterian token by the name METERIAN_API_TOKEN
    - Create an account or log into your account on http://meterian.com
    - Create an new secret API token from the dashboard
    - Add this secret token for the GitHub action to use

Note: go to the https://github.com/[your org]/[your repo]/settings/secrets page and click on the `Add a new Secret` link, to add the above secret to the repository where the GitHub Action is being setup.