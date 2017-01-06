# gerrit-ci docker
This docker image is an extension of the [Gerrit docker](https://hub.docker.com/r/openfrontier/gerrit/).

## Usage
This project is utilized by the [ci-compose project](https://github.com/openfrontier/ci-compose) to demonstrate how to start a gerrit-jenkins-nexus environment in seconds.
This project can also be utilized as a demo about how to extend the [Gerrit docker](https://hub.docker.com/r/openfrontier/gerrit/) by adding a nohup script to accomplish some setup works while the Gerrit service is starting up.

## Todo
Fix createGerrit.sh, destroyGerrit.sh and upgradeGerrit.sh in order to make it works with the [ci project](https://github.com/openfrontier/ci).
