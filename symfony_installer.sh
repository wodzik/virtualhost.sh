#!/bin/sh
# USAGE:
# 
# CREATE A SYMFONY PROJECT:
# sudo ./symfony_installer <name>
# where <name> is the one-word name you'd like to use. (e.g. mysite)

# By default, this script places files in /home/[you]/Sites. If you would like
# to change this, like to how Apache on Ubuntu does things by default, uncomment the
# following line:
#
#DOC_ROOT_PREFIX="/var/www"

#Extension für local vhost
VHOSTEXTENSION=local
#vhost script that you call afterwards for vhost creation
VHOST_SCRIPT="virtualhost.sh"

usage()
{
	cat << __EOT
Usage: symfony_installer.sh <name>
   where <name> is the one-word name you'd like to use. (e.g. mysite)
__EOT
	exit 1
}

if [ -z $1 ]; then
	usage
else
	PROJECT=$1"."$VHOSTEXTENSION
fi

if [ -z $DOC_ROOT_PREFIX ]; then
	DOC_ROOT_PREFIX="/home/$USER/Sites"
fi

mkdir $PROJECT
cd $PROJECT
mkdir -p lib/vendor

svn checkout http://svn.symfony-project.com/branches/1.4/ lib/vendor/symfony
svn pe svn:externals lib/vendor/

php lib/vendor/symfony/data/bin/symfony generate:project $PROJECT

echo "Check symfony Version:"
php lib/vendor/symfony/data/bin/symfony -V

#ask for app name
echo "generate this app: "
read app
php symfony generate:app $app
#TODO ask for more apps

chmod 777 cache/ log/
ln -s /srv/www/$PROJECT/lib/vendor/symfony/data/web/sf web/sf

echo "configure the database"
echo "caution: we will use doctrine on localhost"
echo "enter dsn: "
echo "f.e. something like this: sqlite:%SF_DATA_DIR%/sandbox.db"
read dsn
echo "enter db user: "
read dbuser
echo "enter db passwort: "
read dbpass
php symfony configure:database "$dsn" $dbuser $dbpass

#Use git?
echo -n "- Create .gitignore... Continue? [Y/n]:"
 
gitignore()
{
cat << __EOT
*.log
*~
.project
.buildpath
.settings/*
.svn/
nbproject/*
 
#symfony
config/properties.ini
cache/*
log/*
data/*.db
__EOT

}
read continue
	
case $continue in
	y*|Y*) gitignore > .gitignore
	esac

#TODO git import
#create vhost
echo -n "- Create vhost. Continue? [Y/n]:"
read continue
	
case $continue in
	y*|Y*) 
	sudo .././$VHOST_SCRIPT $PROJECT
	esac
exit 0



