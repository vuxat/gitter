#!/bin/bash

DIRCUR="$(pwd)"
DIR="$(cd $(dirname "$0"); pwd)"
CURUSR="$(whoami)"
SCRIPT="$(basename $0)"

COUNTC=0
COUNTF=0
RUNVARN=0
GITVERSOVRD=0
GITVERS=""
FILTER=""
ONLYMISSING=0
DLSUM=0

# exit codes and text
ENO_SUCCESS=0; ETXT[0]="ENO_SUCCESS"
ENO_GENERAL=1; ETXT[1]="ENO_GENERAL"
ENO_LOCKFAIL=2; ETXT[2]="ENO_LOCKFAIL"
ENO_RECVSIG=3; ETXT[3]="ENO_RECVSIG"

GITVERS="master"
GITVERSSTND="master"

starttime=$(date +"%Y-%m-%d_%H-%M-%S")

for INPUTARG in $@; do
	ARGC=$((ARGC+1))
	RESETARG="$INPUTARG"
	#~ echo "next argument $ARGC : $INPUTARG"
	case "$INPUTARG" in
	"--version="* | "-v="* )
		GITVERS="${INPUTARG#*=}"
		GITVERSOVRD=1
		echo "Arg.: replacing link Version with ${GITVERS}";;
	"--help" )
		echo "USAGE: ./$0 |nothing - go through all textfiles and download every repository again
./$0 {certain-file} (without .txt) | download every repository from this specific file
./$0 -m | download only missing repositories
./$0 {certain-file} -f={name} | (re)download from this file every repository with path containing stated name
"
		exit 0;;
	"--missing" | "-m" )
		ONLYMISSING=1
		echo "Arg.: Only download missing files";;
	"--filter="* | "-f="* )
		FILTER="${INPUTARG#*=}"
		echo "Arg.: Filter downloads for *${FILTER}*";;
	* )
		RUNVARN=$((RUNVARN+1))
		if [ ${RUNVARN} -eq 1 ] ; then
			GROUPFILE="${INPUTARG/+/*}"
		else
			OTHERARG="$OTHERARG $INPUTARG"
		fi;;
	esac
	RESETFINAL="$RESETFINAL $RESETARG"
done
#~ echo "Groupfile ${GROUPFILE}"
if [ "${GROUPFILE}" = "" ] ; then
	GROUPFILE="*"
fi

#~ for f in "${DIR}"/${GROUPFILE}.txt
#~ do
	#~ echo "${f}"
#~ done
FINDCHECK=`find ${DIR} -name "${GROUPFILE}.txt"`
if [ "${GROUPFILE}" != "*" ] && [ ! -f "${DIR}/${GROUPFILE}.txt" ] ; then
	if [[ "${GROUPFILE}" =~ "*" ]] ; then
		#~ echo "${FINDCHECK}"
		if [[ ! "${FINDCHECK}" == *"${DIR}"* ]] && [[ ! "${FINDCHECK}" == *".txt"* ]] ; then
			echo "Multi-File(s) not found ... ${DIR}/${GROUPFILE}.txt"
			exit 2
		fi
	else
		echo "File(s) not found ... ${DIR}/${GROUPFILE}.txt"
		exit 2
	fi
fi

#~ filename=$(basename -- "$fullfile")
#~ extension="${filename##*.}"
#~ filename="${filename%.*}"

