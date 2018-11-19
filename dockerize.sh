#mkdir /tmp/cult
for i in $(ldd bazel-bin/lisp/cult) 
do 
    if [ -e "$i" ]; 
	then 
		mkdir -p /tmp/cult/$(dirname $i)
		cp $i /tmp/cult/$i; 
	fi   
done

mkdir -p /tmp/cult/bin
mkdir -p /tmp/cult/usr/lib
cp bazel-bin/lisp/cult /tmp/cult/bin/
cp bazel-bin/lisp/liblisp.so /tmp/cult/usr/lib/
cp bazel-bin/types/libtypes.so /tmp/cult/usr/lib/

cd /tmp/cult
tar -czf /src/cult.tar.gz *
cd -
