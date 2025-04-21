repo=ashley-cui/citesting
version=v0.0.4


retries=180
retry_interval=15
for n in $(seq 1 $retries); do
  gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/$repo/commits/$version/check-runs \
  > runs.json
  cat runs.json | jq

#   status=`jq '.check_runs[] | select(.name=="Total Success").status' runs.json`
#   conclusion=`jq '.check_runs[] | select(.name=="Total Success").conclusion' runs.json`
  status=$(jq --raw-output '.check_runs[] | select(.name=="Image Push").status' runs.json)
  conclusion=$(jq --raw-output '.check_runs[] | select(.name=="Image Push").conclusion' runs.json)
  echo $status

  if [[ "$status" == "completed" ]] && [[ "$conclusion" == "success" ]]; then
    # exit 0
    echo "success"
    break
  elif [[ "$status" == "completed" ]] && [[ "$conclusion" != "success" ]]; then
    echo "::error:: Build did not succeed!"
    break
    # exit 1
  fi
  sleep $retry_interval
done


function get_images {
          arch=$1
          taskid=$2

          baseurl=https://api.cirrus-ci.com/v1/artifact/task
          for end in applehv.raw.zst hyperv.vhdx.zst qemu.qcow2.zst tar; do
                name="podman-machine.$arch.$end"
                echo "$baseurl/$taskid/$name"
                curl --retry 5 --retry-delay 8 --fail --location -O --output-dir artifacts --url "$baseurl/$taskid/image/$name"
          done
        }

mkdir artifacts

x86taskid=$(jq --raw-output '.check_runs[] | select(.name=="Image Build x86_64").external_id' runs.json)
aarchtaskid=$(jq --raw-output '.check_runs[] | select(.name=="Image Build aarch64").external_id' runs.json)


get_images x86_64 $x86taskid
get_images aarch64 $aarchtaskid

pushd artifacts
sha256sum * > shasums
popd


if [[ $pr != "" ]]; then
  echo "yes pr"
else
echo "hehwkdfh"
fi
