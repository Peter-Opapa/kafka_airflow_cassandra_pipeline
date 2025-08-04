#!/usr/bin/env python3
import json
import time
from kafka import KafkaConsumer
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
import uuid
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def connect_to_cassandra():
    """Connect to Cassandra"""
    try:
        cluster = Cluster(['cassandra'], port=9042)
        session = cluster.connect()
        
        # Create keyspace and table if they don't exist
        session.execute("""
            CREATE KEYSPACE IF NOT EXISTS spark_streams
            WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}
        """)
        
        session.execute("USE spark_streams")
        
        session.execute("""
            CREATE TABLE IF NOT EXISTS created_users (
                id UUID PRIMARY KEY,
                first_name TEXT,
                last_name TEXT,
                gender TEXT,
                email TEXT,
                username TEXT,
                phone TEXT,
                address TEXT,
                post_code TEXT,
                dob TIMESTAMP,
                registered_date TIMESTAMP,
                picture TEXT,
                timestamp TIMESTAMP
            )
        """)
        
        # Prepare the insert statement once
        insert_stmt = session.prepare("""
            INSERT INTO created_users (
                id, first_name, last_name, gender, email, username,
                phone, address, post_code, dob, registered_date,
                picture, timestamp
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """)
        
        logger.info("Connected to Cassandra successfully")
        return session, insert_stmt
    except Exception as e:
        logger.error(f"Error connecting to Cassandra: {e}")
        raise

def process_kafka_messages():
    """Process Kafka messages and write to Cassandra"""
    # Connect to Cassandra
    session, insert_stmt = connect_to_cassandra()
    
    # Connect to Kafka
    consumer = KafkaConsumer(
        'users_created',
        bootstrap_servers=['broker:29092'],
        value_deserializer=lambda x: json.loads(x.decode('utf-8')),
        group_id='python_consumer_group_v2',  # New group to start fresh
        auto_offset_reset='latest',  # Start from latest messages
        enable_auto_commit=True,
        consumer_timeout_ms=60000  # Timeout after 60 seconds of no messages
    )
    
    logger.info("Started consuming from Kafka...")
    
    try:
        for message in consumer:
            try:
                user_data = message.value
                first_name = user_data.get('first_name', 'Unknown')
                last_name = user_data.get('last_name', 'Unknown')
                logger.info("Processing user: %s %s", first_name, last_name)
                
                # Insert into Cassandra
                try:
                    # Parse timestamps safely
                    dob_parsed = None
                    if user_data.get('dob'):
                        try:
                            dob_parsed = datetime.fromisoformat(user_data['dob'].replace('Z', '+00:00'))
                        except:
                            pass
                    
                    registered_parsed = None
                    if user_data.get('registered_date'):
                        try:
                            registered_parsed = datetime.fromisoformat(user_data['registered_date'].replace('Z', '+00:00'))
                        except:
                            pass
                    
                    timestamp_parsed = None
                    if user_data.get('timestamp'):
                        try:
                            timestamp_parsed = datetime.fromisoformat(user_data['timestamp'].replace('Z', '+00:00'))
                        except:
                            pass

                    session.execute(insert_stmt, (
                        uuid.UUID(user_data['id']),
                        user_data.get('first_name'),
                        user_data.get('last_name'),
                        user_data.get('gender'),
                        user_data.get('email'),
                        user_data.get('username'),
                        user_data.get('phone'),
                        user_data.get('address'),
                        user_data.get('post_code'),
                        dob_parsed,
                        registered_parsed,
                        user_data.get('picture'),
                        timestamp_parsed
                    ))
                    
                    logger.info("Successfully inserted user: %s %s", first_name, last_name)
                    
                except Exception as e:
                    logger.error("Error inserting to Cassandra: %s", str(e))
                    logger.error("User data: %s", user_data)
                
                logger.info(f"✅ Inserted user {user_data.get('first_name')} {user_data.get('last_name')} into Cassandra")
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                continue
                
    except KeyboardInterrupt:
        logger.info("Stopping consumer...")
    finally:
        consumer.close()
        session.shutdown()

if __name__ == "__main__":
    process_kafka_messages()
