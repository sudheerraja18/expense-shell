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

dnf module disable nodejs -y
VALIDATE $? "Disable default NodeJS"

dnf module enable nodejs:20 -y
VALIDATE $? "Enable NodeJS"

dnf install nodejs -y
VALIDATE $? "Install NodeJS"

useradd expense
VALIDATE $? "Add expense user"

mkdir /app
VALIDATE $? "Create app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Download the application"

cd /app

unzip /tmp/backend.zip
VALIDATE $? "Unzip the backend application"

npm install 
VALIDATE $? "Install dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Copy backend service"

systemctl daemon-reload
VALIDATE $? "Reload daemon"

systemctl start backend
VALIDATE $? "Start backend"

systemctl enable backend
VALIDATE $? "Enable backend"

dnf install mysql -y
VALIDATE $? "Installing MySQL"

mysql -h db.harvargurram.onlin -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Load backend schema"

systemctl restart backend
VALIDATE $? "Restart backend"