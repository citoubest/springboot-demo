#!/bin/bash

# param define
project_name=${project.name}
jar_file_name=${project.name}-${version}
servers=(${servers})

# server path
remote_project_home=/data/deploy/tomcat/$project_name/
remote_usr=***
jenkins_jar_file=artifacts/$jar_file_name

# environment check
if type -p java; then
    java_home=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    java_home="$JAVA_HOME/bin/java"
else
    echo "please install jdk first. thanks"
    exit 0
fi
version=$("$java_home" -version 2>&1 | awk -F '"' '/version/ {print $2}')
echo jdk version "$version"

# deploy on servers
serverCount=${#servers[@]}
serial_no=`date +%s`
i=0
while [ $i -lt $serverCount ]
do
    server=${servers[$i]}
    echo "deploy ${project.name} on $server"
    host=`echo $server | cut -d: -f1`
    port=`echo $server | cut -d: -f2`

    #stop server
    server_pid=`ssh $remote_usr@$host "ps -ef | grep $project_name | grep -v grep | awk '{printf\"%s\", \\$2}'"`
    while `ssh $remote_usr@$host "ps -p $server_pid > /dev/null 2>&1"`
    do
        echo "Waiting for old jar $jar_file_name in $host:$port--$server_pid to stop."
        ssh $remote_usr@$host "kill -TERM $server_pid"
        sleep 1
    done
    echo "Server is already closed."

    #start new service
    ssh $remote_usr@$host "mkdir -p $remote_project_home"
    scp $jenkins_jar_file $remote_usr@$host:$remote_project_home
    ssh $remote_usr@$host "/usr/bin/nohup $java_home  -Dserver.port=$jar_server_port -jar $remote_project_home/$jar_file_name > /dev/null 2>&1 &"
    new_server_pid=`ssh $remote_usr@$host "ps -ef | grep $jar_file_name | grep -v grep | awk '{printf\"%s\", \\$2}'"`
    echo "new pid:" $new_server_pid
    sleep 15
done

echo "all done."
