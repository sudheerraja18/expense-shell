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

dnf install nginx -y &>>$LOGS_FILE_NAME
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGS_FILE_NAME
VALIDATE $? "Enablelling Nginx"

systemctl start nginx &>>$LOGS_FILE_NAME
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGS_FILE_NAME
VALIDATE $? "Remove existing version of code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGS_FILE_NAME
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
VALIDATE $? "Moving to HTML directory"

unzip /tmp/frontend.zip &>>$LOGS_FILE_NAME
VALIDATE $? "Unzip frontend"

systemctl restart nginx &>>$LOGS_FILE_NAME
VALIDATE $? "Restart nginx"