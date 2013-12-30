A fancy little script to setup a new virtualhost in Ubuntu based upon the  
excellent virtualhost (V1.04) script by Patrick Gibson <patrick@patrickg.com> for OS X: https://github.com/pgib/virtualhost.sh  

## Downloading

You can grab the [script here](https://github.com/ivoba/virtualhost.sh/raw/master/virtualhost.sh) (Option-click to download.)

## Documentation
This installer is a fork of: https://github.com/pgib/virtualhost.sh  
See the [wiki](https://github.com/pgib/virtualhost.sh/wiki) there.  

If you have upgraded from previous Ubuntu versions to 13.10 and you kept your apache.conf file, make sure your apache.conf also loads
*.conf files:

    # Include the virtual host configurations:
    IncludeOptional sites-enabled/*.conf

Since 13.10 a2ensite handles only files with "conf" suffix and this script has to rely on this.

