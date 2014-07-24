Jankins
=======

## Overview
Uses [Github Webhooks](https://developer.github.com/webhooks/creating/) to trigger [Jenkins](http://jenkins-ci.org/) builds automagically when a Pull Request is created/synchronized for a repository.

### Chain of Events:

- **PAYLOAD RECEIVED** – Web hook from Github
  - **TRIGGER JENKINS BUILD** – polls for build id for 30 minutes by default (configurable)
    - **RECEIVES BUILD ID** – schedules a build output job to begin in 60 seconds (configurable)
      - **BUILD COMPLETES** – looks for FINISHED: line in build output
        - **POST TO GITHUB** – Post summary of build to Github
        - **UPDATE JIRA LINK** - Jira link is updated to included status (ie: FAILURE/SUCCESS)
    - **CREATE/UPDATE JIRA LINK** – Link to console output of triggered Jenkins job
    - CREATE/UPDATE CODE REVIEW – Phabricator code review with Arc Diff

**BOLD** – Implemented

## Getting Started

### Development
- `bundle install`
- create .env file in root directory with required env variables
- `foreman start -f Procfile.development`

### Monitoring Sidekiq
- `rake monitor_sidekiq`
- Open browser to http://hostname:9494


### Deploying
Requires Ruby 2.1.2

- create .env file in root directory with required env variables

#### Supervisord
Information about [Foreman](http://ddollar.github.io/foreman/) export: [http://ddollar.github.io/foreman/#EXPORT-FORMATS](http://ddollar.github.io/foreman/#EXPORT-FORMATS)

Example export:
`foreman export supervisord -t /path/to/supervisord/confs -l /path/to/put/logs`

## Sample .env

```
export JENKINS_USERNAME=username
export JENKINS_PASSWORD=password
export JENKINS_URL=https://jenkins.url
export JENKINS_JOB=Sample_Job_Name
export JENKINS_BUILD_WAIT_TIME=300
export JENKINS_BUILD_START_TIMEOUT=1800
export GITHUB_USERNAME=hasuser
export GITHUB_PASSWORD=hasPassword
export GITHUB_SECRET_TOKEN=SecretToke
export JIRA_PROJECT_PREFIX=ABC
export JIRA_URL=https://jira.url
export JIRA_USERNAME=username
export JIRA_PASSWORD=password
```
