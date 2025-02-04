#!/bin/bash

CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
MAGENTA="\e[35m"
NC="\e[0m"

# Function to continue after pressing Enter
press_enter() {
    echo -e "\n ${RED}Press Enter to continue... ${NC}"
    read
}

# Function to display a fancier progress bar
display_fancy_progress() {
    local duration=$1
    local sleep_interval=0.1
    local progress=0
    local bar_length=40

    while [ $progress -lt $duration ]; do
        echo -ne "\r[${YELLOW}"
        for ((i = 0; i < bar_length; i++)); do
            if [ $i -lt $((progress * bar_length / duration)) ]; then
                echo -ne "▓"
            else
                echo -ne "░"
            fi
        done
        echo -ne "${RED}] ${progress}%"
        progress=$((progress + 1))
        sleep $sleep_interval
    done
    echo -ne "\r[${YELLOW}"
    for ((i = 0; i < bar_length; i++)); do
        echo -ne "#"
    done
    echo -ne "${RED}] ${progress}%"
    echo
}

BLUE='\033[0;34m'
NC='\033[0m' # No Color

logo() {
    echo -e "\n${BLUE}
    Smartsina                                                                                                            
    ${NC}\n"
}


# Check if script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\n ${RED}This script must be run as root.${NC}"
    exit 1
fi
##############################
install() {
 # Change SSH ports using cat
    cat << EOF >> /etc/ssh/sshd_config
Port 3300
Port 34500
Port 9011
Port 22
EOF

    # Reload SSH settings
    systemctl reload sshd
    systemctl restart sshd

    # Change nameservers
    echo "nameserver 217.218.127.127
nameserver 178.22.122.100
nameserver 185.51.200.2
nameserver 84.200.69.80
nameserver 84.200.70.40" > /etc/resolv.conf
    clear
    echo -e "${RED}At First we should make sure all packages are suitable for VPN server.${NC}"
    sleep 1
            apt-get update > /dev/null 2>&1
            display_fancy_progress 20

            apt-get upgrade -y > /dev/null 2>&1
            display_fancy_progress 40

            apt-get install build-essential -y && apt-get install expect -y > /dev/null 2>&1
            display_fancy_progress 50

            apt-get install wget certbot make ufw gcc binutils gzip libreadline-dev libssl-dev libncurses5-dev libncursesw5-dev libpthread-stubs0-dev -y > /dev/null 2>&1
            display_fancy_progress 70

    
}


config() {
    echo ""
    echo -e "${YELLOW}Let's start configuring the Softether VPN server.${NC}"
    press_enter
    # Enable IPv4 and IPv6 forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    sysctl -p

    # Download SoftEther installer file and overwrite if it already exists
    wget -N https://www.softether-download.com/files/softether/v4.43-9799-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz
    #wget https://www.softether-download.com/files/softether/v4.42-9798-rtm-2023.06.30-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.42-9798-rtm-2023.06.30-linux-x64-64bit.tar.gz

    # Extract the installer file quietly
    tar xzf softether-vpnserver-v*
    
    cd vpnserver && make

    cd ..

    mv vpnserver /usr/local/vpnserver
    cd /usr/local/vpnserver/
    chmod 600 *
    chmod 700 vpnserver vpncmd
    ./vpnserver start
    #sudo /opt/softether/vpnserver start

    # Create a service file
    echo "[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/vpnserver.service



    # Create the lock directory
    chmod +x /lib/systemd/system/vpnserver.service
    systemctl stop vpnserver
    systemctl enable vpnserver
    systemctl start vpnserver
    systemctl reload vpnserver
    systemctl restart vpnserver
    #systemctl status vpnserver

echo ""
echo -e "               ${YELLOW}AFTER REBOOT RUN THIS SCRIPT AGAIN AND PLEASE CHOOSE OPTION 2.${NC}"

echo -ne "${GREEN}Reboot your VPS now? [Y/N]: ${NC}"
read reboot
case "$reboot" in
        [Yy]) 
        systemctl reboot
        ;;
        *) 
        return 
        ;;
    esac
    display_fancy_progress 100
exit
}


#################################
root_password() {


# اضافه کردن پورت‌ها و تنظیمات به فایل sshd_config
echo "به‌روزرسانی فایل sshd_config..."
sudo sed -i '1i Port 22\nPort 34500\nPort 9011\nPermitRootLogin yes' /etc/ssh/sshd_config

# ری‌لود و ری‌استارت سرویس SSHD
echo "ری‌لود و ری‌استارت کردن سرویس sshd..."
sudo systemctl reload sshd
sudo systemctl restart sshd

# تنظیم رمز عبور root
echo "تنظیم رمز عبور برای کاربر root..."
echo "root:Mohamadreza61810511" | sudo chpasswd

echo "همه مراحل انجام شد."



}

