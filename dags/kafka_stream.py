from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
import json
import uuid
import requests
from kafka import KafkaProducer

# Default arguments for the DAG
default_args = {
    'owner': 'admin',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=1)
}

# Create the DAG
dag = DAG(
    'kafka_user_streaming',
    default_args=default_args,
    description='Stream user data from Random User API to Kafka',
    schedule_interval=timedelta(minutes=1),  # Run every minute
    catchup=False,
    tags=['kafka', 'streaming', 'api']
)

def get_user_data():
    """Get random user data from API"""
    try:
        response = requests.get("https://randomuser.me/api/")
        data = response.json()
        user = data['results'][0]
        
        # Format the data
        formatted_data = {
            'id': str(uuid.uuid4()),
            'first_name': user['name']['first'],
            'last_name': user['name']['last'],
            'gender': user['gender'],
            'email': user['email'],
            'username': user['login']['username'],
            'phone': user['phone'],
            'address': f"{user['location']['street']['number']} {user['location']['street']['name']}, {user['location']['city']}, {user['location']['state']}, {user['location']['country']}",
            'post_code': str(user['location']['postcode']),
            'dob': user['dob']['date'],
            'registered_date': user['registered']['date'],
            'picture': user['picture']['medium'],
            'timestamp': datetime.now().isoformat()
        }
        return formatted_data
    except Exception as e:
        print(f"Error fetching user data: {e}")
        raise

def send_user_to_kafka(**context):
    """Send user data to Kafka"""
    try:
        # Get user data
        user_data = get_user_data()
        
        # Connect to Kafka (using service name from docker-compose)
        producer = KafkaProducer(
            bootstrap_servers=['broker:29092'],  # Internal Kafka address
            value_serializer=lambda x: json.dumps(x).encode('utf-8')
        )
        
        # Send to Kafka topic
        producer.send('users_created', user_data)
        producer.flush()  # Ensure message is sent
        producer.close()
        
        print(f"✅ Sent user data: {user_data['first_name']} {user_data['last_name']} ({user_data['email']})")
        return f"User {user_data['first_name']} {user_data['last_name']} sent to Kafka successfully"
        
    except Exception as e:
        print(f"❌ Error sending to Kafka: {e}")
        raise

# Define the task
stream_user_task = PythonOperator(
    task_id='stream_user_to_kafka',
    python_callable=send_user_to_kafka,
    dag=dag,
)

# Set task dependencies (only one task in this case)
stream_user_task