gitdl () {
	gitlink="$1"
	if [[ "${gitlink}" != "" ]]  && ( [[ "${FILTER}" == "" ]] || ( [[ "${FILTER}" != "" ]] && [[ "${gitlink,,}" =~ "${FILTER,,}" ]] ) ); then
		if [ "${gitlink: -1}" == "/" ] ; then
			gitlink="${gitlink::-1}"
			echo "--//-- correction of link --//--"
		fi
		gitlinkdl="${gitlink% *}"
		gitfile="${gitlink##*/}"
		gitverscur="${GITVERSSTND}"
		gitverscurname="${gitverscur}"
		if [[ "${gitlinkdl}" == *"/tree/"* ]] ; then
			#~ gitverscur="${gitfile}"
			gitlinkdl="${gitlinkdl%/tree/*}"
			gitfile="${gitlinkdl##*/}"
			gitverscur="${gitlink##*/tree/}"
			gitverscur="${gitverscur% *}"
			gitverscurname="${gitverscur//\//-}"
			echo "--- link contains diverging Version ${gitverscurname}"
		fi
		if [[ "${gitlink}" =~ ( ) ]] ; then
			gitfile="${gitlink##* }"
			echo "--- Using diverging filename --- ${gitfile}"
		fi
		#~ if [[ "${gitlink}" =~ "/tree/" ]]; then
		if [ ${GITVERSOVRD} -eq 1 ] ; then
			if [ "${gitverscurname}" != "${GITVERS}" ] ; then
				echo "--- ignoring Version ${gitverscurname} due to override"
				return
			fi
			gitverscurname="${GITVERS}"
		fi
		echo "--- Current target is ${CURGITDLDIR}/${gitfile}-${gitverscurname} ..."
		if [ ${ONLYMISSING} -eq 1 ] ; then
			if [ -f "${CURGITDLDIR}/${gitfile}-${gitverscurname}.zip" ] ; then
				echo "-##- Skipping - File ./${gitfile}-${gitverscurname}.zip already present"
				return
			fi
		fi
		COUNTC=$((COUNTC+1))
		if [[ "${gitlinkdl}" =~ "gitlab.com" ]] || [[ "${gitlinkdl}" =~ "ow2.org" ]] ; then
			gitlinkdl="${gitlinkdl}/-"
		fi
		if [ -f "${CURGITDLDIR}/__current.zip" ] ; then
			rm "${CURGITDLDIR}/__current.zip"
		fi
		echo "---- Downloading ${gitlinkdl}/archive/${gitverscurname}.zip > ./${gitfile}-${gitverscurname}.zip ..."
		#~ curl -s -L ${gitlinkdl}/archive/${gitverscurname}.zip > "${CURGITDLDIR}/${gitfile}-${gitverscurname}.zip"
		#~ curl -s -o "${CURGITDLDIR}/${gitfile}-${gitverscurname}.zip" -z "${CURGITDLDIR}/${gitfile}-${gitverscurname}.zip" -L ${gitlinkdl}/archive/${gitverscur}.zip
		curl --progress-bar -o "${CURGITDLDIR}/__current.zip" -L ${gitlinkdl}/archive/${gitverscur}.zip
		file_size=`du -b "${CURGITDLDIR}/__current.zip" | cut -f1`
		echo "Filesize is ${file_size}"
		if [ ${file_size} -le 100 ] ; then
			rm "${CURGITDLDIR}/__current.zip"
			if [ "${gitverscurname}" == "master" ] ; then
				echo "---- MASTER not successful - trying main"
				gitverscur="main"
				curl --progress-bar -o "${CURGITDLDIR}/__current.zip" -L ${gitlinkdl}/archive/${gitverscur}.zip
				file_size=`du -b "${CURGITDLDIR}/__current.zip" | cut -f1`
				echo "Filesize is ${file_size}"
				if [ ${file_size} -le 100 ] ; then
					echo "---- ERROR: MAIN also not successful"
					rm "${CURGITDLDIR}/__current.zip"
				else
					DLSUM=$((DLSUM+file_size))
				fi
			fi
		else
			DLSUM=$((DLSUM+file_size))
		fi
		if [ -f "${CURGITDLDIR}/__current.zip" ] ; then
			mv "${CURGITDLDIR}/__current.zip" "${CURGITDLDIR}/${gitfile}-${gitverscurname}.zip"
		fi
	fi
}

#~ shopt -s nullglob
for f in "${DIR}"/${GROUPFILE}.txt
do
	COUNTF=$((COUNTF+1))
	echo "running links of $f ..."
	CURGITDLDIR="${f%.*}"
	if [ ! -d "${CURGITDLDIR}" ] ; then
		echo "- Directory ${CURGITDLDIR} created ..."
		mkdir -p "${CURGITDLDIR}"
	fi
	while IFS= read -r gitl
        do
		gitdl "$gitl"
        done < <(grep "" "$f")
done

stoptime=$(date +"%Y-%m-%d_%H-%M-%S")
echo "$starttime - $stoptime"
echo "${COUNTF} files; ${COUNTC} downloads"
echo "total download size: $(numfmt --to iec --format '%8.2f' ${DLSUM})"
