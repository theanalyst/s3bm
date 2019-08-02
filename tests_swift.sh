#!/bin/bash
set -x

if [ -x $(swift --version) ]; then
    echo 'swift cli not found! exiting'
    exit 1
fi

mkdir -p ~/swift-runs/

endpoint=${1:-https://localhost}
http_host=$(awk -F/ '{print $3}' <<<$endpoint)
export ST_USER=test:tester
export ST_KEY=testing
export ST_AUTH=$endpoint/auth
iosize=100M

for bsize in 64k 32k 16k 8k 4k 1k; do
    bucket=c`date +'%d%m%H%M'`
    swift post -m $bucket)
    if [ $? -ne 0 ]; then
        echo "unable to create container"
        exit 1
    fi

    eval `swift auth`
    cat <<EOF > /tmp/swift-$bucket.fio
[global]
ioengine=http
name=fiotest
direct=1
https=off
#http_verbose=2
http_mode=swift
http_host=$http_host
filename_format=/swift/v1/$bucket/obj.\$jobnum
unique_filename=1
group_reporting
bs=$bsize
size=$iosize
io_size=$iosize
direct=1
numjobs=24
http_swift_auth_token=$OS_AUTH_TOKEN
# With verify, this both writes and reads the object
[create1k]
rw=write
[read1k]
stonewall
rw=randread
[trim]
stonewall
rw=trim

EOF

    fio /tmp/swift-$bucket.fio --output ~/swift-runs/fio-$bsize-$bucket.out
done

bucket=c`date +'%d%m%H%M'`
swift post -m $bucket
if [ $? -ne 0 ]; then
    echo "unable to create container"
    exit 1
fi

eval `swift auth`
cat <<EOF > /tmp/swift-$bucket.fio
[global]
ioengine=http
name=fiotest
direct=1
https=off
#http_verbose=2
http_mode=swift
http_host=teuthida-6.ses.suse.de
filename_format=/swift/v1/$bucket/obj.\$jobnum
unique_filename=1
group_reporting
bsrange=1k-16k
size=$size
io_size=$iosize
direct=1
numjobs=24
http_swift_auth_token=$OS_AUTH_TOKEN
# With verify, this both writes and reads the object
[create1k]
rw=write
[read1k]
stonewall
rw=randread
[trim]
stonewall
rw=trim

EOF

fio /tmp/swift-$bucket.fio --output ~/swift-runs/fio-range-$bucket.out
