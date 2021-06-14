# Example Docker Compose project for Telegraf, InfluxDB and Grafana in the Kafka ecosystem

This an example project to show the TIG (Telegraf, InfluxDB and Grafana) and Kafka-Ecosystem stack.

![Example Screenshot](./example.png?raw=true "Example Screenshot")

## Start the stack with docker compose

```bash
$ docker-compose up
```

## Services and Ports

### Grafana
- URL: http://localhost:3000 
- User: admin 
- Password: admin 

### Telegraf
- Port: 8125 UDP (StatsD input)

### InfluxDB
- Port: 8086 (HTTP API)
- User: admin 
- Password: admin 
- Database: influx


Run the influx client:

```bash
$ docker-compose exec influxdb influx -execute 'SHOW DATABASES'
```

Run the influx interactive console:

```bash
$ docker-compose exec influxdb influx

Connected to http://localhost:8086 version 1.8.0
InfluxDB shell version: 1.8.0
>
```

[Import data from a file with -import](https://docs.influxdata.com/influxdb/v1.8/tools/shell/#import-data-from-a-file-with-import)

```bash
$ docker-compose exec -w /imports influxdb influx -import -path=data.txt -precision=s
```

## Run the PHP Example

The PHP example generates random example metrics. The random metrics are beeing sent via UDP to the telegraf agent using the StatsD protocol.

The telegraf agents aggregates the incoming data and perodically persists the data into the InfluxDB database.

Grafana connects to the InfluxDB database and is able to visualize the incoming data.

```bash
$ cd php-example
$ composer install
$ php example.php
Sending Random metrics. Use Ctrl+C to stop.
..........................^C
Runtime:	0.88382697105408 Seconds
Ops:		27 
Ops/s:		30.548965899738 
Killed by Ctrl+C
```

# Kafka - Kafka Connect - InfluxDB

Docker compose also starts the following kafka ecosystem containers:
- zookeeper
- kafka
- kafka connect
- schema-registry - 
- kafkacat        - 
- kafdrop         - For visualization

See blog post: https://rmoff.net/2020/01/23/notes-on-getting-data-into-influxdb-from-kafka-with-kafka-connect/ for details.

## JSON, using embedded Kafka Connect schema and a `map` field type for `tags`.

Load test data:

Produce data with schema and payload

```bash
bin/load-json-data.sh

# To produce one message
docker exec -i kafkacat kafkacat -b kafka:9092 -P -t json_01 <<EOF
{ "schema": { "type": "struct", "fields": [ { "field": "tags" , "type": "map", "keys": { "type": "string", "optional": false }, "values": { "type": "string", "optional": false }, "optional": false}, { "field": "stock", "type": "double", "optional": true } ], "optional": false, "version": 1 }, "payload": { "tags": { "host": "FOO", "product": "wibble" }, "stock": 500.0 } }
EOF
```

Produce a nested plain json without any schema. 
```bash
bin/load-json-stats-data.sh
```

Check data is there:
```bash
docker exec kafkacat kafkacat -b kafka:9092 -C -u -t json_01
docker exec kafkacat kafkacat -b kafka:9092 -C -u -t statistics-topic
```

Create the connector:
```bash
bin/register-connectors.sh
```

Check that the data's made it to InfluxDB:

```bash
$ docker exec -it influxdb influx -execute 'show measurements on "influx"'
name: measurements
name
----
json_01

$ docker exec -it influxdb influx -execute 'show tag keys on "influx"'
name: json_01
tagKey
------
host
product

$ docker exec -it influxdb influx -execute 'SELECT * FROM json_01 GROUP BY host, product;' -database "influx"
name: json_01
tags: host=FOO, product=wibble
time                stock
----                -----
1579779810974000000 500
1579779820028000000 500
1579779833143000000 500
-----
```

## AVRO

Load test data:

```bash
bin/load-avro-data.sh

# To produce one message
docker exec -i schema-registry /usr/bin/kafka-avro-console-producer --broker-list kafka:9092 --topic avro_01 --property schema.registry.url='http://schema-registry:18081' --property value.schema='{ "type": "record", "name": "myrecord", "fields": [ { "name": "tags", "type": { "type": "map", "values": "string" } }, { "name": "stock", "type": "double" } ] }' <<EOF
{ "tags": { "host": "FOO", "product": "wibble" }, "stock": 500.0 }
EOF
```

Check the data's there (I'm using kafkacat just to be contrary; you can use `kafka-avro-console-consumer` too):

