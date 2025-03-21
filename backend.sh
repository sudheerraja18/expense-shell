#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOGS_FILE="$(echo $0 | cut -d "." -f1)"
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOGS_FILE_NAME="$LOGS_FOLDER/$LOGS_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2..... $R FAILURE $N"
        exit 1
    else
        echo -e "$2..... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "Error: User need to have super user permission to execute this script"
        exit 1
    fi
}

echo "Script started excuting at : $TIMESTAMP" &>>$LOGS_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOGS_FILE_NAME
VALIDATE $? "Disabling existing  default NodeJS"

dnf module enable nodejs:20 -y &>>$LOGS_FILE_NAME
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOGS_FILE_NAME
VALIDATE $? "Installing NodeJS"

id expense &>>$LOGS_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGS_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo -e "expense user already exists .....$Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGS_FILE_NAME
VALIDATE $? "Downloading backend"

cd /app

rm -rf /app/*

unzip /tmp/backend.zip &>>$LOGS_FILE_NAME
VALIDATE $? "Unzip backend"

npm install &>>$LOGS_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOGS_FILE_NAME
VALIDATE $? "Installing MySQL"

mysql -h db.harvargurram.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOGS_FILE_NAME
VALIDATE $? "Setting up trnsactions schema and tables"

systemctl daemon-reload &>>$LOGS_FILE_NAME
VALIDATE $? "Daemon Reload"

systemctl enable backend &>>$LOGS_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl restart backend &>>$LOGS_FILE_NAME
VALIDATE $? "Restarting backend"