# OtelCollector PowerShell Module

A comprehensive PowerShell module for sending logs, metrics, and traces to OpenTelemetry collectors using the OTLP/HTTP JSON protocol.

## Features

- **Logs**: Send structured log entries with severity levels and custom attributes
- **Metrics**: Send gauge, counter, and histogram metrics with units and attributes
- **Traces**: Create distributed traces with parent-child span relationships
- **Correlation**: Link logs to traces for complete observability
- **Easy Configuration**: Simple initialization with service identification
- **Standards Compliant**: Implements OpenTelemetry Protocol (OTLP) over HTTP/JSON

## Installation

### Option 1: Manual Installation

1. Copy the `OtelCollector` folder to one of your PowerShell module paths:
   ```powershell
   $env:PSModulePath -split ';'
   ```

2. Common locations:
   - `C:\Users\<Username>\Documents\WindowsPowerShell\Modules`
   - `C:\Program Files\WindowsPowerShell\Modules`

### Option 2: Import Directly

```powershell
Import-Module .\OtelCollector\OtelCollector.psd1
```

## Prerequisites

- PowerShell 5.1 or higher
- Access to an OpenTelemetry collector endpoint
- Network connectivity to the OTEL collector

## Quick Start

```powershell
# Import the module
Import-Module OtelCollector

# Initialize connection to your OTEL collector
# Option 1: Using parameters
Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "MyApp"

# Option 2: Using environment variables (OTEL_ENDPOINT and SERVICE_NAME)
$env:OTEL_ENDPOINT = "http://localhost:4318"
$env:SERVICE_NAME = "MyApp"
Initialize-OtelCollector

# Send a log
Send-OtelLog -Message "Application started" -Severity "INFO"

# Send a metric
Send-OtelMetric -Name "cpu.usage" -Value 45.5 -Type "Gauge" -Unit "percent"

# Send a trace
$traceId = New-OtelTraceId
$spanId = New-OtelSpanId
Send-OtelTrace -Name "ProcessRequest" -TraceId $traceId -SpanId $spanId
```

## Functions

### Initialize-OtelCollector

Configures the connection to your OpenTelemetry collector.

```powershell
Initialize-OtelCollector `
    -Endpoint "http://localhost:4318" `
    -ServiceName "MyApp" `
    -ServiceVersion "1.0.0" `
    -Headers @{ "Authorization" = "Bearer token123" } `
    -ResourceAttributes @{ "environment" = "production" }
```

**Parameters:**
- `Endpoint`: The base URL of your OTEL collector. If not provided, uses `OTEL_ENDPOINT` environment variable.
- `ServiceName`: Your application/service name. If not provided, uses `SERVICE_NAME` environment variable.
- `ServiceVersion`: Version string (default: "1.0.0")
- `Headers`: Additional HTTP headers for authentication
- `ResourceAttributes`: Additional resource attributes for all telemetry

**Environment Variables:**
You can configure the collector using environment variables instead of parameters:
- `OTEL_ENDPOINT`: The base URL of your OTEL collector (e.g., `http://localhost:4318`)
- `SERVICE_NAME`: Your application/service name

Parameters take priority over environment variables.

### Send-OtelLog

Sends a structured log entry to the collector.

```powershell
Send-OtelLog `
    -Message "User action completed" `
    -Severity "INFO" `
    -Attributes @{ userId = "123"; action = "login" } `
    -TraceId $traceId `
    -SpanId $spanId
```

**Parameters:**
- `Message` (required): The log message
- `Severity`: TRACE, DEBUG, INFO, WARN, ERROR, or FATAL (default: INFO)
- `Attributes`: Custom key-value pairs
- `TraceId`: Optional trace ID for correlation
- `SpanId`: Optional span ID for correlation

**Severity Levels:**
- `TRACE` - Most detailed information
- `DEBUG` - Detailed debugging information
- `INFO` - General informational messages
- `WARN` - Warning messages
- `ERROR` - Error messages
- `FATAL` - Critical errors

### Send-OtelMetric

Sends a metric data point to the collector.

```powershell
Send-OtelMetric `
    -Name "http.request.duration" `
    -Value 125.5 `
    -Type "Histogram" `
    -Unit "ms" `
    -Attributes @{ method = "GET"; status = "200" }
```

**Parameters:**
- `Name` (required): Metric name (use dotted notation)
- `Value` (required): Numeric value
- `Type`: Gauge, Counter, or Histogram (default: Gauge)
- `Unit`: Unit of measurement (e.g., "ms", "bytes", "count")
- `Attributes`: Custom dimensions for the metric

**Metric Types:**
- `Gauge` - Current value (e.g., memory usage, temperature)
- `Counter` - Cumulative value (e.g., request count)
- `Histogram` - Distribution of values (e.g., request duration)

### Send-OtelTrace

Sends a trace span to the collector.

```powershell
$startTime = Get-Date
# ... do some work ...
$endTime = Get-Date

Send-OtelTrace `
    -Name "DatabaseQuery" `
    -TraceId $traceId `
    -SpanId $spanId `
    -ParentSpanId $parentSpanId `
    -Kind "CLIENT" `
    -StartTime $startTime `
    -EndTime $endTime `
    -Attributes @{ "db.system" = "postgresql"; "db.statement" = "SELECT * FROM users" } `
    -Status "OK"
