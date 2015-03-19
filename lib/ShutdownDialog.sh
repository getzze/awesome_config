#!/bin/sh

#ACTION=`zenity --width=90 --height=200 --list --radiolist --text="Select logout action" --title="Logout" --column "Choice" --column "Action" TRUE Shutdown FALSE Reboot FALSE Lock FALSE Suspend FALSE Logout`
ACTION=`zenity --width=100 --height=250 --list --text="Select logout action" --title="Logout"  --column "Actions" Shutdown Reboot Lock Suspend Logout`

if [ -n "${ACTION}" ];then
  case $ACTION in
  Shutdown)
    systemctl poweroff
    #zenity --question --text "Are you sure you want to halt?" && systemctl poweroff
    ;;
  Reboot)
    systemctl reboot
    #zenity --question --text "Are you sure you want to reboot?" && systemctl reboot
    ;;
  Lock)
    #xscreensaver-command -lock
    systemctl lock
    ;;
  Suspend)
    systemctl suspend
    ;;
  Logout)
    echo 'awesome.quit()' | awesome-client
    ;;
  esac
fi
