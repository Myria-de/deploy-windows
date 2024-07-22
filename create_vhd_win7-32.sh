#!/bin/bash
# Das Verzeichnis, aus dem das Script aufgerufen wurde
# ist das Arbeitsverzeichnis
WORKDIR=`pwd`
###########################
###### Konfiguration ######
###########################
# Der Name der VHD-Datei.
# Diese darf nicht existieren.
# Wenn Sie das Script mehrfach ausführen,
# entfernen Sie die VHD-Datei in Virtualbox
# über "Datei -> Werkzeuge -> Virtuelle Medien"
# Wählen Sie die VHD-Datei und klicken Sie auf "Freigeben" und
# dann auf "Entfernen".
# Oder Sie geben einen anderen Dateinamen an.
IMAGENAME=image_win7_x86.vhd
# Die Größe der VHD-Datei in MB
# 20000 sind 20 GB
IMAGESIZE=20000
# Der Name der neuen virtuellen Maschine.
# Diese darf nicht existieren.
# Wenn Sie das Script mehrfach ausführen,
# geben Sie einen anderen Namen an oder löschen
# Sie die VM
VMNAME=Win7_x86
# Typ der VM
# VBoxManage list ostypes liefert eine Liste der Typen
# z.B. "Windows10" (32-Bit) "Windows10_64" "Windows11_64" "Windows7_64" "Windows7" (32 Bit)
OSTYPE=Windows7
# EFI-Installation (Standard bei Windows 11)
# UEFI=--efi
# BIOS-Installation (Windows 7)
UEFI=
# Der Image-Index in der Datei install.wim
# ISO-Datei in das Dateisystem einhängen
# und Index mit
# wiminfo install.wim
# ermitteln
IMGIDX="--image-name=3" # Windows 7 Pro
# Virtualbox-Gasterweiterungen automatisch installieren
# PPROC="--postproc=$WORKDIR/deploy-win/postproc/guest-additions/setup.sh"
# oder
PPROC=
# Automatisch Installation durchführen
# UNATT="--unattend=$WORKDIR/deploy-win/unattend_x64.xml"
# oder
UNATT=
# für eine manuelle Installation
#
# Der Ordner, in dem die virtuelle Maschine erstellt wird
VMDIR=$WORKDIR/VMs
# Der Pfad und Name zur ISO-Datei
# für die Windows-Installation
ISOPATH=$WORKDIR/Win7_Pro_SP1_German_x32.iso
# Netwerkadapter konfigurieren
# Bezeichnung des Netzwerkadapters siehe ip a
NICDEVICE=enp0s31f6
NICTYPE=bridged
# oder für NAT
# NICDEVICE=
# NICTYPE=nat
#
# USB 2.0 / Windows 7
USBEHCI=on
# oder
# USB 3.0 / Windows 10/11
#USBXHCI=on

# Das Gerät für qemu-nbd
# /dev/nbd0 bis /dev/nbd7
# Ändern, wenn das Gerät anderweitig belegt ist
NBDDEV=/dev/nbd1

################################
###### Konfiguration Ende ######
################################

IMAGEPATH=$VMDIR/$VMNAME/$IMAGENAME

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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

check_pre() {

# Prüfe Voraussetzungen
# ms-sys ist installiert?
if [ -z $(which ms-sys) ]
then
echo -e "${RED}Fehler: Bitte installieren Sie ms-sys.${NC}"
echo -e "${RED}https://ms-sys.sourceforge.net/${NC}"
exit 1
fi

# Virtualbox ist installiert?
if [ -z $(which VBoxManage) ]
then
echo -e "${RED}Fehler: Bitte installieren Sie zuerst Virtualbox. Abbruch.${NC}"
exit 1
fi

# qemu-nbd ist installiert?
if [ -z $(which  qemu-nbd) ]
then
echo -e "${RED}Fehler: Bitte installieren Sie das Paket qemu-utils. Abbruch.${NC}"
exit 1
fi

# setup_win10.py vorhanden?
if [ ! -e $WORKDIR/deploy-win/setup_win10.py ]
then
echo -e "${RED}Fehler: Bitte kopieren Sie den Ordner $WORKDIR/deploy-win/ in das Arbeitsverzeichnis. Abbruch.${NC}"
exit 1
fi

# wimlib installiert?
if [ -z $(which  wimapply ) ]
then
echo -e "${RED}Fehler: Bitte installieren Sie das Paket wimtools. Abbruch.${NC}"
exit 1
fi

# VM bereits vorhanden?
if [ -d $VMDIR/$VMNAME ]
then
echo -e "${RED}Die VM $VMDIR/$VMNAME existiert bereits."
echo -e "Bitte löschen Sie die VM in Virtualbox"
echo -e "oder passen Sie die Konfiguration an.${NC}"
exit 1
fi

# VHD-Datei bereits vorhanden?
if [ -e $IMAGEPATH ]
then
echo -e "${RED}Die Datei $IMAGEPATH existiert bereits."
echo -e "Bitte entfernen Sie die Datei über Virtualbox.${NC}"
exit 1
fi

$WORKDIR/check_modules.py
check-state
}
##########################################
###      Das Script startet hier       ###
##########################################
# Voraussetzungen prüfen
check_pre

