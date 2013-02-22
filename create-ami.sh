#!/bin/sh

DEBUG=0
validation=0
set_env=1
tpd=/remote/tuxstart/AMAZON_EC2/temp
lk=/remote/tuxstart/AMAZON_EC2/license_keys
boot_inst=$tpd/boot_int.$$
errorlog=$tpd/error.$$.log
mkdir $tpd
touch $boot_inst
touch $errorlog

st1=1;st2=1;st3=1;st4=1;st5=1;st6=1;st7=1;st8=1;st9=1
function _sleep {
	if [ "x$DEBUG" = "x1" ]; then
		sleep $*;
	fi
}


function getAMIname {
echo "Enter the name for the new AMI"
read aminame
a1="`ec2-describe-images | cut -f 3`"
                for img in ${a1[@]}
                do
                        bimg="`basename $img`"
                        if [ "x$aminame" = "x$bimg" ]; then
                                echo "#########################"
				echo "Imagename already exists"
                                echo "##########################"
                                echo "Enter other name"
                                getAMIname
                        fi
                done
}

function setEnv {
		clear
		echo "******************** Settings Menu**************************************"
		echo "1)	Modify the existing AWS envoirnment variables and Credentials"
		echo "2)	Preview and Confirm your settings"
		echo "3)	Validate your settings (IMPORTANT)"
		echo "4)	Go back to main menu"
		echo "*************************************************************************"
		echo -n "Enter your choice : "
		read setch
		case $setch in
			1)
				modify	
				;;
			2)
				preview
				;;
			3)
				validate
				;;
			4)
				clear
				break
				;;
			*)
				echo "Invalid Entry"
				echo "Please enter the valid option"
				;;		
				
		esac
}

function validate {
	if [ $set_env -eq 0 ]; then
	validation=1
	echo "Validating ec2-api tools"
		if [ "x`$EC2_HOME/bin/ec2-describe-availability-zones | cut -f 2 | head -1 2>/dev/null`" = "x" ]; then
			echo "########################################"
			echo "Invalid path for EC2_HOME. Please verify and modify the path"
			valAPI=1
			echo "########################################"
		else
			echo "done..."
			valAPI=0
		fi	

	echo "Validating java path"
		java_version=/tmp/java_version.$$
		$JAVA_HOME/bin/java -version &> $java_version
	        if [ "x`cat $java_version | head -1 | awk '/1.6/ {print $3}'`" = "x" ]; then
			echo "########################################"
       			echo "WARNING: the directory [$java_path] does not point to a valid java installation. Please check and modify.";
			rm -rf $java_version
			valJAVA=1
			echo "########################################"
	        else
        	        echo "done..."
			valJAVA=0
			rm -rf $java_version
	        fi
		
	echo "validating the ec2-ami tools"
		if [ "x`$EC2_AMITOOL_HOME/bin/ec2-bundle-image --version | awk '/ec2-bundle-image/ {print $1}' 2>/dev/null`" = "x" ];then
			echo "########################################"
			echo "Invalid path for EC2_AMITOOL_HOME. Please varify and modify the path"
			valAMI=1
			echo "########################################"
		else
			echo "done..."
			valAMI=0
		fi
	
	echo "Validating Private key file"
		if [ -e $EC2_PRIVATE_KEY ];then
			echo "done..."
			valPK=0
		else
			echo "########################################"
			echo "Private key file doesnot exist on the specified path, Modify and enter the correct path"
			valPK=1
			echo "########################################"
		fi
	echo "Validating Certificate key file"
                if [ -e $EC2_CERT ];then
                        echo "done..."
			valCERT=0
                else
			echo "########################################"
                        echo "Certificate key file doesnot exist on the specified path, Modify and enter the correct path"
			valCERT=1
			echo "########################################"
                fi

	echo "Verifying Python path"
		pypath=/tmp/py_path
		$PYPATH -V &> $pypath
		if [ "x`cat $pypath | awk '/2.4/'`" = "x" ];then
			echo "########################################"
			echo "Python 2.4 or higher is required or python path not set properly"
			valPY=1
			rm -rf $pypath
			echo "########################################"
		else
			echo "done..."
			valPY=0
			rm -rf $pypath
		fi

	echo "Validating the bucket"
		if [ "x`$S3PATH/s3cmd ls | grep "s3://$BUCKET_NAME"`" = "x" ]; then
			echo "########################################"
			echo "Specified bucket doesnot exist"
			echo "Modify and enter the existing bucket name"
			echo "########################################"
			valB=1
		else
			echo "done..."
			valB=0
		fi
	echo "Validating ARCH"
	validarch=1
	for ar in i386 x86_64
	do
		if [ $ARCH = $ar ]; then
			validarch=0
			break	
		else
			continue
		fi
	done
	if [ $validarch -eq 0 ];then
		echo "done"
	else
		echo "########################################"
		echo "Invalid architecture"
		echo "Only i386 and x86_64 supported right now"
		echo "########################################"
	fi

	if [ $valAPI -eq 0 ] && [ $valJAVA -eq 0 ] && [ $valAMI -eq 0 ] && [ $valPK -eq 0 ] && [ $valCERT -eq 0 ] && [ $valPY -eq 0 ] && [ $valB -eq 0 ] && [ $validarch -eq 0 ]; then
		validation=0
		set_env=0
		echo "Validation done"
		echo "*****************************"
		echo "Ready to start the automation"
		echo "*******************************"
		echo "Press enter to continue"
		read
	else
		echo "########################################"
		echo "Validation failed"
		echo "Kindly update the failed values and validate again"
		echo "########################################"
		echo "Press enter to continue"
		read
	fi
	else
		echo "Please preview and confirm your settings before you validate"
		echo "Press enter to continue"
                read
	fi	
}

function regionSelect {
		echo "-------------------------------------------"
		echo "Select one the following available regions"
		echo "1)	us-east-1"
		echo "2)	us-west-1"
		echo "3)	eu-west-1"
		echo "4)	ap-southeast-1"
		echo "-------------------------------------------"
		echo -n "Enter YOur choice : "
		read regch
		case $regch in 
			1)
				export EC2_URL=http://ec2.amazonaws.com
				echo "us-east-1 setup..."
				regionsel=0
				;;
			2)
				export EC2_URL=http://ec2.us-west-1.amazonaws.com
				echo "us-west-1 setup..."
				regionsel=0
				;;
			3)	
				export EC2_URL=http://ec2.eu-west-1.amazonaws.com
				echo "eu-west-1 setup..."
				regionsel=0
				;;
			4)
				export EC2_URL=http://ec2.ap-southeast-1.amazonaws.com
				echo "ap-southeast-1 setup..."
				regionsel=0
				;;
			*)
				echo "Invalid entry"
				echo "Please provide valid option"
				echo "Press enter to continue"
		                read
				regionSelect
				;;
		esac
}

function mainoptions {
		echo "*************************   Main Menu  **********************************"
		echo "1)	Set Environment"
		echo "2)	Start AMI Automation"	
		echo "3)	Enable DEBUG Mode"
		echo "4)	Exit"
		echo "*************************************************************************"
		echo -n "Enter your choice : "
}	

function preview {
		
		clear
		echo "*********************************************************"
		echo "Verify the following AWS env variables and Credentials"
		echo "Kindly modify the parameter if incorrect or not defined"
		echo "*********************************************************"
		echo "EC2_URL: " $EC2_URL
		export EC2_URL
		echo ""
		echo "EC2_HOME: " $EC2_HOME
		export EC2_HOME
		echo ""
		echo "EC2_AMITOOL_HOME: " $EC2_AMITOOL_HOME
		export EC2_AMITOOL_HOME
		echo ""
		echo "JAVA_HOME: "$JAVA_HOME
		export JAVA_HOME
		echo ""
		echo "AWS_ACCOUNT_NUMBER: "$AWS_ACCOUNT_NUMBER	
		export AWS_ACCOUNT_NUMBER
		echo ""
		echo "AWS_ACCESS_KEY_ID: "$AWS_ACCESS_KEY_ID
		export AWS_ACCESS_KEY_ID
		echo ""
		echo "AWS_SECRET_ACCESS_KEY: "$AWS_SECRET_ACCESS_KEY
		export AWS_ACCESS_KEY_ID
		echo ""
		echo "EC2_PRIVATE_KEY: "$EC2_PRIVATE_KEY
		export EC2_PRIVATE_KEY
		echo ""
		echo "EC2_CERTIFICATE_KEY: "$EC2_CERTIFICATE_KEY
		export EC2_CERTIFICATE_KEY
		export EC2_CERT=$EC2_CERTIFICATE_KEY
		echo ""
		echo "BUCKET_NAME : "$BUCKET_NAME
		export BUCKET_NAME
		echo ""
		echo "PATH: " $PATH
		export PATH
		echo ""
		echo "ARCH: " $ARCH
		export ARCH
		echo ""
		echo "Python path : $PYPATH"
		export PYPATH
		echo ""
		echo "S3CMD tools path : $S3PATH"
		export S3PATH
		echo ""
		echo "****************************************************"
		
		chk_env
		if [ $set_env -eq 0 ]; then
			echo "Done.."
			echo "ENTER to continue"
			read
		fi

}

