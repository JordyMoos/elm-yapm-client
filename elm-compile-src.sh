#/bin/bash

# "Cleaning" the screen so i can see where this output stars
for i in {1..30}
do
    echo ""
done

ls -R ./src/ | awk '
/:$/&&f{s=$0;f=0}
/:$/&&!f{sub(/:$/,"");s=$0;f=1;next}
NF&&f{ print s"/"$0 }' | grep elm | xargs elm-make --output /dev/null
