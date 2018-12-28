#!/bin/bash
# masskinker - A script to mass-download kink.com videos
# Original: https://www.reddit.com/r/DataHoarder/comments/5w7ofn/masskinker_a_little_shell_script_to_automate/

SHOOTS=( 1111 2222 3333 )
USER_AGENT='Mozilla/5.0 (X11; Linux x86_64; rv:51.0) Gecko/20100101 Firefox/51.0'
COOKIE="kinky.sess=s%3B3tVPW2CRpNrmauRV9q9u5IHmh6EfFK9n.jk1gsRcsvyPMaUgHcidHMy132RGjrfS71bbqp%2B2MI9I"
QUALITY="large" # hd, large, medium, small, mobile

download () {
	url="$1"
	subsite="$2"
	filename="kink/$subsite/"$(echo "$url" | sed -e 's@^.*\/@@g' -e 's@?.*$@@')

	mkdir -p "kink/$subsite"

	echo -e "Downloading file ${filename} from:\n ${url}\n"
	curl -C - -# -A "$USER_AGENT" -o "$filename" "$url" --retry 5 --retry-delay 10 --retry-max-time 60
}

echo ""
for shoot in "${SHOOTS[@]}"; do
	shoot_url="https://www.kink.com/shoot/${shoot}"
	download_html=$(curl -s -A "$USER_AGENT" -b "$COOKIE" "$shoot_url")
	download_url=$(echo "$download_html" | grep -e " $QUALITY " | sed -e 's@^.*\=\"@@' -e 's@\".*@@' -e 's@\&amp\;@\&@' | sed -e 's/\(.*\)what-we-have/\1/' | tr -d " \t\n\r" )
	download_sitename=$(echo "$download_html" | grep 'subsite-logo' | sed -e 's/<a href=\"\/channel\/.*\" class=\"subsite-logo \(.*\)\"><\/a>/\1/' | tr -d " \t\n\r" )
	download "$download_url" "$download_sitename"
	echo ""
done

# keep restarting in case a download wasn't completed
echo ""
echo "retry"
echo ""
exec "$(readlink -f "$0")"
