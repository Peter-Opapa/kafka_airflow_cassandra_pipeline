Write-Host "=== Testing Data Flow ===" -ForegroundColor Green

Write-Host "1. Triggering multiple Airflow DAG runs..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    docker exec airflow-webserver airflow dags trigger kafka_user_streaming
    Write-Host "Triggered DAG run $i"
    Start-Sleep -Seconds 2
}

Write-Host "2. Waiting for DAG execution..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

Write-Host "3. Checking Kafka messages..." -ForegroundColor Yellow
docker exec broker kafka-console-consumer --bootstrap-server localhost:9092 --topic users_created --from-beginning --max-messages 10

Write-Host "4. Submitting Spark job for Cassandra processing..." -ForegroundColor Yellow
# Kill any existing Spark jobs first
docker exec spark-master pkill -f "spark-submit" 2>$null

# Submit the main Spark job
Start-Job -ScriptBlock {
    docker exec spark-master /opt/bitnami/spark/bin/spark-submit `
        --master spark://spark-master:7077 `
        --packages "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0,com.datastax.spark:spark-cassandra-connector_2.12:3.4.0" `
        --conf "spark.cassandra.connection.host=cassandra" `
        --conf "spark.cassandra.connection.port=9042" `
        /opt/bitnami/spark/apps/spark_stream.py
}

Write-Host "5. Waiting for Spark processing..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "6. Checking Cassandra data..." -ForegroundColor Yellow
docker exec cassandra cqlsh --request-timeout=60 -e "SELECT COUNT(*) FROM spark_streams.created_users;"

Write-Host "7. Showing sample records..." -ForegroundColor Yellow
docker exec cassandra cqlsh --request-timeout=60 -e "SELECT first_name, last_name, email FROM spark_streams.created_users LIMIT 10;"

Write-Host "=== Test Complete ===" -ForegroundColor Green
