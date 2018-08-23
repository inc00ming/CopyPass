#!/usr/bin/bash
BACKUP_DIR="/home/atar/backups"

#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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
        echo "                                          by fb ";
        echo "                                                ";
	echo -e "${NC}";
}
help() {
        echo "1 for Take database backup         ";
        echo "2 for List database backups        ";
        echo "3 for Restore from database backup ";
	echo "4 for Show / Edit backup directory ";
        echo "Please select one of the options   ";
        read opt
        case "$opt" in
        1) echo "Tomcat will be stopped for database dump"
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        NC='\033[0m'
        `systemctl stop tomcat > /dev/null 2>&1`;
        echo "Checking tomcat.service status..."
        tomcatStatus=`systemctl is-active tomcat`;
        if [ $tomcatStatus == "failed"  ]
        then
                echo -e "Tomcat stopped ${GREEN}successfully${NC}";
                echo "Please enter the directory for dump";
                read path;
                if [[ -d $path ]]
                then
			echo "Path is already exist, fyi";
                	takeDump $path;
			echo "Tomcat will be starting, please follow catalina logs..."
			`systemctl start tomcat`
		else
			echo "Path will be created...";
                	`mkdir -p $path`;
                	takeDump $path;
			echo "Tomcat will be starting, please follow catalina logs..."
			`systemctl start tomcat`
                fi

        else
                echo "Tomcat stopping ${RED}failed${NC}";
        fi
                ;;
        2) echo "Please enter backup directory"
	read path;
	if [ -d $path ]
	then
		ls -lrt $path
	fi
                ;;
	4) echo "Please enter E(dit) or S(how)"
	read es;
	if [ $es == E ]
	then
		echo "Please enter new full path of backup directory"
		read backupPath;
		if [ -d $backupPath ]
		then
			mkdir -p $backupPath;
		fi	
		echo "$backupPath will be used for backup directory";
	
	else
		echo "Default path is /home/atar/backups";
	fi
		;;
        *) echo "Invalid selection";
        	help
                ;;
        esac
}

main(){
        printBanner
        if [ -d $BACKUP_DIR ]
        then
		echo "";
        else
        	mkdir -p $BACKUP_DIR
        fi
        case "$1" in
        	-backup)
				echo -e "Database dump will be saved to${YELLOW} $BACKUP_DIR ${NC}..."
				sleep 2
				takeDump
				;;
		-list)		
				echo -e "Backup directory${YELLOW} $BACKUP_DIR ${NC}includes backup(s) below"
				listDump
				;;
		-rotate)
				echo -e "Rotation will be done for dumps which are older than${YELLOW} $2 ${NC}days"
				rotate $2
				;;
		-show)
				echo -e "Current backup directory: ${YELLOW} $BACKUP_DIR ${NC}"
				;;
		-edit)
				echo "Enter new backup diretory"
				read NEW_BACKUP_DIR
				BACKUP_DIR=${NEW_BACKUP_DIR}
				if [ -d $BACKUP_DIR ]
				then
					echo 
				else
					mkdir -p $BACKUP_DIR
				fi
				echo -e "New backup directory: ${YELLOW} $BACKUP_DIR ${NC}"
				;;
		*)
				echo "Invalid option"
				help
				;;
		esac
}

takeDump(){
	sudo -Hiu postgres pg_dump -Fcv atar | gzip > ${BACKUP_DIR}/atardb`date +%d-%m-%y`.sql.gz
}

listDump(){
	ls -lrt $BACKUP_DIR
}

rotate(){
	find $BACKUP_DIR -mtime +$1 -name "*.sql.gz" -delete
}
main $1 $2
