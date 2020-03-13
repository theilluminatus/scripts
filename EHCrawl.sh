#!/bin/bash
# EHCrawl
# This scripts downloads every gallery page (metadata) and torrent on a specific e(x)-hentai url. Missing torrents are logged.

LIST_LINK="https://exhentai.org/" # link to a gallery page
MODE="exhentai" # either e-hentai or exhentai, must match LIST_LINK
COOKIE="sk=hash; ipb_member_id=int; ipb_pass_hash=hash" # has to contain: ipb_member_id, ipb_member_hash (and sk)
FOLDER="./eh"


save() {
    # TODO: download thumbnails as well
    wget $1 -P "$2" \
        --header="Cookie: $COOKIE" \
        --timestamping \
        --random-wait \
        −q -N -nd -p -k -r \
        --include-directories="t,z" \
        -R js \
        -e robots=off \
        --compression=auto
        # -q -nv -d
}

download () {
	curl -s -b "$COOKIE" "$1" > "$2"
}

downloadhtml () {
    echo $(curl -s -b "$COOKIE" "$1") | sed "s/'/\"/g"
}


echo -e "# Getting galleries"
list_html=$(downloadhtml $LIST_LINK)
list_items=($(echo $list_html | grep -o "https://$MODE.org/g/[^\"]*/"))
echo -e "## ${#list_items[@]} Galleries found"

for gallery_link in "${list_items[@]}"; do

    echo -e "## Getting next gallery $gallery_link"

    id=$(echo $gallery_link | sed -e "s/https:\/\/$MODE.org\/g\///g" | cut -d '/' -f1)
    token=$(echo $gallery_link | sed -e "s/https:\/\/$MODE.org\/g\///g" | cut -d '/' -f2)

    if [ -d "$FOLDER/$id/" ]; then
        echo -e "### Gallery $id already downloaded"
        continue
    fi

    gallery_html=$(downloadhtml $gallery_link)
    name=$(echo $gallery_html | grep -o '<h1 id="gn">[^<]*<' | cut -c 13- | sed 's/.$//')

    echo -e "### Gallery $name found"

    mkdir -p "$FOLDER/$id/"
    save $gallery_link "$FOLDER/$id/preview"

    echo -e "### Downloaded preview"

    if echo $gallery_html | grep -q "Torrent Download ( 0 )" ; then
        echo -e "### No torrents found"
        touch "./$FOLDER/$id/notorrent"
    else

        echo -e "### Getting torrents"

        torrents_link="https://$MODE.org/gallerytorrents.php?gid=$id&t=$token"
        torrents_html=$(downloadhtml $torrents_link )
        IFS=$'\n'
        torrents_list=($(echo $torrents_html | tr -d '\011\012\015' | grep -o '<table[^#]*#'))

        echo -e "#### ${#torrents_list[@]} Torrents found"

        best_link=""
        best_name=""
        best_seeders=0
        for torrent in "${torrents_list[@]}"; do

            torrent_link=$(echo $torrent | grep -o "https://$MODE.org/torrent/[^\"]*\.torrent?' | sed 's/.$//')
            torrent_name=$(echo $torrent | grep -o 'return false">[^<]*<' | cut -c 15- | sed 's/.$//' )
            torrent_seeders=$(echo $torrent | grep -o 'Seeds:</span> [^<]*<' | cut -c 15- | sed 's/.$//')

            echo "##### Found $torrent_name with $torrent_seeders seeders at $torrent_link"

            if [ "$torrent_seeders" -ge "$best_seeders" ]; then
                best_link=$torrent_link
                best_name=$torrent_name
                best_seeders=$torrent_seeders
            fi

        done

        echo -e "#### Downloading best torrent $best_name with $best_seeders seeders"
        download $best_link "$FOLDER/$id/$torrent_name.torrent"
    fi

done
