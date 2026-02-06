# Example: Advanced Distributed Tracing with OtelCollector Module

Import-Module .\OtelCollector\OtelCollector.psd1 -Force

# Initialize with additional resource attributes
Initialize-OtelCollector `
    -Endpoint "http://localhost:4318" `
    -ServiceName "OrderProcessingService" `
    -ServiceVersion "2.0.0" `
    -ResourceAttributes @{
        "deployment.environment" = "production"
        "host.name" = $env:COMPUTERNAME
    }

# Simulate a distributed trace with parent and child spans
$traceId = New-OtelTraceId
Write-Host "Starting trace: $traceId" -ForegroundColor Cyan

# Parent span: Main request handler
$parentSpanId = New-OtelSpanId
$parentStart = Get-Date

Write-Host "Processing order..." -ForegroundColor Yellow

# Child span 1: Validate order
$validateSpanId = New-OtelSpanId
$validateStart = Get-Date
Start-Sleep -Milliseconds 50
$validateEnd = Get-Date

Send-OtelTrace -Name "ValidateOrder" `
    -TraceId $traceId `
    -SpanId $validateSpanId `
    -ParentSpanId $parentSpanId `
    -Kind "INTERNAL" `
    -StartTime $validateStart `
    -EndTime $validateEnd `
    -Attributes @{
        "order.id" = "ORD-12345"
        "order.items.count" = "3"
    } `
    -Status "OK"

# Log correlated with the trace
Send-OtelLog -Message "Order validation completed" `
    -Severity "INFO" `
    -TraceId $traceId `
    -SpanId $validateSpanId `
    -Attributes @{
        orderId = "ORD-12345"
    }

# Child span 2: Check inventory
$inventorySpanId = New-OtelSpanId
$inventoryStart = Get-Date
Start-Sleep -Milliseconds 75
$inventoryEnd = Get-Date

Send-OtelTrace -Name "CheckInventory" `
    -TraceId $traceId `
    -SpanId $inventorySpanId `
    -ParentSpanId $parentSpanId `
    -Kind "CLIENT" `
    -StartTime $inventoryStart `
    -EndTime $inventoryEnd `
    -Attributes @{
        "inventory.service" = "InventoryAPI"
        "inventory.available" = "true"
    } `
    -Status "OK"

# Record metric for inventory check duration
$inventoryDuration = ($inventoryEnd - $inventoryStart).TotalMilliseconds
Send-OtelMetric -Name "inventory.check.duration" `
    -Value $inventoryDuration `
    -Type "Histogram" `
    -Unit "ms" `
    -Attributes @{
        service = "InventoryAPI"
        result = "success"
    }

# Child span 3: Process payment
$paymentSpanId = New-OtelSpanId
$paymentStart = Get-Date
Start-Sleep -Milliseconds 120
$paymentEnd = Get-Date

Send-OtelTrace -Name "ProcessPayment" `
    -TraceId $traceId `
    -SpanId $paymentSpanId `
    -ParentSpanId $parentSpanId `
    -Kind "CLIENT" `
    -StartTime $paymentStart `
    -EndTime $paymentEnd `
    -Attributes @{
        "payment.method" = "credit_card"
        "payment.amount" = "99.99"
        "payment.currency" = "USD"
    } `
    -Status "OK"

Send-OtelLog -Message "Payment processed successfully" `
    -Severity "INFO" `
    -TraceId $traceId `
    -SpanId $paymentSpanId `
    -Attributes @{
        amount = "99.99"
        transactionId = "TXN-67890"
    }

# Child span 4: Create shipment
$shipmentSpanId = New-OtelSpanId
$shipmentStart = Get-Date
Start-Sleep -Milliseconds 60
$shipmentEnd = Get-Date

Send-OtelTrace -Name "CreateShipment" `
    -TraceId $traceId `
    -SpanId $shipmentSpanId `
    -ParentSpanId $parentSpanId `
    -Kind "PRODUCER" `
    -StartTime $shipmentStart `
    -EndTime $shipmentEnd `
    -Attributes @{
        "shipment.carrier" = "USPS"
        "shipment.tracking" = "TRACK-ABC123"
    } `
    -Status "OK"

# Complete parent span
$parentEnd = Get-Date

Send-OtelTrace -Name "ProcessOrder" `
    -TraceId $traceId `
    -SpanId $parentSpanId `
    -Kind "SERVER" `
    -StartTime $parentStart `
    -EndTime $parentEnd `
    -Attributes @{
        "http.method" = "POST"
        "http.url" = "/api/orders"
        "http.status_code" = "201"
        "order.id" = "ORD-12345"
        "customer.id" = "CUST-789"
    } `
    -Status "OK"

# Record overall metrics
$totalDuration = ($parentEnd - $parentStart).TotalMilliseconds

Send-OtelMetric -Name "order.processing.duration" `
    -Value $totalDuration `
    -Type "Histogram" `
    -Unit "ms" `
    -Attributes @{
        status = "success"
    }

Send-OtelMetric -Name "orders.processed.total" `
    -Value 1 `
    -Type "Counter" `
    -Unit "count" `
    -Attributes @{
        status = "success"
    }

Write-Host "`nDistributed trace completed!" -ForegroundColor Green
Write-Host "Trace ID: $traceId" -ForegroundColor Cyan
Write-Host "Total Duration: $($totalDuration)ms" -ForegroundColor Yellow
Write-Host "`nView this trace in your observability platform using the Trace ID above." -ForegroundColor White
