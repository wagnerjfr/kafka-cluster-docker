# High availability with Kafka cluster using Docker containers

## Build image
```
docker build -t kafka-oel7 .
```
## Docker network
```
docker create network kafkanet
```
## ZOOKEPER
```
docker run -d --net kafkanet --name zookeeper -e ZOOKEEPER_HOST=zookeeper kafka-oel7:latest ./run_start_zookeeper.sh
```
## SERVERS
```
for N in {1..3};
do
  docker run -d --net kafkanet --name kafka$N \
  -e ZOOKEEPER_HOST=zookeeper -e ZOOKEEPER_PORT=2181 -e BROKER_ID=$N \
  kafka-oel7:latest \
  ./run_start_server.sh
done
```
## TOPIC
```
docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 3 --partitions 3 --topic MyTopic
```
## DESCRIBE TOPIC
```
docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh --describe --topic MyTopic  --zookeeper zookeeper:2181
```
## CONSUMERS
### Consumer group
```
for N in {1..3};
do
  docker run -d --net kafkanet --name consumer$N kafka-oel7:latest \
  bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 \
  --topic MyTopic --from-beginning --consumer-property group.id=test
done
```
### Unique consumer
```
docker run -d --net kafkanet --name consumer4 kafka-oel7:latest bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic MyTopic --from-beginning
```
## PRODUCERS
```
for P in {1..2};
do
  docker run -d --net kafkanet --name producer$P -e MESG=Producer$P -e KAFKA_BROKER_LIST=kafka1:9092,kafka2:9092,kafka3:9092 -e TOPIC=MyTopic kafka-oel7:latest ./start_producer.sh
done
```
## CLEAN UP
```
for N in {1..2};
  do docker stop producer$N && docker rm producer$N 
done
for N in {1..4};
  do docker stop consumer$N && docker rm consumer$N
done
for N in {1..3};
  do docker stop kafka$N && docker rm kafka$N
done
docker stop zookeeper && docker rm zookeeper
```
