#!/usr/bin/env bash

REPOSITORY=/home/ubuntu/spring/project3
cd $REPOSITORY

APP_NAME=cicdproject
JAR_NAME=$(ls $REPOSITORY/build/libs/ | grep 'SNAPSHOT.jar' | tail -n 1)
JAR_PATH=$REPOSITORY/build/libs/$JAR_NAME

CURRENT_PID=$(pgrep -f $APP_NAME)

if [ -z $CURRENT_PID ]
then
  echo "> 종료할 프로세스가 없습니다."
else
  echo "> kill -15 $CURRENT_PID"
  kill -15 $CURRENT_PID
  sleep 5
fi

echo "> $JAR_PATH 배포"
nohup java -jar $JAR_PATH >/dev/null 2>&1 &

# CodeDeploy 배포
aws deploy create-deployment \
  --application-name $CODE_DEPLOY_APP_NAME \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --deployment-group-name $DEPLOYMENT_GROUP_NAME \
  --s3-location bucket=$BUCKET_NAME,bundleType=zip,key=$PROJECT_NAME/$GITHUB_SHA.zip || {
    ACTIVE_DEPLOYMENT=$(aws deploy list-deployments --application-name $CODE_DEPLOY_APP_NAME --deployment-group-name $DEPLOYMENT_GROUP_NAME --include-only-statuses InProgress --query 'deployments[0]' --output text)
    if [ "$ACTIVE_DEPLOYMENT" != "None" ]; then
      echo "Stopping active deployment: $ACTIVE_DEPLOYMENT"
      aws deploy stop-deployment --deployment-id $ACTIVE_DEPLOYMENT --region ap-northeast-2
      echo "Retrying deployment..."
      aws deploy create-deployment \
        --application-name $CODE_DEPLOY_APP_NAME \
        --deployment-config-name CodeDeployDefault.OneAtATime \
        --deployment-group-name $DEPLOYMENT_GROUP_NAME \
        --s3-location bucket=$BUCKET_NAME,bundleType=zip,key=$PROJECT_NAME/$GITHUB_SHA.zip
    fi
  }