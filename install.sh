
ORIGINAL_USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)


# Check if the script is being run with sudo
if [ -z "$SUDO_USER" ]; then
    echo "This script must be run with sudo."
    exit 1
 fi

rm /usr/local/bin/mordrik

cp ${ORIGINAL_USER_HOME}/moordrik/mordrik /usr/local/bin/
chmod +x /usr/local/bin/mordrik
