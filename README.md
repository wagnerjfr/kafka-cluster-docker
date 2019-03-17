# High availability with Kafka cluster using Docker containers

## Steps
### 1. Clone the project and cd into the folder
```
$ git clone https://github.com/wagnerjfr/kafka-cluster.git

$ cd kafka-cluster-docker-compose
```
### 2. Build the image
```
$ docker build -t kafka-oel7 .
```
### 3. Create the Docker network
```
docker create network kafkanet
```
### 4. Create the Zookeeper container
```
docker run -d --net kafkanet --name zookeeper -e ZOOKEEPER_HOST=zookeeper kafka-oel7:latest ./run_start_zookeeper.sh
```
### 5. Start the Kafka Servers containers
```
for N in {1..3};
do
  docker run -d --net kafkanet --name kafka$N \
  -e ZOOKEEPER_HOST=zookeeper -e ZOOKEEPER_PORT=2181 -e BROKER_ID=$N \
  kafka-oel7:latest \
  ./run_start_server.sh
done
```
### 6. Creat a Kafka topic
```
docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 3 --partitions 3 --topic MyTopic
```
To describe the topic, run:
```
docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh --describe --topic MyTopic  --zookeeper zookeeper:2181
```
### 7. Starting four Kafka Consumers
#### Consumer group with 3 containers
```
for N in {1..3};
do
  docker run -d --net kafkanet --name consumer$N kafka-oel7:latest \
  bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 \
  --topic MyTopic --from-beginning --consumer-property group.id=test
done
```
#### Unique consumer
```
docker run -d --net kafkanet --name consumer4 kafka-oel7:latest bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 --topic MyTopic --from-beginning
```
### 7. Starting two Kafka producers
```
for P in {1..2};
do
  docker run -d --net kafkanet --name producer$P -e MESG=Producer$P -e KAFKA_BROKER_LIST=kafka1:9092,kafka2:9092,kafka3:9092 -e TOPIC=MyTopic kafka-oel7:latest ./start_producer.sh
done
```
### 8. Some results
Coming soon

### 9. Clean up
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
