#!/bin/bash

# Real-Time Data Pipeline Quick Start Script
# This script helps new users get the pipeline running quickly

echo "🚀 Real-Time Data Pipeline Quick Start"
echo "======================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install it and try again."
    exit 1
fi

echo "✅ Docker is running"
echo "✅ Docker Compose is available"
echo ""

# Check for required ports
echo "🔍 Checking for port conflicts..."
PORTS=(8082 9021 8083 8084 9042 5432 9092 2181)
for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "⚠️  Warning: Port $port is already in use"
    fi
done
echo ""

# Start the pipeline
echo "🏗️  Starting the Real-Time Data Pipeline..."
echo "This will download and start all required services..."
echo ""

if docker-compose up -d; then
    echo ""
    echo "✅ All services started successfully!"
    echo ""
    echo "⏳ Waiting for services to initialize (this may take 2-3 minutes)..."
    
    # Wait for services with progress indicator
    for i in {1..36}; do
        echo -n "."
        sleep 5
    done
    echo ""
    echo ""
    
    echo "🎉 Pipeline is ready!"
    echo ""
    echo "🌐 Access the Web UIs:"
    echo "├── 📊 Airflow (Pipeline Management): http://localhost:8082"
    echo "│   └── Username: admin | Password: yk3DNHKWbWCHnzQV"
    echo "├── 📈 Kafka Control Center: http://localhost:9021"
    echo "├── ⚡ Spark Master: http://localhost:8083"
    echo "└── 🔧 Spark Worker: http://localhost:8084"
    echo ""
    echo "📋 Useful Commands:"
    echo "├── Check status: docker-compose ps"
    echo "├── View logs: docker-compose logs [service-name]"
    echo "├── Stop pipeline: docker-compose down"
    echo "└── Restart: docker-compose restart"
    echo ""
    echo "📊 Monitor Data Flow:"
    echo "├── Kafka messages: docker exec broker kafka-console-consumer --bootstrap-server localhost:9092 --topic users_created --max-messages 5"
    echo "└── Cassandra data: docker exec cassandra cqlsh -e \"SELECT COUNT(*) FROM spark_streams.created_users;\""
    echo ""
    echo "📖 For detailed documentation, see README.md and docs/WEB_UI_ACCESS.md"
    echo ""
    echo "🎯 The pipeline will start generating user data automatically!"
    echo "   Visit the Airflow UI to see the 'user_automation' DAG running."
    
else
    echo ""
    echo "❌ Failed to start the pipeline. Please check the error messages above."
    echo ""
    echo "🔧 Troubleshooting:"
    echo "├── Ensure Docker has enough memory allocated (8GB+ recommended)"
    echo "├── Check for port conflicts on ports 8082, 9021, 8083, 8084"
    echo "├── Try: docker-compose down && docker-compose up -d"
    echo "└── Check logs: docker-compose logs"
    exit 1
fi
