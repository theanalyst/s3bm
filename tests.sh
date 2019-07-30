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
blocksize_range=1k-16k
size=1M
io_size=1M
direct=1

# With verify, this both writes and reads the object
[create1k]
numjobs=100
rw=write
[read1k]
stonewall
rw=randread
[trim]
stonewall
rw=trim

EOF

fio /tmp/fio-$bucket.fio --output ~/fio-runs/fio-run-$bucket.out

# poor man's Xattr tests
echo "logging time for writing 1000 objects with 2 attrs"
for i in {1..10}; do
    /usr/bin/time -o ~/fio-runs/time-$bucket.log -a parallel aws s3api put-object --endpoint=$endpoint --bucket $bucket --key test-$i-key{} --tagging foo=bar --metadata key=value ::: {1..1000}
done
