# Real-Time Data Pipeline Quick Start Script (PowerShell)
# This script helps new users get the pipeline running quickly on Windows

Write-Host "🚀 Real-Time Data Pipeline Quick Start" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is available
try {
    docker-compose --version | Out-Null
    Write-Host "✅ Docker Compose is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose is not available. Please install Docker Desktop with Compose." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check for required ports
Write-Host "🔍 Checking for port conflicts..." -ForegroundColor Yellow
$ports = @(8082, 9021, 8083, 8084, 9042, 5432, 9092, 2181)
foreach ($port in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        Write-Host "⚠️  Warning: Port $port is already in use" -ForegroundColor Yellow
    }
}
Write-Host ""

# Start the pipeline
Write-Host "🏗️  Starting the Real-Time Data Pipeline..." -ForegroundColor Cyan
Write-Host "This will download and start all required services..." -ForegroundColor White
Write-Host ""

try {
    docker-compose up -d
    Write-Host ""
    Write-Host "✅ All services started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏳ Waiting for services to initialize (this may take 2-3 minutes)..." -ForegroundColor Yellow
    
    # Wait for services with progress indicator
    for ($i = 1; $i -le 36; $i++) {
        Write-Host -NoNewline "."
        Start-Sleep 5
    }
    Write-Host ""
    Write-Host ""
    
    Write-Host "🎉 Pipeline is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Access the Web UIs:" -ForegroundColor Cyan
    Write-Host "├── 📊 Airflow (Pipeline Management): http://localhost:8082" -ForegroundColor White
    Write-Host "│   └── Username: admin | Password: yk3DNHKWbWCHnzQV" -ForegroundColor Gray
    Write-Host "├── 📈 Kafka Control Center: http://localhost:9021" -ForegroundColor White
    Write-Host "├── ⚡ Spark Master: http://localhost:8083" -ForegroundColor White
    Write-Host "└── 🔧 Spark Worker: http://localhost:8084" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Useful Commands:" -ForegroundColor Cyan
    Write-Host "├── Check status: docker-compose ps" -ForegroundColor White
    Write-Host "├── View logs: docker-compose logs [service-name]" -ForegroundColor White
    Write-Host "├── Stop pipeline: docker-compose down" -ForegroundColor White
    Write-Host "└── Restart: docker-compose restart" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Monitor Data Flow:" -ForegroundColor Cyan
    Write-Host "├── Kafka messages: docker exec broker kafka-console-consumer --bootstrap-server localhost:9092 --topic users_created --max-messages 5" -ForegroundColor White
    Write-Host "└── Cassandra data: docker exec cassandra cqlsh -e `"SELECT COUNT(*) FROM spark_streams.created_users;`"" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 For detailed documentation, see README.md and docs/WEB_UI_ACCESS.md" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎯 The pipeline will start generating user data automatically!" -ForegroundColor Green
    Write-Host "   Visit the Airflow UI to see the 'user_automation' DAG running." -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "❌ Failed to start the pipeline. Please check the error messages above." -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "├── Ensure Docker Desktop has enough memory allocated (8GB+ recommended)" -ForegroundColor White
    Write-Host "├── Check for port conflicts on ports 8082, 9021, 8083, 8084" -ForegroundColor White
    Write-Host "├── Try: docker-compose down; docker-compose up -d" -ForegroundColor White
    Write-Host "└── Check logs: docker-compose logs" -ForegroundColor White
    exit 1
}
