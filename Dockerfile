FROM jenkins:2.46.2

MAINTAINER Bryan Sazon and Arcy Teodoro 

ENV GERRIT_HOST_NAME gerrit
ENV GERRIT_PORT 8080
ENV GERRIT_JENKINS_USERNAME="" GERRIT_JENKINS_PASSWORD=""
ENV GITLAB_HOST_NAME gitlab
ENV GITLAB_PORT 80
ENV GITLAB_JENKINS_USERNAME="" GITLAB_JENKINS_PASSWORD="" GITLAB_JENKINS_TOKEN=""
ENV GIT_REPO gitlab

# Copy in configuration files
COPY resources/plugins.txt /usr/share/jenkins/ref/
COPY resources/init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
COPY resources/scripts/ /usr/share/jenkins/ref/adop_scripts/
COPY resources/jobs/ /usr/share/jenkins/ref/jobs/
COPY resources/scriptler/ /usr/share/jenkins/ref/scriptler/scripts/
COPY resources/views/ /usr/share/jenkins/ref/init.groovy.d/
COPY resources/m2/ /usr/share/jenkins/ref/.m2
COPY resources/entrypoint.sh /entrypoint.sh
COPY resources/jenkins_home/ /usr/share/jenkins/ref/

# Reprotect
USER root
RUN chmod +x -R /usr/share/jenkins/ref/adop_scripts/ && chmod +x /entrypoint.sh
# USER jenkins

# Environment variables
ENV ADOP_LDAP_ENABLED=true ADOP_SONAR_ENABLED=true ADOP_ANT_ENABLED=true ADOP_MAVEN_ENABLED=true ADOP_NODEJS_ENABLED=true ADOP_GERRIT_ENABLED=true
ENV LDAP_GROUP_NAME_ADMIN=""
ENV JENKINS_OPTS="--prefix=/jenkins -Djenkins.install.runSetupWizard=false"

RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

ENTRYPOINT ["/entrypoint.sh"]
