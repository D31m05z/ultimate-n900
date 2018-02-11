#!/bin/sh
#
#///////-iRSoftware-////////////////////
#-----Ultimate N900 Rover-------------// 
#-----Copyright-(c)-2011--aFagylaltos-//
#- Boross-Gergely-<sk8Geri@gmail.com>-//
#///////////////////////////////////////
#

## Config

# pack könyvtár
DIR='/home/user/MyDocs/ultimate'

# Jelenlegi verzió
VER=0.2.5

#color
red='\033[1;31;40m'
RED='\033[1;31;40m'
blue='\033[1;34;40m'
BLUE='\033[1;34;40m'
cyan='\033[1;36;40m'
CYAN='\033[1;36;40m'
brown='\033[1;33;40m'
BROWN='\033[1;33;40m'
green='\033[1;32;40m'
white='\033[1;37;40m'
NC='\033[1;37;40m' # No Color
#NC='\033[0m' # No Color

#systems
INTERNET='1'

#packes
pFULES='0'
pPOWER='0'
pSYGIC='0'
pNEMIT='0'
pNEXT='0'
pRESTART='0'
pANDROID='0'
pANDROID_EMMC='0'
pANDROID_SD='0'
pMULTIBOOT='0'
pCSSU='0'
pPOWER_47='0'
pFAIRCRACK='0'
pBACKUPMENU='0'
pBUSYBOX='0'

pREPARTITIONING='0' #1 ha a partició táblás megoldást választom!
pFORMAT_AFTER='0'
pFORMAT2GB='0'
pFORMAT4GB='0'
pFORMAT6GB='0'
pFORMAT8GB='0'
#PACKS

#-----------------ANDROID---------------------------
# Root device
ROOT_DEV='/dev/mmcblk1p2'

# Filesystem options
ROOT_OPTS='rw,noatime,errors=remount-ro'

# Options
FDISK_MMC='TRUE'
FORMAT_VFAT='TRUE'
FORMAT_ROOT='TRUE'
PURGE_KERNELS='TRUE'

# Package storage
PKGDIR='/home/user/MyDocs/.nitdroid'

# Verbose log file
LOG_FILE="${PKGDIR}/installer.log"



## ENV

check_n900(){
	# Maemo has osso-product-info
	test -x /usr/bin/osso-product-info  || return 1

	# HW must be RX-51
	test $( osso-product-info | fgrep 'HARDWARE' | cut -f2 -d'=' ) = "'RX-51'"  || return 1

	return 0
}


check_root(){
	test $(id -u) = '0'
}

get_opts(){
	local opt

	for opt
	do
		case "${opt}" in

		  --no-format)
		  	FORMAT_ROOT=FALSE
			;;

		  --no-purge)
			PURGE_KERNELS=FALSE
			;;

		  --android-dev=*)
		  	ROOT_DEV=${opt##*=}
			FDISK_MMC=FALSE
			FORMAT_VFAT=FALSE
			;;

		  *)
		  	FAIL "Don't understand '${opt}'"
			;;
		esac
	done
}

## Log


PASS(){
echo -e "${green}TELJESÍTVE${NC}"
}

NEXT(){
echo -e "${green}"
read -p "Nyomd meg az enter-t a továbblépéshez!" msg
echo -e "${NC}"
}

OK(){
echo -e $green"OK\n"$NC
#sleep 1
}


unmount_ext_mmc(){
	cat /proc/mounts | while read dev dir rest
	do
		case $dev in
		    /dev/mmcblk1*)
			MSG "Unmounting $dev"
			  safe sudo umount $dev
			  sync
			END
			;;
		esac
	done
}

INIT(){
	set -e

	trap ERROR SIGINT
	trap ERROR SIGHUP
	trap ERROR SIGQUIT

	test -d ${PKGDIR} || sudo mkdir -p -m 0755 ${PKGDIR}

	exec 5>$LOG_FILE

	echo -e "\n*** NITDroid installer ${VER} on $(date)\n" >&5

	safe sudo uname -a
	safe sudo sfdisk -l
	safe sudo df -h

#echo -e $RED"HIBA MEGELŐZÉS!"
#echo -e $RED"CSAK 8GB-os kártyával megy egyenlőre!"
#echo -e $RED"ELŐFORMÁZÁS!!!!"
#sleep 2
#echo -e $RED"unmount"
#	sudo umount /dev/mmcblk1p1
#unmount_ext_mmc
#echo -e $RED"sfdisk 8GB beállításokkal!"
#sleep 20
#	sudo sfdisk -uM /dev/mmcblk1 << EOF
#,6100,C
#,,L
#,,
#,,
#EOF
#echo -e $RED"unmount"
#	sudo umount /dev/mmcblk1p1
#unmount_ext_mmc
#echo -e $RED"formatting"
#	sudo mkdosfs /dev/mmcblk1p1
#	sudo mke2fs -L NITDroid -j -m0 /dev/mmcblk1p2
#echo -e $RED"formatting finish... only 8GB yet!!!"
}

ERROR(){
	echo "*** ERROR - CLEANING UP THE CRAP" >&5

	quiet sudo umount /and

	quiet resume_process ke-recv

	exit 1
}

FAIL(){
	echo "!!!" "$@" >&5
	echo "FAILURE. Bailing out." >&2
	ERROR
}

MSG(){
	echo "***" "$@" >&5
	echo -ne "$@" "..." >&2
}

END(){
	echo "*** DONE" >&5
	echo "done" >&2
}

LOG(){
	echo "===" "$@" >&5
	echo -e "$@"  >&2
}

RUN(){
	eval "$@" >&5 2>&5
}

safe(){
	echo "--- RUN [$@]" >&5
	RUN "$@" || FAIL "ERROR:$?" "$@"
	echo "--- END [$@]" >&5
}

