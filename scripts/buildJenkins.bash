#!/bin/bash

set -e    # Abort script at first error
set -u    # Attempt to use undefined variable outputs error message, and forces an exit

# https://maven.apache.org/maven-release/maven-release-plugin/perform-mojo.html
# mvn -Prelease help:active-profiles

# Temporary
WORKSPACE="/tmp"

: "${MAVEN_PROFILE:=release}"
: "${GIT_REPOSITORY:=scm:git:git://github.com/olblak/jenkins.git}"
: "${GIT_EMAIL:=jenkins-bot@example.com}"
: "${GIT_NAME:=jenkins-bot}"
: "${GPG_KEYNAME:=test-jenkins-release}"
: "${GPG_PASSPHRASE:?GPG Passphrase Required}" # Password must be the same for gpg agent and gpg key
: "${SIGN_ALIAS:=jenkins}"
: "${SIGN_KEYSTORE:=${WORKSPACE}/jenkins.pfx}"
: "${SIGN_STOREPASS:=pass}"
: "${SIGN_CERTIFICATE:=jenkins.pem}"
: "${REPOSITORY_USERNAME:=olblak}"
: "${REPOSITORY_PASSWORD:?Repository Password Missing}"

export MAVEN_PROFILE
export GIT_REPOSITORY
export GIT_EMAIL
export GIT_NAME
export GPG_KEYNAME
export GPG_PASSPHRASE
export REPOSITORY_USERNAME
export REPOSITORY_PASSWORD
export SIGN_ALIAS
export SIGN_KEYSTORE
export SIGN_STOREPASS
export SIGN_CERTIFICATE

function configureGit(){
  git config --local user.email "${GIT_EMAIL}"
  git config --local user.name "${GIT_NAME}"
  git config --get user.name
  git config --get user.email
}

function configureGPG(){ 
  if ! gpg --fingerprint "${GPG_KEYNAME}"; then
    if [ ! -f "${GPG_FILE}" ]; then
      exit "${GPG_KEYNAME} or ${GPG_FILE} cannot be found"
    else
      ## --pinenty-mode is needed to avoid gpg prompt during maven release
      gpg --import --batch "${GPG_FILE}"
    fi
  fi
}


function configureKeystore(){
  if [ ! -f ${SIGN_CERTIFICATE} ]; then
      exit "${SIGN_CERTIFICATE} not found"
  else
    openssl pkcs12 -export \
      -out $SIGN_KEYSTORE \
      -in ${SIGN_CERTIFICATE} \
      -password pass:$SIGN_STOREPASS \
      -name $SIGN_ALIAS
  fi
}

function generateSettingsXml(){
cat <<EOT> settings-release.xml
<settings>
  <servers>
    <server>
      <id>$REPOSITORY_USERNAME</id>
      <username>$REPOSITORY_USERNAME</username>
      <password>$REPOSITORY_PASSWORD</password>
    </server>
  </servers>
</settings>
EOT
}


function prepareRelease(){
  printf "\\n Prepare Jenkins Release\\n\\n"
  mvn -P"${MAVEN_PROFILE}" -s settings-release.xml -B release:prepare
}

function stageRelease(){
  printf "\\n Perform Jenkins Release\\n\\n"
  mvn -P"${MAVEN_PROFILE}" -s settings-release.xml -B release:stage
}

function validateKeystore(){
  keytool -keystore "${SIGN_KEYSTORE}" -storepass "${SIGN_STOREPASS}" -list -alias "${SIGN_ALIAS}"
}
function validateGPG(){
  true
}

function main(){
  if [ $# -eq 0 ] ;then
    configureGPG
    configureKeystore
    configureGit
    validateKeystore
    validateGPG
    generateSettingsXml
    prepareRelease
    stageRelease
  else
    while [ $# -gt 0 ];
    do
      case "$1" in
            --configureGPG) echo "ConfigureGPG" && configureGPG ;;
            --configureKeystore) echo "Configure Keystore" && configureKeystore ;;
            --configureGit) echo "Configure Git" && configureGit ;;
            --validateKeystore) echo "Validate Keystore"  && validateKeystore ;;
            --validateGPG) echo "Validate GPG" && validateGPG ;;
            --prepareRelease) echo "Prepare Release" && generateSettingsXml && prepareRelease ;;
            --stageRelease) echo "Stage Release" && stageRelease ;;
            -h) echo "help" ;;
            -*) echo "help" ;;
        esac
        shift
    done
  fi
}

main "$@"