if [ ! -d $VMDIR/$VMNAME ]
then
echo -e "- ${GREEN}Erstelle Verzeichnis $VMDIR/$VMNAME ${NC}"
mkdir -p $VMDIR/$VMNAME
fi

echo -e "- ${GREEN}Erstelle Festplattenimage (vhd)${NC}"
VBoxManage createmedium disk --filename $IMAGEPATH --size $IMAGESIZE --format vhd --variant fixed
check-state "VBoxManage: Fehler $?"

MODULE=nbd
if lsmod | grep "$MODULE" &> /dev/null ; then
  echo -e "- ${GREEN}$MODULE ist bereits geladen.${NC}"
else
  echo -e "- ${RED}$MODULE ist nicht geladen.${NC}"
  echo -e "- ${GREEN}Lade $MODULE${NC}"
  sudo modprobe nbd max_part=8
fi

echo -e "- ${GREEN}Device /dev/nbd0 für $IMAGEPATH erstellen${NC}"
sudo -E qemu-nbd --disconnect $NBDDEV
sudo -E qemu-nbd -c $NBDDEV --format=vpc $IMAGEPATH

check-state "qemu-nbd: Fehler $?"

echo -e "- ${GREEN}Windows in der VHD-Datei installieren${NC}"
sudo -E $WORKDIR/deploy-win/setup_win10.py --disk=$NBDDEV --iso=$ISOPATH $IMGIDX $UEFI $UNATT $PPROC

check-state "setup_win10.py: Fehler $?"

echo -e "- ${GREEN}Device /dev/nbd0 für $IMAGEPATH trennen.${NC}"
sudo -E qemu-nbd --disconnect $NBDDEV

echo -e "- ${GREEN}Virtuelle Maschine mit virtueller Standard-Hardware erstellen.${NC}"
VBoxManage createvm --name "$VMNAME" --ostype "$OSTYPE" --register --basefolder "$VMDIR" --default
check-state "VBoxManage createvm: Fehler $?"

echo -e "- ${GREEN}$IMAGEPATH für die VM konfigurieren.${NC}"
VBoxManage storageattach "$VMNAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$IMAGEPATH"

echo -e "- ${GREEN}Virtuelles DVD-Laufwerk erstellen.${NC}"
VBoxManage storageattach "$VMNAME" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium emptydrive

if [ ! -z "$PPROC" ];then
 echo -e "- ${GREEN}ISO der Gasterweiterungen einbinden.${NC}"
 VBoxManage storageattach "$VMNAME" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium additions
fi

echo -e "- ${GREEN}Netzwerkadapter konfigurieren.${NC}"
if [ "$NICTYPE" == "nat" ]; then
 VBoxManage modifyvm "$VMNAME" --nic1=$NICTYPE
else
 VBoxManage modifyvm "$VMNAME" --nic1=$NICTYPE --bridge-adapter1=$NICDEVICE
fi
echo -e "- ${GREEN}Datenaustausch konfigurieren (Clipboard, DragandDrop.${NC}"
VBoxManage modifyvm "$VMNAME" --clipboard=bidirectional
VBoxManage modifyvm "$VMNAME" --draganddrop=bidirectional

if [ "$UEFI" == "--efi" ]; then
 echo -e "- ${GREEN}EFI aktivieren.${NC}"
 VBoxManage modifyvm "$VMNAME" --firmware efi
else
 echo -e "- ${GREEN}BIOS aktivieren.${NC}"
 VBoxManage modifyvm "$VMNAME" --firmware bios
fi

if [ "$USBEHCI" == "on" ]; then
 echo -e "- ${GREEN}USB 2.0 aktivieren.${NC}"
 VBoxManage modifyvm "$VMNAME" --usbehci on
fi
if [ "$USBXHCI" == "on" ]; then
 echo -e "- ${GREEN}USB 3.0 aktivieren.${NC}"
 VBoxManage modifyvm "$VMNAME" --usbxhci on
fi

echo -e "${GREEN}Zugriffrechte für den Benutzer setzen${NC}"
sudo bash -c "chown -R \"\$SUDO_UID:\$SUDO_GID\" $VMDIR/$VMNAME"
echo -e "${GREEN}Windows-Installation beendet.${NC}"
