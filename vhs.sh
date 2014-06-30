#!/bin/sh
#================================================================================
# vhs.sh
#
# A fancy little script to setup a new virtualhost in Ubuntu based upon the  
# excellent virtualhost (V1.04) script by Patrick Gibson <patrick@patrickg.com> for OS X.
#


# No point going any farther if we're not running correctly...
if [ `whoami` != 'root' ]; then
  echo "virtualhost.sh requires super-user privileges to work."
  echo "Enter your password to continue..."
  sudo "$0" $* || exit 1
  exit 0
fi

#if [ "$SUDO_USER" = "root" ]; then
#  /bin/echo "You must start this under your regular user account (not root) using sudo."
#  /bin/echo "Rerun using: sudo $0 $*"
#  exit 1
#fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# If you are using this script on a production machine with a static IP address,
# and you wish to setup a "live" virtualhost, you can change the following IP
# address to the IP address of your machine.
#
IP_ADDRESS="127.0.0.1"


# Configure the apache-related paths
#
APACHE_CONFIG_FILENAME="apache2.conf"
APACHE_CONFIG="/etc/apache2"
APACHECTL="/usr/sbin/apache2ctl"

# Set the virtual host configuration directory
APACHE_VIRTUAL_HOSTS_ENABLED="sites-enabled"
APACHE_VIRTUAL_HOSTS_AVAILABLE="sites-available"

# By default, use the site folders that get created will be 0wn3d by this group
OWNER_GROUP="www-data"

# If Apache works on a different port than the default 80, set it here
APACHE_PORT="80"

# Set to "yes" if you don't have a browser (headless) or don't want the site
# to be launched in your browser after the virtualhost is setup.
#SKIP_BROWSER="yes"

#DELETE_HOST_DIR=1

# You can now store your configuration directions in a ~/.vhs.sh.conf
# file so that you can download new versions of the script without having to
# redo your own settings.
if [ -e ~/.virtualhost.sh.conf ]; then
  . ~/.virtualhost.sh.conf
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

###############################################################################
########                         FUNCTIONS                         ############
###############################################################################

usage()
{
  cat <<__EOT
  Usage: virtualhost.sh <name> #create host in current dir
       virtualhost.sh <name> <dir>
       virtualhost.sh --delete <name>
       virtualhost.sh --list
__EOT

  exit 1
}

list_hosts()
{
  echo "Listing virtualhosts found in $APACHE_CONFIG/$APACHE_VIRTUAL_HOSTS_AVAILABLE"
  echo
  for i in $APACHE_CONFIG/$APACHE_VIRTUAL_HOSTS_AVAILABLE/*; do
    echo "file `basename $i:`"
    server_name=`grep "^\s*ServerName" $i | awk '{print $2}'`
    server_alias=`grep "^\s*ServerAlias" $i | awk '{print $2}'`
    doc_root=`grep "^\s*DocumentRoot" $i | awk '{print $2}' | sed -e 's/"//g'`
    if [ -z "$server_name" ]; then server_name="localhost (not set)" ; fi
    echo "\tServer name: $server_name"
    if [ "$server_alias" ]; then echo "\tServer alias: $server_alias" ; fi
    echo "\tDocument root: $doc_root"
  done
}

host_exiest()
{
    if [ -f "$APACHE_CONFIG/$APACHE_VIRTUAL_HOSTS_AVAILABLE/$1.conf" ]; then
      return 0
    else
      return 1
    fi
}


create_virtualhost()
{
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Create a default virtualhost file
  #
  echo  " + Creating virtualhost file... "
  cat << __EOT >"$APACHE_CONFIG/$APACHE_VIRTUAL_HOSTS_AVAILABLE/$1".conf
  <VirtualHost *:$APACHE_PORT>
    DocumentRoot $2
    ServerName $1

    <Directory $2>
      Options All
      AllowOverride All
      Require local
    </Directory>
  </VirtualHost>
__EOT
}

is_in_hosts()
{
  if grep -Fq $1 /etc/hosts ; then
    return 0
  else
    return 1
  fi
}

delete_from_hosts()
{
  echo "  - Removing $1 from /etc/hosts..."
  echo -n "  * Backing up current /etc/hosts as /etc/hosts.original..."
  cp /etc/hosts /etc/hosts.original
  sed "/$IP_ADDRESS\t*\s*$1/d" /etc/hosts > /etc/hosts2
  mv -f /etc/hosts2 /etc/hosts
  echo " done.."
}

delete_host()
{
  if [ -z $2 ] ; then
   usage
   exit 1
  fi
  host_name=$2

  if host_exiest $host_name ; then
    a2dissite $host_name".conf"
    if [ -z $DELETE_HOST_DIR ] || [ -z $3 ] ; then
      host_dir=`grep -F "DocumentRoot" $APACHE_CONFIG/$APACHE_VIRTUAL_HOSTS_AVAILABLE/$host_name.conf | awk '{print $2}' | sed -e 's/"//g'`
      echo $host_dir
    fi
    rm $APACHE_CONFIG/$APACHE_VIRTUAL_HOSTS_AVAILABLE/$host_name.conf
    service apache2 reload
  fi

  if is_in_hosts $host_name ; then
    delete_from_hosts $host_name
  fi
}

add_host()
{
  if [ -z $1 ] ; then
   usage
   exit 1
  fi
  host_name=$1
  if [ -z "$2" ]; then
    host_dir=`pwd`
  else
    if [ ! -d "$2" ]; then
      usage
      echo "Invalid dir"
      exit 1
    fi
    host_dir=`cd $2;pwd`
  fi

  if host_exiest ${host_name} ; then
    echo "Host alredy exist."
  else
    create_virtualhost $host_name $host_dir
  fi

  if is_in_hosts ${host_name} ; then
    echo "Host alredy exist in /et/hosts."
  else
    echo "$IP_ADDRESS\t$host_name" >> "/etc/hosts"
  fi

  a2ensite $host_name".conf"
  service apache2 reload
}

###############################################################################
########                     END FUNCTIONS                         ############
###############################################################################

case $1 in
  "") usage ;;
  "--list") list_hosts ;;
  "--delete") delete_host $@;;
  *) add_host $@;;
esac

exit 1