```

**Parameters:**
- `Name` (required): Span name describing the operation
- `TraceId`: Trace ID (auto-generated if not provided)
- `SpanId`: Span ID (auto-generated if not provided)
- `ParentSpanId`: Parent span ID for nested spans
- `Kind`: INTERNAL, SERVER, CLIENT, PRODUCER, or CONSUMER
- `StartTime`: Start timestamp (default: current time)
- `EndTime`: End timestamp (default: current time)
- `Attributes`: Custom span attributes
- `Status`: OK, ERROR, or UNSET (default: OK)
- `StatusMessage`: Optional message for ERROR status

**Span Kinds:**
- `INTERNAL` - Internal operation
- `SERVER` - Server-side request handler
- `CLIENT` - Client-side request
- `PRODUCER` - Message producer
- `CONSUMER` - Message consumer

### New-OtelTraceId

Generates a new 32-character hexadecimal trace ID.

```powershell
$traceId = New-OtelTraceId
```

### New-OtelSpanId

Generates a new 16-character hexadecimal span ID.

```powershell
$spanId = New-OtelSpanId
```

## Common Use Cases

### 1. Application Monitoring

```powershell
# Initialize
Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "WebAPI"

# Log important events
Send-OtelLog -Message "API server started" -Severity "INFO"

# Track request metrics
Send-OtelMetric -Name "http.requests.total" -Value 1 -Type "Counter" `
    -Attributes @{ endpoint = "/api/users"; method = "GET" }

# Monitor performance
Send-OtelMetric -Name "http.request.duration" -Value 87.3 -Type "Histogram" -Unit "ms"
```

### 2. Distributed Tracing

```powershell
# Create a parent trace
$traceId = New-OtelTraceId
$parentSpanId = New-OtelSpanId

# Parent operation
Send-OtelTrace -Name "ProcessOrder" -TraceId $traceId -SpanId $parentSpanId

# Child operation
$childSpanId = New-OtelSpanId
Send-OtelTrace -Name "ValidatePayment" `
    -TraceId $traceId `
    -SpanId $childSpanId `
    -ParentSpanId $parentSpanId
```

### 3. Error Tracking

```powershell
try {
    # Your code here
    throw "Something went wrong"
}
catch {
    Send-OtelLog `
        -Message "Operation failed: $($_.Exception.Message)" `
        -Severity "ERROR" `
        -Attributes @{
            errorType = $_.Exception.GetType().Name
            stackTrace = $_.ScriptStackTrace
        }
}
```

### 4. Performance Monitoring

```powershell
$startTime = Get-Date

# Perform operation
Start-Sleep -Seconds 2

$duration = ((Get-Date) - $startTime).TotalMilliseconds

Send-OtelMetric -Name "operation.duration" `
    -Value $duration `
    -Type "Histogram" `
    -Unit "ms" `
    -Attributes @{ operation = "data.processing" }
```

## Setting up an OTEL Collector

### Using Docker

```bash
docker run -p 4318:4318 -p 4317:4317 \
  -v $(pwd)/otel-collector-config.yaml:/etc/otel-collector-config.yaml \
  otel/opentelemetry-collector:latest \
  --config=/etc/otel-collector-config.yaml
```

### Basic collector configuration (otel-collector-config.yaml):

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:

exporters:
  logging:
    loglevel: debug
  # Add your exporters here (Jaeger, Prometheus, etc.)

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
```

## Examples

See the `examples` folder for complete working examples:

- `basic-usage.ps1` - Simple examples of logs, metrics, and traces
- `advanced-tracing.ps1` - Distributed tracing with parent-child spans
- `error-handling.ps1` - Error handling and retry patterns with telemetry

## Best Practices

1. **Initialize Once**: Call `Initialize-OtelCollector` at the start of your script
2. **Use Trace IDs**: Generate trace IDs for operations you want to track end-to-end
3. **Add Context**: Use attributes to add relevant context to all telemetry
4. **Consistent Naming**: Use consistent naming conventions (e.g., `http.request.duration`)
5. **Correlate Logs**: Use TraceId and SpanId to correlate logs with traces
6. **Handle Errors**: Wrap telemetry calls in try-catch if collector availability is uncertain

## Troubleshooting

### Connection Errors

If you receive connection errors, verify:
- OTEL collector is running
- Endpoint URL is correct (include http:// or https://)
- Network connectivity to the collector
- Firewall rules allow connections

### Verbose Output

Enable verbose output to see detailed information:

```powershell
$VerbosePreference = "Continue"
Send-OtelLog -Message "Test" -Severity "INFO" -Verbose
```

## Standards and Protocols

This module implements:
- OpenTelemetry Protocol (OTLP) v1
- OTLP/HTTP with JSON encoding
- OpenTelemetry semantic conventions

## License

This module is provided as-is for use with OpenTelemetry-compatible systems.

## Contributing

Contributions are welcome! Areas for improvement:
- gRPC protocol support
- Batch sending for better performance
- Additional metric types
- Span events and links
- Compression support

## Resources

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [OTLP Specification](https://github.com/open-telemetry/opentelemetry-proto)
- [Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
