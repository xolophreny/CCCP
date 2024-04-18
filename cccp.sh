#!/bin/bash

update() {
	echo "Updating..."
	[ -e Userdata ] && rm Userdata
	for file in $(ls -A); do rm -r "${file}"; done
	wget -O cccp.zip https://github.com/cortex-command-community/Cortex-Command-Community-Project/releases/download/v${version}/CortexCommand.linux.zip
	[ ! -e cccp.zip ] && echo "Download failed. Incorrect version?" && exit 2
	7z -y x cccp.zip
	chmod +x CortexCommand.AppImage
	ln -s "${cccp_userdata}" "${cccp_dir}/Userdata"
	cleanup
	echo "Finished updating."
}

run() {
	if [ ! -x ./CortexCommand.AppImage ] ; then
		echo "Make sure to install CCCP with -u first."
		exit 1
	fi
	if [ "$vars" != "" ] ; then
		echo "Variables: $vars"
	else
		vars="DRI_PRIME=1 "
		echo "Default variables: $vars"
	fi
	echo "Running..."
	exec env $vars ./CortexCommand.AppImage
}

cleanup() {
	echo "Cleanup..."
	[ -e cccp.zip ] && rm cccp.zip
}

usage() {
	echo "Usage:	$(basename $0) [-r] [-u <version>] [-l <dir>] [-d <dir>] [-e <envvar>] ..."
	echo "Options:"
	echo "	-u		Update to the specified CCCP release."
	echo "	-r		Run CCCP."
	echo
	echo "	-l		Set CCCP directory. Default:"
	echo "			~/.local/share/cccp"
	echo
	echo "	-d		Set userdata directory. Default:"
	echo "			~/.local/share/cccp-userdata"
	echo
	echo "	-e		Set additional env variables for running CCCP. Example:"
	echo "			-e DRI_PRIME=1 -e MESA_GLTHREAD=1"
}


cccp_dir=~/.local/share/cccp
cccp_userdata=~/.local/share/cccp-userdata
update=0
run=0
vars=""

# Processing parameters
while [ "${1:0:1}" = '-' ] ; do # While the first parameter starts with a dash
	n=1 # Character counter
	l=${#1} # Length of parameter
	while [ $n -lt $l ] ; do # Going through every character in a parameter
		case ${1:$n:1} in # Case of Nth character
			'u') 
				if [ $n -ne $(($l-1)) -o ! -n "${2}" ] ; then
					usage
					exit 1
				fi
				update=1
				version="${2}"
				shift;;
			'r')
				run=1;;
			'l')
				if [ $n -ne $(($l-1)) -o ! -n "${2}" ] ; then
					usage
					exit 1
				fi
				cccp_dir="${2}"
				shift;;
			'd')
				if [ $n -ne $(($l-1)) -o ! -n "${2}" ] ; then
					usage
					exit 1
				fi
				cccp_userdata="${2}"
				shift;;
			'e')
				if [ $n -ne $(($l-1)) -o ! -n "${2}" ] ; then
					usage
					exit 1
				fi
				vars+="${2} "
				shift;;
			*)
				usage
				exit 1;;
		esac
		n=$(($n+1))
	done
	shift
done

# Doing things
if which wget &> /dev/null && which 7z &> /dev/null && which env &> /dev/null; then
	if [ ${update} -eq 0 -a ${run} -eq 0 ] ; then
		usage
		exit 1
	fi
	
	echo "CCCP dir is ${cccp_dir}"
	echo "CCCP userdata dir is ${cccp_userdata}"
	mkdir -p ${cccp_dir}
	if [ ! -e "${cccp_dir}" ] ; then
		echo "Could not find or create ${cccp_dir}"
		exit 1
	fi
	mkdir -p ${cccp_userdata}
	if [ ! -e "${cccp_userdata}" ] ; then
		echo "Could not find or create ${cccp_userdata}"
		exit 1
	fi
	cd ${cccp_dir}
	trap cleanup SIGINT
	if [ $update -ne 0 ] ; then update; fi
	if [ $run -ne 0 ] ; then run; fi
else
	echo "Requires env, wget and 7z."
	exit 1
fi
