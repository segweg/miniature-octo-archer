#!/bin/sh

. lib/misc/stdio

header () {
	VERSION="2.1"
	SVNVERSION="$Revision: 360 $" # Don't change this line.  Auto-updated.
	SVNVNUM="`echo $SVNVERSION | sed \"s/[^0-9]//g\"`"
	if [ -n "${SVNVNUM}" ]; then
		VERSION="${VERSION}-svn-${SVNVNUM}"
	fi
	printf "unix-privesc-check v${VERSION} ( http://code.google.com/p/unix-privesc-check )\n\n"
}

version () {
	header
	preamble
	printf "Brought to you by:\n"
	cat docs/AUTHORS
	exit 1
}

preamble () {
	printf "Shell script to check for simple privilege escalation vectors on Unix systems.\n\n"
}

usage () {
	header
	preamble
	printf "Usage: ${0}\n"
	printf "\n"
	printf "\t--help\tdisplay this help and exit\n"
	printf "\t--version\tdisplay version and exit\n"
	printf "\t--color\tenable output coloring\n"
	printf "\t--verbose\tverbose level (0-2, default: 1)\n"
	printf "\t--type\tselect from one of the following check types:\n"
	for checktype in lib/checks/enabled/*
	do
		printf "\t\t`basename ${checktype}`\n"
	done
	printf "\t--check\tprovide a comma separated list of checks to run, select from the following checks:\n"
	for check in lib/checks/*
	do
		if [ "`basename \"${check}\"`" != "enabled" ]
		then
			printf "\t\t`basename ${check}`\n"
		fi
	done
	exit 1
}

# TODO make it use lib/misc/validate
CHECKS=""
CHECKTYPE="all"
COLORING="0"
VERBOSE="1"
while [ -n "${1}" ]
do
	case "${1}" in
		--help|-h)
			usage
			;;
		--version|-v|-V)
			version
			;;
		--type|-t)
			shift
			CHECKTYPE="${1}"
			;;
		--check|-c)
			shift
			CHECKS="${1}"
			;;
		--color)
			COLORING="1"
			;;
		--verbose)
			shift
			VERBOSE="${1}"
			;;
	esac
	shift
done
header
if [ "${VERBOSE}" != "0" -a "${VERBOSE}" != "1" -a "${VERBOSE}" != "2" ]
then
	stdio_message_error "upc" "the provided verbose level ${VERBOSE} is invalid - use 0, 1 or 2 next time"
	VERBOSE="1"
fi
if [ -n "${CHECKS}" ]
then
	for checkfilename in `printf "${CHECKS}" | tr -d " " | tr "," " "`
	do
		if [ ! -e "lib/checks/${checkfilename}" ]
		then
			stdio_message_error "upc" "the provided check name '${checkfilename}' does not exist"
		else
			. "lib/checks/${checkfilename}"
			`basename "${checkfilename}"`_init
			`basename "${checkfilename}"`_main
			`basename "${checkfilename}"`_fini
		fi
	done
else
	if [ ! -d "lib/checks/enabled/${CHECKTYPE}" ]
	then
		stdio_message_error "upc" "the provided check type '${CHECKTYPE}' does not exist"
	else
		for checkfilename in lib/checks/enabled/${CHECKTYPE}/*
		do
			. "${checkfilename}"
			`basename "${checkfilename}"`_init
			`basename "${checkfilename}"`_main
			`basename "${checkfilename}"`_fini
		done
	fi
fi
exit 0
