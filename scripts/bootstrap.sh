#!/bin/bash
docker network create --attachable --driver overlay redis
set -e

export TAG=${1:-"latest"}

NUM_OF_SENTINELS=4
NUM_OF_REDIS=4
REDIS_SENTINEL_NAME="redis-sentinel"
REDIS_MASTER_NAME="redismaster"

echo "Starting redis-zero"
docker service create --network redis --name redis-zero redis:4.0.11-alpine

echo "Starting services"
docker stack deploy -c docker-compose.yml cache

until [ "$(docker run --rm --network redis khrost1905/redis-utils:latest \
	$REDIS_SENTINEL_NAME $REDIS_MASTER_NAME \
	value num-other-sentinels)" = "$((NUM_OF_SENTINELS - 1))" ]; do
	echo "Sentinels not set up yet - sleeping"
	sleep 2
done

until [ "$(docker run --rm --network redis khrost1905/redis-utils:latest \
	$REDIS_SENTINEL_NAME $REDIS_MASTER_NAME \
	value "num-slaves")" = "$NUM_OF_REDIS" ]; do
	echo "Slaves not set up yet - sleeping"
	sleep 2
done

old_master=$(docker run --rm --network redis khrost1905/redis-utils:latest \
	$REDIS_SENTINEL_NAME $REDIS_MASTER_NAME value ip)
echo "redis-zero ip is ${old_master}"

echo "Removing redis-zero"
docker service rm redis-zero

echo "All services are ready"
echo "Enter the redis with"
echo " **** docker run --rm --network redis -ti redis:4.0.11-alpine redis-cli -h redis ****"
echo "After that "AUTH <password>""

