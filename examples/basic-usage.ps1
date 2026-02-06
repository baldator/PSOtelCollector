# Example: Basic Usage of OtelCollector Module

# Import the module
Import-Module .\OtelCollector\OtelCollector.psd1 -Force

# Initialize the OTEL collector connection
Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "MyPowerShellApp" -ServiceVersion "1.0.0"

# Example 1: Send a simple log
Send-OtelLog -Message "Application started successfully" -Severity "INFO"

# Example 2: Send a log with attributes
Send-OtelLog -Message "User logged in" -Severity "INFO" -Attributes @{
    userId = "user123"
    userEmail = "user@example.com"
    loginMethod = "oauth"
}

# Example 3: Send an error log
Send-OtelLog -Message "Failed to connect to database" -Severity "ERROR" -Attributes @{
    errorCode = "DB_CONNECTION_FAILED"
    retryAttempt = "3"
}

# Example 4: Send a gauge metric
Send-OtelMetric -Name "memory.usage" -Value 1024 -Type "Gauge" -Unit "MB" -Attributes @{
    host = $env:COMPUTERNAME
}

# Example 5: Send a counter metric
Send-OtelMetric -Name "http.requests.total" -Value 1 -Type "Counter" -Unit "count" -Attributes @{
    method = "GET"
    endpoint = "/api/users"
    status = "200"
}

# Example 6: Send a histogram metric
Send-OtelMetric -Name "http.request.duration" -Value 245.5 -Type "Histogram" -Unit "ms" -Attributes @{
    method = "POST"
    endpoint = "/api/data"
}

# Example 7: Send a simple trace span
$traceId = New-OtelTraceId
$spanId = New-OtelSpanId

$startTime = Get-Date
Start-Sleep -Milliseconds 100
$endTime = Get-Date

Send-OtelTrace -Name "ProcessUserRequest" `
    -TraceId $traceId `
    -SpanId $spanId `
    -Kind "SERVER" `
    -StartTime $startTime `
    -EndTime $endTime `
    -Attributes @{
        "http.method" = "GET"
        "http.url" = "/api/users/123"
        "http.status_code" = "200"
    } `
    -Status "OK"

Write-Host "Telemetry data sent successfully!" -ForegroundColor Green
