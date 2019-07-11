# Meterian Scanner GitHub Action

Scan for vulnerabilities in your project using the Meterian Scanner GitHub action 

## How to configure and use the action

- Via the GitHub interface add action via the Action tab
- Create or amend an existing workflow
- Enter MeterianHq/meterian-scanner-action@master
- Add your secret Meterian token by the name METERIAN_API_TOKEN from account on http://meterian.com
    - Create an account or log into your account on http://meterian.com
    - Create an new secret API token from the dashboard
    - Add this secret token into the new GitHub action