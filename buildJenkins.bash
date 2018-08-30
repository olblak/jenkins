#!/bin/bash

set -e    # Abort script at first error
set -u    # Attempt to use undefined variable outputs error message, and forces an exit

# https://maven.apache.org/maven-release/maven-release-plugin/perform-mojo.html
# mvn -Prelease help:active-profiles

# Temporary
WORKSPACE="/tmp"

: "${MAVEN_PROFILE:=release}"
: "${GIT_REPOSITORY:=scm:git:git@github.com:olblak/jenkins.git}"
: "${GIT_EMAIL:=jenkins-bot@example.com}"
: "${GIT_NAME:=jenkins-bot}"
: "${GPG_KEYNAME:=test-jenkins-release}"
: "${GPG_PASSPHRASE:?GPG Passphrase Required}" # Password must be the same for gpg agent and gpg key
: "${SIGN_ALIAS:=jenkins}"
: "${SIGN_KEYSTORE:=${WORKSPACE}/jenkins.pfx}"
: "${SIGN_STOREPASS:=pass}"
: "${SIGN_CERTIFICATE:=jenkins.pem}"

export MAVEN_PROFILE
export GIT_REPOSITORY
export GIT_EMAIL
export GIT_NAME
export GPG_KEYNAME
export GPG_PASSPHRASE
export SIGN_ALIAS
export SIGN_KEYSTORE
export SIGN_STOREPASS
export SIGN_CERTIFICATE

function configureGPG(){ 
  if ! gpg --fingerprint "${GPG_KEYNAME}"; then
    if [ ! -f "${GPG_FILE}" ]; then
      exit "${GPG_KEYNAME} or ${GPG_FILE} cannot be found"
    else
      gpg --import "${GPG_FILE}"
    fi
  fi
}

function configureGit(){
  git config --local user.email "${GIT_EMAIL}"
  git config --local user.name "${GIT_NAME}"
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

function makeRelease(){
  printf "\\n Prepare Jenkins Release\\n\\n"
  mvn -P"${MAVEN_PROFILE}" -B release:prepare
  printf "\\n Perform Jenkins Release\\n\\n"
  # mvn -P"${MAVEN_PROFILE}" -B release:perform
}

function validateKeystore(){
  keytool -keystore "${SIGN_KEYSTORE}" -storepass "${SIGN_STOREPASS}" -list -alias "${SIGN_ALIAS}"
}
function validateGPG(){
  true
}

# Validate GPG access
# Validate 

configureGPG
configureKeystore
configureGit
validateKeystore
validateGPG
makeRelease