password() {

  clear
  # Use an expect script to automate interaction with vpncmd
  echo ""
  echo ""
echo -ne "${YELLOW}Type your desire admin password ${NC}"
read password

expect <<EOF
    spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

    expect "Select 1, 2 or 3:"
    send "1\r"

    expect "VPN Server>"
    send "ServerPasswordSet\r"

    expect "Password:"
    send "${password}\r"

    expect "Confirm input:"
    send "${password}\r"

    expect "VPN Server>"
    send "exit\r"

    expect eof
EOF

   echo -e "${GREEN}Go to SOFTETHER SERVER MANAGER use your IP and ${password}.${NC}"
   ${GREEN} display_fancy_progress 100 ${NC}
}
#########################################
add-expieration-date () {
sudo apt update && sudo apt upgrade -y
sudo apt install expect python3 python3-pip build-essential unzip -y
pip3 install persiantools
# گرفتن رمز عبور ادمین از کاربر
echo -ne "${YELLOW}Enter your desired admin password: ${NC}"
read  admin_password  # مخفی کردن رمز عبور
echo ""


  # تعریف پسورد ثابت ادمین
  #admin_password="12345678"

  # اجرای اسکریپت expect برای دریافت اطلاعات کاربران
  expect <<EOF > /tmp/vpncmd_output.txt
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# انتخاب گزینه برای تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب FR
expect "VPN Server>"
send "hub fr\r"

# دریافت لیست کاربران
expect "VPN Server/FR>"
send "UserList\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof
EOF

  # تابع تبدیل تاریخ میلادی به شمسی
  convert_to_shamsi() {
  sudo apt update && sudo apt upgrade -y
sudo apt install expect python3 python3-pip build-essential unzip -y
pip3 install persiantools

    local miladi_date="$1"
    clean_date=$(echo "$miladi_date" | sed 's/ (.*)//' | cut -d' ' -f1)

    if [[ "$clean_date" == "No" ]]; then
      echo "No Expiration"
      return
    fi

    python3 -c "
from persiantools.jdatetime import JalaliDate
try:
    miladi_date = '${clean_date}'
    shamsi_date = JalaliDate.to_jalali(*map(int, miladi_date.split('-')))
    print(shamsi_date)
except ValueError:
    print('Invalid Date')
"
  }

  # پردازش خروجی vpncmd
  echo -e "${YELLOW}User Name and Expiration Date in Shamsi:${NC}"

  while IFS= read -r line; do
    # بررسی و استخراج نام کاربری
    if [[ "$line" == *"User Name"* ]]; then
      username=$(echo "$line" | awk -F '|' '{print $2}' | xargs)
      continue
    fi

    # بررسی و استخراج تاریخ انقضا
    if [[ "$line" == *"Expiration Date"* ]]; then
      expiration=$(echo "$line" | awk -F '|' '{print $2}' | xargs)

      if [[ "$expiration" != "No Expiration" ]]; then
        expiration_date=$(convert_to_shamsi "$expiration")
      else
        expiration_date="No Expiration"
      fi

      # چاپ اطلاعات به فرمت مناسب
      printf " %-15s - %s\n" "$expiration_date" "$username"
    fi
  done < /tmp/vpncmd_output.txt

# تعریف پسورد ثابت ادمین
#admin_password="12345678"

# گرفتن یوزرنیم کاربر از کاربر
echo -ne "${YELLOW}Enter the username for which you want to check the expiration date: ${NC}"
read username
echo ""

# استفاده از اسکریپت expect برای تعامل خودکار با vpncmd و دریافت اطلاعات کاربر
output=$(expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# انتخاب گزینه برای تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب FR
expect "VPN Server>"
send "hub fr\r"

# دریافت اطلاعات کاربر
expect "VPN Server/FR>"
send "UserGet $username\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof
EOF
)

# استخراج تاریخ انقضا از خروجی
expiration_date=$(echo "$output" | grep "Expiration" | awk -F': ' '{print $2}')

# چک کردن اگر تاریخ انقضا موجود باشد
if [ -z "$expiration_date" ]; then
  echo -e "${YELLOW}No expiration date found for user '$username'. Setting expiration to 1 month from now.${NC}"

  # اگر تاریخ انقضا وجود ندارد، تاریخ کنونی + 1 ماه محاسبه می‌شود و فرمت مورد نظر تنظیم می‌شود
  expiration_date=$(date -d "+1 month" "+%Y/%m/%d %H:%M:%S")
else
  echo -e "${GREEN}Expiration date for user '$username' is: $expiration_date.${NC}"
fi

echo -e "${GREEN}Setting new expiration date to: $expiration_date.${NC}"
${GREEN} display_fancy_progress 50 ${NC}
# استفاده از دستور UserExpiresSet برای تغییر تاریخ انقضا
expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# ورود به تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور
expect "Password:"
send "$admin_password\r"

# انتخاب هاب
expect "VPN Server>"
send "hub fr\r"

# تنظیم تاریخ انقضا
expect "VPN Server/FR>"
send "UserExpiresSet $username /EXPIRES:\"$expiration_date\"\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof

EOF

echo -e "${GREEN}The expiration date for user '$username' has been successfully updated to $expiration_date.${NC}"

${GREEN} display_fancy_progress 100 ${NC}
}

