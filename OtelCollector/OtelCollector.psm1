using namespace System.Collections.Generic

class OtelConfig {
    [string]$Endpoint
    [hashtable]$Headers
    [string]$ServiceName
    [string]$ServiceVersion
    [hashtable]$ResourceAttributes

    OtelConfig([string]$endpoint, [string]$serviceName) {
        $this.Endpoint = $endpoint
        $this.ServiceName = $serviceName
        $this.ServiceVersion = "1.0.0"
        $this.Headers = @{
            "Content-Type" = "application/json"
        }
        $this.ResourceAttributes = @{}
    }
}

$script:OtelConfig = $null

function Initialize-OtelCollector {
    <#
    .SYNOPSIS
        Initializes the OpenTelemetry collector configuration.

    .DESCRIPTION
        Sets up the OTEL collector endpoint and service information for subsequent telemetry operations.

    .PARAMETER Endpoint
        The base URL of the OTEL collector (e.g., http://localhost:4318)

    .PARAMETER ServiceName
        The name of your service

    .PARAMETER ServiceVersion
        The version of your service (default: 1.0.0)

    .PARAMETER Headers
        Additional HTTP headers to include in requests

    .PARAMETER ResourceAttributes
        Additional resource attributes to include with all telemetry

    .EXAMPLE
        Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "MyApp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $false)]
        [string]$ServiceVersion = "1.0.0",

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$ResourceAttributes = @{}
    )

    $script:OtelConfig = [OtelConfig]::new($Endpoint, $ServiceName)
    $script:OtelConfig.ServiceVersion = $ServiceVersion

    foreach ($key in $Headers.Keys) {
        $script:OtelConfig.Headers[$key] = $Headers[$key]
    }

    foreach ($key in $ResourceAttributes.Keys) {
        $script:OtelConfig.ResourceAttributes[$key] = $ResourceAttributes[$key]
    }

    Write-Verbose "OTEL Collector initialized for service '$ServiceName' at '$Endpoint'"
}

function Send-OtelLog {
    <#
    .SYNOPSIS
        Sends a log entry to the OTEL collector.

    .DESCRIPTION
        Sends structured log data to the configured OpenTelemetry collector endpoint.

    .PARAMETER Message
        The log message body

    .PARAMETER Severity
        The severity level (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)

    .PARAMETER Attributes
        Additional attributes to include with the log

    .PARAMETER TraceId
        Optional trace ID to correlate logs with traces

    .PARAMETER SpanId
        Optional span ID to correlate logs with specific spans

    .EXAMPLE
        Send-OtelLog -Message "User logged in" -Severity "INFO" -Attributes @{ userId = "123" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Severity = "INFO",

        [Parameter(Mandatory = $false)]
        [hashtable]$Attributes = @{},

        [Parameter(Mandatory = $false)]
        [string]$TraceId,

        [Parameter(Mandatory = $false)]
        [string]$SpanId
    )

    if ($null -eq $script:OtelConfig) {
        throw "OTEL Collector not initialized. Call Initialize-OtelCollector first."
    }

    $severityMap = @{
        "TRACE" = 1
        "DEBUG" = 5
        "INFO"  = 9
        "WARN"  = 13
        "ERROR" = 17
        "FATAL" = 21
    }

    $timeUnixNano = [string]([long]((Get-Date).ToUniversalTime() - [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalMilliseconds * 1000000)

    $attributesArray = @()
    foreach ($key in $Attributes.Keys) {
        $attributesArray += @{
            key   = $key
            value = @{ stringValue = [string]$Attributes[$key] }
        }
    }

    $logRecord = @{
        timeUnixNano   = $timeUnixNano
        severityNumber = $severityMap[$Severity]
        severityText   = $Severity
        body           = @{ stringValue = $Message }
        attributes     = $attributesArray
    }

    if ($TraceId) { $logRecord.traceId = $TraceId }
    if ($SpanId) { $logRecord.spanId = $SpanId }

    $resourceAttributes = @(
        @{
            key   = "service.name"
            value = @{ stringValue = $script:OtelConfig.ServiceName }
        },
        @{
            key   = "service.version"
            value = @{ stringValue = $script:OtelConfig.ServiceVersion }
        }
    )

    foreach ($key in $script:OtelConfig.ResourceAttributes.Keys) {
        $resourceAttributes += @{
            key   = $key
            value = @{ stringValue = [string]$script:OtelConfig.ResourceAttributes[$key] }
        }
    }

    $payload = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = $resourceAttributes
                }
                scopeLogs = @(
                    @{
                        scope = @{
                            name = "powershell-otel"
                        }
                        logRecords = @($logRecord)
                    }
                )
            }
        )
    }

    $endpoint = "$($script:OtelConfig.Endpoint)/v1/logs"

    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $script:OtelConfig.Headers -Body ($payload | ConvertTo-Json -Depth 10) -ErrorAction Stop
        Write-Verbose "Log sent successfully to $endpoint"
        return $response
    }
    catch {
        Write-Error "Failed to send log to OTEL collector: $_"
        throw
    }
}

