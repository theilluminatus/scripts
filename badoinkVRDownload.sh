#!/bin/bash
# masskinker - A script to mass-download kink.com videos
# Original: https://www.reddit.com/r/DataHoarder/comments/5w7ofn/masskinker_a_little_shell_script_to_automate/

SITE="domain" # vrcosplayx, kinkvr
VIDEO_URL="part-url" # cosplaypornvideo, bdsm-vr-video ...
SHOOTS=( 'name-id' 'name-id' 'name-id' )
USER_AGENT='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'
COOKIE="..." # find this in browsers dev tools
QUALITY="Vive \/ Oculus HQ" # Low Quality, High Quality, Gear VR HQ, Vive \/ Oculus HQ
SETTINGS_3D="oculus_180_180x180_3dh_LR" # must match above quality: mobile_low_180_180x180_3dh_LR, mobile_180_180x180_3dh_LR, oculus_180_180x180_3dh_LR, samsung_180_180x180_3dh_LR, _oculus_180_180x180_3dh_LR

download () {
	url="$1"
	filename="$2"
	mkdir -p "${SITE}"
	echo -e "Downloading file ${SITE}/${filename} from:\n ${url}\n"
	curl -C - -# -A "$USER_AGENT" -o "${SITE}/$filename" "$url" --retry 5 --retry-delay 10 --retry-max-time 60
}

echo ""
for shoot in "${SHOOTS[@]}"; do
	shoot_url="https://${SITE}.com/${VIDEO_URL}/${shoot}/"
	download_html=$(curl -s -A "$USER_AGENT" -b "$COOKIE" "$shoot_url")
	download_url=$(echo "$download_html" | sed -En "s/<source src=\"(.*)\" type=\"video\/mp4\" quality=\"$QUALITY\">/\1/p" | sed -e 's/\&amp;/\&/g' | tr -d " \t\n\r" )
	download "$download_url" "${shoot}_${SETTINGS_3D}.mp4"
	echo ""
done

# keep restarting in case a download wasn't completed
echo ""
echo "retry"
echo ""
exec "$(readlink -f "$0")"
