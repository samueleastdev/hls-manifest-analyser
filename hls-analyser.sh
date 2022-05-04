if [ -z "$1" ]
then
      echo "Url is empty provide the main manifest url"
      exit
fi

if [ -z "$2" ]
then
      echo "An Output folder name is required"
      exit
fi

URL=$1
MANIFESTNAME=$(basename $URL)
LOCAL_FOLDER=$2
mkdir -p $LOCAL_FOLDER 2> /dev/null
LOCAL_MANIFEST="$LOCAL_FOLDER/$MANIFESTNAME"
URLPREF=$(dirname $URL)

# Download main manifest
wget $URL -O  $LOCAL_MANIFEST

# Empty files
cat /dev/null > all_playlists.txt
cat /dev/null > all_subs.txt

# Get all renditions
cat $LOCAL_MANIFEST | grep "#EXT-X-STREAM-INF:" -A1 | grep m3u8 | tr -d '\r' > all_playlists.txt
cat $LOCAL_MANIFEST | grep "#EXT-X-IMAGE-STREAM-INF" | sed -e 's_.*URI=\"\(.*\)\".*_\1_' | tr -d '\r' >> all_playlists.txt
cat $LOCAL_MANIFEST | grep "#EXT-X-MEDIA.*URI" | sed -e 's_.*URI=\"\(.*\)\".*_\1_' | tr -d '\r' >> all_playlists.txt
cat $LOCAL_MANIFEST | grep "#EXT-X-I-FRAME-STREAM-INF.*URI" | sed -e 's_.*URI=\"\(.*\)\".*_\1_' | tr -d '\r' >> all_playlists.txt

while read playList; do

    PL_URL=$URLPREF/$playList

    mkdir -p "$LOCAL_FOLDER/${playList%/*}" 2> /dev/null

    PL_NAME=$(basename $playList)
    LOCAL_PL="$LOCAL_FOLDER/$PL_NAME"

    # Download playlists
    wget $PL_URL -O "$LOCAL_FOLDER/${playList%/*}/$PL_NAME"
    
    if grep -q webvtt "$LOCAL_FOLDER/${playList%/*}/$PL_NAME"; then
        cat "$LOCAL_FOLDER/${playList%/*}/$PL_NAME" | grep webvtt  >> all_subs.txt
        while read subs; do
            URLPREF2=$(dirname $PL_URL)
            wget "$URLPREF2/$subs" -O "$LOCAL_FOLDER/${playList%/*}/$subs"
        done < all_subs.txt
        # Clear subs
        cat /dev/null > all_subs.txt
    fi

done < all_playlists.txt