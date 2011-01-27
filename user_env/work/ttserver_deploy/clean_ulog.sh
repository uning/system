
my_loc=`dirname $0`
echo $my_loc
for f in `find $my_loc -ctime +1 -name *.ulog`
do
    echo rm $f
    rm $f
done
