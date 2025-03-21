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

dnf install mysql-server -y &>>$LOGS_FILE_NAME
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld &>>$LOGS_FILE_NAME
VALIDATE $? "Enabling MySQL Server"

systemctl start mysqld &>>$LOGS_FILE_NAME
VALIDATE $? "Starting MySQL Server"

mysql -h db.harvargurram.online -u root -pExpenseApp@1 -e 'show databases'
if [ $? -ne 0 ]
then
    echo "MySQL root password not setup" &>>$LOGS_FILE_NAME
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "Setting up root password"
else
    echo "MySQL root password already setup"
fi