function chk_env {
		 if [ -z $EC2_URL ] || [ -z $EC2_HOME ] || [ -z $EC2_AMITOOL_HOME ] || [ -z $JAVA_HOME ] || [ -z $AWS_ACCOUNT_NUMBER ] || [ -z $AWS_ACCESS_KEY_ID ] || [ -z $EC2_PRIVATE_KEY ] || [ -z $EC2_CERTIFICATE_KEY ] || [ -z $BUCKET_NAME ] || [ -z $PATH ] || [ -z $ARCH ] || [ -z $PYPATH ] || [ -z $S3PATH ]; then
			echo "########################################"
                        echo "Some of the parameters are not set; plese modify them before you continue"
                        echo "Press ENTER to continue"
			echo "########################################"
                        read
                else
                        echo "Proceed to step 3 and validate"
			set_env=0
                fi


}
function modify {
	clear
	echo ""
	echo "**************************************************************************************************************************"
	echo "Select the attribute to modify.. Warning !! Do not forget to update the path if modifying EC2_HOME/EC2_AMITOOL_HOME !!"
	echo "1)	EC2_HOME: " 
	echo "2)	EC2_AMITOOL_HOME: " 
	echo "3)	JAVA_HOME: "
	echo "4)	AWS_ACCOUNT_NUMBER: "
	echo "5)	AWS_ACCESS_KEY_ID: "
	echo "6)	AWS_SECRECT_ACCESS_KEY: "
	echo "7)	EC2_PRIVATE_KEY: "
	echo "8)	EC2_CERTIFICATE_KEY: "
	echo "9)	BUCKET_NAME"
	echo "10)	PYTHON_PATH"
	echo "11)	S3CMD_TOOL_PATH"
	echo "12)	ARCH"
	echo "13)	EC2_URL"
	echo "14)	Go Back to previous menu"
	echo "***************************************************************************************************************************"
	echo -n "Enter your choice now: "
	read modchoice
	set_env=1
	case $modchoice in 
	1)	
		echo "Enter the entire path of API tools directory"
		read api_path
		export EC2_HOME=$api_path
		export PATH=$PATH:$EC2_HOME/bin
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read 
		;;		
	2)	echo "Enter the entire path of AMI tools directory"
		read ami_path
		export EC2_AMITOOL_HOME=$ami_path
		export PATH=$PATH:$EC2_AMITOOL_HOME/bin
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;		
	3)	echo "Enter the entire path of java directory"
		read java_path
		export JAVA_HOME=$java_path
		export PATH=$PATH:$JAVA_HOME/bin
		echo "Press ENTER to continue"
		read
		;;
	4)	echo "Enter your AWS account number"
		read AWS_acno
		export AWS_ACCOUNT_NUMBER=$AWS_acno
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;	
	5)	echo "Enter your AWS access key"
		read AWS_accesskey
		export AWS_ACCESS_KEY_ID=$AWS_accesskey
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;		
	6)	echo "Enter your secret access key"                
		read sec_accesskey
		export AWS_SECRECT_ACCESS_KEY=$sec_accesskey
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;		
	7)	echo "Enter your EC2 Private key (enter entire path)"
		read pkid
		export EC2_PRIVATE_KEY=$pkid
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;		
	8)	echo "Enter your EC2 Certificate key (enter entire path)"
		read cert
		export EC2_CERTIFICATE_KEY=$cert
		export EC2_CERT=$cert
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;
	9)	echo "Enter bucket name to upload your image"
		read bcktnm
		export BUCKET_NAME=$bcktnm
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;
	10)     echo "Enter python path"
                read pypath
                export PYTHON_PATH=$pypath
		export PATH=$PATH:$PYTHON_PATH
                echo "updated the variable"
                echo "Press ENTER to continue"
                read
                ;;
	11)     echo "Enter S3CMD tools path"
                read s3path
                export S3PATH=$s3path
		export PATH=$PATH:$S3PATH
                echo "updated the variable"
                echo "Press ENTER to continue"
                read
              	;;
	12)
		echo "Enter image architecture"
		read archi
		export ARCH=$archi
		echo "updated the variable"		
		echo "Press ENTER to continue"
		read
		;;

	13)	regionSelect
		;;

	14)	setEnv	
		;;
	
	*)	echo "Wrong option"
		echo "Please enter the correct option"
		echo "Press ENTER to continue"
		read
		;;
	esac	 
}


function selectiveInstall {
	echo "enter the name of the package you want to install"
	read packname
	yum -c /etc/yum.repos.d/my.repo --installroot=$imgloopmnt install -y $packname 2> $errorlog
chk_err $?
 
}

################################################################################################################
function rhelScratch {
echo "Starting AMI creation from SCRATCH"
echo "**********************************"
        while [ 1 ]
        do
        clear
        echo "Complete ALL steps one by one. (Enter 0 to abort anytime)"
        echo "------------------------------------------------------------------"
        echo "Step 1)   Mount ISO and Create loopback filesystem"
        echo "Step 2)   Update yum configuration file for OS install"
        echo "Step 3)   Update the config files (fstab,ifcfg-eth0,network,sshd_config,hosts,rc.local)"
        echo "Step 4)   Install additional RPMS (provide tar file containing RPMS)(Optional)"
        echo "Step 5)   Run script (modify.sh) to further modify the system (remove rpms, start/stop services, etc) (Optional)"
        echo "Step 6)   Bundle UPload and register image"
        echo "Step 7) Cleanup"
        echo "Step 8) Go back to previous menu"
        echo "0)        Abort"
        echo "------------------------------------------------------------------"
        echo ""
        echo -n "Enter your choice : "
        read stepch

        case $stepch in
        1)
		echo ""
                echo "Enter the location of ISO image (absolute path)"
                read ISOpath
                if [ -e $ISOpath ]
                then

                mkdir /mnt/loopmnt &> /dev/null
		echo "mounting ....."
                export loopmnt=/mnt/loopmnt
        	export imgloopmnt=/mnt/ec2-fs 	
                umount $imgloopmnt/proc &> /dev/null
		umount $imgloopmnt &> /dev/null
        	umount $loopmnt &> /dev/null
		mount -o loop $ISOpath $loopmnt

                export imgdir=$tpd
                echo ""
		echo "Enter the name for the root disk image file (example: xyz.fs )"
                read imgname
                echo ""
                echo "Enter the required size of root disk in GB (enter 1 for 1GB; warning!! 10 GB max)"
                read imgsize
                echo "Creating $imgname image in $imgdir directory"
                _sleep 2
                cd $imgdir
                dd if=/dev/zero of=$imgname bs=1M count=`expr 1000 \* $imgsize` 2> $errorlog
		chk_err $?

                echo "$imgname is created in $imgdir directory"

                echo "creating ext3 file system on $imgname"
                _sleep 2
                /sbin/mke2fs -F -j $imgname 2> $errorlog
		chk_err $?

                _sleep 2
                echo ""

                echo "mounting the image via loopback to a mount point $imgloopmnt"
                _sleep 2
                umount $imgloopmnt/proc &> /dev/null
                umount $imgloopmnt &> /dev/null
                mount -o loop $imgname $imgloopmnt 2> $errorlog
		chk_err $?
		
                else
                        echo "ISO file doesnot exist or worong path"
			break
                fi
				
		echo "creating $imgloopmnt/dev directory"
                _sleep 2
                mkdir $imgloopmnt/dev 2> $errorlog
		chk_err $?


                echo "populating $imgloopmnt/dev with concole"
                _sleep 2
                /sbin/MAKEDEV -d $imgloopmnt/dev -x console 2> $errorlog
		chk_err $?


                echo "populating $imgloopmnt/dev with null"
                _sleep 2
                /sbin/MAKEDEV -d $imgloopmnt/dev -x null 2> $errorlog
		chk_err $?


                echo "populating $imgloopmnt/dev with zero"
                _sleep 2
                /sbin/MAKEDEV -d $imgloopmnt/dev -x zero 2> $errorlog
		chk_err $?


                echo "creating $imgloopmnt/etc directory"
                _sleep 2
                mkdir $imgloopmnt/etc 2> $errorlog
