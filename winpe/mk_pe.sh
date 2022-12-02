#!/bin/bash
#[ $UID -ne 0 ] && { 
#    echo "Fehler: Das Script benötigt root-Rechte."
#    echo "Aufruf mit mit sudo -E $0"
#    exit 1
#}
#####################
### Konfiguration ###
#####################
WINISO=Win11_22H2_German_x64v1.iso
# Für einen USB-Stick ist kein ISO erforderlich
# In diesem Fall: MAKEISO=no
MAKEISO=yes
##########################
### Konfiguration Ende ###
##########################

# Voraussetzungen prüfen

if [ "$MAKEISO" == "yes" ]
then
  if [ -z $(which genisoimage) ]
   then
   echo "genisoimage nicht gefunden."
   echo "Bitte installieren mit sudo apt install genisoimage."
   exit 1
  fi
fi

if [ ! -d tmp ]; then
mkdir tmp
fi

if [ ! -d /mnt/windows11 ]; then
sudo mkdir -p /mnt/windows11
fi

if [ ! -d /mnt/windows11/sources ]; then
sudo mount -o loop $WINISO /mnt/windows11
fi

echo "Kopiere Boot-Dateien (EFI)"
if [ -e winpe/sources/boot.wim ]; then
echo "winpe/sources/boot.wim ist vorhanden."
echo "Bitte löschen Sie Datei und Verzeichnis."
exit 1
fi

if [ ! -d winpe/sources ]; then
sudo mkdir -p winpe/sources
fi
sudo cp -a /mnt/windows11/boot* /mnt/windows11/efi winpe/

echo "Erstelle boot.wim"
sudo mkwinpeimg --windows-dir=/mnt/windows11 --overlay=pe_files --tmp-dir=tmp --only-wim winpe/sources/boot.wim

if [ "$MAKEISO" == "yes" ]
  then
  echo "Erstelle winpe.iso"
    genisoimage -b "boot/etfsboot.com" -allow-limited-size --no-emul-boot --eltorito-alt-boot -b "efi/microsoft/boot/efisys.bin" --no-emul-boot --udf -iso-level 3 --hide "*" -V "WinPE" -o "winpe.iso" winpe
  fi

if [ -d /mnt/windows11/sources ]; then
sudo umount /mnt/windows11
fi
sudo bash -c "chown -R \"\$SUDO_UID:\$SUDO_GID\" winpe"
sudo chmod -R 755 winpe

