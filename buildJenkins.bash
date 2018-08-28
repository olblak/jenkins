#!/bin/bash

# https://maven.apache.org/maven-release/maven-release-plugin/perform-mojo.html

# Temporary
WORKSPACE="/tmp"

: "${MAVEN_PROFILE:=release}"
: "${GIT_REPOSITORY:=https://github.com/olblak/jenkins}"
: "${GIT_EMAIL:=jenkins-bot@example.com}"
: "${GIT_NAME:=jenkins-bot}"
: "${GPG_KEYNAME:=test-jenkins-release}"
: "${GPG_PASSPHRASE:=}"
: "${SIGN_ALIAS:=}"
: "${SIGN_KEYSTORE:=${WORKSPACE}/jenkins.pfx}"
: "${SIGN_STOREPASS:=securepassword}"
: "${SIGN_CERTIFICATE:=jenkins.pem}"

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
  mvn -P"${MAVEN_PROFILE}" -B -DtagNameFormat release:prepare
  printf "\\n Perform Jenkins Release\\n\\n"
  mvn -P"${MAVEN_PROFILE}" release:stage
}

function validateKeystore(){
  true
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
