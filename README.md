# Kafka cluster using Docker containers

## Steps
### 1. Clone the project and cd into the folder
```
$ git clone https://github.com/wagnerjfr/kafka-cluster-docker.git

$ cd kafka-cluster-docker
```
### 2. Build the image
```
$ docker build -t kafka-oel7 .
```
### 3. Create the Docker network
```
$ docker network create kafkanet
```
### 4. Create the Zookeeper container
```
$ docker run -d --net kafkanet --name zookeeper -e ZOOKEEPER_HOST=zookeeper \
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
$ docker ps -a
```
### 6. Creat a Kafka topic
Let's add a topic which will have replicas at all the 3 Kafka Brokers (Servers) and with 3 partitions.
```
$ docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh \
  --create --zookeeper zookeeper:2181 --replication-factor 3 --partitions 3 --topic MyTopic
```
Expected output:
```console
Created topic "MyTopic".
```
By running the command below, we can see how the partitions are distributed among the Kafka Brokers and who is the leader of each one:
```
$ docker run -t --rm --net kafkanet kafka-oel7:latest bin/kafka-topics.sh \
  --describe --topic MyTopic  --zookeeper zookeeper:2181
```
A similar output should appear:
```console
Topic:MyTopic	PartitionCount:3	ReplicationFactor:3	Configs:
	Topic: MyTopic	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3
	Topic: MyTopic	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1
	Topic: MyTopic	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2
```
From the output, we see that `Partition: 0` has ***kafka1*** as its leader. `Partition: 1` and `Partition: 2` have ***kafka2*** and ***kafka3*** as their leaders (respectively). The leader handles all read and write requests for the partition while the replicas (followers) passively replicate the leader.

Taking `Partition: 0` as example, we have two more information:
1. `Replicas: 1,2,3`: This shows that `Partition: 0` has replicas at *kafka1*, *kafka2* and *kafka3*, in our example.
2. `Isr: 1,2,3`: (Isr: in-sync replica) This shows that *kafka1*, *kafka2* and *kafka3* are synchronized with the partition's leader.

### 7. Starting four Kafka Consumers
#### Consumer group with 3 containers
Each consumer will consume from one of the 3 topic partitions.
```
for N in {1..3};
do
  docker run -d --net kafkanet --name consumer$N kafka-oel7:latest \
  bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 \
  --topic MyTopic --from-beginning --consumer-property group.id=test
done
```
#### Unique consumer
This consumer will consume from all the 3 topic partitions.
```
$ docker run -d --net kafkanet --name consumer4 \
  kafka-oel7:latest bin/kafka-console-consumer.sh \
  --bootstrap-server kafka1:9092,kafka2:9092,kafka3:9092 \
  --topic MyTopic --from-beginning
```
### 8. Starting two Kafka producers
Two kafka producers wil send 20 messages each.
```
for P in {1..2};
do
  docker run -d --net kafkanet --name producer$P \
  -e MESG=Producer$P -e KAFKA_BROKER_LIST=kafka1:9092,kafka2:9092,kafka3:9092 \
  -e TOPIC=MyTopic kafka-oel7:latest ./start_producer.sh
done
```
### 9. Some results
Let's check how consumer will receive the messages.

#### Consumer 1
`$ docker logs consumer1`

As expected, consumer1 consumes just some of the messages.
* Total: 15 messages
* Producer1: 9 messages
* Producer2: 6 messages
```console
Producer1 1
Producer1 2
Producer2 2
Producer1 3
Producer2 5
Producer1 9
Producer2 10
Producer1 11
Producer1 12
Producer1 13
Producer2 13
Producer2 15
Producer2 17
Producer1 18
Producer1 19
```
#### Consumer 2
`$ docker logs consumer2`

As expected, consumer2 consumes just some of the messages.
* Total: 9 messages
* Producer1: 5 messages
* Producer2: 4 messages
```console
Producer1 4
Producer2 4
Producer1 5
Producer2 9
Producer1 15
Producer1 16
Producer2 18
Producer1 20
Producer2 20
```
#### Consumer 3
`$ docker logs consumer3`

As expected, consumer3 consumes just some of the messages.
* Total: 16 messages
* Producer1: 6 messages
* Producer2: 10 messages
```console
Producer2 1
Producer2 3
Producer1 6
Producer2 6
Producer1 7
Producer2 7
Producer1 8
Producer2 8
Producer1 10
Producer2 11
Producer2 12
Producer1 14
Producer2 14
Producer2 16
Producer1 17
Producer2 19
```
#### Consumer 4
`$ docker logs consumer4`

As expected, consumer4 consumes all the messages.
* Total: 40 messages
* Producer1: 20 messages
* Producer2: 20 messages
```console
Producer1 1
Producer2 1
Producer1 2
Producer2 2
Producer1 3
Producer2 3
Producer1 4
Producer2 4
Producer1 5
Producer2 5
Producer1 6
Producer2 6
Producer1 7
Producer2 7
Producer1 8
Producer2 8
Producer1 9
Producer2 9
Producer1 10
Producer2 10
Producer1 11
Producer2 11
Producer1 12
Producer2 12
Producer1 13
Producer2 13
Producer1 14
Producer2 14
Producer1 15
Producer2 15
Producer1 16
Producer2 16
Producer1 17
Producer2 17
Producer1 18
Producer2 18
Producer1 19
Producer2 19
Producer1 20
Producer2 20
```
### 10. Clean up
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
