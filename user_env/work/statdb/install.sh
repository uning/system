
source ../tools/config.sh
env_root=$SYS
statdb=/home/hotel/work/statdb/
cd $statdb

ver=3.3.1-x86_64-ice
pack=infobright-$ver.tar.gz
packdir=infobright-$ver
if [ ! -d infobright ] ; then
ne_download_untar $pack http://www.infobright.org/downloads/ice/$pack
if [ ! -d $packdir ] ; then
echo  "source dir not exists: $packdir"
exit
fi
mv $packdir infobright
fi
cd  infobright
sudo ./install-infobright.sh --datadir=$statdb/data --cachedir=$statdb/cache --config=$statdb/my.cnf --port=3307 --socket=/tmp/mysql3307.sock --user=hotel --
group=hotel

cat <<EOT
mysql -uroot -P3307  --socket=/tmp/mysql3307.sock 
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' IDENTIFIED BY '123456';
EOT
