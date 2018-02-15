#!/bin/bash
# kink crawler - A script to mass-download kink.com video meta data
# and exports them as a html page

SHOOTS=( 1111 2222 3333 )
USER_AGENT='Mozilla/5.0 (X11; Linux x86_64; rv:51.0) Gecko/20100101 Firefox/51.0'
COOKIE="kinky.sess=s%3B3tVPW2CRpNrmauRV9q9u5IHmh6EfFK9n.jk1gsRcsvyPMaUgHcidHMy132RGjrfS71bbqp%2B2MI9I"
MOVIEFOLDER='C:\kink\'
DOWNLOADED_QUALITY='_hi' # empty for hd, _hi, _md, _lo

getRating() {
	shoot="$1"
	rating=$(curl -s -A "$USER_AGENT" -b "$COOKIE" "https://www.kink.com/api/ratings/$shoot")
	rating=$(echo $rating | jq -r '.avgRating')
	echo "a=$rating; scale=1; a/1" | bc -l
}

parse () {
	html="$1"
	shoot="$2"

	title=$(echo "$download_html" | grep 'class="shoot-title"' | sed -e 's/<[^>]*>//g' | sed 's/  */ /g' | sed 's/[ \t]*$//')

	#head
	echo '<!doctype html>'
	echo ''
	echo "<html>"
	echo "<head>"
	echo "	<title>$shoot - $title</title>"
	echo "	<style type='text/css'>body{background:black;color:white;text-align:center;padding:10px}body > *{display:inline-block;margin:20px;vertical-align:top}a:link,a:visited{color:grey}.shoot-title{display:block}.shoot-link{display:block;}.shoot-description{max-width:800px;display:block;margin:50px auto;text-align:left}.shoot-tags,.shoot-models{max-width:800px}.shoot-tags a{margin:5px 0 5px 5px}.shoot-images{text-align:center}.shoot-images img{margin:10px;vertical-align:middle;width:400px;}</style>"
	echo "</head>"
	echo "<body>"

	#title & link
	echo "	<h1 class='shoot-title'>$title</h1>"
	echo "	<a href='https://www.kink.com/shoot/${shoot}' class='shoot-id'>${shoot}</a>" #link

	#channel
	subsite=$(echo "$download_html" | grep 'subsite-logo' | grep -o 'class="subsite-logo [^"]*"' | cut -d '"' -f2 | sed -e 's/subsite-logo //g')
	echo "	<a href='https://www.kink.com/channel/$subsite' class='shoot-channel'>$subsite</a>"

	#date
	echo -n '	<p class="shoot-date">'
	echo -n $(echo "$download_html" | awk '/date: /,//' | sed -e 's/date: //g')
	echo '</p>'

	#length
	echo -n "	<p class='shoot-length'>"
	length=$(echo "$download_html" | grep -m 1 'data-length')
	length=$(echo $length | grep -o 'data-length="[^"]*"' | cut -d '"' -f2)
	length=$(echo "a=$length / 1000; scale=2; a/1" | bc -l)
	echo -n $(date -d@$length -u +%H:%M:%S)
	echo '</p>'

	#rating
	echo -n "	<p class='shoot-rating'>"
	echo -n $(getRating $shoot)
	echo '/5.0</p>'

	#filename
	shootname=$(echo "$download_html" | grep -E -m 1 "\/video\/h264(sd)?\/full\/.*$DOWNLOADED_QUALITY.*")
	echo -n "	<p class='shoot-link'>$MOVIEFOLDER$subsite\\"
	echo -n $(echo "$shootname" | sed -n 's/.*\/video\/h264\(sd\)\?\/full\/\([^}]*\)\?nva.*/\2/p' | sed 's/.$//')
	echo "</p>"

	#description
	descr=$(echo "$download_html" | awk '/"description" content="/,/\/>/')
	descr=$(echo $descr | sed -e 's/<meta name=[[:space:]]\?"description" content="/<p class="shoot-description">/g')
	echo "	$descr" | sed -e 's/\/>/<\/p>/g'

	#models
	echo '	<div class="shoot-models">'
	echo "$download_html" | awk '/<span class="names">/{flag=1;next}/<\/span>/{flag=0}flag' | sed -e 's/<a href="/<a href="https:\/\/www.kink.com/g' | tr -d ',' | grep -v -e '^$' | sed -e 's/^/		/'
	echo '	</div>'

	#tags
	echo '	<div class="shoot-tags">'
	echo "$download_html" | grep '^[[:space:]]*<a href="/tag/' | sed -e 's/<a href="/<a href="https:\/\/www.kink.com/g' | tr -d ',' | sed -e 's/^/		/'
	echo '	</div>'

	#images *(410,650,830)
	echo '	<div class="shoot-images">'
	echo "$download_html" | grep 'img src="https://cdnp.kink.com/imagedb/' | sed -e 's/\sdata-image-file="\/imagedb\/.*"//' | sed -e 's/\/410\//\/650\//' | sed -e 's/\/>/ alt="preview"\/>/' | sed -e 's/^/		/'
	echo '	</div>'

	echo '</body>'
	echo -n '</html>'
}

echo ""
folder="metadata"
mkdir -p "$folder"

for shoot in "${SHOOTS[@]}"; do
	shoot_url="https://www.kink.com/shoot/${shoot}"

	echo "Downloading & parsing ${shoot}"
	download_html=$(curl -s -A "$USER_AGENT" -b "$COOKIE" "$shoot_url" | tr -d '\t' )

	name=$(echo "$download_html" | grep 'class="shoot-title"' | awk '/<h1 class="shoot-title">/,/<\/h1>/' | sed -e 's/<[^>]*>//g' | tr -c '[[:alnum:]]_-' ' ' | sed 's/  */ /g' | sed 's/[ \t]*$//' ) #title
	parse "$download_html" "${shoot}" > "$folder/$shoot $name.html"
done

echo ""
