
statdb=/home/hotel/statdb/
wget http://www.infobright.org/downloads/ice/infobright-3.3.1-x86_64-ice.tar.gz
tar zxvf infobright-3.3.1-x86_64-ice.tar.gz
mv infobright-3.3.1-x86_64 infobright
cd  infobright
./install-infobright.sh --datadir=$statdb/data --cachedir=$statdb/cache --config=$statdb/my.cnf --port=3307 --socket=/tmp/mysql3307.sock --user=mysql --group=mysql

