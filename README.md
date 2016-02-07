# gerrit-docker
Operational scripts for docker-gerrit project.
## Create gerrit container.
    createGerrit.sh <Gerrit canonicalWebUrl> <LDAP server ip/name> <LDAP AccountBase> <SMTP server ip> <Sender email address> <SMTP server auth user> <SMTP server auth password>
## Add administrator's public ssh key.
    addGerritUser.sh <Gerrit canonicalWebUrl> <admin http uid> <admin http password> <public ssh key path>
## Destroy gerrit container.
    destroyGerrit.sh
## Upgrade gerrit container.
   ## Gerrit 2.10.6->2.11.2 tested
   ## Gerrit 2.11.5->2.12 tested
    upgradeGerrit.sh
