#!/bin/bash
set -ex
endpoint=${1:-https://localhost:8000}
http_host=$(awk -F/ '{print $3}' <<<$endpoint)
mkdir -p ~/fio-runs/
bucket=fio`date +'%d%m%H%M'`
aws s3api create-bucket --bucket $bucket --endpoint=$endpoint

cat <<EOF> /tmp/fio-$bucket.fio
[global]
ioengine=http
name=fiotest
direct=1
https=off
#http_verbose=2
http_mode=s3
http_s3_key=secret1
http_s3_keyid=access1
http_host=$http_host
filename_format=/$bucket/obj.$jobnum
http_s3_region=eu-central-1
unique_filename=1
group_reporting
size=10M
io_size=10M
direct=1
numjobs=1000

# With verify, this both writes and reads the object
[create1k]
rw=write
bs=1k
[create4k]
rw=write
bs=4k
[create8k]
rw=write
bs=8k
[create16k]
rw=write
bs=16k
[create256k]
rw=write
bs=256k
[create1M]
rw=write
bs=1M


[read1k]
stonewall
rw=read
bs=1k
[read4k]
rw=read
bs=4k
[read8k]
rw=read
bs=8k
[read16k]
rw=read
bs=16k
[read256k]
rw=read
bs=256k
[read1M]
rw=read
bs=1M




[trim]
stonewall
rw=trim

EOF

fio /tmp/fio-$bucket.fio --output ~/fio-runs/fio-run-$bucket.out

# poor man's Xattr tests
echo "logging time for writing 1000 objects with 2 attrs"
for i in {1..10}; do
    /usr/bin/time -o ~/fio-runs/time-$bucket.log -a parallel aws s3api put-object --endpoint=$endpoint --bucket $bucket --key test-$i-key{} --tagging foo=bar --metadata key=value ::: {1..1000} > /dev/null
done
