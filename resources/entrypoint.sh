#!/bin/bash

if [[ $ADOP_GERRIT_ENABLED == "true" ]] && [[ $ADOP_GITLAB_ENABLED = "true" ]]; then
  echo "You can't have both Gerrit and Gitlab enabled.."
  echo "Please set only either to true. Exiting with error.."
  exit 1

elif [[ $ADOP_GERRIT_ENABLED == "true" ]]; then
  echo "'jenkins' user will now be configured for Gerrit."
  host=$GERRIT_HOST_NAME
  port=$GERRIT_PORT
  username=$GERRIT_JENKINS_USERNAME
  password=$GERRIT_JENKINS_PASSWORD

  # Delete Load Platform for Gitlab
  rm -rf /usr/share/jenkins/ref/jobs/GitLab_Load_Platform

  nohup /usr/share/jenkins/ref/adop\_scripts/generate_key.sh -c ${host} -p ${port} -u ${username} -w ${password} &

elif [[ $ADOP_GITLAB_ENABLED = "true" ]]; then
  echo "'jenkins' user will now be configured for Gitlab."
  host=$GITLAB_HOST_NAME
  port=$GITLAB_PORT
  username=$GITLAB_JENKINS_USERNAME
  password=$GITLAB_JENKINS_PASSWORD

  # Delete Load Platform for Gerrit
  rm -rf /usr/share/jenkins/ref/jobs/Load_Platform
  
  nohup /usr/share/jenkins/ref/adop\_scripts/generate_key.sh -c ${host} -p ${port} -u ${username} -w ${password} &
fi

echo "Starting Jenkins.."
echo "skip upgrade wizard step after installation"
echo "2.7.2" > /var/jenkins_home/jenkins.install.UpgradeWizard.state

chown -R 1000:1000 /var/jenkins_home
su jenkins -c /usr/local/bin/jenkins.sh
