# Example: Error Handling and Monitoring with OtelCollector Module

Import-Module .\OtelCollector\OtelCollector.psd1 -Force

Initialize-OtelCollector `
    -Endpoint "http://localhost:4318" `
    -ServiceName "DataProcessingService" `
    -ServiceVersion "1.0.0"

function Process-DataFile {
    param([string]$FilePath)

    $traceId = New-OtelTraceId
    $spanId = New-OtelSpanId
    $startTime = Get-Date

    try {
        # Log the start of processing
        Send-OtelLog -Message "Starting file processing" `
            -Severity "INFO" `
            -TraceId $traceId `
            -SpanId $spanId `
            -Attributes @{
                filePath = $FilePath
            }

        # Simulate file processing
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }

        # Simulate some work
        Start-Sleep -Milliseconds 100

        # Success metrics
        Send-OtelMetric -Name "files.processed" `
            -Value 1 `
            -Type "Counter" `
            -Unit "count" `
            -Attributes @{
                status = "success"
                fileType = [System.IO.Path]::GetExtension($FilePath)
            }

        $endTime = Get-Date

        # Success trace
        Send-OtelTrace -Name "ProcessDataFile" `
            -TraceId $traceId `
            -SpanId $spanId `
            -Kind "INTERNAL" `
            -StartTime $startTime `
            -EndTime $endTime `
            -Attributes @{
                "file.path" = $FilePath
                "file.size" = (Get-Item $FilePath).Length
            } `
            -Status "OK"

        Write-Host "Successfully processed: $FilePath" -ForegroundColor Green
    }
    catch {
        $endTime = Get-Date
        $errorMessage = $_.Exception.Message

        # Log the error
        Send-OtelLog -Message "File processing failed: $errorMessage" `
            -Severity "ERROR" `
            -TraceId $traceId `
            -SpanId $spanId `
            -Attributes @{
                filePath = $FilePath
                errorType = $_.Exception.GetType().Name
                stackTrace = $_.ScriptStackTrace
            }

        # Error metrics
        Send-OtelMetric -Name "files.processed" `
            -Value 1 `
            -Type "Counter" `
            -Unit "count" `
            -Attributes @{
                status = "error"
                errorType = $_.Exception.GetType().Name
            }

        # Error trace
        Send-OtelTrace -Name "ProcessDataFile" `
            -TraceId $traceId `
            -SpanId $spanId `
            -Kind "INTERNAL" `
            -StartTime $startTime `
            -EndTime $endTime `
            -Attributes @{
                "file.path" = $FilePath
                "error.type" = $_.Exception.GetType().Name
                "error.message" = $errorMessage
            } `
            -Status "ERROR" `
            -StatusMessage $errorMessage

        Write-Host "Failed to process: $FilePath" -ForegroundColor Red
        Write-Host "Error: $errorMessage" -ForegroundColor Red
    }
}

# Example 1: Process existing file (success case)
Write-Host "`n--- Processing existing file ---" -ForegroundColor Cyan
$testFile = New-TemporaryFile
"test data" | Out-File $testFile
Process-DataFile -FilePath $testFile.FullName
Remove-Item $testFile

# Example 2: Process non-existent file (error case)
Write-Host "`n--- Processing non-existent file ---" -ForegroundColor Cyan
Process-DataFile -FilePath "C:\NonExistent\File.txt"

# Example 3: Simulate a retry scenario with exponential backoff
Write-Host "`n--- Demonstrating retry with telemetry ---" -ForegroundColor Cyan

$traceId = New-OtelTraceId
$maxRetries = 3
$retryCount = 0
$success = $false

while ($retryCount -lt $maxRetries -and -not $success) {
    $spanId = New-OtelSpanId
    $startTime = Get-Date

    try {
        # Simulate an operation that might fail
        $randomFailure = Get-Random -Minimum 0 -Maximum 2

        if ($randomFailure -eq 0) {
            throw "Temporary network error"
        }

        $success = $true
        $endTime = Get-Date

        Send-OtelLog -Message "Operation succeeded after $retryCount retries" `
            -Severity "INFO" `
            -TraceId $traceId `
            -SpanId $spanId `
            -Attributes @{
                retryCount = [string]$retryCount
            }

        Send-OtelTrace -Name "RetryableOperation" `
            -TraceId $traceId `
            -SpanId $spanId `
            -Kind "INTERNAL" `
            -StartTime $startTime `
            -EndTime $endTime `
            -Attributes @{
                "retry.count" = [string]$retryCount
                "result" = "success"
            } `
            -Status "OK"

        Write-Host "Operation succeeded!" -ForegroundColor Green
    }
    catch {
        $retryCount++
        $endTime = Get-Date

        if ($retryCount -lt $maxRetries) {
            $waitTime = [Math]::Pow(2, $retryCount) * 100

            Send-OtelLog -Message "Operation failed, retrying... (attempt $retryCount of $maxRetries)" `
                -Severity "WARN" `
                -TraceId $traceId `
                -SpanId $spanId `
                -Attributes @{
                    retryCount = [string]$retryCount
                    errorMessage = $_.Exception.Message
                    nextRetryDelayMs = [string]$waitTime
                }

            Send-OtelTrace -Name "RetryableOperation" `
                -TraceId $traceId `
                -SpanId $spanId `
                -Kind "INTERNAL" `
                -StartTime $startTime `
                -EndTime $endTime `
                -Attributes @{
                    "retry.count" = [string]$retryCount
                    "result" = "retry"
                    "error.message" = $_.Exception.Message
                } `
                -Status "ERROR" `
                -StatusMessage "Retry attempt $retryCount"

            Write-Host "Retry attempt $retryCount failed, waiting $($waitTime)ms..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds $waitTime
        }
        else {
            Send-OtelLog -Message "Operation failed after $maxRetries retries" `
                -Severity "ERROR" `
                -TraceId $traceId `
                -SpanId $spanId `
                -Attributes @{
                    retryCount = [string]$retryCount
                    errorMessage = $_.Exception.Message
                }

            Send-OtelTrace -Name "RetryableOperation" `
                -TraceId $traceId `
                -SpanId $spanId `
                -Kind "INTERNAL" `
                -StartTime $startTime `
                -EndTime $endTime `
                -Attributes @{
                    "retry.count" = [string]$retryCount
                    "result" = "failure"
                    "error.message" = $_.Exception.Message
                } `
                -Status "ERROR" `
                -StatusMessage "Max retries exceeded"

            Write-Host "Operation failed after $maxRetries retries" -ForegroundColor Red
        }
    }
}

Write-Host "`nError handling examples completed!" -ForegroundColor Green
