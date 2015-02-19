#!/bin/sh

ACTION=`zenity --width=90 --height=300 --list --radiolist --text="Select logout action" --title="Logout" --column "Choice" --column "Action" TRUE Shutdown FALSE Reboot FALSE Logout False LockScreen`

if [ -n "${ACTION}" ];then
  case $ACTION in
  Shutdown)
    zenity --question --text "Are you sure you want to halt?" && systemctl poweroff
    ## or via ConsoleKit
    # dbus-send --system --dest=org.freedesktop.ConsoleKit.Manager \
    # /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop
    ;;
  Reboot)
    zenity --question --text "Are you sure you want to reboot?" && systemctl reboot
    ## Or via ConsoleKit
    # dbus-send --system --dest=org.freedesktop.ConsoleKit.Manager \
    # /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Restart
    ;;
  Logout)
    echo 'awesome.quit()' | awesome-client
    ;;
  LockScreen)
    slock
    # Or gnome-screensaver-command -l
    ;;
  esac
fi

