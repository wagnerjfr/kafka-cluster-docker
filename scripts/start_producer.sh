#!/bin/bash

for N in {1..20};
do
  echo $MESG $N | bin/kafka-console-producer.sh --broker-list $KAFKA_BROKER_LIST --topic $TOPIC
  sleep 1
done
