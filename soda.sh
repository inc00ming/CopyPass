#!/usr/bin/bash

#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

printBanner() {
	
	echo -e "${GREEN}";
        echo "                                o               ";
        echo "                               <|>              ";
        echo "                               < \              ";
        echo "     __o__   o__ __o      o__ __o/     o__ __o/ ";
        echo "    />  \   /v     v\    /v     |     /v     |  ";
        echo "    \o     />       <\  />     / \   />     / \ ";
        echo "     v\    \         /  \      \o/   \      \o/ ";
        echo "      <\    o       o    o      |     o      |  ";
        echo " _\o__</    <\__ __/>    <\__  / \    <\__  / \ ";
        echo "                                                ";
        echo -e "		                         ${YELLOW}by fb ";
        echo "                                                ";
	echo -e "${NC}";
}

main(){
        printBanner
        case "$1" in
        	
	 	       -backup)
					includeProperties
					echo -e "Database dump will be saved to ${YELLOW}${BACKUP_DIRECTORY}${NC}..."
					sleep 2
					takeDump
					;;
			-list)
					includeProperties		
					echo -e "Backup directory ${YELLOW}${BACKUP_DIRECTORY}${NC} includes backup(s) below"
					listDump
					;;
			-rotate)
					echo -e "Rotation will be done for dumps which are older than${YELLOW} $2 ${NC}days"
					rotate $2
					;;
			-show)
					echo -e "You can find the backup directory, tomcat service name, catalina home directory, ATAR URL below.\n\n"
					includeProperties
					echo -e "Backup Directory:        ${YELLOW}${BACKUP_DIRECTORY}${NC}"
					echo -e "Tomcat Service Name:     ${YELLOW}${TOMCAT_SERVICE_NAME}${NC}"
					echo -e "Catalina Home Directory: ${YELLOW}${CATALINA_HOME}${NC}"
					echo -e "ATAR URL:                ${YELLOW}${ATAR_URL}${NC}"
					;;
			-edit)
					includeProperties
					
					echo "Enter backup directory:"
					read NEW_BACKUP_DIRECTORY
					if [ -z "$NEW_BACKUP_DIRECTORY" ]
					then
						echo -e "No change, current backup directory is ${YELLOW}${BACKUP_DIRECTORY}${NC}"
					elif [ -d $NEW_BACKUP_DIRECTORY ]
					then
						sed -i "s;BACKUP_DIRECTORY=.*;BACKUP_DIRECTORY=${NEW_BACKUP_DIRECTORY};g" properties.conf
					else
						mkdir -p $NEW_BACKUP_DIRECTORY
						sed -i "s;BACKUP_DIRECTORY=.*;BACKUP_DIRECTORY=${NEW_BACKUP_DIRECTORY};g" properties.conf
					fi
					
					echo "Enter tomcat service name:"
                                        read NEW_TOMCAT_SERVICE_NAME
					if [ -z "$NEW_TOMCAT_SERVICE_NAME" ]
                                        then
                                                echo -e "No change, current tomcat service name is ${YELLOW}${TOMCAT_SERVICE_NAME}${NC}"
                                        else
						
                                        	systemctl list-units | grep $NEW_TOMCAT_SERVICE_NAME || echo "Tomcat service is not exist"
						 sed -i "s;TOMCAT_SERVICE_NAME=.*;TOMCAT_SERVICE_NAME=${NEW_TOMCAT_SERVICE_NAME};g" properties.conf
                                        fi

					echo "Enter catalina home directory:"
                                        read NEW_CATALINA_HOME
				 	if [ -z "$NEW_CATALINA_HOME" ]
                                        then
                                                echo -e "No change, current catalina home directory is ${YELLOW}${CATALINA_HOME}${NC}"
                                        elif [ -d $NEW_CATALINA_HOME ]
					then
						echo "New directory is already exist"
                                        	sed -i "s;CATALINA_HOME=.*;CATALINA_HOME=${NEW_CATALINA_HOME};g" properties.conf
                                        else
						echo "Invalid catalina home directory"
						echo -e "No change, current catalina home directory is ${YELLOW}${CATALINA_HOME}${NC}"
					fi

					echo "Enter ATAR URL:"
                                        read NEW_ATAR_URL
					if [ -z "$NEW_ATAR_URL" ]
                                        then
                                                echo -e "No change, current ATAR URL is ${YELLOW}${ATAR_URL}${NC}"
                                        else
                                        	sed -i "s;ATAR_URL=.*;ATAR_URL=${NEW_ATAR_URL};g" properties.conf
                                        fi

					echo
					echo -e "Backup directory: ${YELLOW}${BACKUP_DIRECTORY}${NC}"
					echo -e "Tomcat service name: ${YELLOW}${TOMCAT_SERVICE_NAME}${NC}"
					echo -e "Catalina home directory: ${YELLOW}${CATALINA_HOME}${NC}"
					echo -e "ATAR URL: ${YELLOW}${ATAR_URL}${NC}"
					;;
			-upgrade)
					includeProperties
	        			echo "Checking tomcat service status..."
	       				tomcatStatus=`systemctl is-active ${TOMCAT_SERVICE_NAME}`;
	        			if [ $tomcatStatus == "failed"  ]
	        			then
						echo "Tomcat already stopped, war file will be copied to catalina home..."
						yes | cp $2 ${CATALINA_HOME}/webapps/ROOT.war
					else
						echo "Tomcat application is running, it will be stopped first"
						systemctl stop ${TOMCAT_SERVICE_NAME}
						yes | cp $2 ${CATALINA_HOME}/webapps/ROOT.war
						systemctl start ${TOMCAT_SERVICE_NAME}
					fi
					;;
			-version)
					getVersion
					;;
			-restore)
					includeProperties
                                        echo "Checking tomcat service status..."
                                        tomcatStatus=`systemctl is-active ${TOMCAT_SERVICE_NAME}`;
                                        if [ $tomcatStatus == "failed"  ]
                                        then
                                                echo "Tomcat already stopped"
                                        else
                                                echo "Tomcat application is running, it will be stopped first"
                                                systemctl stop ${TOMCAT_SERVICE_NAME}
					fi
					restore
					;;
			*)
					help
					;;
		esac
}