###################################
adduser () {
sudo apt update && sudo apt upgrade -y
sudo apt install expect python3 python3-pip build-essential unzip -y
pip3 install persiantools

# گرفتن رمز عبور ادمین از کاربر
echo -ne "${YELLOW}Enter your desired admin password: ${NC}"
read  admin_password  # مخفی کردن رمز عبور
echo ""

# گرفتن یوزرنیم و پسورد جدید از کاربر
echo -ne "${YELLOW}Enter the username for the new user: ${NC}"
read new_username
echo -ne "${YELLOW}Enter the password for the new user: ${NC}"
read  new_password  # مخفی کردن پسورد
echo ""

# استفاده از اسکریپت expect برای تعامل خودکار با vpncmd
expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555


# انتخاب گزینه برای تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب FR
expect "VPN Server>"
send "hub fr\r"

# ایجاد یوزر جدید
expect "VPN Server/FR>"
send "UserCreate $new_username /GROUP:1 /REALNAME:$new_password /NOTE:Auto-created\r"

# تنظیم پسورد برای یوزر جدید
expect "VPN Server/FR>"
send "UserPasswordSet $new_username /PASSWORD:$new_password\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

# اتمام اسکریپت expect
expect eof
EOF


# تعریف پسورد ثابت ادمین
#admin_password="12345678"

# گرفتن یوزرنیم کاربر از کاربر
#echo -ne "${YELLOW}Enter the username for which you want to check the expiration date: ${NC}"
#read username
#echo ""

username = $new_username

# استفاده از اسکریپت expect برای تعامل خودکار با vpncmd و دریافت اطلاعات کاربر
output=$(expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# انتخاب گزینه برای تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب FR
expect "VPN Server>"
send "hub fr\r"

# دریافت اطلاعات کاربر
expect "VPN Server/FR>"
send "UserGet $new_username\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof
EOF
)

# استخراج تاریخ انقضا از خروجی
expiration_date=$(echo "$output" | grep "Expiration" | awk -F': ' '{print $2}')

# چک کردن اگر تاریخ انقضا موجود باشد
if [ -z "$expiration_date" ]; then
  echo -e "${YELLOW}No expiration date found for user '$username'. Setting expiration to 1 month from now.${NC}"

  # اگر تاریخ انقضا وجود ندارد، تاریخ کنونی + 1 ماه محاسبه می‌شود و فرمت مورد نظر تنظیم می‌شود
  expiration_date=$(date -d "+1 month" "+%Y/%m/%d %H:%M:%S")
else
  echo -e "${GREEN}Expiration date for user '$username' is: $expiration_date.${NC}"
fi

echo -e "${GREEN}Setting new expiration date to: $expiration_date.${NC}"

# استفاده از دستور UserExpiresSet برای تغییر تاریخ انقضا
expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# ورود به تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور
expect "Password:"
send "$admin_password\r"

# انتخاب هاب
expect "VPN Server>"
send "hub fr\r"

# تنظیم تاریخ انقضا
expect "VPN Server/FR>"
send "UserExpiresSet $new_username /EXPIRES:\"$expiration_date\"\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof

EOF

echo -e "${GREEN}The expiration date for user '$new_username' has been successfully updated to $expiration_date.${NC}"



# پیام موفقیت
echo -e "${GREEN}The new user '$new_username' has been created successfully.${NC}"
echo -e "${GREEN}You can now use this username and password to log in to the SoftEther VPN server.${NC}"
}
########################################
delete_user () {
sudo apt update && sudo apt upgrade -y
sudo apt install expect python3 python3-pip build-essential unzip -y
pip3 install persiantools
# گرفتن رمز عبور ادمین از کاربر
echo -ne "${YELLOW}Enter your desired admin password: ${NC}"
read  admin_password  # مخفی کردن رمز عبور
echo ""


  # تعریف پسورد ثابت ادمین
  #admin_password="12345678"

  # اجرای اسکریپت expect برای دریافت اطلاعات کاربران
  expect <<EOF > /tmp/vpncmd_output.txt
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# انتخاب گزینه برای تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب FR
expect "VPN Server>"
send "hub fr\r"

# دریافت لیست کاربران
expect "VPN Server/FR>"
send "UserList\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof
EOF

  # تابع تبدیل تاریخ میلادی به شمسی
  convert_to_shamsi() {
    local miladi_date="$1"
    clean_date=$(echo "$miladi_date" | sed 's/ (.*)//' | cut -d' ' -f1)

    if [[ "$clean_date" == "No" ]]; then
      echo "No Expiration"
      return
    fi

    python3 -c "
from persiantools.jdatetime import JalaliDate
try:
    miladi_date = '${clean_date}'
    shamsi_date = JalaliDate.to_jalali(*map(int, miladi_date.split('-')))
    print(shamsi_date)
except ValueError:
    print('Invalid Date')
"
  }

  # پردازش خروجی vpncmd
  echo -e "${YELLOW}User Name and Expiration Date in Shamsi:${NC}"

  while IFS= read -r line; do
    # بررسی و استخراج نام کاربری
    if [[ "$line" == *"User Name"* ]]; then
      username=$(echo "$line" | awk -F '|' '{print $2}' | xargs)
      continue
    fi

    # بررسی و استخراج تاریخ انقضا
    if [[ "$line" == *"Expiration Date"* ]]; then
      expiration=$(echo "$line" | awk -F '|' '{print $2}' | xargs)

      if [[ "$expiration" != "No Expiration" ]]; then
        expiration_date=$(convert_to_shamsi "$expiration")
      else
        expiration_date="No Expiration"
      fi

      # چاپ اطلاعات به فرمت مناسب
      printf " %-15s - %s\n" "$expiration_date" "$username"
    fi
  done < /tmp/vpncmd_output.txt

# تعریف پسورد ثابت ادمین
#admin_password="12345678"

# گرفتن یوزرنیم کاربر از کاربر
echo -ne "${YELLOW}Enter the username for which you want to Delete: ${NC}"
read username
echo ""

# استفاده از اسکریپت expect برای تعامل خودکار با vpncmd و دریافت اطلاعات کاربر
output=$(expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# انتخاب گزینه برای تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب FR
expect "VPN Server>"
send "hub fr\r"

# دریافت اطلاعات کاربر
expect "VPN Server/FR>"
send "UserGet $username\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof
EOF
)

# استخراج تاریخ انقضا از خروجی
expiration_date=$(echo "$output" | grep "Expiration" | awk -F': ' '{print $2}')

# چک کردن اگر تاریخ انقضا موجود باشد
if [ -z "$expiration_date" ]; then
  echo -e "${YELLOW}No expiration date found for user '$username'. Setting expiration to 1 month from now.${NC}"

  # اگر تاریخ انقضا وجود ندارد، تاریخ کنونی + 1 ماه محاسبه می‌شود و فرمت مورد نظر تنظیم می‌شود
  expiration_date=$(date -d "+1 month" "+%Y/%m/%d %H:%M:%S")
else
  echo -e "${GREEN}Expiration date for user '$username' is: $expiration_date.${NC}"
fi

#echo -e "${GREEN}Setting new expiration date to: $expiration_date.${NC}"


    # دریافت نام کاربری برای حذف
    #echo -ne "${YELLOW}Enter the username you want to delete: ${NC}"
    #read username
    #echo ""

    # اجرای دستور expect برای حذف کاربر
    expect <<EOF
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# انتخاب گزینه تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب موردنظر
expect "VPN Server>"
send "hub fr\r"

# حذف کاربر
expect "VPN Server/FR>"
send "UserDelete $username\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof
EOF

    # بررسی نتیجه عملیات
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}User '$username' has been successfully deleted.${NC}"
    else
        echo -e "${RED}Failed to delete user '$username'. Please check your input and try again.${NC}"
    fi
}

