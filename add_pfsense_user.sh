#!/bin/sh

# Usage: ./add_pfsense_user.sh <username> <password> <group>
# Example: ./add_pfsense_user.sh testuser mypass admins

USER="$1"
PASS="$2"
GROUP="${3:-admins}"   # default group = admins

if [ -z "$USER" ] || [ -z "$PASS" ]; then
  echo "Usage: $0 <username> <password> <group>"
  exit 1
fi

# Generate bcrypt hash of the password
HASH=$(openssl passwd -bcrypt "$PASS")

# Create a temporary XML snippet
TMPFILE=$(mktemp)
/bin/cat > "$TMPFILE" <<EOF
<user>
  <name>${USER}</name>
  <descr>Created via CLI script</descr>
  <scope>user</scope>
  <groupname>${GROUP}</groupname>
  <bcrypt-hash>${HASH}</bcrypt-hash>
</user>
EOF

# Insert the user entry into config.xml (before </system>)
sed -i "" "/<\/system>/e cat $TMPFILE" /conf/config.xml

# Clean up
rm -f "$TMPFILE"

# Reload pfSense config
/etc/rc.reload_all

echo "User '${USER}' created in pfSense with group '${GROUP}'"
