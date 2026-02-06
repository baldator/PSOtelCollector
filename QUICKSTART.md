# Quick Start Guide

Get started with the OtelCollector PowerShell module in 5 minutes!

## Step 1: Start the OTEL Collector

### Option A: Using Docker Compose (Recommended)

```bash
docker-compose up -d
```

This starts:
- OpenTelemetry Collector on ports 4317 (gRPC) and 4318 (HTTP)
- Jaeger UI on http://localhost:16686
- Prometheus on http://localhost:9090

### Option B: Using Standalone Docker

```bash
docker run -p 4318:4318 otel/opentelemetry-collector:latest
```

## Step 2: Import the Module

```powershell
Import-Module .\OtelCollector\OtelCollector.psd1
```

## Step 3: Initialize

```powershell
Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "MyApp"
```

## Step 4: Send Your First Telemetry

### Send a Log

```powershell
Send-OtelLog -Message "Hello from PowerShell!" -Severity "INFO"
```

### Send a Metric

```powershell
Send-OtelMetric -Name "requests.count" -Value 1 -Type "Counter"
```

### Send a Trace

```powershell
$traceId = New-OtelTraceId
$spanId = New-OtelSpanId

Send-OtelTrace -Name "MyOperation" -TraceId $traceId -SpanId $spanId
```

## Step 5: View Your Data

### View Traces
Open http://localhost:16686 in your browser to see traces in Jaeger.

### View Metrics
Open http://localhost:9090 in your browser to query metrics in Prometheus.

## Complete Example

```powershell
# Import and initialize
Import-Module .\OtelCollector\OtelCollector.psd1
Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "WebAPI"

# Start a traced operation
$traceId = New-OtelTraceId
$spanId = New-OtelSpanId
$startTime = Get-Date

# Log the start
Send-OtelLog -Message "Starting data processing" -Severity "INFO" `
    -TraceId $traceId -SpanId $spanId

# Do some work
Start-Sleep -Seconds 1

# Record metrics
Send-OtelMetric -Name "processing.duration" -Value 1000 -Type "Histogram" -Unit "ms"

# Complete the trace
$endTime = Get-Date
Send-OtelTrace -Name "ProcessData" `
    -TraceId $traceId `
    -SpanId $spanId `
    -StartTime $startTime `
    -EndTime $endTime `
    -Status "OK"

Write-Host "Telemetry sent! View in Jaeger at http://localhost:16686" -ForegroundColor Green
```

## Testing the Module

Run the included test script:

```powershell
.\test-module.ps1
```

## Examples

Check out the `examples` folder for more:
- `basic-usage.ps1` - Simple examples
- `advanced-tracing.ps1` - Distributed tracing
- `error-handling.ps1` - Error handling patterns

## Troubleshooting

### "Unable to connect" errors

Make sure the collector is running:
```bash
docker ps | grep otel
```

### View collector logs

```bash
docker-compose logs otel-collector
```

### Test collector endpoint

```powershell
Invoke-WebRequest -Uri "http://localhost:4318/v1/logs" -Method Post
```

## Next Steps

1. Explore the examples in the `examples` folder
2. Read the full documentation in `README.md`
3. Integrate into your PowerShell scripts
4. Configure exporters for your observability platform

## Common Patterns

### Wrap Functions with Tracing

```powershell
function Invoke-TracedOperation {
    param([string]$Name, [scriptblock]$Operation)

    $traceId = New-OtelTraceId
    $spanId = New-OtelSpanId
    $startTime = Get-Date

    try {
        $result = & $Operation
        Send-OtelTrace -Name $Name -TraceId $traceId -SpanId $spanId `
            -StartTime $startTime -EndTime (Get-Date) -Status "OK"
        return $result
    }
    catch {
        Send-OtelTrace -Name $Name -TraceId $traceId -SpanId $spanId `
            -StartTime $startTime -EndTime (Get-Date) `
            -Status "ERROR" -StatusMessage $_.Exception.Message
        throw
    }
}

# Use it
Invoke-TracedOperation -Name "DatabaseQuery" -Operation {
    # Your code here
}
```

### Automatic Metrics Collection

```powershell
function Measure-Operation {
    param([string]$Name, [scriptblock]$Operation)

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $result = & $Operation
        $stopwatch.Stop()

        Send-OtelMetric -Name "$Name.duration" `
            -Value $stopwatch.ElapsedMilliseconds `
            -Type "Histogram" -Unit "ms"

        Send-OtelMetric -Name "$Name.success" -Value 1 -Type "Counter"

        return $result
    }
    catch {
        $stopwatch.Stop()

        Send-OtelMetric -Name "$Name.duration" `
            -Value $stopwatch.ElapsedMilliseconds `
            -Type "Histogram" -Unit "ms"

        Send-OtelMetric -Name "$Name.error" -Value 1 -Type "Counter"

        throw
    }
}
```

## Support

For issues or questions, please refer to:
- Full documentation: `README.md`
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Example scripts: `examples/` folder
