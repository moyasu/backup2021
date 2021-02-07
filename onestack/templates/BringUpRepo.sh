#! /bin/bash

harbor_service=(nginx harbor-jobservice harbor-core registryctl redis harbor-portal harbor-db registry harbor-log)
apt_service=(osh-repo)

retry=0
while ((retry<10)); do
  echo "--- Check Harbor Status ---"
  # Check and Bring up Harbor
  harbor_status="good"
  for service in ${harbor_service[@]};do
    container_id=`docker ps -aq --filter "name=${service}"`
    container_status=(`docker inspect ${container_id} | jq -r '.[0].State | .Status,.Running,.Health.Status' | xargs`)
    if [[ ${container_status[0]} == "exited" && ${container_status[1]} == "false" && ${container_status[2]} == "unhealthy" ]]; then
      echo "${service} is not Ready, Status is ${container_status[0]} and Running = ${container_status[1]} and Health is ${container_status[2]}"
      harbor_status="bad"
      cd /opt/harbor && docker-compose up -d
      break
    elif [[ ${container_status[0]} == "running" && ${container_status[1]} == "true" && ${container_status[2]} == "starting" ]]; then
      echo "${service} is starting..."
      harbor_status="starting"
    else
      echo "${service} status is ${container_status[0]} and Running = ${container_status[1]} and Health is ${container_status[2]}"
    fi
  done

  echo "--- Check repo Status ---"
  # Check and Bring up osh-repo
  repo_status="good"
  for service in ${apt_service[@]};do
    container_id=`docker ps -aq --filter "name=${service}"`
    container_status=(`docker inspect ${container_id} | jq -r '.[0].State | .Status,.Running' | xargs`)
    if [[ ${container_status[0]} == "exited" && ${container_status[1]} == "false" ]]; then
      echo "Need to Start ${service}! Status is ${container_status[0]} and Running = ${container_status[1]}"
      repo_status="bad"
      docker restart ${container_id}
    else
      echo "${service} status is ${container_status[0]} and Running = ${container_status[1]}"
    fi
  done

  if [[ ${harbor_status} == "good" && ${repo_status} == "good" ]]; then
    echo "Bring up Harbor and Repo Succeed!"
    break;
  else
    sleep 5
    ((++retry))
  fi
done
if [ ${retry} -eq 10 ]; then
  echo "Bring up Harbor and Repo Failed in 50s..."
  exit 1
fi
