#!/bin/bash

sudo -u postgres psql -d sonarqube

\dt


UPDATE users
SET crypted_password='100000$t2h8AtNs1AlCHuLobDjHQTn9XppwTIx88UjqUm4s8RsfTuXQHSd/fpFexAnewwPsO6jGFQUv/24DnO55hY6Xew==', 
    salt='k9x9eN127/3e/hf38iNiKwVfaVk=', 
    hash_method='PBKDF2', 
    reset_password='true', 
    user_local='true'
WHERE login='admin';


sudo systemctl restart sonar
