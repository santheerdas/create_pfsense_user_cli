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

CONFIG="/conf/config.xml"
BACKUP="/conf/config.xml.bak.$(date +%F_%H%M%S)"

# Step 1: Backup config.xml
cp "$CONFIG" "$BACKUP"
if [ $? -ne 0 ]; then
  echo "Backup failed. Aborting."
  exit 1
fi
echo "Backup created: $BACKUP"

# Step 2: Generate bcrypt hash of the password
HASH=$(openssl passwd -bcrypt "$PASS")

# Step 3: Create temporary XML snippet for new user
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

# Step 4: Insert new user into config.xml (before </system>)
sed -i "" "/<\/system>/e cat $TMPFILE" "$CONFIG"

# Clean up temp file
rm -f "$TMPFILE"

# Step 5: Reload pfSense config
/etc/rc.reload_all

echo "User '${USER}' created in pfSense with group '${GROUP}'"