chk_err $?


                echo "creating /proc directory"
                _sleep 2

                mkdir $imgloopmnt/proc 2> $errorlog
chk_err $?


                echo "mounting /proc"
                mount -t proc none $imgloopmnt/proc 2> $errorlog
chk_err $?
		st1=0
                echo "Step 1 Completed ; Press ENTER to continue"
                read
                ;;

        2)      
		if [ $st1 -eq 0 ]; then
		echo "Taking back up of old repos"
                cd /etc/yum.repos.d
                tar -cvzf yum.old.tgz ./*
                rm -rf *.repo

		echo "Updating yum.conf file"
cat << EOL | tee /etc/yum.repos.d/my.repo
[RHEL_5_Workstation_Repository]
name=Red Hat Enterprise Linux
baseurl=file://$loopmnt/Server
enabled=1
[RHEL_5_VT_Repository]
name=Red Hat Enterprise Linux
baseurl=file://$loopmnt/VT
enabled=1
[RHEL_5_Client_Repository]
name=Red Hat Enterprise Linux
baseurl=file://$loopmnt/Cluster
enabled=1
EOL
                echo "Now installing operating system"
                echo "enter one of the option below"
                echo "1>        Group/Base Install"
                echo "2>        Selective Install (selecting packages one by one from yum repository ex: httpd, gcc, mysql, etc )"
                read instoption

                case $instoption in
                1)
                        echo "You have selected group install"
                        echo "installing the base packages by yum"
                        _sleep 2
                        yum -c /etc/yum.repos.d/my.repo --installroot=$imgloopmnt -y groupinstall Base 2> $errorlog
chk_err $?

                        ;;
                2)
                        echo "You have selected selective install"
                        ans=y
                        while [ "$ans" == y ]
                        do
                                selectiveInstall
                                echo "Do you want to install another package (y/n)?"
                                read ans
                        done
                        ;;
                esac
		st2=0
		echo "Restoring old repos"
		tar -xzf yum.old.tgz
		rm -rf yum.old.tgz
                echo "Step 2 Completed ; Press ENTER to continue"
                read
                else
			echo "INFO : Compelte step 1 first " >&2
		fi
		;;

        3)     
		if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] ; then 
		echo "Modifying fstab in $imgloopmnt/etc "
                #echo "----------------------------------------"
                cat << EOL > $imgloopmnt/etc/fstab
/dev/sda1  /         ext3    defaults        1 1
/dev/sdb   /mnt      ext3    defaults        0 0
none       /dev/pts  devpts  gid=5,mode=620  0 0
none       /dev/shm  tmpfs   defaults        0 0
none       /proc     proc    defaults        0 0
none       /sys      sysfs   defaults        0 0
EOL
		_sleep 1


                echo "updating ifcfg-eth0 file in $imgloopmnt/etc/sysconfig/network-scripts "
                cat << EOL > $imgloopmnt/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
TYPE=Ethernet
USERCTL=yes
PEERDNS=yes
IPV6INIT=no
EOL
		_sleep 1
                echo "updating network file in $imgloopmnt/etc/sysconfig "
                cat << EOL > $imgloopmnt/etc/sysconfig/network
HOSTNAME=localhost.localdomain
NETWORKING=yes
EOL
		_sleep 1
                echo "updating rc.local file in $imgloopmnt/etc/ "
                cat << EOL >> $imgloopmnt/etc/rc.local
#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

touch /var/lock/subsys/local
if [ ! -d /root/.ssh ] ; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
fi
# Fetch public key using HTTP
curl -f http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > /tmp/my-key
if [ 0 -eq 0 ] ; then
        cat /tmp/my-key >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
        rm /tmp/my-key
fi
# or fetch public key using the file in the ephemeral store:
if [ -e /mnt/openssh_id.pub ] ; then
        cat /mnt/openssh_id.pub >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
fi
# Update the EC2 AMI creation tools
#echo " + Updating AMI tools"
#rpm -Uvh http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm
#rpm -Uvh http://s3.amazonaws.com/redhat-cloud/RHEL-cloud-tools/hosted-tools.el.noarch.rpm
chmod 1777 /tmp
chmod 1777 /mnt

EOL
		_sleep 1
                echo "updating sshd_config"
                cat <<EOL >> $imgloopmnt/etc/ssh/sshd_config
UseDNS no
PermitRootLogin without-password
GatewayPorts yes
EOL
		_sleep 1
                echo "updating hosts"
                cat <<EOL >> $imgloopmnt/etc/hosts
127.0.0.1 localhost localhost.localdomain
EOL
 		echo "Updating kernel modules"
	               #echo "hosts updated"
		cp -r /remote/tuxstart/AMAZON_EC2/kernels/kernel_rhel/2.6.18-xenU-ec2-v1.4 $imgloopmnt/lib/modules/
		st3=0
                echo "Step 3 Completed ; Press ENTER to continue"
                read
		else
			echo "INFO: complete steps 1,2 first"
		fi
                ;;
	4)
		if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ]; then
                echo "Enter the location of tar file"
                read rpmPath
                mkdir $tpd/extra_rpms 2> $errorlog
chk_err $?

                tar -xzf $rpmPath -C $tpd/extra_rpms 2> $errorlog
chk_err $?

                rpm --root $imgloopmnt -Uvh $tpd/extra_rpms/*.rpm --force --nodeps 2> $errorlog
chk_err $?

                rm -rf $tpd/extra_rpms 2> $errorlog
chk_err $?
                st4=0
                echo "Step 4 Completed ; Press ENTER to continue"
                read
		else
			echo "Complete step 1,2,3 first"
		fi

                ;;

        5)	
		if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] && [ $st4 -eq 0 ] || [ $st4 -eq 1 ]; then
                echo "provide the script (proper location) to further modify the services, rpms, etc..."
                read service_script
		touch $imgloopmnt/tmp/modify.sh
		cat $service_script > $imgloopmnt/tmp/modify.sh
		chmod +x $imgloopmnt/tmp/modify.sh
                /usr/sbin/chroot $imgloopmnt /tmp/modify.sh 2> $errorlog
chk_err $?
		rm -rf $imgloopmnt/tmp/modify.sh
                st5=0
		echo "done"
		echo "Step 5 Completed ; Press ENTER to continue"
                read
		else
			echo "Complete steps 1,2,3 (4 optional) first"
		fi
                ;;



        6)      
                if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] && [ $st4 -eq 0 ] || [$st5 -eq 0 ] || [ $st4 -eq 1 ] || [$st5 -eq 1 ]; then

		echo "Creating the bundle of root disk image"
                echo "rename $imgname to OSname.fs"
                echo ""
		echo "Enter the new name for your image bundle (ex- rhel_5.4_x86_64.fs) Manifest file and AMI will be created by this name"
                read osimgname
                umount $imgloopmnt/proc &> /dev/null
                umount $imgloopmnt &> /dev/null
		cd $imgdir
		mv $imgname $osimgname
                echo "Starting bundling image"
		ec2-bundle-image -i $osimgname -k $EC2_PRIVATE_KEY -c $EC2_CERTIFICATE_KEY -u $AWS_ACCOUNT_NUMBER --arch $ARCH
		if [ $? -ne 0 ]
		then
			echo "Image bundle failed"
			exit
		else
                	echo "Image bundled"
		fi
                

		echo "Starting upload and register"
                ec2-upload-bundle -b $BUCKET_NAME -m /tmp/$osimgname.manifest.xml -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY 2> $errorlog
chk_err $?
			
                echo "Upload done"
		getAMIname

                echo "Now registering with AMI name "$aminame""

		echo "Enter the kernel image ID to register your ami(aki-2a42a043) (Optional; ENTER to skip)"
		read akireg
		echo "Enter the Ramdisk ID to register your ami(aki-2a42a043)(Optional; ENTER to skip)"
                read arireg
		echo "Now registering"

		if [ -z $akireg ] && [ -z $arireg  ];then
			ec2-register -n $aminame -a $ARCH $BUCKET_NAME/$osimgname.manifest.xml 2> $errorlog
			chk_err $?
        	elif [ -n $akireg ] && [ -z $arireg  ];then
        	  	 ec2-register -n $aminame -a $ARCH $BUCKET_NAME/$osimgname.manifest.xml --kernel $akireg 2> $errorlog
                	chk_err $?
	        else
			 ec2-register -n $aminame -a $ARCH $BUCKET_NAME/$osimgname.manifest.xml --kernel $akireg --ramdisk $arireg 2> $errorlog
        	        chk_err $?
	        fi

                echo "image registerd with the above ami ID"
                echo "Step 6 Completed ; Press ENTER to continue"
                read
		else
			echo "Complete steps 1,2,3 (4,5 optional) first"
		fi
                ;;

        7)     echo "Unmount loopback directories and Cleanup files"
                umount $loopmnt &> /dev/null
                rm -rf $tpd
		echo "File system cleaned"
                echo "Step 7 Completed ; Press ENTER to continue"
                read
                ;;
        8)
                break
                ;;
	0)
                umount $loopmnt &> /dev/null
		rm -rf $tpd
		exit
		;;
        *)
                echo "Invalid option,  please provide valid entry"
                echo "press ENTER to try again"
                read
                ;;

        esac
done

}
#################################################################################################################
function centosScratch {
echo "Starting AMI creation from SCRATCH"
echo "**********************************"
        while [ 1 ]
        do
        clear
        echo "Complete ALL steps one by one. (Enter 0 to abort anytime)"
        echo "------------------------------------------------------------------"
        echo "Step 1)	Mount ISO, Create loopback filesystem and necessary devices"
        echo "Step 2)	Update yum configuration and Install OS"
        echo "Step 3)	Update the config files (fstab,ifcfg-eth0,network,sshd_config,hosts,rc.local)"
        echo "Step 4)	Install additional RPMS (provide tar file containing RPMS (Optional))"
        echo "Step 5)	Run script(modify.sh) to further modify the system (remove rpms, start/stop services, etc) (Optional)"
        echo "Step 6)	Bundle Upload and Register Image"
        echo "Step 7)	Cleanup"
        echo "Step 8)	Go back to previous menu"
        echo "0)        Abort"
        echo "------------------------------------------------------------------"
        echo ""
        echo -n "Enter your choice : "
        read stepch

        case $stepch in
        1)
                echo ""
                echo "Enter the location of ISO image (absolute path)"
                read ISOpath
                if [ -e $ISOpath ]
                then
		
		umount /mnt/loopmnt &> /dev/null
		umount /mnt/ec2-fs/proc &> /dev/null
		umount /mnt/ec2-fs &> /dev/null	
		rm -rf /mnt/loopmnt &> /dev/null
		mkdir /mnt/loopmnt &> /dev/null
                mkdir /mnt/ec2-fs &> /dev/null

                export loopmnt=/mnt/loopmnt
		umount $loopmnt &> /dev/null
                mount -o loop $ISOpath $loopmnt

                export imgdir=$tpd
		echo ""
		echo "Enter the name for the root disk image file (example: xyz.fs )"
                read imgname
		echo ""
                echo "Enter the required size of root disk in GB (enter 1 for 1GB; warning!! 10 GB max)"
                read imgsize
                echo "Creating $imgname image in $imgdir directory"
                _sleep 2
                cd $imgdir
                dd if=/dev/zero of=$imgname bs=1M count=`expr 1000 \* $imgsize` 2> $errorlog
chk_err $?
		
                echo "$imgname is created in $imgdir directory"

                echo "creating ext3 file system on $imgname"
                _sleep 2
                /sbin/mke2fs -F -j $imgname 2> $errorlog
chk_err $?

                _sleep 2
                echo ""

		export imgloopmnt=/mnt/ec2-fs
                echo "mounting the image via loopback to a mount point $imgloopmnt"
                _sleep 2
                umount $imgloopmnt/proc &> /dev/null
                umount $imgloopmnt &> /dev/null
                mount -o loop $imgname $imgloopmnt 2> $errorlog
chk_err $?

                else
                        echo "ISO file doesnot exist or worong path"
                        read
			break
                fi



              echo "creating $imgloopmnt/dev directory"
                _sleep 2
                mkdir $imgloopmnt/dev 2> $errorlog
chk_err $?

                echo "populating $imgloopmnt/dev with concole"
                _sleep 2
                /sbin/MAKEDEV -d $imgloopmnt/dev -x console 2> $errorlog
chk_err $?

                echo "populating $imgloopmnt/dev with null"
                _sleep 2
                /sbin/MAKEDEV -d $imgloopmnt/dev -x null 2> $errorlog
chk_err $?

                echo "populating $imgloopmnt/dev with zero"
                _sleep 2
                /sbin/MAKEDEV -d $imgloopmnt/dev -x zero 2> $errorlog
chk_err $?

                echo "creating $imgloopmnt/etc directory"
                _sleep 2
                mkdir $imgloopmnt/etc 2> $errorlog
chk_err $?

                echo "creating /proc directory"
                _sleep 2

                mkdir $imgloopmnt/proc 2> $errorlog
chk_err $?

                echo "mounting /proc"
                mount -t proc none $imgloopmnt/proc 2> $errorlog
chk_err $?
		st1=0
                echo "Step 1 Completed ; Press ENTER to continue"
                read
                ;;

        2)     
		if [ $st1 -eq 0 ];then
		echo "Taking back up of old repos"
		cd /etc/yum.repos.d
		tar -cvzf yum.old.tgz ./*
		rm -rf *.repo

cat << EOL | tee /etc/yum.repos.d/my.repo 
[CentOS_Repository]
name=CentOS
baseurl=file://$loopmnt/
enabled=1
EOL
                echo ""
                echo "Now installing operating system"
                echo "enter one of the option below"
                echo "1>        Group/Base Install"
                echo "2>        Selective Install (selecting packages one by one from yum repository ex: httpd, gcc, mysql, etc )"
                read instoption

                case $instoption in
                1)
                        echo "You have selected group install"
                        echo "installing the base packages by yum"
                        _sleep 2
                        yum -c /etc/yum.repos.d/my.repo --installroot=$imgloopmnt -y groupinstall Base 2> $errorlog
chk_err $?

                        ;;
                2)
                        echo "You have selected selective install"
                        ans=y
                        while [ "$ans" == y ]
                        do
                                selectiveInstall
                                echo "Do you want to install another package (y/n)?"
                                read ans
                        done
                        ;;
                esac
                st2=0
		echo "Restoring old repos"
		tar -xzf yum.old.tgz
		rm *.tgz

		echo "Step 2 Completed ; Press ENTER to continue"
                read
		else
			echo "Complete step 1 first"
		fi
                ;;


        3)      if [ $st1 -eq 0 ] && [ $st2 -eq 0 ]; then
		echo "Modifying fstab in $imgloopmnt/etc "
                #echo "----------------------------------------"
                cat << EOL > $imgloopmnt/etc/fstab
/dev/sda1  /         ext3    defaults        1 1
none       /dev/pts  devpts  gid=5,mode=620  0 0
none       /dev/shm  tmpfs   defaults        0 0
none       /proc     proc    defaults        0 0
none       /sys      sysfs   defaults        0 0
EOL



                echo "updating ifcfg-eth0 file in $imgloopmnt/etc/sysconfig/network-scripts "
                cat << EOL > $imgloopmnt/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
TYPE=Ethernet
USERCTL=yes
PEERDNS=yes
IPV6INIT=no
EOL

                echo "updating network file in $imgloopmnt/etc/sysconfig "
                cat << EOL > $imgloopmnt/etc/sysconfig/network
HOSTNAME=localhost.localdomain
NETWORKING=yes
EOL

                echo "updating rc.local file in $imgloopmnt/etc/ "
                cat << EOL >> $imgloopmnt/etc/rc.local
#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

if [ ! -d /root/.ssh ] ; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
fi
# Fetch public key using HTTP
curl -f http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > /tmp/my-key
if [ 0 -eq 0 ] ; then
        cat /tmp/my-key >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
        rm /tmp/my-key
fi
# or fetch public key using the file in the ephemeral store:
if [ -e /mnt/openssh_id.pub ] ; then
        cat /mnt/openssh_id.pub >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
fi

touch /var/lock/subsys/local
# Update the EC2 AMI creation tools
#echo " + Updating AMI tools"
#rpm -Uvh http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm
chmod 1777 /tmp
chmod 1777 /mnt

EOL
		echo "updating sshd_config"
                cat <<EOL >> $imgloopmnt/etc/ssh/sshd_config
UseDNS no
PermitRootLogin without-password
GatewayPorts yes
EOL
                echo "updating hosts"
                cat <<EOL >> $imgloopmnt/etc/hosts
127.0.0.1 localhost localhost.localdomain
EOL
		echo "Updating kernel modules"
		cp -r /remote/tuxstart/AMAZON_EC2/kernels/kernel_centos/2.6.16-xenU $imgloopmnt/lib/modules
		cp -r  /remote/tuxstart/AMAZON_EC2/kernels/kernel_centos/2.6.18-xenU-ec2-v1.0 $imgloopmnt/lib/modules
		cp -r  /remote/tuxstart/AMAZON_EC2/kernels/kernel_centos/2.6.21.7-2.fc8xen $imgloopmnt/lib/modules
               	st3=0
		 echo "Step 3 Completed ; Press ENTER to continue"
                read
		else
			echo "Complete step 1,2 first"
		fi
                ;;
	4)
                if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] ; then
                echo "Enter the location of tar file"
                read rpmPath
                mkdir $tpd/extra_rpms 2> $errorlog
chk_err $?

                tar -xzf $rpmPath -C $tpd/extra_rpms 2> $errorlog
chk_err $?

                rpm --root $imgloopmnt -Uvh $tpd/extra_rpms/*.rpm --force --nodeps 2> $errorlog
chk_err $?

                rm -rf $tpd/extra_rpms 2> $errorlog
chk_err $?
                st4=0
                echo "Step 4 Completed ; Press ENTER to continue"
                read
                else
                        echo "INFO: Complete step 1,2,3 first"
                fi

                ;;

        5)	if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] && [ $st4 -eq 1 ] || [ $st4 -eq 0 ]; then
		 echo "provide the script (proper location) to further modify the services, rpms, etc..."
                read service_script
                touch $imgloopmnt/tmp/modify.sh
                cat $service_script > $imgloopmnt/tmp/modify.sh
                chmod +x $imgloopmnt/tmp/modify.sh
                /usr/sbin/chroot $imgloopmnt /tmp/modify.sh 2> $errorlog
chk_err $?
                rm -rf $imgloopmnt/tmp/modify.sh
                echo "done..."
		st5=0
		echo "Step 5 Completed ; Press ENTER to continue"
                read
		else
			echo "Complete steps 1,2,3 first (4 optional)"
		fi
                ;;


        6)      
		if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] && [ $st4 -eq 0 ] || [ $st5 -eq 0 ] || [ $st4 -eq 1 ] || [ $st5 -eq 1 ]; then
		echo "Creating the bundle of root disk image"
                echo "rename $imgname to OSname.fs"
                echo "enter the new name for your image bundle (ex- rhel_5.4_x86_64.fs); manifest file and AMI will be created by this name "
                read osimgname
		 umount $imgloopmnt/proc &> /dev/null
                umount $imgloopmnt &> /dev/null
                cd $imgdir
                mv $imgname $osimgname
                echo "starting bundling of image "
		ec2-bundle-image -i $imgdir/$osimgname -k $EC2_PRIVATE_KEY -c $EC2_CERTIFICATE_KEY -u $AWS_ACCOUNT_NUMBER --arch $ARCH
                if [ $? -ne 0 ]
                then
                echo "Image bundle failed"
		exit 1
		else
                echo "Image bundled"
                fi
                

                echo "Starting upload and register"
                ec2-upload-bundle -b $BUCKET_NAME -m /tmp/$osimgname.manifest.xml -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY 2> $errorlog
chk_err $?

		getAMIname
                
		echo "Now registering with AMI name "$aminame""
                 echo "Enter the kernel image ID to register your ami(aki-a71cf9ce) (Optional; ENTER to skip)"
                read akireg
                echo "Enter the Ramdisk ID to register your ami(ari-a51cf9cc)(Optional; ENTER to skip)"
                read arireg
                echo "Now registering"

                if [ -z $akireg ] && [ -z $arireg  ];then
                        ec2-register -n $aminame -a $ARCH $BUCKET_NAME/$osimgname.manifest.xml 2> $errorlog
                        chk_err $?
                elif [ -n $akireg ] && [ -z $arireg  ];then
                         ec2-register -n $aminame -a $ARCH $BUCKET_NAME/$osimgname.manifest.xml --kernel $akireg 2> $errorlog
                        chk_err $?
                else
                         ec2-register -n $aminame -a $ARCH $BUCKET_NAME/$osimgname.manifest.xml --kernel $akireg --ramdisk $arireg 2> $errorlog
                        chk_err $?
                fi


                echo "image registerd with the above ami ID"
                echo "Step 6 Completed ; Press ENTER to continue"
                read
		else
			echo "Compelete step 1,2,3 (4,5 optioanl) first"
		fi
                ;;

        7)     echo "Unmount loopback directories and Cleanup files"
                umount $loopmnt &> /dev/null
		rm -rf $tpd
		rmdir /mnt/loopmnt
		echo "File system cleaned"
                echo "Step 7 Completed ; Press ENTER to continue"
                read
                ;;
        8)
                break
                ;;
        0)
                umount $loopmnt &> /dev/null
		 rm -rf $tpd
                rmdir /mnt/loopmnt
		exit
                ;;
        *)
                echo "Invalid option,  please provide valid entry"
                echo "press ENTER to try again"
                read
                ;;

        esac
done

}

################################################################################################################
function amiExisting {
echo "********************************"
echo "Creating AMI from existing AMI"
echo "Complete the steps one by one"
echo "********************************"

while [ 1 ]
do 
	clear
		
	echo "*************************************************************************"
	echo "1) Boot the existing AMI"
	echo "2) Test the SSH connectivity"
	echo "3) Copy Private key and Certificate key to AMI /tmp directory"
	echo "4) Install additional RPMS (Optional) "
	echo "5) Provide a script to further modify services and remove RPMS (Optional) "
	echo "6) License Provision (Optional)"
	echo "7) Bundle the AMI and Upload the bundle and Register"
	echo "8) Terminating the original Instance"
	echo "9) Go back to main menu"
	echo "0) Abort"
	echo "*************************************************************************"
	echo -n "Enter your choice : "
	read rhelexisting_choice 
	case $rhelexisting_choice in

1)
	echo "Enter the ami ID to boot"
	read ami_id
	echo "Authenticating....."
	ami_exists="`ec2-describe-images -a | grep "$ami_id" | cut -f 2`"
	if [ "$ami_id" != "$ami_exists" ];then
		echo "AMI doesnot exist"
		echo "Enter to repeat step 1"
		read
		amiExisting
	fi
	echo ""
	echo "enter ssh key pair name (Required)"
	read ssh_key_pair
	echo "Authenticating....."
	for key in `ec2-describe-keypairs | cut -f 2`
	do
        	valid=0;
	        if [ "x$ssh_key_pair"  = "x$key" ];then
        	        valid=1;
                	break;
	        else
        	        continue
	        fi
	done
	if [ $valid -eq 0 ];then
        	echo "Invalid key"
		echo "Valid Keys are : `ec2-describe-keypairs | cut -f 2`"
		echo "Enter to repeat step 1"
		read
		amiExisting
	fi

	echo ""
	echo "enter the path for the ssh key pair on your local machine (Required)"
	read ssh_key_path
	if [ -e $ssh_key_path ];then
	        echo ""
	else
	        echo "SSH Key file does not exist on the specified path"      
        	echo "Enter to repeat step 1"
		read
		amiExisting
	fi


	echo ""
	echo "Enter the AKI ID (Optional : press enter to skip)"
	read aki_id
	if [ -n "$aki_id" ];then
		echo "Authenticating....."
		aki_exists="`ec2-describe-images -a | grep "$aki_id" | cut -f 2`" 2> $errorlog
		if [ "$aki_id" != "$aki_exists" ];then
			echo "AKI doesnot exist"
			echo "Enter to repeat step 1"
			read
			amiExisting
		fi
	fi

	echo ""
	echo "Enter the ARI ID (Optional : press enter to skip)"
	read ari_id
	if [ -n "$ari_id" ];then
		echo "Authenticating....."
		ari_exists="`ec2-describe-images -a | grep "$ari_id" | cut -f 2`" 2> $errorlog
		if [ "$ari_id" != "$ari_exists" ];then
			echo "ARI doesnot exist"	
			echo "Enter to repeat step 1"
			read
			amiExisting
		fi
	fi

	echo ""
	echo "Enter the zone name (Required)"
	read zone_id
	echo "verifying..."
	for zone in `ec2-describe-availability-zones | cut -f 2`
	do
        	zvalid=0;
	        if [ "x$zone_id"  = "x$zone" ];then
        	        zvalid=1;
                	break;
	        else
        	        continue
	        fi
	done
	if [ $zvalid -eq 0 ];then
        	echo "Invalid zone"
		echo "Your availability zones are: `ec2-describe-availability-zones | cut -f 2`"
		echo "Enter to repeat step 1"
                read
		amiExisting
	fi

	echo ""
	echo "Enter the instance type to boot the instance (ex: m1.large) (Required)"
	read inst_type
	for inst in m1.small m1.large m2.xlarge m2.2xlarge m2.4xlarge c1.medium c1.xlarge cc1.4xlarge
	do
		inst_valid=0
		if [ "x$inst_type" = "x$inst" ];then
			inst_valid=1
			break;
		else
			continue
		fi
	done
	if [ $inst_valid -eq 0 ];then
		echo "ERROR:"
		echo "Invalid instance type"
		echo "Available instance types are :  m1.small m1.large m1.xlarge m2.xlarge m2.2xlarge m2.4xlarge c1.medium c1.xlarge cc1.4xlarge"
		echo "Enter to repeat step 1"
                read
		amiExisting
	fi

	echo "Booting up the instance"

	if [ -z $aki_id ] && [ -z $ari_id  ];then
		ec2-run-instances $ami_id -z $zone_id -k $ssh_key_pair -t $inst_type 1> $boot_inst 2> $errorlog
		chk_err $?
	elif [ -n $aki_id ] && [ -z $ari_id  ];then 
		ec2-run-instances $ami_id --kernel $aki_id -z $zone_id -k $ssh_key_pair -t $inst_type 1> $boot_inst 2> $errorlog
		chk_err $?
	else
		ec2-run-instances $ami_id --kernel $aki_id --ramdisk $ari_id -z $zone_id -k $ssh_key_pair -t $inst_type 1> $boot_inst 2> $errorlog
		chk_err $?
	fi

	instance_id="`cat $boot_inst | cut -f 2 | tail -1`"

	echo "Bootup requested with Instance ID : $instance_id"
        echo""
	status="pending"
	declare -i count
	count=600
	echo "AMI not booted yet"
        while [ $count -gt 0 ]
        do
                status="`ec2-describe-instances | grep $instance_id | cut -f 6`" 2> $errorlog
		if [ $status == "running" ]; then
                        echo "AMI booted up successfully"
                        st1=0
			break
                else
                        echo "$count sec remaining to timeout....."
                        count=$count-20
                	sleep 20
        	fi
        done
        if [ $status == "pending" ]; then
               echo "Unable to boot ami $ami_id"
               exit 1
        fi
	echo "Enter to continue"
	read
	;;

2)
	if [ $st1 -eq 0 ]; then
	ssh_log=$tpd/ssh_$$.log
	public_dns="`ec2-describe-instances | grep $instance_id | cut -f 4`"
 	ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no root@$public_dns uptime 1> $ssh_log 2> $errorlog &

        pid=`echo $!`
        _sleep 10
        if [ -e $ssh_log ]; then
                echo "AMI SSH ready"
		st2=0
		rm -rf $ssh_log  
	else
                echo "##################################################"
                echo "Not able to SSH original AMI $ami_id"
                echo "##################################################"
                kill $pid
                exit 1
        fi
	echo "Press ENTER to contine"
	read
	else
		echo "Complete step 1 first"
	fi
	;;

3)
	if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] ;then
	echo "Transfering the Private key, certificate key to the booted AMI"
	scp -i $ssh_key_path -o StrictHostKeyChecking=no $EC2_PRIVATE_KEY root@$public_dns:/tmp 2> $errorlog
	chk_err $?

	scp -i $ssh_key_path -o StrictHostKeyChecking=no $EC2_CERTIFICATE_KEY root@$public_dns:/tmp 2> $errorlog
	chk_err $?

	echo "Done..."
	st3=0
	echo "Press ENTER to contine"
	read
	else
		echo "Complete step 1,2 first"
	fi
	;;


4)
	 if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] ;then
	echo "Transfering extra_rpms"
	echo "enter the path for the rpm.tar file"
	read rpm_tar_path
	if [ -e $rpm_tar_path ];then
		rpm_tar=`basename $rpm_tar_path`
		scp -i $ssh_key_path -o StrictHostKeyChecking=no $rpm_tar_path root@$public_dns:/tmp/ 2> $errorlog
		chk_err $?


		echo "Installing extra RPMs"
	ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
mkdir /tmp/rpms
cd /tmp
tar -xzf $rpm_tar -C /tmp/rpms
rpm -Uvh /tmp/rpms/*.rpm --force --nodeps
EOL
		st4=0
		echo "Done..."
		echo "Proceed to next step"
		echo "Press ENTER to contine"
		read
	else
		echo "Specified tar file doesnot exist. Verify the location. Repeat step 4"
		echo "Enter to continue"
		read
		amiExisting
	fi
	else
		echo "Complete step 1,2,3 first"
	fi
	;;

5)
	if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] && [ $st4 -eq 0 ] || [ $st4 -eq 1 ] ;then
	echo "Enter the script to remove rpms or modify services"
	read user_script
	if [ -e $user_script ]; then

		cat $user_script > $tpd/modify.sh
		scp -i $ssh_key_path -o StrictHostKeyChecking=no $tpd/modify.sh root@$public_dns:/tmp 2> $errorlog
	
		echo "Modifing Services and RPMS"
	ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns 2> $errorlog << EOL
cd /tmp
chmod 777 modify.sh
./modify.sh 
EOL
		echo "Done..."
		st5=0
		echo "Step 5 complete...Proceed to next step"
		echo "Press ENTER to contine"
		read
	else
	 	echo "Specified file doesnot exist. Verify the location. Repeat step 4"
                echo "Enter to continue"
                read
                amiExisting
	fi
	else
		echo "Complete step 1,2,3(4 optional) first"
	fi
	;;

6)
	if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] && [ $st4 -eq 0 ] || [ $st5 -eq 0 ] || [ $st4 -eq 1 ] || [ $st5 -eq 1 ];then
	
	echo "License Provisioning"
	while [ 1 ]
                do
                        echo "1)	Copy tunnel program to ami, create ssh keys, update rc.local, scan license server ssh keys"
                        echo "2)	Turn off the unnecessary Sevices (provide 'stripdown.sh' script)"
                        echo "3)	Turn off sshd"
			echo "4)	Go back to previous menu"
                        echo -n "Enter your option : "
                        read licen_option

                case $licen_option in
		1)	
			scp -i $ssh_key_path -o StrictHostKeyChecking=no /remote/us01home25/vsakode/ami_auto/snps.tar.gz root@$public_dns:/tmp

			ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
cd /tmp
tar -xzf snps.tar.gz
EOL
			ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
cp -r /tmp/snps /opt/
EOL
			echo "done...."
			echo "Enter to continue"
			read

			rm -rf $tpd/ssh_keys &> /dev/null
			mkdir $tpd/ssh_keys &> /dev/null
			ssh-keygen -t rsa -N '' -f $tpd/ssh_keys/snps_rsa
			cd $tpd
			ssh_keys_tar="ssh_keys.`date "+%d%b%y_%H%M"`.tar.gz"
			tar -cvzf ../license_keys/$ssh_keys_tar ssh_keys
			cd /u/vsakode/ami_auto/
			scp -i $ssh_key_path -o StrictHostKeyChecking=no $lk/$ssh_keys_tar root@$public_dns:/tmp	
			ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
cd /tmp
tar -xzf $ssh_keys_tar
cp /tmp/ssh_keys/snps_rsa /opt/snps/.ssh/
cp /tmp/ssh_keys/snps_rsa.pub /opt/snps/.ssh/
echo "/opt/snps/License_Provisioner.py &" >> /etc/rc.local
export SNPSLMD_LICENSE_FILE=27005@localhost
ssh-keyscan -t rsa,dsa poclic1.synopsys.com >> /root/.ssh/known_hosts
ssh-keyscan -t rsa,dsa poclic2.synopsys.com >> /root/.ssh/known_hosts
EOL
			
			rm -rf $tpd/ssh_keys
			echo ""
			echo ""
			echo "License keys set.."
			echo "Grab the keys from $lk/$ssh_keys_tar to setup on the server"
			echo ""
			echo "ENTER to continue to next step"
			read
			
			;;

		2)
			echo "Provide your script(Stripdown) to turn off unnecessary devices"
			read turnoff
			cat $turnoff > $tpd/stripdown.sh
			scp -i $ssh_key_path -o StrictHostKeyChecking=no $tpd/stripdown.sh root@$public_dns:/tmp
			ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
cd /tmp
chmod +x stripdown.sh
./stripdown.sh
EOL
			rm -rf $tpd/stripdown.sh
			echo "ENTER to continue to next step"
                        read

			;;
		3)
			 ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
chkconfig --level 2345 sshd off
EOL

			 echo "ENTER to continue to next step"
                        read

			;;

		4)
			break
			;;
		
		*)
			echo "Invalid Option; Please provide valid entry"
			echo "Press enter to continue"
			read
		esac
	st6=0
	done
	else
		echo "Complete steps 1,2,3(4,5 optional) first"
	fi
	;;
7) 
	if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ]; then
	pkid=`echo $EC2_PRIVATE_KEY | cut -d / -f 7`
	certid=`echo $EC2_CERTIFICATE_KEY | cut -d / -f 7`
	echo "Now bundling the AMI"
	ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
ec2-bundle-vol -k /tmp/$pkid -c /tmp/$certid -u $AWS_ACCOUNT_NUMBER -e /mnt,/tmp,/root/.ssh 
EOL

	echo "uploading the Bundle"
	ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
ec2-upload-bundle -b $BUCKET_NAME -m /tmp/image.manifest.xml -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY
EOL
	echo "Done..."

	echo "Registering the AMI"
	getAMIname	

	ec2-register -n $aminame -a $ARCH $BUCKET_NAME/image.manifest.xml  2> $errorlog
	chk_err $?

	echo "AMI registered with above ami-id"
	echo "Press ENTER to contine"
	read
	else
                echo "Compelte steps 1,2,3 (4,5,6 optional) first"
        fi
	;;

8) 
	
	echo "Terminating..............."
	ec2-terminate-instances $instance_id  2> $errorlog
	chk_err $?
	rm -rf $tpd
	echo "Done"
	echo "Press ENTER to contine"
	read
	;;

9)
	break
	;;

0)
	 ssh -i $ssh_key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -T root@$public_dns << EOL
rm -f /tmp/pk*
rm -f /tmp/cert*
rm -rf /tmp/rpms
EOL
	rm -rf $tpd
	echo "Cleared your keys from the image; Now press ENTER to exit"
	read
	exit
	;;
*)

	echo "Invalid option; Please provide valid entry"
	;;
	esac
done
}

#################################################################################################################
function slesScratch {

echo "Starting SUSE AMI creation from SCRATCH using kiwi tool"
echo "**********************************"
while [ 1 ] 
do
	clear
	echo "------------------------------------------------------------------"
	echo "Complete ALL steps one by one. (Enter 0 to abort anytime)"
	echo "------------------------------------------------------------------"
	echo "1) Create kiwi config.xml file"
	echo "2) Install SUSE base, Create root disk image and update kernel module and config files  "
	echo "3) Install additional RPMS (Optional)"
	echo "4) Modify services and RPMS (Optional)"
	echo "5) Bundle Upload and Register Image"
	echo "6) Clean up"
	echo "7) Go Back to Previous Menu"
	echo "0) Abort"
	echo "------------------------------------------------------------------"
	echo -n "Enter your choice : "
	read susechoice
	
	case $susechoice in
	1)	
		if [ -d /usr/share/doc/packages/kiwi/examples/suse-11.0/suse-ec2-guest/ ];then
			
		echo "Please provide path of the iso file ; provide complete path ex : /remote/tuxstart....."
		read slesiso
		if [ -e $slesiso ]; then 
			umount /mnt/loopmnt &> /dev/null
			mkdir /mnt/loopmnt &> /dev/null
			mount -o loop $slesiso /mnt/loopmnt/
		cat << EOL > /usr/share/doc/packages/kiwi/examples/suse-11.0/suse-ec2-guest/config.xml 
<?xml version="1.0" encoding="utf-8"?>
<image schemaversion="3.7" name="sles-11.0-ec2">
	<description type="system">
		<author>Marcus Schaefer</author>
		<contact>ms@novell.com</contact>
		<specification>SLES ec2 11.0 test system</specification>
	</description>
	<preferences>
		<type primary="true" ec2accountnr="$AWS_ACCOUNT_NUMBER" ec2privatekeyfile="$EC2_PRIVATE_KEY" ec2certfile="$EC2_CERTIFICATE_KEY">ec2</type>
		<type filesystem="ext3" boot="vmxboot/suse-11.0">vmx</type>
		<type filesystem="ext3" boot="xenboot/suse-11.0">xen</type>
		<version>1.1.2</version>
		<packagemanager>zypper</packagemanager>
		<rpm-check-signatures>false</rpm-check-signatures>
	</preferences>
	<users group="root">
		<user pwd="$1$wYJUgpM5$RXMMeASDc035eX.NbYWFl0" home="/root" name="root"/>
	</users>
	<repository type="yast2">
		<!--<source path="/image/CDs/full-11.0-i386"/>-->
		<source path="/mnt/loopmnt"/>
	</repository>
	<packages type="image">
		<package name="bootsplash-branding-SLES" bootinclude="true" bootdelete="true"/>
	        <package name="gfxboot-branding-SLES" bootinclude="true" bootdelete="true"/>
		<package name="kernel-default"/>
		<package name="kernel-xen"/>
		<package name="bootsplash"/>
		<package name="vim"/>
		<opensusePattern name="base"/>
	</packages>
	<packages type="xen">
		<package name="kernel-xen"/>
		<package name="xen"/>
	</packages>
	<packages type="vmware">
	</packages>
	<xenconfig memory="512">
		<xendisk device="/dev/sda"/>
	</xenconfig>
	<vmwareconfig memory="512">
		<vmwaredisk controller="ide" id="0"/>
	</vmwareconfig>
	<packages type="bootstrap">
		<package name="filesystem"/> 
		<package name="glibc-locale"/>
	</packages>
</image>

EOL
			st1=0
			echo "Step 1 Completed ; Press ENTER to continue"
        		read
		else
			echo "ISO doesnot exist"
			echo "Repeat step 1"
			echo "Press ENTER to continue"
       			read

		fi
		else
			echo "KIWI tool not found.. EXITING..."
			exit 21	
		fi
		;;
	
	2)
		if [ $st1 -eq 0 ];then
		rm -rf $tpd/sles11_image_root &> /dev/null
		kiwi -p /usr/share/doc/packages/kiwi/examples/suse-11.0/suse-ec2-guest --root $tpd/sles11_image_root

		echo ""
		echo "Root disk image created"
		_sleep 1 
		echo "Updating kernel modeules and config files"
		cp -r /remote/tuxstart/AMAZON_EC2/kernels/kernel_sles/2.6.31-302-ec2 $tpd/sles11_image_root/lib/modules/  2> $errorlog
		chk_err $?


		cat << EOL > $tpd/sles11_image_root/etc/fstab
/dev/sda1  /            ext3    defaults        1 1
/dev/sdb   /mnt         ext3    defaults        0 0
none       /dev/pts     devpts  mode=0620,gid=5 0 0
none       /proc        proc    defaults        0 0
none       /sys         sysfs   defaults        0 0
EOL

		cat << EOL > $tpd/sles11_image_root/etc/inittab
#
# /etc/inittab
#
# Copyright (c) 1996-2002 SuSE Linux AG, Nuernberg, Germany.  All rights reserved.
#
# Author: Florian La Roche, 1996
# Please send feedback to http://www.suse.de/feedback
#
# This is the main configuration file of /sbin/init, which
# is executed by the kernel on startup. It describes what
# scripts are used for the different run-levels.
#
# All scripts for runlevel changes are in /etc/init.d/.
#
# This file may be modified by SuSEconfig unless CHECK_INITTAB
# in /etc/sysconfig/suseconfig is set to "no"
#

# The default runlevel is defined here
id:3:initdefault:

# First script to be executed, if not booting in emergency (-b) mode
si::bootwait:/etc/init.d/boot

# /etc/init.d/rc takes care of runlevel handling
#
# runlevel 0  is  System halt   (Do not use this for initdefault!)
# runlevel 1  is  Single user mode
# runlevel 2  is  Local multiuser without remote network (e.g. NFS)
# runlevel 3  is  Full multiuser with network
# runlevel 4  is  Not used
# runlevel 5  is  Full multiuser with network and xdm
# runlevel 6  is  System reboot (Do not use this for initdefault!)
#
l0:0:wait:/etc/init.d/rc 0
l1:1:wait:/etc/init.d/rc 1
l2:2:wait:/etc/init.d/rc 2
l3:3:wait:/etc/init.d/rc 3
l4:4:wait:/etc/init.d/rc 4
l5:5:wait:/etc/init.d/rc 5
l6:6:wait:/etc/init.d/rc 6

# what to do in single-user mode
ls:S:wait:/etc/init.d/rc S
~~:S:respawn:/sbin/sulogin

# what to do when CTRL-ALT-DEL is pressed
ca::ctrlaltdel:/sbin/shutdown -r -t 4 now

# special keyboard request (Alt-UpArrow)
# look into the kbd-0.90 docs for this
kb::kbrequest:/bin/echo "Keyboard Request -- edit /etc/inittab to let this work."

# what to do when power fails/returns
pf::powerwait:/etc/init.d/powerfail start
pn::powerfailnow:/etc/init.d/powerfail now
#pn::powerfail:/etc/init.d/powerfail now
po::powerokwait:/etc/init.d/powerfail stop

# for ARGO UPS
sh:12345:powerfail:/sbin/shutdown -h now THE POWER IS FAILING

# getty-programs for the normal runlevels
# <id>:<runlevels>:<action>:<process>
# The "id" field  MUST be the same as the last
# characters of the device (after "tty").
1:2345:respawn:/sbin/mingetty --noclear tty1
2:2345:respawn:/sbin/mingetty tty2
3:2345:respawn:/sbin/mingetty tty3
4:2345:respawn:/sbin/mingetty tty4
5:2345:respawn:/sbin/mingetty tty5
6:2345:respawn:/sbin/mingetty tty6
#
#S0:12345:respawn:/sbin/agetty -L 9600 ttyS0 vt102
#cons:1235:respawn:/sbin/smart_agetty -L 38400 console

#
#  Note: Do not use tty7 in runlevel 3, this virtual line
#  is occupied by the programm xdm.
#

#  This is for the package xdmsc, after installing and
#  and configuration you should remove the comment character
#  from the following line:
#7:3:respawn:+/etc/init.d/rx tty7


# modem getty.
# mo:235:respawn:/usr/sbin/mgetty -s 38400 modem

# fax getty (hylafax)
# mo:35:respawn:/usr/lib/fax/faxgetty /dev/modem

# vbox (voice box) getty
# I6:35:respawn:/usr/sbin/vboxgetty -d /dev/ttyI6
# I7:35:respawn:/usr/sbin/vboxgetty -d /dev/ttyI7

# end of /etc/inittab
EOL
		echo ""
		st2=0
		echo "Step 2 Completed ; Press ENTER to continue"
		read
		else
			echo "Complete step 1 first"
		fi
		;;
	3)	
		if [ $st1 -eq 0 ] && [ $st2 -eq 0 ];then
		echo "Enter the complete location of tar file"
                read rpmPath
		mkdir $tpd/extra_rpms  2> $errorlog
		chk_err $?

                tar -xzf $rpmPath -C $tpd/extra_rpms  2> $errorlog
		chk_err $?

                rpm --root $tpd/sles11_image_root -Uvh $tpd/extra_rpms/*.rpm --force --nodeps  2> $errorlog
		chk_err $?

                rm -rf $tpd/extra_rpms

		st3=0
		echo "Step 3 Completed ; Press ENTER to continue"
		read
		else
			echo "Compelte step 1 and 2 first"
		fi
		;;
		
	4)	if [ $st1 -eq 0 ] && [ $st2 -eq 0 ] && [ $st3 -eq 0 ] || [ $st3 -eq 1 ] ; then
                 echo "provide the script (proper location) to further modify the services, rpms, etc..."
                read service_script
                touch $tpd/sles11_image_root/tmp/modify.sh
                cat $service_script > $tpd/sles11_image_root/tmp/modify.sh
                chmod +x $tpd/sles11_image_root/tmp/modify.sh
                /usr/sbin/chroot $tpd/sles11_image_root /tmp/modify.sh 2> $errorlog
chk_err $?
                rm -rf $tpd/sles11_image_root/tmp/modify.sh
                echo "done..."
                st4=0
                echo "Step 5 Completed ; Press ENTER to continue"
                read
                else
                        echo "Complete steps 1,2,3 first (4 optional)"
                fi
                ;;
	

	5)	if [ $st1 -eq 0 ] && [ $st2 -eq 0 ];then

		rm -rf $tpd/sles11_x86_64_image &> /dev/null	
		mkdir $tpd/sles11_x86_64_image
		kiwi --create $tpd/sles11_image_root -d $tpd/sles11_x86_64_image 	
		echo""
		echo "Image Bundled"
		_sleep 2
		echo ""
		echo "Starting upload and register"
		cd $tpd/sles11_x86_64_image 
		mani_name="`ls *.xml`"
		echo $mani_name
		ec2-upload-bundle -b $BUCKET_NAME -m $mani_name -a $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY
		echo ""
		echo "Upload done"
		_sleep 2
		echo ""
		echo "Now registering"
		 getAMIname
		ec2-register -n $aminame -a $ARCH $BUCKET_NAME/$mani_name --kernel aki-fd15f694 --ramdisk ari-7b739e12
		echo "Image registerd with the above ami ID"	
		echo ""
		echo "Step 4 Completed ; Press ENTER to continue"
		read

		else 
			echo "Complete steps 1,2 (3 optional) first"
		fi
		;;
	
		
	6)
		rm -rf $tpd
		umount /mnt/loopmnt &> /dev/null
		rm -rf /mnt/loopmnt
		echo "Cleanup complete"
		echo "Press ENTER to continue"
		read
		;;
	
	0)
                rm -rf $tpd
		umount /mnt/loopmnt &> /dev/null
                rm -rf /mnt/loopmnt
		echo "Cleanup complete"
		exit
        	;;

	7)
		break
		;;
	*)
		echo "wrong entry"
		echo "try again"
		echo "Press ENTER to comtinue"
		read
		;;
	esac
done	
	
}


function chk_err {
if [ $1 -ne 0 ]
then
echo "##################################################################################"
echo "Error occured"
echo "-----------------------------------------------------------------------------------"
cat $errorlog
echo "####################################################################################"
echo "Enter 1 to CONTINUE with this error or 0 to EXIT "
read exit_option
	if [ $exit_option = "0" ]
	then
		echo "Exiting : $1 "
		exit $1
	else
		echo "Continuing Installation with the error "
	fi
fi
}


########################Script for AMI creation#####################
clear
echo "--------------------------------------------------------------------------"
echo "		Welcome to the AMI Automation Script"
echo "--------------------------------------------------------------------------"
while [ 1 ]
do
mainoptions
read mainchoice
case $mainchoice in
	1 )
			while [ 1 ]
			do			
				setEnv
			done	
			;;
	2 )
			if [ $validation -eq 0 ]; then
			while [ 1 ]
			do
			clear
			echo "********************************************************"			
			echo "Starting AMI creation process"
			echo "---------------------------------------------------------"
			echo "1)	RHEL 5.4 from SCRATCH"
			echo "2)	SLES 11 from SCRATCH"
			echo "3)	CentOS 5.4 from SCRATCH"
			echo "4)	Create AMI from existing AMI (Any OS with License Provisioning Option)"
			echo "5)	Go back to main menu"
			echo "********************************************************"
			echo -n "Enter your choice now : "
			read opsys	
			case $opsys in
				1)	clear
					echo "************************************************"
					echo "Starting RHEL AMI creation process from SCRATCH"
					echo "************************************************"
					rhelScratch
					;;
					
				2)	clear
					echo "***************************************"
					echo "Starting SLES ami creation from SCRATCH"
					echo "***************************************"
					slesScratch
					;;
				
				3)	clear
                                        echo "*************************************************"
                                        echo "Starting CentOS License ami creation from SCRATCH"
                                        echo "*************************************************"
                                        centosScratch
                                        clear
                                        ;;

				4)
					clear
                                        echo "***********************************************"
                                        echo "Starting AMI creation process from existing AMI"
                                        echo "***********************************************"
                                        amiExisting
                                        clear
                                        ;;
				5)	

					break	
					;;
				*)
					echo "Invalid option, please provide valid entry"							
					echo "Press ENTER to try again"
					read					
					;;
			esac
			done
			else
				echo "Set the environment and validate before starting automation"
				echo "Enter to continue"
				read
			fi
			;;
	3)
			echo "Setting DEBUG mode!" >&2;
			DEBUG=1;
			;;
	4)	
			rm -rf $tpd &> /dev/null
			exit
			;;
		
	*)
			echo "Invalid option, please provide valid entry"							
			echo "Press ENTER to try again"
			read					
			;;
				
	esac
done
