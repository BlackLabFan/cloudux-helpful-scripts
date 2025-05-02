#!/bin/bash
# setup this node to send emails via a gmail account that you supply
# creds for. Note, the gmail account you use must have mfa enabled.
# author: Joel Reyes joel.reyeseng@gmail.com

# check for root
if ! [ $(id -u) -eq 0 ]
then
  echo "You forgot to say the magic word... sudo!"
  exit 1
fi

# check to see if postfix is already installed
which postfix
if [ $? -eq 0 ]
then
  echo "postfix is already installed! Proceeding will delete existing"
  echo "postfix configs and the system will reboot."
  read -p "Do you want to continue? yes or no? " answer
  echo "$answer" | grep -qi y
  if [ $? -eq 0 ]
  then
    echo "Uninstalling postfix now. Rerun this script after reboot."
    sleep 5
    apt purge postfix -y && reboot
  else
    echo "exiting now, nothing was changed."
    exit
  fi
else
  echo ""
  echo "installing postfix now!"
  echo "when the installer completes and the GUI appears select the defaults"
  sleep 5
  apt install postfix
fi

# supply the needed gmail account info
clear
read -p "enter the gmail account you will use to send email: " gmail
sleep 1 # to protect against fat fingers
read -p "enter the app password associated with the above gmail \
account. You must enter the app password with no spaces: " app_passwd
echo "[smtp.gmail.com]:587 $gmail:$app_passwd" > /etc/postfix/sasl/sasl_passwd

postmap /etc/postfix/sasl/sasl_passwd

chmod 0600 /etc/postfix/sasl/*
chown root:root /etc/postfix/sasl/sasl_passwd

# edit main.cf
update_main="/etc/postfix/main.cf"
sed -i 's/relayhost =/relayhost = [smtp.gmail.com]:587/' $update_main

# finally we add this to the bottom of the main.cf:
echo "# Enable SASL authentication" >> $update_main
echo "smtp_sasl_auth_enable = yes" >> $update_main
echo "smtp_sasl_security_options = noanonymous" >> $update_main
echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd"\
 >> $update_main
echo "smtp_tls_security_level = encrypt" >> $update_main
echo "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" >> $update_main

systemctl restart postfix

echo ""
echo "Installation Complete!"
echo ""
read -p "Do you want to send a test email? yes or no? " answer
echo "$answer" | grep -qi y
if [ $? -eq 0 ]
then
  echo -e "Subject: Test Email\nTo: $gmail\n\nThis is an email test."\
 | sendmail -F "Test Email" $gmail
  echo "check your $gmail inbox for a message, subject line: Test Email"

else
  "All done!"
fi
