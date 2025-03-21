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
VALIDATE $? "Disable default NodeJS"

dnf module enable nodejs:20 -y &>>$LOGS_FILE_NAME
VALIDATE $? "Enable NodeJS"

dnf install nodejs -y &>>$LOGS_FILE_NAME
VALIDATE $? "Install NodeJS"

id expense
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGS_FILE_NAME
    VALIDATE $? "Add expense user"
else
    echo "User expence already added"
fi

mkdir /app &>>$LOGS_FILE_NAME
VALIDATE $? "Create app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGS_FILE_NAME
VALIDATE $? "Download the application"

cd /app

unzip /tmp/backend.zip &>>$LOGS_FILE_NAME
VALIDATE $? "Unzip the backend application"

npm install &>>$LOGS_FILE_NAME
VALIDATE $? "Install dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGS_FILE_NAME
VALIDATE $? "Copy backend service"

systemctl daemon-reload &>>$LOGS_FILE_NAME
VALIDATE $? "Reload daemon"

systemctl start backend &>>$LOGS_FILE_NAME
VALIDATE $? "Start backend"

systemctl enable backend &>>$LOGS_FILE_NAME
VALIDATE $? "Enable backend"

dnf install mysql -y &>>$LOGS_FILE_NAME
VALIDATE $? "Installing MySQL"

mysql -h db.harvargurram.onlin -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOGS_FILE_NAME
VALIDATE $? "Load backend schema"

systemctl restart backend &>>$LOGS_FILE_NAME
VALIDATE $? "Restart backend"