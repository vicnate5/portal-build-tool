#!/bin/bash

######################################################################################################################
#ENVIROMENT VARIABLES#################################################################################################
######################################################################################################################

## Username for properties files ##
username="vicnate5"

## MYSQL ##
# The script can re-create your mysql database after building the bundle

## MySQL login##
mysqlUsername=""
mysqlPassword=""

## MySQL Databases ##
masterDB="master"
public70xDB="lportal"
ee70xDB="lportal"
ee62xDB="lportal"

## Portal Directories ##
masterSourceDir="/Users/vicnate5/Liferay/liferay-portal-master"
masterBundleDir="/Users/vicnate5/bundles/master-bundles"

public70xSourceDir="/Users/vicnate5/Liferay/liferay-portal-7.0.x"
public70xBundleDir="/Users/vicnate5/bundles/7.0.x-bundles"

ee70xSourceDir="/Users/vicnate5/Liferay/liferay-portal-ee-7.0.x"
ee70xBundleDir="/Users/vicnate5/bundles/ee-7.0.x-bundles"

ee62xSourceDir="/Users/vicnate5/Liferay/liferay-portal-ee-6.2.x"
ee62xBundleDir="/Users/vicnate5/bundles/ee-6.2.x-bundles"

######################################################################################################################
#FUNCTIONS############################################################################################################
######################################################################################################################

dbClear(){
	if [[ -n "$mysqlUsername" ]]; then
		if [[ -n "$mysqlPassword" ]]
		then
			mysql -u $mysqlUsername -p $mysqlPassword -e "drop database if exists $db; create database $db char set utf8;"
		else
			mysql -u $mysqlUsername -e "drop database if exists $db; create database $db char set utf8;"
		fi
	else
		mysql -e "drop database if exists $db; create database $db char set utf8;"
	fi
}

updateToHeadOption(){
	read -p "Switch to main branch and update to HEAD? (y/n)?" -n 1 -r
		echo
		if [[ $REPLY == y ]]
		then
			echo "Checking for modified files"
			echo
			modified=$(git ls-files -m)
			if [ -n "$modified" ]
			then
				printf "\e[31mModified Files:\e[0m"
				echo $modified
				echo
				printf "\e[31mAny modified files will be cleared, are you sure you want to continue?\e[0m"
				printf "\e[31m[y/n?]\e[0m"

				read -n 1 -r
					echo
					if [[ $REPLY = y ]]
					then
						echo "Sweetness"
					elif [[ $REPLY = n ]]
					then
						echo "No"
						echo "Come back when you have committed or stashed your modified files."
						sleep 3
						exit
					else
						echo "please choose y or n"
						sleep 1
						exit
					fi
			else
				echo "No modified files"
			fi

			return 0
		elif [[ $REPLY == n ]]
		then
			echo "No"
			return 1
		else
			echo "please choose y or n"
			exit
		fi
}

detectOS(){
	OS=$(uname)
	if [[ ${OS} == *Darwin* ]]
	then
		sed="sed -i '' -e"
	elif [[ ${OS} == *Linux* ]]
	then
		sed="sed -i -e"
	elif [[ ${OS} == *NT* ]]
	then
		sed="sed -i -e"
	else
		echo "Could not detect OS"
		exit
	fi
}

######################################################################################################################
#SCRIPT###############################################################################################################
######################################################################################################################

branch="$1"
appServer="$2"
start="$3"

scriptSourceDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
propsDir=${scriptSourceDir}/properties

echo "Building $branch"
echo

if [[ $branch == "master"  ]]
then
	sourceDir=$masterSourceDir
	bundleDir=$masterBundleDir
	db=$masterDB
elif [[ $branch == "7.0.x" ]]
then
	sourceDir=$public70xSourceDir
	bundleDir=$public70xBundleDir
	db=$public70xDB
elif [[ $branch == "ee-7.0.x" ]]
then
	sourceDir=$ee70xSourceDir
	bundleDir=$ee70xBundleDir
	db=$ee70xDB
elif [[ $branch == "ee-6.2.x" ]]
then
	sourceDir=$ee62xSourceDir
	bundleDir=$ee62xBundleDir
	db=$ee62xDB
else
	echo "Not a valid branch option"
	exit
fi

detectOS

cd $sourceDir

if updateToHeadOption
then
	echo "Switching to base branch $branch"
	git checkout $branch
	echo
	echo "Clearing Gradle Cache"
	rm -r $sourceDir/.gradle/caches
	echo "Resetting main branch"
	git reset --hard
	echo
	echo "Pulling Upstream"
	echo
	git pull upstream $branch
	echo
	echo "Pushing to Origin"
	echo
	git push origin $branch
fi

echo "Adding properties files"
if [[ -e $propsDir/test.${username}.properties ]]
then
	cp $propsDir/test.${username}.properties $sourceDir/test.${username}.properties
else
	cp $propsDir/test.username.properties $sourceDir/test.${username}.properties
fi

if [[ -e $propsDir/app.server.${username}.properties ]]
then
	cp $propsDir/app.server.${username}.properties $sourceDir/app.server.${username}.properties
else
	cp $propsDir/app.server.username.properties $sourceDir/app.server.${username}.properties
fi

if [[ -e $propsDir/build.${username}.properties ]]
then
	cp $propsDir/build.${username}.properties $sourceDir/build.${username}.properties
else
	cp $propsDir/build.username.properties $sourceDir/build.${username}.properties
fi

echo
echo "Configuring app server parent directory"
${sed} "s~app.server.parent.dir=.*~app.server.parent.dir=${bundleDir}~" app.server.$username.properties
echo
echo "Configuring test.$username.properties for MySQL"
${sed} "s/database.mysql.schema=.*/database.mysql.schema=${db}/" test.$username.properties
echo
echo "Creating portal-ext.properties"
ant -f build-test.xml prepare-portal-ext-properties
echo
echo "ANT CLEAN"
ant clean
echo "ANT COMPILE"
ant compile
echo "ANT BUILD-DIST-$appServer"

if [[ $appServer == "tomcat" ]] || [[ -z $appServer ]]
then
	ant -f build-dist.xml build-dist-tomcat \
	-Dtomcat.keep.app.server.properties=true \
	-Denv.JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_74.jdk/Contents/Home
else
	ant -f build-dist.xml build-dist-$appServer
fi

echo "Remaking MySQL Database"
dbClear
echo "$db has been remade"
echo "PORTAL BUILD IS COMPLETE"

if [[ $start == "start" ]] && [[ $appServer == "tomcat" ]]
then
	cd $bundleDir/tomcat-8.0.32/bin
	./catalina.sh run
else
	read -rsp $'Press any key to continue...\n' -n1 key
fi