################################
see-expieration-date() {
sudo apt update && sudo apt upgrade -y
sudo apt install expect python3 python3-pip build-essential unzip -y
pip3 install persiantools
    # گرفتن رمز عبور ادمین از کاربر
echo -ne "${YELLOW}Enter your desired admin password: ${NC}"
read  admin_password  # مخفی کردن رمز عبور
echo ""
  # تعریف پسورد ثابت ادمین
  #admin_password="12345678"

  # اجرای اسکریپت expect برای دریافت اطلاعات کاربران
  expect <<EOF > /tmp/vpncmd_output.txt
spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

# انتخاب گزینه برای تنظیمات سرور
expect "Select 1, 2 or 3:"
send "1\r"

# وارد کردن رمز عبور ادمین
expect "Password:"
send "$admin_password\r"

# انتخاب هاب FR
expect "VPN Server>"
send "hub fr\r"

# دریافت لیست کاربران
expect "VPN Server/FR>"
send "UserList\r"

# خروج از vpncmd
expect "VPN Server/FR>"
send "exit\r"

expect eof
EOF

  # تابع تبدیل تاریخ میلادی به شمسی
  convert_to_shamsi() {
    local miladi_date="$1"
    clean_date=$(echo "$miladi_date" | sed 's/ (.*)//' | cut -d' ' -f1)

    if [[ "$clean_date" == "No" ]]; then
      echo "No Expiration"
      return
    fi

    python3 -c "
from persiantools.jdatetime import JalaliDate
try:
    miladi_date = '${clean_date}'
    shamsi_date = JalaliDate.to_jalali(*map(int, miladi_date.split('-')))
    print(shamsi_date)
except ValueError:
    print('Invalid Date')
"
  }

  # پردازش خروجی vpncmd
  echo -e "${YELLOW}User Name and Expiration Date in Shamsi:${NC}"

  while IFS= read -r line; do
    # بررسی و استخراج نام کاربری
    if [[ "$line" == *"User Name"* ]]; then
      username=$(echo "$line" | awk -F '|' '{print $2}' | xargs)
      continue
    fi

    # بررسی و استخراج تاریخ انقضا
    if [[ "$line" == *"Expiration Date"* ]]; then
      expiration=$(echo "$line" | awk -F '|' '{print $2}' | xargs)

      if [[ "$expiration" != "No Expiration" ]]; then
        expiration_date=$(convert_to_shamsi "$expiration")
      else
        expiration_date="No Expiration"
      fi

      # چاپ اطلاعات به فرمت مناسب
      printf " %-15s - %s\n" "$expiration_date" "$username"
    fi
  done < /tmp/vpncmd_output.txt


}
################################

uninstall() {
    clear
    echo ""
    echo -ne "${GREEN}Are you sure you want to uninstall the VPN server? [Y/N]: ${NC}"
    read uninstall_software

    case "$uninstall_software" in
        [yY])
            systemctl stop vpnserver
            systemctl disable vpnserver
            rm -rf /usr/local/vpnserver
            rm /lib/systemd/system/vpnserver.service

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}VPN server successfully uninstalled.${NC}"
            else
                echo -e "${RED}Error: Failed to uninstall VPN server.${NC}"
            fi
            ;;
        [Nn])
            continue
            ;;
        *)
            exit 0
            ;;
    esac
}

certificate() {
    clear
    echo ""
    echo -ne "${GREEN}Enter your domain: ${NC}"
    read domain
    echo ""
    echo -ne "${YELLOW}Type your "ADMIN PASSWORD" ${NC}"
    read password

    # Check if the certificate already exists in the specified directory
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]; then
        echo "Certificate files already exist for $domain."
    else
        # Obtain a new certificate if it doesn't exist
        certbot certonly --register-unsafely-without-email --standalone --preferred-challenges http --agree-tos -d $domain
    fi

    expect <<EOF
    spawn sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555

    expect "Select 1, 2 or 3:"
    send "1\r"

    expect "password:"
    send "${password}\r"

    expect "VPN Server>"
    send "ServerCertSet\r"

    expect "Public key:"
    send "/etc/letsencrypt/live/$domain/fullchain.pem\r"

    expect "private key:"
    send "/etc/letsencrypt/live/$domain/privkey.pem\r"

    expect "VPN Server>"
    send "exit\r"

    expect eof
EOF

    echo -e "${YELLOW}Your admin Panel available at ${GREEN}https://$domain:5555 ${YELLOW} and admin password is ${GREEN}$password ${NC}"
    # Restart the VPN server
    systemctl restart vpnserver

    # Set up a cron job to renew the certificate automatically
    echo "0 0 * * * certbot renew --quiet" | sudo crontab -
}