quiet(){
	eval "$@" >/dev/null 2>/dev/null
}

## PROC

suspend_process(){
	PID=$(pidof $1)
	if [ -f /proc/$PID/status ]
	then
		sudo kill -STOP $PID
	fi
}


resume_process(){
	PID=$(pidof $1)
	if [ -f /proc/$PID/status ]
	then
		sudo kill -CONT $PID
	fi
}


## UNINSTALL

init_fake_and(){
	safe sudo install -d -m 0700 /and
	safe sudo mount -t tmpfs -o rw,nosuid,noatime,size=256k,mode=755 tmpfs /and
	safe sudo install -d /and/system/etc
}

done_fake_and(){
	safe sudo umount /and
}


uninstall_crap(){
	MSG "Uninstalling any incompatible software"
	  safe sudo dpkg --purge bootmenu
	  safe sudo dpkg --purge bootmenu-n900
	  safe sudo dpkg --purge multiboot-extras
	END
	
	## Remove old kernels

	if [ X${PURGE_KERNELS} = XTRUE ]
	then
		init_fake_and

		for list in /var/lib/dpkg/info/nitdroid-kernel-*.list
		do
			if [ -f $list ]
			then
				pkg=${list##*/nitdroid-kernel-}
				ver=${pkg%%.list}

				MSG "Uninstalling kernel $ver"
				  safe sudo dpkg --purge nitdroid-kernel-$ver
				END
        		fi
		done

		for mod in /lib/modules/2.6.28.NIT.*
		do
			if [ -d $mod ]
			then
				ver=${mod##*/}

                		MSG "Removing manual kernel $ver"
				  sudo rm -f /boot/vmlinuz-$ver
				  sudo rm -f /boot/multiboot/vmlinuz-$ver
				  sudo rm -f -r $mod
				END
			fi
        	done

		done_fake_and
	fi
}

create_uninstall_icon(){
sudo cp $DIR/pANDROID/nitdroid-installer.desktop /usr/share/applications/hildon/
sudo touch /usr/share/applications/hildon/nitdroid-installer.desktop
}


## MMC

get_mmc_size(){
	sudo sfdisk -s /dev/mmcblk1
}


get_fat_size(){
	MMC=$(get_mmc_size)

	if [ $MMC -gt 3840000 ] ; then
		FAT=$(expr $MMC - 2000000)
	elif [ $MMC -gt 1920000 ] ; then
		FAT=$(expr $MMC - 1000000)
	elif [ $MMC -gt 960000 ] ; then
		FAT=$(expr $MMC - 500000)
	elif [ $MMC -gt 480000 ] ; then
		FAT=$(expr $MMC - 250000)
	else
		FAIL "Your MMC card (${MMC}kb) is not big enough for NITDroid. Sorry."
	fi

	echo ${FAT}
}


erase_block(){
	quiet sudo dd if=/dev/zero of=$1 bs=1k count=$2
}


try_erase(){
	T=$3

	until erase_block $1 $2
	do
		T=$(expr $T - 1)
		test $T -gt 0 || return 1
		sleep 1
	done
}


fdisk_ext_mmc(){
	if [ X${FDISK_MMC} = XTRUE ]
	then
		MMC=$(get_mmc_size)
		FAT=$(get_fat_size)

		MSG "Creating partitions"

		 safe sudo sfdisk -R /dev/mmcblk1

		 safe sudo sfdisk -uB /dev/mmcblk1 << EOM
0,$FAT,C
,,L
,,
,,
EOM

		  sync
		  safe sudo sfdisk -R /dev/mmcblk1
		  sleep 5
		  sync

		END
	else
		LOG "Using existing partitions"
	fi

	echo
	sudo sfdisk -l /dev/mmcblk1 | grep 'mmcblk1p'
	echo
}


format_ext_mmc(){
	if [ X${FORMAT_VFAT} = XTRUE ]
	then
		MSG "Formatting /dev/mmcblk1p1 (vfat)"
		  if try_erase /dev/mmcblk1p1 30 1k
		  then
			safe sudo mkfs.vfat -n 'sdcard' /dev/mmcblk1p1
			sync
		  fi
		END
	fi

	if [ X${FORMAT_ROOT} = XTRUE ]
	then
		MSG "Formatting ${ROOT_DEV} (ext3)"
		  if try_erase ${ROOT_DEV} 30 1k
		  then
			safe sudo mkfs.ext3 -m0 -L 'NITDroid' ${ROOT_DEV}
			sync
		  fi
		END
	fi
}


mount_root_dev(){
	test -d /and  || safe sudo install -d -m 0700 /and

	MSG "Mounting ${ROOT_DEV}"
	  safe sudo mount ${ROOT_DEV} /and -o ${ROOT_OPTS}
	END
}

extract_files(){
	

if [ -f $DIR/pANDROID/N12_UMay.tar ]; then
	echo -e $green"Már ki van csomagolva!"$NC
	OK
else
	echo -e $CYAN"Még nincs kicsomagolva!"$NC
	sleep 2
	echo -e $CYAN "Kicsomagolás..."$NC
	bzip2 -d $DIR/pANDROID/N12_UMay.tar.bz2
	OK
fi

	cd /and
	echo -e $CYAN "Kicsomagolás..."$NC
	sudo tar xvf $DIR/pANDROID/N12_UMay.tar
	OK
	echo -e $CYAN "Telepítés..."$NC
	sudo dpkg -i $DIR/pANDROID/nitdroid-kernel-2.6.28-07_rc4_armel.deb
	OK
	cd /
	
	
}

#-----------------------------------------------------

ABOUT(){
clear
echo -e "${BROWN}"
echo -e "//////////////////////////////////////////////////////////"
echo -e "//----------- ${red} Ultimate N900 Rover ${BROWN} telepítő -----------//"
echo -e "//-------${brown} aFagylaltos${BROWN}------V${VER}-----------------------//"
echo -e "//--------${brown} Boross Gergely|e-mail:sk8Geri@gmail.com${BROWN}------//"
echo -e "//--------------------------- ${RED} BETA ${BROWN} -------------------//"
echo -e "//////////////////////////////////////////////////////////${NC}"
}

CHECK(){
#///////DEVICE TEST//////
echo -e $BROWN"check: device"$NC
	if ! check_n900
	then
		echo "ERROR: this program is for N900 only!"
		NEXT
		exit 1
	fi
OK
#///////ROOTSH///////////
echo -e $BROWN"check: rootsh ..."$NC
sleep 2
if [ -f /usr/bin/root ]; then
	OK
else
	echo -e $RED"A csomag nem található!"
	echo -e $RED"Tedd fel az alkalmazáskezelővel a 'rootsh' csomagot!"$NC
	NEXT
	exit
fi
#///////SUDSER///////////
echo -e $BROWN"check: sudser ..."$NC
sleep 2
if [ -f /usr/bin/sudser ]; then
	OK
else
	echo -e $RED"A csomag nem található!"
	echo -e $RED"Tedd fel az alkalmazáskezelővel a 'sudser' csomagot!"$NC
	NEXT
	exit
fi
#///////INTERNET/////////
while [ "$INTERNET" = "1" ]
do
echo -e $BROWN"check: INTERNET"$NC
IS=`echo "ping -c 4 google.com | grep -c '64 bytes'" | root`
if (test "$IS" -lt "3" ) then
	eval INTERNET="1";
	echo -e $RED"\nA telepítő internetkapcsolatot igényel! Kapcsolódj fel a netre és nyomj egy entert!"$NC
	NEXT
else
	eval INTERNET="0";
	OK
fi
done

#/////////////////////////


}

ANDROID_SD(){

echo -e $CYAN"INIT..."$NC
sleep 1
INIT
OK

echo -e $CYAN"GET..."$NC
sleep 1
get_opts "$@"
OK

echo -e $CYAN"PROCESS..."$NC
sleep 1
suspend_process ke-recv
OK

echo -e $CYAN"UNMOUNT..."$NC
sleep 1
unmount_ext_mmc
OK

echo -e $CYAN"UNINSTALL..."$NC
sleep 1
uninstall_crap
OK

echo -e $CYAN"UNMOUNT"$NC
sleep 1
unmount_ext_mmc
OK

echo -e $CYAN"FORMAT..."$NC
sleep 1
format_ext_mmc
OK

echo -e $CYAN"MOUNT..."$NC
sleep 1
mount_root_dev
OK

echo -e $CYAN"Kicsomagolás..."$NC
sleep 1
extract_files
OK

echo -e $CYAN"UNMOUNT..."$NC
sleep 1
unmount_ext_mmc
OK

echo -e $CYAN"PROCESS RESMUTE..."$NC
sleep 1
resume_process ke-recv
OK

echo -e $CYAN"CREATE_UNINSTALL..."$NC
sleep 1
create_uninstall_icon
OK

}

ANDROID_EMMC(){
cd /
sudo mkdir /and
sudo mount /home /and
extract_files
}

LOAD(){
while read LINE
do


if [ "$LINE" = "pREPARTITIONING 1" ]
	then
	echo -e $BLUE"add: pREPARTITIONING"$NC
	sleep 1
	eval pREPARTITIONING="1";
	OK
	fi
	
#if [ "$LINE" = "pREPARTITIONING 0" ]
#		then
#		echo -e $BLUE"remove: pREPARTITIONING"$NC
#		eval pREPARTITIONING="0";
#		OK
#		fi	
		
if [ "$pREPARTITIONING" = "1" ]
then

	if [ "$LINE" = "pFORMAT_AFTER 1" ]
		then
		echo -e $BLUE"add: pFORMAT_AFTER"$NC
		eval pFORMAT_AFTER="1";
		OK
	fi
	
#	if [ "$LINE" = "pFORMAT_AFTER 0" ]
#		then
#		echo -e $BLUE"remove: pFORMAT_AFTER"$NC
#		eval pFORMAT_AFTER="0";
#		OK
#	fi
	

	if [ "$LINE" = "pFORMAT 2" ]
		then
		echo -e $BLUE"add: pFORMAT2GB"$NC
		eval pFORMAT4GB="1"; #hibás! 4GB-re van állítva!
		OK
	fi	
	if [ "$LINE" = "pFORMAT 4" ]
		then
		echo -e $BLUE"add: pFORMAT4GB"$NC
		eval pFORMAT4GB="1";
		OK
	fi
	if [ "$LINE" = "pFORMAT 6" ]
		then
		echo -e $BLUE"add: pFORMAT6GB"$NC
		eval pFORMAT6GB="1";
		OK
	fi
	if [ "$LINE" = "pFORMAT 8" ]
		then
		echo -e $BLUE"add: pFORMAT8GB"$NC
		eval pFORMAT8GB="1";
		OK
	fi
fi	

if [ "$LINE" = "pMULTIBOOT 1" ]
	then
	echo -e $BLUE"add: pMULTIBOOT"$NC
	eval pMULTIBOOT="1";
	OK
	fi

if [ "$LINE" = "pANDROID 1" ]
	then
	echo -e $BLUE"add: pANDROID"$NC
	eval pANDROID="1";
	OK
	fi

if [ "$pANDROID" = "1" ]
then
      if [ "$LINE" = "pANDROID_EMMC 1" ]
	then
	echo -e $BLUE"add: pANDROID_EMMC"$NC
	eval pANDROID_EMMC="1";
	OK
	fi

	if [ "$LINE" = "pANDROID_SD 1" ]
	then
	echo -e $BLUE"add: pANDROID_SD"$NC
	eval pANDROID_SD="1";
	OK
	fi
fi

if [ "$LINE" = "pMEEGO 1" ]
	then
	echo -e $BLUE"add: pMEEGO"$NC
	echo -e "${RED}HIBA > MeeGo még nem támogatott! ( hamarosan... )${NC}"
	sleep 3
	fi

if [ "$LINE" = "pCSSU 1" ]
	then
	echo -e $BLUE"add: pCSSU"$NC
	eval pCSSU="1";
	OK
	fi

if [ "$LINE" = "pPOWER47 1" ]
	then
	echo -e $BLUE"add: pPOWER_47"$NC
	eval pPOWER_47="1";
	OK
	fi


if [ "$LINE" = "pFAIRCRACK 1" ]
	then
	echo -e $BLUE"add: pFAIRCRACK"$NC
	eval pFAIRCRACK="1";
	OK
	fi

if [ "$LINE" = "pNEOPWN 1" ]
	then
	echo -e $BLUE"add: pNEOPWN"$NC
	echo -e "${RED}HIBA > neopwn még nem támogatott!${NC}"
	sleep 3
	fi

if [ "$LINE" = "pBACKUPMENU 1" ]
	then
	echo -e $BLUE"add: pBACKUPMENU"$NC
	eval pBACKUPMENU="1";
	OK
	fi

if [ "$LINE" = "pSYGIC 1" ]
	then
	echo -e $BLUE"add: pSYGIC"$NC
	eval pSYGIC="1";
	OK
	fi

if [ "$LINE" = "pBUSYBOX 1" ]
	then
	echo -e $BLUE"add: pBUSYBOX"$NC
#	eval pBUSYBOX="0";
	echo -e "${RED}HIBA > busybox még nem támogatott!${NC}"
	sleep 3
	fi

if [ "$LINE" = "pFULES 1" ]
	then
	echo -e $BLUE"add: pFULES"$NC
	eval pFULES="1";
	fi

if [ "$pFULES" = "1" ]
then

if [ "$LINE" = "pNEMIT 1" ]
	then
	echo -e $BLUE"add: pNEMIT"$NC
	eval pNEMIT="1";
	PACKS="$PACKS headphoned"
	OK
	fi

if [ "$LINE" = "pNEXT 1" ]
	then
	echo -e $BLUE"add: pNEXT"$NC
	eval pNEXT="1";
	PACKS="$PACKS headset-control headset-button-enabler"
	OK
	fi

fi

if [ "$LINE" = "pRESTART 1" ]
	then
	echo -e $BLUE"add: pRESTART"$NC
	eval pRESTART="1";
	OK
	fi


#-------minPACKs----------------------------------




if [ "$LINE" = "////// mini-PACKs---------" ]
then
	echo -e "${green}mini PACK-ek beolvasása...${NC}"
	sleep 2
fi


if [ "$LINE" = "pBLESS 1" ]
then
	echo -e $BLUE"add: pBLESS"$NC
	#PACKS="$PACKS blessn900"
	#OK
	echo -e "${RED}HIBA > blessn900 még nem támogatott!${NC}"
	sleep 3
fi

if [ "$LINE" = "pCUTE 1" ]
then
	echo -e $BLUE"add: pCUTE"$NC
	PACKS="$PACKS qmltube qmltube-widget"
	OK
fi

if [ "$LINE" = "pMEDIA 1" ]
then
	echo -e $BLUE"add: pMEDIA"$NC
	PACKS="$PACKS mediabox"
	OK
fi

if [ "$LINE" = "pRECORDER 1" ]
then
	echo -e $BLUE"add: pRECORDER"$NC
	PACKS="$PACKS recorder"
	OK
fi

if [ "$LINE" = "pMIRROR 1" ]
then
	echo -e $BLUE"add: pMIRROR"$NC
	PACKS="$PACKS mirror"
	OK
fi

if [ "$LINE" = "pOFFICE 1" ]
then
	echo -e $BLUE"add: pOFFICE"$NC
	PACKS="$PACKS freoffice"
	OK
fi

if [ "$LINE" = "pOPERA 1" ]
then
	echo -e $BLUE"add: pOPERA"$NC
	PACKS="$PACKS opera-mobile"
	OK
fi

if [ "$LINE" = "pVNCVIEWER 1" ]
then
	echo -e $BLUE"add: pVNCVIEWER"$NC
	PACKS="$PACKS vncviewer"
	OK
fi

if [ "$LINE" = "pWIRE 1" ]
then
	echo -e $BLUE"add: pWIRE"$NC
	PACKS="$PACKS wireshark"
	OK
fi

if [ "$LINE" = "pFLASH 1" ]
then
	echo -e $BLUE"add: pFLASH"$NC
	PACKS="$PACKS flashlight-applet flashlight-extra-gtk"
	OK
fi

if [ "$LINE" = "pHEALTH 1" ]
then
	echo -e $BLUE"add: pHEALTH"$NC
	PACKS="$PACKS healthcheck"
	OK
fi

if [ "$LINE" = "pMC 1" ]
then
	echo -e $BLUE"add: pMC"$NC
	PACKS="$PACKS mc"
	OK
fi

if [ "$LINE" = "pMSTARDICT 1" ]
then
	echo -e $BLUE"add: pMSTARDICT"$NC
	PACKS="$PACKS mstardict"
	OK
fi

if [ "$LINE" = "pTWEAKFLASH 1" ]
then
	echo -e $BLUE"add: pTWEAKFLASH"$NC
	PACKS="$PACKS tweakflashver"
	OK
fi

if [ "$LINE" = "pHOSTHUI 1" ]
then
	echo -e $BLUE"add: pHOSTHUI"$NC
	PACKS="$PACKS hostmode-gui bt-hid-scripts"
	OK
fi

if [ "$LINE" = "pATI 1" ]
then
	echo -e $BLUE"add: pATI"$NC
	PACKS="$PACKS ati85"
	OK
fi

if [ "$LINE" = "pWOL 1" ]
then
	echo -e $BLUE"add: pWOL"$NC
	PACKS="$PACKS qtwol"
	OK
fi

if [ "$LINE" = "pPAINT 1" ]
then
	echo -e $BLUE"add: pPAINT"$NC
	PACKS="$PACKS mypaint"
	OK
fi

if [ "$LINE" = "pRAW 1" ]
then
	echo -e $BLUE"add: pRAW"$NC
	PACKS="$PACKS mrawviewer"
	OK
fi

if [ "$LINE" = "pTHEME 1" ]
then
	echo -e $BLUE"add: pTHEME"$NC
	PACKS="$PACKS camaro-theme"
	OK
fi

if [ "$LINE" = "pTINYC 1" ]
then
	echo -e $BLUE"add: pTINYC"$NC
	PACKS="$PACKS tcc"
	OK
fi

if [ "$LINE" = "pCATEGORISE 1" ]
then
	echo -e $BLUE"add: pCATEGORISE"$NC
	PACKS="$PACKS catorisegui"
	OK
fi

if [ "$LINE" = "pCONKY 1" ]
then
	echo -e $BLUE"add: pCONKY"$NC
	PACKS="$PACKS conky-n900"
	OK
fi

if [ "$LINE" = "pINSTICTIV 1" ]
then
	echo -e $BLUE"add: pINSTICTIV"$NC
	#PACKS="$PACKS instinctiv"
	#OK
	echo -e "${RED}HIBA > instinctiv még nem támogatott!${NC}"
	sleep 3
fi

if [ "$LINE" = "pCPUFREQ 1" ]
then
	echo -e $BLUE"add: pCPUFREQ"$NC
	PACKS="$PACKS qcpufreq"
	OK
fi

if [ "$LINE" = "pCLIPMAN 1" ]
then
	echo -e $BLUE"add: pCLIPMAN"$NC
	PACKS="$PACKS clipman"
	OK
fi

if [ "$LINE" = "pX11VNC 1" ]
then
	echo -e $BLUE"add: pX11VNC"$NC
	PACKS="$PACKS x11vnc"
	OK
fi

if [ "$LINE" = "pSUBTITLES 1" ]
then
	echo -e $BLUE"add: pSUBTITLES"$NC
	PACKS="$PACKS mafw-gst-subtitles-applet"
	OK
fi

if [ "$LINE" = "pREACTION 1" ]
then
	echo -e $BLUE"add: pREACTION"$NC
	PACKS="$PACKS reactionfaceoff"
	OK
fi

if [ "$LINE" = "pFAM 1" ]
then
	echo -e $BLUE"add: pFAM"$NC
	PACKS="$PACKS fapman"
	OK
fi

if [ "$LINE" = "pBOOTVIDEO 1" ]
then
	echo -e $BLUE"add: pBOOTVIDEO"$NC
	#PACKS="$PACKS BOOT"
	echo -e "${RED}HIBA > boot videó még nem támogatott!${NC}"
	sleep 3
fi

if [ "$LINE" = "pCONNNOW 1" ]
then
	echo -e $BLUE"add: pCONNNOW"$NC
	PACKS="$PACKS connectnow-home-widget"
	OK
fi

if [ "$LINE" = "pEXTRADECODERS 1" ]
then
	echo -e $BLUE"add: pEXTRADECODERS"$NC
	PACKS="$PACKS decoders-support"
	OK
fi

if [ "$LINE" = "pCUTEEXPLORER 1" ]
then
	echo -e $BLUE"add: pCUTEEXPLORER"$NC
	PACKS="$PACKS cuteexplorer"
	OK
fi

if [ "$LINE" = "pIRRECO 1" ]
then
	echo -e $BLUE"add: pIRRECO"$NC
	PACKS="$PACKS irwi"
	OK
fi

if [ "$LINE" = "pLIVEFOCUS 1" ]
then
	echo -e $BLUE"add: pLIVEFOCUS"$NC
	PACKS="$PACKS lfocus"
	OK
fi

if [ "$LINE" = "pNMAP 1" ]
then
	echo -e $BLUE"add: pNMAP"$NC
	PACKS="$PACKS nmap"
	OK
fi

if [ "$LINE" = "pLEAFPAD 1" ]
then
	echo -e $BLUE"add: pLEAFPAD"$NC
	PACKS="$PACKS leafpad"
	OK
fi

if [ "$LINE" = "pSSH 1" ]
then
	echo -e $BLUE"add: pSSH"$NC
	PACKS="$PACKS openssh openssh-client openssh-server ssh-status"
	OK
fi

if [ "$LINE" = "pPIP 1" ]
then
	echo -e $BLUE"add: pPIP"$NC
	PACKS="$PACKS personal-ip-address"
	OK
fi

if [ "$LINE" = "pWINE 1" ]
then
	echo -e $BLUE"add: pWINE"$NC
	PACKS="$PACKS wine wine-fonts wine-ttf-fonts"
	OK
fi

if [ "$LINE" = "pTVOUT 1" ]
then
	echo -e $BLUE"add: pTVOUT"$NC
	PACKS="$PACKS maemo-tvout-control"
	OK
fi

if [ "$LINE" = "pMADDEVELOPER 1" ]
then
	echo -e $BLUE"add: pMADDEVELOPER"$NC
	PACKS="$PACKS mad-developer"
	OK
fi

if [ "$LINE" = "pOGGSUPPORT 1" ]
then
	echo -e $BLUE"add: pOGGSUPPORT"$NC
	PACKS="$PACKS ogg-support"
	OK
fi

if [ "$LINE" = "pSIMPLEFMTX 1" ]
then
	echo -e $BLUE"add: pSIMPLEFMTX"$NC
	PACKS="$PACKS simple-fmtx-widget"
	OK
fi

if [ "$LINE" = "pMBARCODE 1" ]
then
	echo -e $BLUE"add: pMBARCODE"$NC
	PACKS="$PACKS mbarcode-plugin-qrcode"
	OK
fi




done < /home/user/MyDocs/ultimate/install.cfg
PASS
}
#----------------------------------------------------------------------------

INSTALL(){
#--------------------------
if [ "$pREPARTITIONING" = "1" ]
	then
	echo -e $CYAN"vérehajtás: pREPARTITIONING"$NC
	sleep 2
#	if [ "$pFORMAT_VFAT" = "0" ]
#		then
#		echo -e $CYAN"ideiglenes ultimate mappa létrehozása a home particióra..."$NC
#		sleep 2
#		sudo mkdir /home/ultimate/
#		echo -e $CYAN"ultimate csomag lementése a home particióra."$NC
#		echo -e $CYAN"Ez a folyamat nagyon lassú! Türelem!..."$NC
#		sleep 2
#		sudo cp -a /home/user/MyDocs/ultimate/* /home/ultimate
#		
#		echo -e $CYAN"MyDocs lecsatolása..."$NC
#		sleep 2	
#		sudo umount /home/user/MyDocs
#		
#		echo -e $CYAN"formázás ext3..."$NC
#		sleep 2
#		sudo sfdisk -c /dev/mmcblk0 1 83 # optional (safer): change FAT to ext3 id 
#		sudo mkfs.ext3 /dev/mmcblk0p1 # create ext3 on large partition
#		sudo mount /dev/mmcblk0p1 /mnt # mount new /home
#		echo -e $CYAN"Másolás: Régi home másolása a megnövelt/csökkentett particióra!"$NC
#		echo -e $CYAN"Ez a folyamat nagyon lassú! Türelem!..."$NC
#		sudo cp -a /home/* /mnt # copy contents of /home to large partition
#		sudo umount /mnt # unmount it
#		
#	
#		echo -e $CYAN"particiós tábla kiválasztása!"$NC
#		sleep 3
#		if [ "$pFORMAT2GB" = "1" ]
#		then
#		echo -e $CYAN" 2GB home 27GB MyDocs"$NC
#		sleep 3
#		sudo sfdisk --no-reread /dev/mmcblk0 < /home/ultimate/pTABLE/table_2 # change partition table, swap p1 and p2
#		fi
#		if [ "$pFORMAT4GB" = "1" ]
#		then
#		echo -e $CYAN" 4GB home 25GB MyDocs"$NC
#		sleep 3
#		sudo sfdisk --no-reread /dev/mmcblk0 < /home/ultimate/pTABLE/table_4 # change partition table, swap p1 and p2
#		fi
#		if [ "$pFORMAT6GB" = "1" ]
#		then
#		echo -e $CYAN" 6GB home 23GB MyDocs"$NC
#		sleep 3
#		sudo sfdisk --no-reread /dev/mmcblk0 < /home/ultimate/pTABLE/table_6 # change partition table, swap p1 and p2
#		fi
#		if [ "$pFORMAT8GB" = "1" ]
#		then
#		echo -e $CYAN" 8GB home 21GB MyDocs"$NC
#		sleep 3
#		sudo sfdisk --no-reread /dev/mmcblk0 < /home/ultimate/pTABLE/table_8 # change partition table, swap p1 and p2
#		fi
#		
#		echo -e $CYAN"A telefon újra fog indúlni! Restart után a telepítő befejezi a hátramaradó csomagok telepítését..."$NC
#		NEXT
#		echo -e $CYAN"pFORMAT_VFAT set 1"$NC
#		sleep 2
#		sudo sed -i 's/pFORMAT_VFAT 0/pFORMAT_VFAT 1/' /home/ultimate/install.cfg
#		sleep 1
#		sudo reboot
#		exit  # reboot to re-read new table
#		
 #    else
#		echo -e $CYAN"formázás vfat..."$NC
#		sleep 2
#		sudo mkfs.vfat -F32 /dev/mmcblk0p2  # create VFAT on 2GB partition
#		
#		echo -e $CYAN"fstab és rcS-late módosítás..."$NC
#		sleep 2
#		sudo cp /home/ultimate/pTABLE/fstab2 /etc/
#		sudo cp /home/ultimate/pTABLE/fstab2 /etc/fstab
#		sudo cp /home/ultimate/pTABLE/rcS-late /etc/event.d/
#		
#		echo -e $CYAN"MyDocs csatolása..."$NC
#		sleep 2
#		sudo mount /home/user/MyDocs
#		echo -e $CYAN"ultimate csomag visszamásolása a MyDocs-ba!"$NC
#		sleep 2
#		sudo mkdir /home/user/MyDocs/ultimate
#		sudo cp -a /home/ultimate/* /home/user/MyDocs/ultimate
#		echo -e $CYAN"ultimate csomag törlése a home-ról!"$NC
#		sudo rm -R /home/ultimate	
#			
#		echo -e $CYAN"pREPARTITIONING set 0"$NC
#		sleep 2
#		sudo sed -i 's/pREPARTITIONING 1/pREPARTITIONING 0/' /home/user/MyDocs/ultimate/install.cfg
#		echo -e $CYAN"KONFIGURÁCIÓS FÁJL ÚJRAOLVASÁSA!..."$NC
#		sleep 4
#		LOAD
#		#echo "paraméter" | parted
#		#dbus-send --system --type=method_call --dest=com.nokia.phone.SSC /com/nokia/phone/SSC com.nokia.phone.SSC.set_radio boolean:false
#	fi

# -------------------------parted--------------------
if [ "$pFORMAT_AFTER" = "0" ]
then
   		echo -e $CYAN"Kellékek feltelepítése..."$NC
		sudo apt-get -y install parted
		sleep 2

		echo -e $CYAN"MyDocs lecsatolása..."$NC
		sleep 2
		sudo umount /home/user/MyDocs/
		
		echo -e $CYAN"home méretének beállítása"$NC
		sleep 2
		
		if [ "$pFORMAT2GB" = "1" ]
		then
		echo -e $CYAN" 2GB home 27GB MyDocs"$NC
		sleep 3
		sudo parted /dev/mmcblk0 rm 4
		sudo parted /dev/mmcblk0 resize 1 32.8kB 29GB
		fi
		if [ "$pFORMAT4GB" = "1" ]
		then
		echo -e $CYAN" 4GB home 25GB MyDocs"$NC
		sleep 3
		sudo parted /dev/mmcblk0 rm 4
		sudo parted /dev/mmcblk0 resize 1 32.8kB 25GB
		sudo parted /dev/mmcblk0 mkpart p ext2 25GB 29GB
		fi
		if [ "$pFORMAT6GB" = "1" ]
		then
		echo -e $CYAN" 6GB home 23GB MyDocs"$NC
		sleep 3
		sudo parted /dev/mmcblk0 rm 4
		sudo parted /dev/mmcblk0 resize 1 32.8kB 23GB
		sudo parted /dev/mmcblk0 mkpart p ext2 23GB 29GB
		fi
		if [ "$pFORMAT8GB" = "1" ]
		then
		echo -e $CYAN" 8GB home 21GB MyDocs"$NC
		sleep 3
		sudo parted /dev/mmcblk0 rm 4
		sudo parted /dev/mmcblk0 resize 1 32.8kB 21GB
		sudo parted /dev/mmcblk0 mkpart p ext2 21GB 29GB
		fi
		
		echo -e $CYAN"Az új home formázása ext3-ra..."$NC
		sleep 2
		sudo mke2fs -t ext3 /dev/mmcblk0p4
		echo -e $CYAN"csatolási mappa létrehozása..."$NC
		sleep 2
		sudo mkdir /mnt/newhome
		echo -e $CYAN"MyDocs lecsatolása..."$NC
		sleep 2
		sudo umount /home/user/MyDocs/
		echo -e $CYAN"Új home felcsatolása..."$NC
		sleep 2
		sudo mount -t ext3 /dev/mmcblk0p4 /mnt/newhome
		echo -e $CYAN"Másolás: Régi home másolása a megnövelt/csökkentett particióra!"$NC
		echo -e $CYAN"Ez a folyamat nagyon lassú! Türelem!..."$NC
		sudo cp -a /home/* /mnt/newhome/

		echo -e $CYAN"MyDocs felcsatolása..."$NC
		sleep 2
		sudo mount /home/user/MyDocs
		
		echo -e $CYAN"fstab és rcS-late módosítás..."$NC
		sleep 2
		sudo cp $DIR/pTABLE/fstab2 /etc/
		sudo cp $DIR/pTABLE/rcS-late /etc/event.d/
		
		echo -e $CYAN"A telefon újra fog indúlni! Restart után a telepítő befejezi a hátramaradó csomagok telepítését..."$NC
		NEXT
		echo -e $CYAN"pFORMAT_AFTER set 1"$NC
		sleep 2
		sudo sed -i 's/pFORMAT_AFTER 0/pFORMAT_AFTER 1/' $DIR/install.cfg
		sleep 1
		echo -e $CYAN"Automatizáló script másolása..."$NC
		sleep 1
		sudo cp $DIR/pTABLE/startup-script /etc/event.d/
		sleep 1
		sudo reboot
		
		
		while [ true ]
		do
		echo -e $RED"."$NC
		sleep 1
		done

else
		echo -e $CYAN"pREPARTITIONING művelet már végrehajtva!"$NC
		sleep 2
		echo -e $CYAN"Automatizáló script törlése..."$NC
		sleep 1
		sudo rm /etc/event.d/startup-script
		sleep 1
		echo -e $CYAN"Folytatom a hátramaradt csomagok telepítését..."$NC
		sleep 4
fi

PASS
fi
#--------------------------
if [ "$pMULTIBOOT" = "1" ]
	then
	echo -e $CYAN"telepítés: pMULTIBOOT"$NC
	sleep 2
	cd $DIR/pMULTI/

	sudo dpkg -i i2c-tools.deb liblzo2-2.deb mtd-utils.deb
	sudo dpkg -i multiboot-0.2.11.deb
        sudo dpkg -i multiboot-kernel-maemo_0.3-1_armel.deb
PASS
fi
#--------------------------
if [ "$pANDROID" = "1" ]
	then
	echo -e $CYAN"telepítés: pANDROID"$NC
	sleep 2
	sudo apt-get -y install bzip2 wget nitdroid-installer
	echo -e $green"Android telepítő indítása..."$NC
	sleep 2
      
	if [ "$pANDROID_EMMC" = "1" ]
	then
	ANDROID_EMMC
	else
	ANDROID_SD
	fi
	PASS
fi
#--------------------------
if [ "$pPOWER_47" = "1" ]
	then
	echo -e $CYAN"telepítés: pPOWER_47"$NC
	sleep 2
	sudo apt-get -y install kernel-power-flasher kernel-power-bootimg
	PASS
fi
#--------------------------
if [ "$pFAIRCRACK" = "1" ]
	then
	echo -e $CYAN"telepítés: pFAIRCRACK"$NC
	sleep 2
	cd /home/user/MyDocs/

if [ -f /home/user/MyDocs/FAS/faircrack.desktop ]; then
	echo -e $green"Már létezik a FAS mappa."$NC
	OK
else
	echo -e $CYAN"Mappa létrehozása."$NC
	mkdir FAS
	cd FAS
	OK
	echo -e $CYAN"Kicsomagolás..."$NC
	tar -xzvf $DIR/pFAIRCRACK/faircrack.tar.gz
	OK
	echo -e $CYAN"Kicsomagolás..."$NC
	tar -xzvf $DIR/pFAIRCRACK/hildon.tar.gz
	OK
	echo -e $CYAN"Másolás..."$NC
	sudo cp -f /home/user/MyDocs/FAS/faircrack.desktop /usr/share/applications/hildon
	OK
	echo -e $CYAN"Másolás..."$NC
	sudo cp -f /home/user/MyDocs/FAS/faircrack.png /usr/share/icons/hicolor/48x48/hildon
	OK

	echo -e $CYAN"add: aircrack-ng, wireless-tools, python2.5, qt4"$NC
	PACKS="$PACKS aircrack-ng wireless-tools python2.5-qt4"
	OK
fi
	PASS
fi
#--------------------------
if [ "$pSYGIC" = "1" ]
	then
	echo -e $CYAN"telepítés: pSYGIC"$NC
	sleep 2
	cd $DIR/pSYGIC/

	echo -e $CYAN"Törlöm ha létezik Drive | wlc | Res mappa"$NC

	if [ -f /home/user/MyDocs/Res/eula/english.eula ]; then
	echo -e $RED"Res TÖRLÉS..."$NC
	sudo rm -R /home/user/MyDocs/Res
	fi

	if [ -f /home/user/MyDocs/Drive/Maemo/menu.ini ]; then
	echo -e $RED"Drive TÖRLÉS..."$NC
	sudo rm -R /home/user/MyDocs/Drive
	fi

	if [ -f /home/user/MyDocs/Maps/wcl/wcl.pak ]; then
	echo -e $RED"wcl TÖRLÉS..."$NC
	sudo rm -R /home/user/MyDocs/Maps/wcl
	fi
	

	echo -e $CYAN"Telepítés..."$NC
	sudo dpkg -i mobile-maps_8.1.6_armel.deb 
	
	echo -e $CYAN"Modifikálás..."$NC
	sudo perl modifica.pl
	PASS
fi
#--------------------------
if [ "$pRESTART" = "1" ]
	then
	echo -e $CYAN"telepítés: pRESTART"$NC
	sleep 2
	sudo cp -f $DIR/pRESTART/callui.xml /etc/systemui
	sudo cp -f $DIR/pRESTART/systemui.xml /etc/systemui
	PASS
fi
#--------------------------
echo -e $BLUE"csomagok:$CYAN$PACKS"$NC
echo -e $CYAN"---------------"$NC
sleep 3
sudo apt-get -y install $PACKS
#--------------------------
if [ "$pNEXT" = "1" ]
	then
	echo -e $CYAN"setup: pNEXT"$NC
	sleep 2
	sudo gconftool-2 --set /apps/headset-control/next-mode --type bool true
	PASS
fi
#--------------------------
if [ "$pBACKUPMENU" = "1" ]
	then
	echo -e $CYAN"telepítés: pBACKUPMENU"$NC
	sleep 2

	cd $DIR/pMULTI/	
	sudo dpkg -i backupmenu-multiboot-1.0.deb

	PASS
fi

}
## MAIN
$NC
clear
$NC
ABOUT
sleep 2
echo -e $white "Telefon hálózat tiltása..."$NC
sleep 3
sudo dbus-send --system --type=method_call --dest=com.nokia.phone.SSC /com/nokia/phone/SSC com.nokia.phone.SSC.set_radio boolean:false
OK
CHECK
#echo -e $white "KATALÓGUSOK HOZZÁADÁSA AZ ALKALMAZÁSKEZELŐHÖZ..."$NC
#sleep 3
#sudo cp $DIR/KATALOGUSOK/hildon-application-manager.list /etc/apt/sources.list.d/
#echo -e $CYAN"add: extras-devel"$NC
#OK
#echo -e $CYAN"add: community-testing"$NC
#OK
echo -e $white "KATALÓGUSOK FRISSÍTÉSE..."$NC
sleep 2
sudo apt-get update
echo -e $white "KONFIGURÁCIÓS FÁJL BEOLVASÁSA..."$NC
sleep 3
LOAD
echo -e $white "BETÖLTÖTT ÉRTÉKEKKEL VALÓ TELEPÍTÉS..."$NC
sleep 3
INSTALL
PASS


#--------------------------
if [ "$pCSSU" = "1" ]
	then
	echo -e $CYAN"telepítés: pCSSU"$NC
	NEXT
	echo -e $RED"Fogadjuk el a telepítést! Üssük be ,hogy yes és nyomjunk enter-t!"$NC
	echo -e $RED"A telepítő elérte az utolsó fázist. Miután feltette a Community-SSU-t a készülék újraindúl és a telepítés befejeződik!"$NC
	sleep 4
	sudo apt-get install community-ssu-enabler
	sudo /usr/sbin/install-community-ssu
	PASS
	sleep 1
	sudo reboot
fi

echo -e $white "Telefon hálózat engedélyezése..."$NC
sudo dbus-send --system --type=method_call --dest=com.nokia.phone.SSC /com/nokia/phone/SSC com.nokia.phone.SSC.set_radio boolean:true
OK
echo -e $white "A TELEPÍTÉS BEFEJEZŐDÖTT..."$NC
NEXT

exit 0
## END.



