#find "$1" -type l \
#  -lname '$2*' -printf \
#  'ln -nsf "$(readlink "%p"|sed s/$2/$3/)" "$(echo "%p"|sed s/$2/$3/)"\n'\
# > script.sh


# /dvr/recordings/(w4-0DXY80R)|(wd2tb-eads)|(sea4tb-Z300S2A7)|(sea2tb-1)/recordings/
#  ->
# /dvr/recordings/raw

#find ./Workaholics -type l -lname '/dvr/recordings/*' -printf \
#find /dvr/recordings/mythtv -type l -lname '/dvr/recordings/*' -printf \
# 'ln -nsf "$(readlink "%p" | sed '\''s/dvr\\/recordings\\/.*\\?\\/recordings/dvr\\/recordings\\/raw/'\'')" "$(echo "%p" | sed '\''s/dvr\\/recordings\\/.*\\?\\/recordings/dvr\\/recordings\\/raw/'\'')" \n'


# /dvr/recordings/wd2tb-eads/archive/
#  ->
# /dvr/recordings/archive

#find ./ -type l -lname '/dvr/recordings/*' -printf \
#find ./test -type l -lname '/dvr/recordings/*' -printf \
find /dvr/recordings/mythtv -type l -lname '/dvr/recordings*archive*' -printf \
 'ln -nsf "$(readlink "%p" | sed '\''s/dvr\\/recordings\\/.*\\?\\/\\?archive/dvr\\/recordings\\/raw/'\'')" "$(echo "%p" | sed '\''s/dvr\\/recordings\\/.*\\?\\/\\?archive/dvr\\/recordings\\/raw/'\'')" \n'