firewall() {
    clear
    echo -ne "${GREEN}Are you sure you want to set up a firewall and disable all ports except VPN server ports? [Y/N]: ${NC}"
    read firewall

    case "$firewall" in
        [yY])
            ufw allow 22
            ufw allow 443
            ufw allow 34501
            ufw allow 56000
            ufw allow 9011
            ufw allow 80
            ufw allow 992
            ufw allow 1194
            ufw allow 5555
            ufw allow 4500
            ufw allow 1701
            ufw allow 500
            ufw allow 500/udp
            ufw allow 4500/udp
            ufw disable 
            ;;
        [Nn])
            continue
            ;;
        *)
            exit 0
            ;;
    esac
}

status() {
    clear
    echo -e "${CYAN}*** ${GREEN}SoftEther VPN Server ${YELLOW}Service${CYAN} ***${NC}"

    # Check the status of the SoftEther VPN Server service
    status_output=$(systemctl status vpnserver 2>&1)

    if [[ "$status_output" =~ "Active: active" ]]; then
        echo -e "${GREEN}Status: Running${NC}"
    else
        echo -e "${RED}Status: Not Running${NC}"
    fi

    echo ""
    echo "$status_output"
}

help() {
    clear
    echo ""
    echo -e "${CYAN}***${GREEN} برای راه اندازی سرویس در پس‌زمینه سرور ${CYAN}***${NC}"
    echo -e "${YELLOW}/opt/softether/vpnserver start${NC}"
    echo ""
    echo ""
    echo -e "${CYAN}***${GREEN} برای راه اندازی دوباره سرویس  ${CYAN}***${NC}"
    echo -e "${YELLOW}systemctl restart softether-vpnserver${NC}"
    echo ""
    echo ""
    echo -e "${CYAN}***${GREEN} برای توقف سرویس ${CYAN}***${NC}"
    echo -e "${YELLOW}/opt/softether/vpnserver stop${NC}"
    echo ""
    echo ""
    echo -e "${CYAN}***${GREEN} برای پیکربندی سرور ${CYAN}***${NC}"
    echo -e "${YELLOW}sudo /usr/local/vpnserver/vpncmd 127.0.0.1:5555${NC}"
    echo ""
    echo ""
    echo -e "${CYAN}***${GREEN} Server Manager  برای کاربران ویندوز و مک ${CYAN}***${NC}"
    echo -e "${YELLOW}softether-download.com${NC}"
    echo ""
    echo ""
    echo -e "${CYAN}*** ${GREEN}کنسول مدیریتی ${CYAN}***${NC}"
    echo ""
    echo -e "${YELLOW}https://IPV4/IPV6:5555/${NC}"
    echo -e "یا"
    echo -e "${YELLOW}https://DOMAIN:5555/${NC}"
    echo ""
}



vpn_logs() {
    clear
    echo -e "${CYAN}*** ${GREEN}VPN Server Logs ${CYAN}***${NC}"
    echo ""
    journalctl -u vpnserver.service --no-pager
    echo -e "${NC}"
}

menu_status() {
    if systemctl is-active --quiet vpnserver; then
        echo -e "${CYAN}Status: ${GREEN}Running${NC}"
    else
        echo -e "${CYAN}Status: ${RED}Not Running${NC}"
    fi
    echo ""
}

