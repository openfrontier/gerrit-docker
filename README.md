# gerrit-docker
Operational scripts for docker-gerrit project.
## Create gerrit container.
    createGerrit.sh <Gerrit canonicalWebUrl> <LDAP server ip/name> <LDAP AccountBase>
## Add administrator's public ssh key.
    addGerritUser.sh <Gerrit canonicalWebUrl> <admin http uid> <admin http password> <public ssh key path>
## Destroy gerrit container.
    destroyGerrit.sh
