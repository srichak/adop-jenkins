#!/bin/bash
set -e

# Usage
usage() {
  echo "Usage:"
  echo "    ${0} -c <host> -p <port> -u <username> -w <password>"
  exit 1
}

# Constants
SLEEP_TIME=5
MAX_RETRY=10
BASE_JENKINS_KEY="adop/core/jenkins"
BASE_JENKINS_SSH_KEY="${BASE_JENKINS_KEY}/ssh"
BASE_JENKINS_SSH_PUBLIC_KEY_KEY="${BASE_JENKINS_SSH_KEY}/public_key"
JENKINS_HOME="/var/jenkins_home"
JENKINS_SSH_DIR="${JENKINS_HOME}/.ssh"
JENKINS_USER_CONTENT_DIR="${JENKINS_HOME}/userContent/"
GERRIT_ADD_KEY_PATH="accounts/self/sshkeys"
GERRIT_REST_AUTH="jenkins:jenkins"

while getopts "c:p:u:w:" opt; do
  case $opt in
    c)
    host=${OPTARG}
    ;;
    p)
    port=${OPTARG}
    ;;
    u)
    username=${OPTARG}
    ;;
    w)
    password=${OPTARG}
    ;;
    *)
    echo "Invalid parameter(s) or option(s)."
    usage
    ;;
  esac
done

if [ -z "${host}" ] || [ -z "${port}" ] || [ -z "${username}" ] || [ -z "${password}" ]; then
  echo "Parameters missing"
  usage
fi

echo "Generating Jenkins Key Pair"
if [ ! -d "${JENKINS_SSH_DIR}" ]; then mkdir -p "${JENKINS_SSH_DIR}"; fi

cd "${JENKINS_SSH_DIR}"

if [[ ! $(ls -A "${JENKINS_SSH_DIR}") ]]; then 
  ssh-keygen -t rsa -f 'id_rsa' -b 4096 -C "jenkins@adop-core" -N ''; 
  echo "Copying the key to userContent folder .."
  mkdir -p ${JENKINS_USER_CONTENT_DIR}
  rm -f ${JENKINS_USER_CONTENT_DIR}/id_rsa.pub
  cp ${JENKINS_SSH_DIR}/id_rsa.pub ${JENKINS_USER_CONTENT_DIR}/id_rsa.pub

  # Set correct permissions for Content Directory
  chown 1000:1000 "${JENKINS_USER_CONTENT_DIR}"
 
  public_key_val=$(cat ${JENKINS_SSH_DIR}/id_rsa.pub) 
fi

# If Git repo choice is Gitlab
if [[ ${GIT_REPO} == "gitlab" ]]; then

  echo "Obtaining GitLab root token .."
  GITLAB_ROOT_TOKEN="$(curl -X POST "http://gitlab/gitlab/api/v3/session?login=root&password=${GITLAB_ROOT_PASSWORD}" | python -c "import json,sys;obj=json.load(sys.stdin);print obj['private_token'];")"

  # Throw the token to a file for later use..
  echo "${GITLAB_ROOT_TOKEN}" > ${JENKINS_HOME}/gitlab-root-token

  echo "Initializing jenkins user in Gitlab.."
  curl --silent --header "PRIVATE-TOKEN: ${GITLAB_ROOT_TOKEN}" -X POST "http://gitlab/gitlab/api/v3/users?email=${GIT_GLOBAL_CONFIG_EMAIL}&name=jenkins&username=jenkins&password=${password}&provider=ldap&extern_uid=cn=jenkins,ou=people,${LDAP_ROOTDN}&admin=true&confirm=false" | true

  echo "Adding jenkins SSH key to GitLab root user.."
  curl --silent --header "PRIVATE-TOKEN: ${GITLAB_ROOT_TOKEN}" -X POST "http://gitlab/gitlab/api/v3/users/1/keys" --data-urlencode "title=jenkins@adop-core" --data-urlencode "key=${public_key_val}" | true

  # The following xml is a gitlab connection settings for Jenkins Managed Configurations to enable Gitlab webhooks.
  # There isn't a way to do this via groovy scripts and this is the current workaround..
  echo "Uploading successful. Updating Jenkins GitLab connection configuration."
  cp /usr/share/jenkins/ref/com.dabsquared.gitlabjenkins.connection.GitLabConnectionConfig.xml ${JENKINS_HOME}/

fi

# Set correct permissions on SSH Key
chown -R 1000:1000 "${JENKINS_SSH_DIR}"
