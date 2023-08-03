#!/bin/bash
#
# @(#)$Id: eduroam-freeradius.sh,v1.0 2023-08-03 nmclarty$
#
# EDUROAM-FREERADIUS DEPLOYMENT SCRIPT
# Author: Nick McLarty <nmclarty@cyber.tamus.edu>

#####
#
# Step 1: Download `freeradius-oauth2-perl` and supporting libraries
# 		: Source: https://github.com/jimdigriz/freeradius-oauth2-perl
#
#####

echo 'Downloading `freeradius-oauth2-perl` from GitHub...'
git clone https://github.com/jimdigriz/freeradius-oauth2-perl.git /opt/freeradius-oauth2-perl

echo 'Installing supporting libraries for `freeradius-oauth2-perl`...'
apt-get update
apt-get -y install --no-install-recommends ca-certificates curl libjson-pp-perl libwww-perl

#####
#
# Step 2: Install `freeradius`
#		: Source: https://networkradius.com/packages/#fr30-ubuntu-jammy
#
#####

echo 'Installing NetworkRADIUS PGP public key...'
install -d -o root -g root -m 0755 /etc/apt/keyrings
curl -s 'https://packages.networkradius.com/pgp/packages%40networkradius.com' | \
    sudo tee /etc/apt/keyrings/packages.networkradius.com.asc > /dev/null

echo 'Adding APT preference file for NetworkRADIUS repository...'
printf 'Package: /freeradius/\nPin: origin "packages.networkradius.com"\nPin-Priority: 999\n' | \
    sudo tee /etc/apt/preferences.d/networkradius > /dev/null

echo 'Adding NetworkRADIUS to APT sources list...'
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.networkradius.com.asc] http://packages.networkradius.com/freeradius-3.0/ubuntu/jammy jammy main" | \
    sudo tee /etc/apt/sources.list.d/networkradius.list > /dev/null

echo 'Installing FreeRADIUS...'
apt-get update
apt-get install freeradius

echo 'Network RADIUS SARL <info@networkradius.com>'
dpkg-query --showformat '${Maintainer}\n' -W freeradius
read 'Do the two lines above match (y/n)?' yn
case $yn in
	y ) echo 'Proceeding with script...';;
	n ) echo 'Exiting...';
			exit;;
esac

#####
#
# Step 3: Backing up /etc/freeradius directory
#		: Source: https://github.com/jimdigriz/freeradius-oauth2-perl
#
#####

cp -a /etc/freeradius /etc/freeradius.orig

#####
#
# Step 4: Adding `freeradius-oauth2-perl` files to /etc/freeradius
# 		: Source: https://github.com/jimdigriz/freeradius-oauth2-perl
#
#####

printf '\n$INCLUDE /opt/freeradius-oauth2-perl/dictionary\n' >> /etc/freeradius/dictionary
ln -s /opt/freeradius-oauth2-perl/module /etc/freeradius/mods-enabled/oauth2
ln -s /opt/freeradius-oauth2-perl/policy /etc/freeradius/policy.d/oauth2

#####
#
# Step 5: Patching /etc/freeradius directory
#		: Source: https://github.com/jimdigriz/freeradius-oauth2-perl
#
#####

patch -d /etc/freeradius -p1 < eduroam-freeradius.patch

#####
#
# Step 6: Cleanup tasks
#		: Source: https://github.com/jimdigriz/freeradius-oauth2-perl
#
#####

echo 'Complete these tasks after the script ends...'
echo '1. Edit `/etc/freeradius/clients.conf` and add the eduroam shared secret to the `client eduroam_tlrs1` and `client eduroam_tlrs2` stanzas.'
echo '2. Edit `/etc/freeradius/proxy.conf` and replace `client contoso.com` with your Azure domain and add the OAuth2 client ID and token from your Azure App Registration.'
echo '3. Generate a new self-signed key pair (you may place the cert/key files in `/etc/freeradius/certs` but not required).'
echo '4. Edit `/etc/freeradius/mods-enabled/eap` with the path to the cert/key files.'
exit
