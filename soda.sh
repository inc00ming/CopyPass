#!/usr/bin/bash
printBanner() {
	RED='\033[0;31m'
        GREEN='\033[0;32m'
        NC='\033[0m'
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
        if [ "$1" == "-h" ]
        then
                help
        else
                printBanner
        fi
}

takeDump(){
	sudo -Hiu postgres pg_dump atar | gzip > $1/atardb`date +%d-%m-%y`.sql.gz
}
main $1