prepration_ipv6() {
    clear
    echo -e "${YELLOW}Lets check the system before proceeding...${NC}"
    apt-get update > /dev/null 2>&1
    display_fancy_progress 20

    if ! dpkg -l | grep -q iproute2; then
        echo -e "${YELLOW}iproute2 is not installed. Installing it now...${NC}"
        apt-get update
        apt-get install iproute2 -y > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}iproute2 has been installed.${NC}"
        else
            echo -e "${RED}Failed to install iproute2. Please install it manually.${NC}"
            return
        fi
    fi
        modprobe ipv6 > /dev/null 2>&1
        echo 1 > /proc/sys/net/ipv4/ip_forward > /dev/null 2>&1
        echo 1 > /proc/sys/net/ipv6/conf/all/forwarding > /dev/null 2>&1

    if [[ $(cat /proc/sys/net/ipv4/ip_forward) -eq 0 ]]; then
        echo -e "${RED}IPv4 forwarding is not enabled. Attempting to enable it...${NC}"
        echo 1 > /proc/sys/net/ipv4/ip_forward
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}IPv4 forwarding has been enabled.${NC}"
        else
            echo -e "${RED}Failed to enable IPv4 forwarding. Please enable it manually before configuring 6to4, just type below command into your terminal${NC}"
            echo ""
            echo -e "${YELLOW}echo 1 > /proc/sys/net/ipv4/ip_forward${NC}"
            return
        fi
    fi

    if [[ $(cat /proc/sys/net/ipv6/conf/all/forwarding) -eq 0 ]]; then
        echo -e "${RED}IPv6 forwarding is not enabled. Attempting to enable it...${NC}"
        for interface in /proc/sys/net/ipv6/conf/*/forwarding; do
            echo 1 > "$interface"
        done
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}IPv6 forwarding has been enabled.${NC}"
        else
            echo -e "${RED}Failed to enable IPv6 forwarding. Please enable it manually before configuring 6to4.${NC}"
            return
        fi
    fi
}

6to4_ipv6() {
    clear
    prepration_ipv6
    systemctl restart systemd-networkd
    sleep 1
    echo ""
    echo -e "       ${MAGENTA}Setting up 6to4 IPv6 addresses...${NC}"

    echo ""
    echo -ne "${YELLOW}Do you have your own 6to4 IPv6 (Convert IPV4 to IPV6)? [Y/N]${NC}   "
    read answer
        case $answer in
        [Yy])
            echo -ne "${YELLOW}Please enter your 6to4 IP?${NC}   "
            read ipv6_address
            ;;
        [Nn])
            echo -ne "${YELLOW}Enter the IPv4 address${NC}   "
            read ipv4
            ipv6_address=$(printf "2002:%02x%02x:%02x%02x::1" `echo $ipv4 | tr "." " "`)
            echo -e "${YELLOW}IPv6to4 Address: ${GREEN}$ipv6_address ${YELLOW}was created but not configured yet for routing.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            return
            ;;
    esac
    echo ""
    echo -e "${YELLOW} مشابه با اسم اینترفیس های موجود نباشد ${NC}"
    echo -ne "${YELLOW}Enter your desire interface (e.g. tun6to4) ${NC}   "
    read interface

    echo ""
    echo -ne "${MAGENTA}Do you want me to configure for routing? [Y/N]${NC}   "
    read answer

    case $answer in
        [Yy])
            /sbin/modprobe sit
            /sbin/ip tunnel add $interface mode sit ttl 255 remote any local "$ipv4"
            /sbin/ip -6 link set dev $interface mtu 1480
            /sbin/ip link set dev $interface up
            /sbin/ip -6 addr add "$ipv6_address/16" dev $interface
            /sbin/ip -6 route add 2000::/3 via ::192.88.99.1 dev $interface metric 1
            sleep 1
            systemctl restart systemd-networkd
            sleep 1
            echo -e "    ${GREEN} [$ipv6_address] was added and routed successfully, please${RED} reboot ${GREEN}then check the route status${NC}"
            ;;
        [Nn])
            echo -e "${YELLOW}IPv6to4 Address: ${GREEN}$ipv6_address ${YELLOW}was created but not configured yet for routing.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            return
            ;;
    esac
}

uninstall_6to4_ipv6() {
    clear
    systemctl restart systemd-networkd
    sleep 1
    echo ""
    echo -e "     ${MAGENTA}List of 6to4 IPv6 addresses:${NC}"
    
    ipv6_list=$(ip -6 addr show dev tun6to4 | grep -oP "(?<=inet6 )[0-9a-f:]+")
    
    if [ -z "$ipv6_list" ]; then
        echo "No 6to4 IPv6 addresses found on the tun6to4 interface."
        return
    fi
    
    ipv6_array=($ipv6_list)
    
    for ((i = 0; i < ${#ipv6_array[@]}; i++)); do
        echo "[$i]: ${ipv6_array[$i]}"
    done
    
    echo ""
    echo -ne "Enter the number of the IPv6 address to uninstall: "
    read choice

    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a valid number."
        return
    fi
    
    if ((choice < 0 || choice >= ${#ipv6_array[@]})); then
        echo "Invalid number. Please enter a valid number within the range."
        return
    fi
    
    selected_ipv6="${ipv6_array[$choice]}"
    
    /sbin/ip -6 addr del "$selected_ipv6" dev tun6to4
    echo ""
    echo -e " ${YELLOW}IPv6 address $selected_ipv6 has been deleted please${RED} reboot ${YELLOW}to take action."
}

list_6to4_ipv6() {
    clear
    systemctl restart systemd-networkd
    sleep 1
    echo ""
    echo -e "     ${MAGENTA}List of 6to4 IPv6 addresses:${NC}"

    ipv6_list=$(ip -6 addr show dev tun6to4 | grep -oP "(?<=inet6 )[0-9a-f:]+")
    
    if [ -z "$ipv6_list" ]; then
        echo "No 6to4 IPv6 addresses found on the tun6to4 interface."
        return
    fi
    
    ipv6_array=($ipv6_list)
    
    for ((i = 0; i < ${#ipv6_array[@]}; i++)); do
        echo "[$i]: ${ipv6_array[$i]}"
    done
}

status_6to4_ipv6() {
    clear
    systemctl restart systemd-networkd
    sleep 1
        echo -e "${MAGENTA}List of 6to4 IPv6 addresses:${NC}"
    
    ipv6_list=$(ip -6 addr show dev tun6to4 | grep -oP "(?<=inet6 )[0-9a-f:]+")
    
    if [ -z "$ipv6_list" ]; then
        echo "No 6to4 IPv6 addresses found on the tun6to4 interface."
        return
    fi
    
    ipv6_array=($ipv6_list)
    
    for ipv6_address in "${ipv6_array[@]}"; do
        if ping6 -c 1 "$ipv6_address" &> /dev/null; then
            echo -e "${GREEN}Live${NC}: $ipv6_address"
        else
            echo -e "${RED}Dead${NC}: $ipv6_address"
        fi
    done
}

add_extra_ipv6() {
    clear
    prepration_ipv6
    systemctl restart systemd-networkd
    sleep 1
    main_interface=$(ip route | awk '/default/ {print $5}')
    ipv6_subnets=($(ip -6 addr show dev "$main_interface" | grep -oP "(?<=inet6 )[0-9a-f:]+(?=/[0-9]+)" | grep -v "^fe80"))
    
    if [ ${#ipv6_subnets[@]} -eq 0 ]; then
        echo -e "${RED}No IPv6 subnets found on the $main_interface.${NC}"
        return
    fi
    echo ""
    echo -e "        ${MAGENTA}List of your all available IPv6 subnets:${NC}"

    for ((i=0; i<${#ipv6_subnets[@]}; i++)); do
        echo ""
        echo -e "${CYAN}$((i+1))${NC}) ${ipv6_subnets[i]}"
    done
    echo ""
    echo -ne "${YELLOW}Whats your choice to create IPV6 from: ${NC}"
    read selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        echo ""
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        return
    fi

    if ((selection >= 1 && selection <= ${#ipv6_subnets[@]})); then
        local selected_subnet="${ipv6_subnets[selection-1]}"
        ipv6_prefix="${selected_subnet%::*}"

        last_ipv6=$(ip -6 addr show dev "$main_interface" | grep "$ipv6_prefix" | awk -F'/' '{print $1}' | tail -n 1)
        last_number=${last_ipv6##*::}

        echo ""
        echo ""
        echo -ne "${YELLOW}Enter the quantity of IPv6 addresses to create: ${NC}"
        read quantity

        if [[ ! "$quantity" =~ ^[0-9]+$ ]]; then
            echo ""
            echo -e "${RED}Invalid quantity. Exiting.${NC}"
            return
        fi

        max_quantity=10

        if ((quantity > max_quantity)); then
            echo ""
            echo "${RED}Quantity exceeds the maximum limit of $max_quantity. Exiting.${NC}"
            return
        fi

        for ((i=last_number+1; i<=last_number+quantity; i++)); do
            local ipv6_address="$ipv6_prefix::$i/64"
            if ip -6 addr add "$ipv6_address" dev "$main_interface"; then
            echo ""
                echo -e "${NC}IPv6 Address ${GREEN}$i${NC}: ${GREEN}$ipv6_address${NC} Interface (dev): ${GREEN}$main_interface${NC}"
            else
            echo ""
                echo -e "${RED}Error creating IPv6 address: $ipv6_address${NC}"
            fi
        done

        echo ""
        echo ""
        echo -e "IPv6 Addresses $((last_number+1))-$((last_number+quantity)) have been created successfully."
    else
        echo -e "${RED}Invalid selection. No IPv6 addresses created.${NC}"
    fi
}

delete_extra_ipv6() {
    clear
    sudo systemctl restart systemd-networkd
    sleep 1
    main_interface=$(ip route | awk '/default/ {print $5}')
    local ipv6_addresses=($(ip -6 addr show dev "$main_interface" | grep -oP "(?<=inet6 )[0-9a-f:]+(?=/[0-9]+)" | grep -v "^fe80"))
    
    if [ ${#ipv6_addresses[@]} -eq 0 ]; then
        echo -e "${RED}No IPv6 addresses found on the $interface.${NC}"
        return
    fi

    echo -e "${MAGENTA}List of IPv6 addresses:${NC}"

    for ((i=0; i<${#ipv6_addresses[@]}; i++)); do
        echo -e "${CYAN}$((i+1))${NC}) ${ipv6_addresses[i]}"
    done

    echo -ne "${YELLOW}Enter the number to delete: ${NC}"
    read selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        echo ""
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        return
    fi

    if ((selection >= 1 && selection <= ${#ipv6_addresses[@]})); then
        local ipv6_address="${ipv6_addresses[selection-1]}"
        if ip -6 addr del "$ipv6_address" dev "$interface"; then
            sudo systemctl restart systemd-networkd
            sleep 1
            echo -e "${NC}Deleted IPv6 address: ${GREEN}$ipv6_address${RED}"
        else
            echo -e "${RED}Error deleting IPv6 address: $ipv6_address${NC}"
        fi
    else
        echo -e "${RED}Invalid selection. No IPv6 address deleted.${NC}"
    fi
}

list_extra_ipv6() {
    clear
    sudo systemctl restart systemd-networkd
    sleep 1
    main_interface=$(ip route | awk '/default/ {print $5}')
    echo -e "${MAGENTA}List of all IPv6 addresses:${NC}"
    ipv6_list=$(ip -6 addr show dev "$main_interface" | grep -oP "(?<=inet6 )[0-9a-f:]+(?=/[0-9]+)" | grep -v "^fe80")
    
    if [ -z "$ipv6_list" ]; then
        echo "No IPv6 addresses found on the $main_interface interface."
        return
    fi
    
    ipv6_array=($ipv6_list)

    for ((i = 0; i < ${#ipv6_array[@]}; i++)); do
        echo -e "${CYAN}$((i+1))${NC}) ${ipv6_array[$i]}"
    done
}

status_extra_ipv6() {
    clear
    sudo systemctl restart systemd-networkd
    sleep 1
main_interface=$(ip route | awk '/default/ {print $5}')
ipv6_list=$(ip -6 addr show dev "$main_interface" | grep -oP "(?<=inet6 )[0-9a-f:]+(?=/[0-9]+)" | grep -v "^fe80")
    
    if [ -z "$ipv6_list" ]; then
        echo "No IPv6 addresses found on the $main_interface interface."
        return
    fi

    ipv6_array=($ipv6_list)
    
    for ipv6_address in "${ipv6_array[@]}"; do
        if ping6 -c 1 "$ipv6_address" &> /dev/null; then
            echo -e "${GREEN}Live${NC}: $ipv6_address"
        else
            echo -e "${RED}Dead${NC}: $ipv6_address"
        fi
    done
}

while true; do
    clear
    # Calculate the padding for adjusting the title position
    title_text="softether vpn server Installation and Configuration"
    tg_title=""
    yt_title="youtube.com/@smartsina"
    clear
    echo -e "                 ${MAGENTA}${title_text}${NC}"
    echo -e "${YELLOW}______________________________________________________${NC}"
    logo
    echo -e ""
    echo -e "${BLUE}$tg_title ${NC}"
    echo -e "${BLUE}$yt_title  ${NC}"
    echo -e "${YELLOW}______________________________________________________${NC}"
    echo ""
    menu_status
    echo ""
    echo -e "${CYAN} P${NC}) ${RED}=> ${YELLOW}change root password${NC}"
    echo -e "${CYAN} 1${NC}) ${RED}=> ${YELLOW}Install softether vpn server${NC}"
    echo -e "${CYAN} 2${NC}) ${RED}=> ${YELLOW}Add/Modify admin password${NC}"
    echo -e "${CYAN} 3${NC}) ${RED}=> ${YELLOW}Certificate for VPN server${NC}"
    echo -e "${CYAN} 4${NC}) ${RED}=> ${YELLOW}Firewall${NC}"
    echo -e "${CYAN} 5${NC}) ${RED}>>>> ${YELLOW}Uninstall Softether${RED}<<<<${NC}"
    echo -e "${CYAN} S${NC}) ${RED}>>>> ${YELLOW}Softether status${RED}<<<<${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
    echo ""
    echo -e "${CYAN} 6${NC}) ${RED}=> ${YELLOW}add 1month expierationdate${NC}"
    echo -e "${CYAN} 7${NC}) ${RED}=> ${YELLOW}delete user${NC}"
    echo -e "${CYAN} 8${NC}) ${RED}=> ${YELLOW}see expieration time of users${NC}"
    echo -e "${CYAN} 9${NC}) ${RED}=> ${YELLOW}add user ${NC}"
    
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
    echo ""
    echo -e "${CYAN} H${NC}) ${RED}>>>> ${YELLOW}Help ${RED}<<<<${NC}"
    echo -e "${CYAN} 0${NC}) ${RED}>>>> ${YELLOW}Exit ${RED}<<<<${NC}"
    echo -e "${CYAN} h${NC}) ${RED}=> ${YELLOW}6to4 IPV6 Menu${NC}"
    echo -e "${CYAN} j${NC}) ${RED}=> ${YELLOW}Extra native IPV6 Menu${NC}"
    echo ""
    
    echo -ne "${GREEN}Select an option ${RED}[1-4]: ${NC}"
    read choice

    case $choice in
        1)
            install
            config
            ;;
        2)
            password
            ;;
        3)
            certificate
            ;;
        4)
            firewall
            ;;
        9)
            adduser
            ;;
        8)
            see-expieration-date
            ;;
        6)
            add-expieration-date 
            
            ;;

        7)
            delete_user
            
            ;;
        
        5)
            uninstall
            ;;
       [gG])
        clear
            title_text="6to4 IPV6 Menu"
            
            yt_title="youtube.com/@smartsina"

            clear
            echo ""
            echo -e "${YELLOW}______________________________________________________${NC}"
            echo -e "                 ${MAGENTA}${title_text}${NC}"
            echo -e ""
            echo -e "${BLUE}$tg_title ${NC}"
            echo -e "${BLUE}$yt_title  ${NC}"
            echo -e "${YELLOW}______________________________________________________${NC}"
            echo ""
            echo -e "${CYAN} 1${NC}) ${RED}=> ${YELLOW}Creating 6to4 IPV6${NC}"
            echo -e "${CYAN} 2${NC}) ${RED}=> ${YELLOW}Deleting 6to4 IPV6${NC}"
            echo -e "${CYAN} 3${NC}) ${RED}=> ${YELLOW}List of 6to4 IPV6${NC}"
            echo -e "${CYAN} 4${NC}) ${RED}=> ${YELLOW}Status of 6to4 IPV6${NC}"
            echo ""
            echo -ne "${GREEN}Select an option ${RED}[1-4]: ${NC}"
            read choice

            case $choice in
                1)
                6to4_ipv6
                    ;;
                2)
                uninstall_6to4_ipv6
                    ;;
                3)
                list_6to4_ipv6
                    ;;
                4)
                status_6to4_ipv6
                    ;;
                *)
                echo "Invalid choice. Please enter a valid option."
                ;;                   
                esac
        ;;
        [jJ])
        clear
            title_text="Extra IPV6 Menu"
            tg_title=""
            yt_title="youtube.com/@smartsina"

            clear
            echo ""
            echo -e "${YELLOW}______________________________________________________${NC}"
            echo -e "                 ${MAGENTA}${title_text}${NC}"
            echo -e ""
            echo -e "${BLUE}$tg_title ${NC}"
            echo -e "${BLUE}$yt_title  ${NC}"
            echo -e "${YELLOW}______________________________________________________${NC}"
            echo ""
            echo -e "${CYAN} 1${NC}) ${RED}=> ${YELLOW}Creating Extra IPV6${NC}"
            echo -e "${CYAN} 2${NC}) ${RED}=> ${YELLOW}Deleting Extra IPV6${NC}"
            echo -e "${CYAN} 3${NC}) ${RED}=> ${YELLOW}List of all IPV6${NC}"
            echo -e "${CYAN} 4${NC}) ${RED}=> ${YELLOW}Status of all IPV6${NC}"
            echo ""
            echo -ne "${GREEN}Select an option ${RED}[1-4]: ${NC}"
            read choice

            case $choice in
                1)
                add_extra_ipv6
                    ;;
                2)
                delete_extra_ipv6
                    ;;
                3)
                list_extra_ipv6
                    ;;
                4)
                status_extra_ipv6
                    ;;
                *)
                echo "Invalid choice. Please enter a valid option."
                ;;                   
                esac
        ;;
        [hH])
            help root_password
            ;;
        [pP])
            root_password
            ;;
        [sS])
            status
            ;;
        [lL])
            vpn_logs
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            ;;
    esac

    echo -e "\n ${RED}Press Enter to continue... ${NC}"
    read
done
