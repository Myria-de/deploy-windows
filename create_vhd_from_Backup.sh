#!/bin/bash
# 
# VHD-Datei aus einem Windows-Backup (wimcapture) erstellen
#
# Das Verzeichnis, aus dem das Script aufgerufen wurde
# ist das Arbeitsverzeichnis
WORKDIR=`pwd`
###########################
###### Konfiguration ######
###########################
# Der Name der VHD-Datei.
IMAGENAME=image_win11_x64.vhd
# Der Ordner, in dem die virtuelle Maschine liegt
VMDIR=$WORKDIR/VMs
# Der Name der virtuellen Maschine.
VMNAME=Win11_x64
# Das Gerät für qemu-nbd
# /dev/nbd0 bis /dev/nbd7
# Ändern, wenn das Gerät anderweitig belegt ist
NBDDEV=/dev/nbd1
# Die EFI-Partition in der VHD-Datei
EFIPART="/dev/nbd1p2"
# Die NTFS-Partition in der VHD-Datei
NTFSPART="/dev/nbd1p1"
# Name der Backup-Datei (NTFS-Partition)
BACKUPWIM="[Pfad-zur-WIM-Datei]"
# Name der Backup-Datei (EFI-Partition, Optional)
BACKUPEFI="[Pfad-zum-tar.gz-Backup-der-Efi-Partition]"
# Der Backup-Index
# Bei einem inkrementellen Backup mit wimappend
# die höchste Index-Nummer eintragen
IMGIDX="1"
################################
###### Konfiguration Ende ######
################################

IMAGEPATH=$VMDIR/$VMNAME/$IMAGENAME
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

##########################################
###      Das Script startet hier       ###
##########################################
check-state() {
if ! test $? -eq 0
then
	if ! [ -z "$1" ]
	 then
	 echo -e "${RED}Fehler: $1${NC}"
	 fi
	 exit 1
fi
}

if [ ! -e $BACKUPWIM ]
then
echo -e "- ${RED}Fehler: $BACKUPWIM nicht gefunden.${NC}"
exit 1
fi

MODULE=nbd
if lsmod | grep "$MODULE" &> /dev/null ; then
  echo -e "- ${GREEN}$MODULE ist bereits geladen.${NC}"
else
  echo -e "- ${RED}$MODULE ist nicht geladen.${NC}"
  echo -e "- ${GREEN}Lade $MODULE${NC}"
  sudo modprobe nbd max_part=8
fi

echo -e "- ${GREEN}Device $NBDDEV für $IMAGEPATH erstellen${NC}"
sudo -E qemu-nbd --disconnect $NBDDEV
sudo -E qemu-nbd -c $NBDDEV --format=vpc $IMAGEPATH

check-state "qemu-nbd: Fehler $?"

if [ ! -b $NTFSPART ]
then
echo -e "- ${RED}Fehler: $NTFSPART nicht gefunden.${NC}"
exit 1
fi


echo -e "- ${GREEN}Erstelle NTFS-Partition auf $NTFSPART.${NC}"
sudo mkntfs -vv -f -S 63 -H 255 --partition-start 2048 $NTFSPART
echo -e "- ${GREEN}wimapply $BACKUPWIM.${NC}"
sudo wimapply $BACKUPWIM $IMGIDX $NTFSPART

###### Optional #######
##  efi-Bootumgebung ##
# ####################-
#if [ ! -e $BACKUPEFI ]
#then
#echo -e "- ${RED}Fehler: $BACKUPEFI nicht gefunden.${NC}"
#exit 1
#fi

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#MOUNTDIR=`mktemp -d -p "$DIR"`

#sudo mount $EFIPART $MOUNTDIR
#sudo tar xvf $BACKUPEFI -C $MOUNTDIR 
#sudo umount $MOUNTDIR
#sudo rm -rf $MOUNTDIR
#sudo -E qemu-nbd --disconnect $NBDDEV

echo -e "${GREEN}Windows-Installation beendet.${NC}"