restore(){
	dropdb atar && createdb atar
}

takeDump(){
	includeProperties
	version=$( getVersion )
	backuploc="${BACKUP_DIRECTORY}/atar_${version}_db_backup_`date +%d-%m-%y`.sql.gz"
	sudo -Hiu postgres pg_dump -v atar | gzip > "${backuploc}"
}

listDump(){
	includeProperties
	ls -lrht $BACKUP_DIRECTORY | awk {'print $5" "$9'}
}

rotate(){
	includeProperties
	find $BACKUP_DIRECTORY -mtime +$1 -name "*.sql.gz" -delete
}

help(){
	includeProperties
	usage="$(basename "$0") [-help] [-backup] [-list] [-rotate n] [-show] [-edit] [-restore s] [-upgrade w] -- program to handle whole error prone process 
	
where:
	${YELLOW}-help${NC}		show help text
	${YELLOW}-backup${NC}		take database backup under the ${BACKUP_DIRECTORY}
       	${YELLOW}-list${NC}		show database backup files under the ${BACKUP_DIRECTORY} 
       	${YELLOW}-rotate n${NC}	apply rotation to database backup files, delete all files which are older than n day(s) under the ${BACKUP_DIRECTORY} 
	${YELLOW}-show${NC}		show backup directory, tomcat service name, catalina home directory and ATAR URL
	${YELLOW}-edit${NC}		edit backup directory, tomcat service name, catalina home directory and ATAR URL
	${YELLOW}-restore s${NC}	restore from backup file s
	${YELLOW}-upgrade w${NC}	upgrade tomcat application with war file w"
	echo -e "${usage}"
}

getVersion(){
	includeProperties
	curlout=`curl -ks ${ATAR_URL}/api/auth/me` 
	curlout=${curlout//[[:space:]]}
	version=`python -c "import sys, json; print(json.loads(\"\"\"${curlout}\"\"\")['version'])"`
	buildNumber=`python -c "import sys, json; print(json.loads(\"\"\"${curlout}\"\"\")['buildNumber'])"`
	echo -e "$version-$buildNumber"
}

includeProperties(){
	. properties.conf
}
main $1 $2