```bash
$ docker exec -i kafkacat kafkacat -b kafka:9092 -C -t avro_01 -r http://schema-registry:18081 -s avro

{"tags": {"host": "FOO", "product": "wibble"}, "stock": 500.0}
```

Make sure that the connector's running

```bash
$ bin/validate-connectors.sh

# One can also use the following command:
$ curl -s "http://localhost:18083/connectors?expand=info&expand=status" | \
jq '. | to_entries[] | [ .value.info.type, .key, .value.status.connector.state,.value.status.tasks[].state,.value.info.config."connector.class"]|join(":|:")' | \
column -s : -t| sed 's/\"//g'| sort
sink  |  sink_influx_avro_01  |  RUNNING  |  RUNNING  |  io.confluent.influxdb.InfluxDBSinkConnector
```

Check that the data's made it to InfluxDB

```bash
$ docker exec -it influxdb influx -execute 'SELECT * FROM avro_01 GROUP BY host, product;' -database "influx"
name: avro_01
tags: host=FOO, product=wibble
time                stock
----                -----
1579781680622000000 500
-----
```
## KSQL

Here, we are creating kafka stream from the JSON.

**_statistics-topic (JSON) -> statistics-avro (formatted JSON) -> kafka sink connector (influxdb) -> Metrics (influxDB) -> Grafana (Visualization)**_

```bash
docker exec --interactive --tty ksqldb ksql http://localhost:8088

SET 'auto.offset.reset' = 'earliest';

CREATE STREAM STATISTICS_JSON_STREAM (`end.event_ts.ns` BIGINT, `operations` STRUCT<`creates` INT, `updates` INT, `deletes` INT, `reads` INT, `total` INT>, `start.event_ts.ns` BIGINT) 
        WITH (KAFKA_TOPIC='statistics-topic', VALUE_FORMAT='JSON');

SELECT * from STATISTICS_JSON_STREAM EMIT CHANGES LIMIT 1;

CREATE STREAM STATISTICS_AVRO_STREAM 
        WITH (VALUE_FORMAT='AVRO', KAFKA_TOPIC='statistics-avro') 
        AS SELECT `start.event_ts.ns`/1000  AS START_TS, `end.event_ts.ns`/1000 AS END_TS, `operations`->`creates` AS CREATES,  
        `operations`->`updates` AS UPDATES, `operations`->`deletes` AS DELETES, `operations`->`reads` AS READS,
        `operations`->`total` AS TOTAL FROM STATISTICS_JSON_STREAM;

SELECT * from STATISTICS_AVRO_STREAM EMIT CHANGES LIMIT 1;

```

Open the Grafana UI to see the graphs: http://localhost:3000
(Already created dashboard from a template)

## Kafkacat

GitHub: https://github.com/edenhill/kafkacat/

To see the `kafkacat` usage:
```bash
docker exec -i kafkacat kafkacat -h
```

## References

- Confluent Influx Connector: https://docs.confluent.io/kafka-connect-influxdb/current/index.html
- Robin Moffat Blog: https://rmoff.net/2020/01/23/notes-on-getting-data-into-influxdb-from-kafka-with-kafka-connect/
- Kafkacat: https://github.com/edenhill/kafkacat/
- Debezium:
  - Documentation: https://debezium.io/
  - Docker images: https://github.com/debezium/docker-images

## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.

