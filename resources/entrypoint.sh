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
  
  # Wait until gitlab is up and running
  SLEEP_TIME=10
  MAX_RETRY=12
  COUNT=0
  until [[ $(curl -I -s gitlab/gitlab/users/sign_in | head -1 | grep 200 | wc -l) -eq 1 ]] || [[ $COUNT -eq $MAX_RETRY ]]
  do
    echo "Testing GitLab Connection endpoint - http://gitlab/gitlab .."
    echo "GitLab unavailable, sleeping for ${SLEEP_TIME}s ..retrying $COUNT/$MAX_RETRY"
    sleep ${SLEEP_TIME}
    ((COUNT ++))
  done

  if [[ $COUNT -ne $MAX_RETRY ]]; then
    nohup /usr/share/jenkins/ref/adop\_scripts/generate_key.sh -c ${host} -p ${port} -u ${username} -w ${password} &
  else
    echo "Skipping Jenkins to Gitlab access configuration because max timeout retries has been reached.."
  fi

fi

echo "Starting Jenkins.."

chown -R 1000:1000 /var/jenkins_home
su jenkins -c /usr/local/bin/jenkins.sh
