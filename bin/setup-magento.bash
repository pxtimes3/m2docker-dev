#!/usr/bin/env bash

VERSION=2.4.1
SAMPLEDATA=0
EXT=""

set -o history -o histexpand

source ./env

function usage()
{
    echo "Usage:"
    echo ""
    echo "$ bash setup-magento.bash" 
    echo ""
    echo "Arguments:"
    echo "--version"
    echo "  Your preferred version of Magento 2."
    echo "  bash setup-magento.bash --version=2.4.1"
    echo "--sample-data"
    echo "  Setup Magento 2 with sample data."
    echo "  bash setup-magento.bash --version=2.4.1 --sample-data=1"
    echo "-h or --help"
    echo "  Shows this help"
}

function download()
{
	if [[ $SAMPLEDATA == 1 ]];then
		EXT=with-samples-${VERSION}
	else
		EXT=${VERSION}
	fi

	if [ ! -f ./source/magento2-${EXT}.tar.gz ]; then
		echo "Downloading magento2-${EXT}.tar.gz"
    	mkdir -p ./source
    	(cd ./source && curl -fOL http://pubfiles.nexcess.net/magento/ce-packages/magento2-${EXT}.tar.gz)
    else
    	echo "magento2-${EXT}.tar.gz found in source/"
	fi
}

function extract() 
{
	if [ ! -f ./source/magento2-${EXT}.tar.gz ]; then
		echo "ERROR: Was expecting to find magento2-${EXT}.tar.gz in source/ but it wasn't there..."
		exit 1
	else
		echo "Extracting magento2-${EXT}.tar.gz to ./src"
    	mkdir -p src && tar xzf ./source/magento2-${EXT}.tar.gz -o -C src
	fi
}

function preinstall()
{
	echo "Installing Magento 2 with the following parameters:"
	echo ""
	echo "MYSQL_HOST = ${MYSQL_HOST}"
	echo "MYSQL_ROOT_PASSWORD = ${MYSQL_ROOT_PASSWORD}"
	echo "MYSQL_DATABASE = ${MYSQL_DATABASE}"
	echo "MYSQL_USER = ${MYSQL_USER}"
	echo "MYSQL_PASSWORD = ${MYSQL_PASSWORD}"
	echo "BASE_URL = ${BASE_URL}"
	echo "ADMIN_URL = ${ADMIN_URL}"
	echo "ADMIN_USER = ${ADMIN_USER}"
	echo "ADMIN_PASSWORD = ${ADMIN_PASSWORD}"
	echo "LANGUAGE = ${LANGUAGE}"
	echo "CURRENCY = ${CURRENCY}"
	echo "TIMEZONE = ${TIMEZONE}"
	echo ""
	read -p "Is this correct [Y/n]?" CHOICE
	case "$CHOICE" in 
  		y|Y ) copyfiles;;
  		n|N ) echo "Please edit the env-file and re-run the installer."; return;;
  		* ) echo "Aborting";;
	esac
}

function copyfiles()
{
	docker-compose -f docker-compose.yml up -d
	[ $? != 0 ] && echo "Failed to start Docker services" && exit
	sleep 5

	echo "Copying files from host to container..."
	rm -rf src/vendor

	PHPFPM_CONTAINER=$(docker-compose ps -q phpfpm | awk '{print $1}')
	docker cp ./src/./ ${PHPFPM_CONTAINER}:/var/www/html

	if [ $? != 0 ]; then
		echo "Copying of files failed!"
		exit
	else
		echo "Files copied from src/ to volume..."
	fi
	
	docker-compose exec -T -u root phpfpm chmod u+x bin/magento
	if [ $? != 0 ]; then
		echo "ERROR: Couldn't set permissions on bin/magento!"
		exit
	fi
}

function composerSetup()
{
	composer global config http-basic.repo.magento.com $PUBLIC_KEY $PRIVATE_KEY
	if [ $? != 0 ]; then
		echo "ERROR: Couldn't set keys for repo.magento.com!"
		exit
	else
		echo "Keys for repo.magento.com set..."
	fi

	docker-compose exec -T phpfpm composer update
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --version)
            VERSION=$VALUE
            ;;
        --sample-data)
			SAMPLEDATA=1
			;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit
            ;;
    esac
    shift
done

#download
#extract
#copyfiles
composerSetup
#install
