#!/bin/bash
[ ! -d ISO ] && mkdir ISO
[ ! -d WIM ] && mkdir WIM

if [ -z "$1" ] ; then
echo "Bitte Pfad und Namen der ISO-Datei angeben"
echo "Beispiel: mk_Win11_bypass.sh ~/Download/Win11.iso"
echo "oder im gleichen Verzeichnis: mk_Win11_bypass.sh Win11.iso"
exit 1
fi

7z x -y $1 -oISO
wimmountrw ISO/sources/boot.wim 2 WIM
hivexregedit --merge WIM/Windows/System32/config/SYSTEM --prefix 'HKEY_LOCAL_MACHINE\SYSTEM' bypass.reg
wimunmount WIM --commit
sleep 10

genisoimage -b "boot/etfsboot.com" -allow-limited-size --no-emul-boot --eltorito-alt-boot -b "efi/microsoft/boot/efisys.bin" --no-emul-boot --udf -iso-level 3 --hide "*" -V "Win11" -o "Windows_11_bypass.iso" ISO
