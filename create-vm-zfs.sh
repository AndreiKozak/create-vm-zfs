#!/bin/bash

TEMPLATE=$2-template
VM_NAME=$3
POOL=$1

#checking number of arguments
if [ "$#" -ne 3 ]; then
	echo -e "You must pass two arguments to the script: \n1)ZFS Pool\n2)Template name (eg. ol8, centos7) \n3)VM Name"
	exit 1
fi

#checking if zfs virt-clone virsh are available in system
for program in zfs virt-clone virsh;do if type $program &>/dev/null; then
	true
else
	echo 'zfs virsh sed grep binaries must be installed'
	exit 1
fi
done

#creating VM
if virsh list --all|grep -q $VM_NAME; then
	echo "Unfortunately VM with name $VM_NAME is already available!"
	exit 1
else virt-clone --print-xml --original "$TEMPLATE" --name "$VM_NAME" --auto-clone|sed "s,/dev/zvol/.*,/dev/zvol/$POOL/$VM_NAME\"/>,g"|virsh define /dev/stdin
fi

#searching for template full path
if [ $(zfs list|grep "$TEMPLATE"|awk '{print $1}'|wc -l) -eq 1 ]; then
	export TEMPLATEFULLPATH=$(zfs list|grep "$TEMPLATE"|awk '{print $1}')
elif [ $(zfs list|grep "$TEMPLATE"|awk '{print $1}'|wc -l) -gt 1 ]; then
	echo "There is more that one template with name $TEMPLATE available!"
	exit 1
else
	echo "I can find a template with name $TEMPLATE"
	exit 1
fi

#creating zvol
if zfs list|grep -q "$POOL/$VM_NAME"; then
	echo 'Unfortunately zvolume with the same name is already available!'
	exit 1
else zfs send "$TEMPLATEFULLPATH"|zfs recv $POOL/"$VM_NAME"
fi
#virsh vol-create-as --pool "$POOL" --name "$VM_NAME" --capacity 200G