function Send-OtelMetric {
    <#
    .SYNOPSIS
        Sends a metric to the OTEL collector.

    .DESCRIPTION
        Sends metric data to the configured OpenTelemetry collector endpoint.

    .PARAMETER Name
        The name of the metric

    .PARAMETER Value
        The numeric value of the metric

    .PARAMETER Type
        The metric type (Gauge, Counter, Histogram)

    .PARAMETER Unit
        The unit of measurement (e.g., "ms", "bytes", "count")

    .PARAMETER Attributes
        Additional attributes to include with the metric

    .EXAMPLE
        Send-OtelMetric -Name "http.request.duration" -Value 245 -Type "Histogram" -Unit "ms" -Attributes @{ method = "GET"; status = "200" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [double]$Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gauge", "Counter", "Histogram")]
        [string]$Type = "Gauge",

        [Parameter(Mandatory = $false)]
        [string]$Unit = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$Attributes = @{}
    )

    if ($null -eq $script:OtelConfig) {
        throw "OTEL Collector not initialized. Call Initialize-OtelCollector first."
    }

    $timeUnixNano = [string]([long]((Get-Date).ToUniversalTime() - [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalMilliseconds * 1000000)

    $attributesArray = @()
    foreach ($key in $Attributes.Keys) {
        $attributesArray += @{
            key   = $key
            value = @{ stringValue = [string]$Attributes[$key] }
        }
    }

    $dataPoint = @{
        timeUnixNano = $timeUnixNano
        attributes   = $attributesArray
    }

    switch ($Type) {
        "Gauge" {
            $dataPoint.asDouble = $Value
            $metricData = @{
                gauge = @{
                    dataPoints = @($dataPoint)
                }
            }
        }
        "Counter" {
            $dataPoint.asDouble = $Value
            $metricData = @{
                sum = @{
                    dataPoints              = @($dataPoint)
                    aggregationTemporality = 2
                    isMonotonic            = $true
                }
            }
        }
        "Histogram" {
            $dataPoint.count = 1
            $dataPoint.sum = $Value
            $metricData = @{
                histogram = @{
                    dataPoints              = @($dataPoint)
                    aggregationTemporality = 2
                }
            }
        }
    }

    $resourceAttributes = @(
        @{
            key   = "service.name"
            value = @{ stringValue = $script:OtelConfig.ServiceName }
        },
        @{
            key   = "service.version"
            value = @{ stringValue = $script:OtelConfig.ServiceVersion }
        }
    )

    foreach ($key in $script:OtelConfig.ResourceAttributes.Keys) {
        $resourceAttributes += @{
            key   = $key
            value = @{ stringValue = [string]$script:OtelConfig.ResourceAttributes[$key] }
        }
    }

    $metric = @{
        name = $Name
        unit = $Unit
    }

    $metric += $metricData

    $payload = @{
        resourceMetrics = @(
            @{
                resource = @{
                    attributes = $resourceAttributes
                }
                scopeMetrics = @(
                    @{
                        scope = @{
                            name = "powershell-otel"
                        }
                        metrics = @($metric)
                    }
                )
            }
        )
    }

    $endpoint = "$($script:OtelConfig.Endpoint)/v1/metrics"

    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $script:OtelConfig.Headers -Body ($payload | ConvertTo-Json -Depth 10) -ErrorAction Stop
        Write-Verbose "Metric sent successfully to $endpoint"
        return $response
    }
    catch {
        Write-Error "Failed to send metric to OTEL collector: $_"
        throw
    }
}

function Send-OtelTrace {
    <#
    .SYNOPSIS
        Sends a trace span to the OTEL collector.

    .DESCRIPTION
        Sends distributed trace data to the configured OpenTelemetry collector endpoint.

    .PARAMETER Name
        The name of the span

    .PARAMETER TraceId
        The trace ID (32 hex characters)

    .PARAMETER SpanId
        The span ID (16 hex characters)

    .PARAMETER ParentSpanId
        The parent span ID if this is a child span

    .PARAMETER Kind
        The span kind (INTERNAL, SERVER, CLIENT, PRODUCER, CONSUMER)

    .PARAMETER StartTime
        The start time of the span (defaults to current time)

    .PARAMETER EndTime
        The end time of the span (defaults to current time)

    .PARAMETER Attributes
        Additional attributes to include with the span

    .PARAMETER Status
        The span status (OK, ERROR, UNSET)

    .PARAMETER StatusMessage
        Optional status message for ERROR status

    .EXAMPLE
        Send-OtelTrace -Name "HTTP GET /api/users" -TraceId $traceId -SpanId $spanId -Kind "SERVER" -Attributes @{ "http.method" = "GET"; "http.status_code" = "200" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$TraceId,

        [Parameter(Mandatory = $false)]
        [string]$SpanId,

        [Parameter(Mandatory = $false)]
        [string]$ParentSpanId,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INTERNAL", "SERVER", "CLIENT", "PRODUCER", "CONSUMER")]
        [string]$Kind = "INTERNAL",

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date).ToUniversalTime(),

        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime = (Get-Date).ToUniversalTime(),

        [Parameter(Mandatory = $false)]
        [hashtable]$Attributes = @{},

        [Parameter(Mandatory = $false)]
        [ValidateSet("OK", "ERROR", "UNSET")]
        [string]$Status = "OK",

        [Parameter(Mandatory = $false)]
        [string]$StatusMessage
    )

    if ($null -eq $script:OtelConfig) {
        throw "OTEL Collector not initialized. Call Initialize-OtelCollector first."
    }

    if (-not $TraceId) {
        $TraceId = [System.Guid]::NewGuid().ToString("N")
    }

    if (-not $SpanId) {
        $SpanId = [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
    }

    $kindMap = @{
        "INTERNAL" = 1
        "SERVER"   = 2
        "CLIENT"   = 3
        "PRODUCER" = 4
        "CONSUMER" = 5
    }

    $statusMap = @{
        "UNSET" = 0
        "OK"    = 1
        "ERROR" = 2
    }

    $startTimeUnixNano = [string]([long](($StartTime - [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalMilliseconds * 1000000))
    $endTimeUnixNano = [string]([long](($EndTime - [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalMilliseconds * 1000000))

    $attributesArray = @()
    foreach ($key in $Attributes.Keys) {
        $attributesArray += @{
            key   = $key
            value = @{ stringValue = [string]$Attributes[$key] }
        }
    }

    $span = @{
        traceId           = $TraceId
        spanId            = $SpanId
        name              = $Name
        kind              = $kindMap[$Kind]
        startTimeUnixNano = $startTimeUnixNano
        endTimeUnixNano   = $endTimeUnixNano
        attributes        = $attributesArray
        status            = @{
            code = $statusMap[$Status]
        }
    }

    if ($ParentSpanId) {
        $span.parentSpanId = $ParentSpanId
    }

    if ($StatusMessage) {
        $span.status.message = $StatusMessage
    }

    $resourceAttributes = @(
        @{
            key   = "service.name"
            value = @{ stringValue = $script:OtelConfig.ServiceName }
        },
        @{
            key   = "service.version"
            value = @{ stringValue = $script:OtelConfig.ServiceVersion }
        }
    )

    foreach ($key in $script:OtelConfig.ResourceAttributes.Keys) {
        $resourceAttributes += @{
            key   = $key
            value = @{ stringValue = [string]$script:OtelConfig.ResourceAttributes[$key] }
        }
    }

    $payload = @{
        resourceSpans = @(
            @{
                resource = @{
                    attributes = $resourceAttributes
                }
                scopeSpans = @(
                    @{
                        scope = @{
                            name = "powershell-otel"
                        }
                        spans = @($span)
                    }
                )
            }
        )
    }

    $endpoint = "$($script:OtelConfig.Endpoint)/v1/traces"

    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $script:OtelConfig.Headers -Body ($payload | ConvertTo-Json -Depth 10) -ErrorAction Stop
        Write-Verbose "Trace sent successfully to $endpoint"
        return @{
            TraceId  = $TraceId
            SpanId   = $SpanId
            Response = $response
        }
    }
    catch {
        Write-Error "Failed to send trace to OTEL collector: $_"
        throw
    }
}

function New-OtelTraceId {
    <#
    .SYNOPSIS
        Generates a new trace ID.

    .DESCRIPTION
        Creates a 32-character hexadecimal trace ID for use with distributed tracing.

    .EXAMPLE
        $traceId = New-OtelTraceId
    #>
    [CmdletBinding()]
    param()

    return [System.Guid]::NewGuid().ToString("N")
}

function New-OtelSpanId {
    <#
    .SYNOPSIS
        Generates a new span ID.

    .DESCRIPTION
        Creates a 16-character hexadecimal span ID for use with distributed tracing.

    .EXAMPLE
        $spanId = New-OtelSpanId
    #>
    [CmdletBinding()]
    param()

    return [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
}

Export-ModuleMember -Function Initialize-OtelCollector, Send-OtelLog, Send-OtelMetric, Send-OtelTrace, New-OtelTraceId, New-OtelSpanId
