# Kafka cluster using Docker containers

## Steps
### 1. Clone the project and cd into the folder
```
git clone https://github.com/wagnerjfr/kafka-cluster.git

cd kafka-cluster-docker-compose
```
### 2. Build the image
```
docker build -t kafka-oel7 .
```
### 3. Create the Docker network
```
docker create network kafkanet
```
### 4. Create the Zookeeper container
```
docker run -d --net kafkanet --name zookeeper -e ZOOKEEPER_HOST=zookeeper \
  kafka-oel7:latest ./run_start_zookeeper.sh
```
### 5. Start the Kafka Servers containers
Run the commnd below to start the containers:
```
for N in {1..3};
do
  docker run -d --net kafkanet --name kafka$N \
  -e ZOOKEEPER_HOST=zookeeper -e ZOOKEEPER_PORT=2181 -e BROKER_ID=$N \
  kafka-oel7:latest \
  ./run_start_server.sh
done
```
Check whether the containers are up and running:
```
docker ps -a
```
### 6. Creat a Kafka topic
Let's add a topic which will have replicas at all the 3 Kafka Brokers (Servers) and with 3 partitions.
```
docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh \
  --create --zookeeper zookeeper:2181 --replication-factor 3 --partitions 3 --topic MyTopic
```
Expected output:
```console
Created topic "MyTopic".
```
By running the command below, we can see how the partitions are distributed among the Kafka Brokers and who is the leader of each one:
```
docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh \
  --describe --topic MyTopic  --zookeeper zookeeper:2181
```
A similar output should appear:
```console
Topic:MyTopic	PartitionCount:3	ReplicationFactor:3	Configs:
	Topic: MyTopic	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3
	Topic: MyTopic	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1
	Topic: MyTopic	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2
```
From the output, we see that `Partition: 0` has kafka1 as its leader. `Partition: 1` and `Partition: 2` have kafka2 and kafka3 as their leaders (respectively). The leader handles all read and write requests for the partition while the replicas (followers) passively replicate the leader.

Taking `Partition: 0` as example, we have two more information:
1. `Replicas: 1,2,3`: This shows that `Partition: 0` has replicas at kafka1, kafka2 and kafka3, in our example.
2. `Isr: 1,2,3`: (Isr: in-sync replica) This shows that kafka1, kafka2 and kafka3 are synchronized with the partition's leader.

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
docker run -d --net kafkanet --name consumer4 \
  kafka-oel7:latest bin/kafka-console-consumer.sh \
  --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 \
  --topic MyTopic --from-beginning
```
### 7. Starting two Kafka producers
```
for P in {1..2};
do
  docker run -d --net kafkanet --name producer$P \
  -e MESG=Producer$P -e KAFKA_BROKER_LIST=kafka1:9092,kafka2:9092,kafka3:9092 \
  -e TOPIC=MyTopic kafka-oel7:latest ./start_producer.sh
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
