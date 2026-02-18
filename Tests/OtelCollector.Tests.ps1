Describe 'OtelCollector Module' {

    BeforeAll {
        $modulePath = (Resolve-Path (Join-Path $PSScriptRoot '..\OtelCollector\OtelCollector.psd1')).Path
        Import-Module $modulePath -Force
        Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "TestService" -ServiceVersion "1.0.0"
        $global:traceId = New-OtelTraceId
        $global:spanId = New-OtelSpanId
    }

    Context 'Module import and initialization' {
        It 'imports module without throwing' {
            { Import-Module $modulePath -Force } | Should -Not -Throw
        }

        It 'initializes without throwing' {
            { Initialize-OtelCollector -Endpoint "http://localhost:4318" -ServiceName "TestService" -ServiceVersion "1.0.0" } | Should -Not -Throw
        }
    }

    Context 'ID generation' {
        It 'generates a 32-character TraceId' {
            $traceId.Length | Should -Be 32
        }

        It 'generates a 16-character SpanId' {
            $spanId.Length | Should -Be 16
        }
    }

    Context 'Send operations (connection-tolerant)' {
        It 'sends a log or reports collector connection error' {
            try {
                Send-OtelLog -Message "Test log message" -Severity "INFO" -Attributes @{ testKey = "testValue" } -ErrorAction Stop
                $ok = $true
            }
            catch {
                $msg = $_.Exception.Message
                $ok = $msg -like '*connection*' -or $msg -like '*Unable to connect*'
            }
            $ok | Should -BeTrue
        }

        It 'sends a metric or reports collector connection error' {
            try {
                Send-OtelMetric -Name "test.metric" -Value 42.5 -Type "Gauge" -Unit "count" -Attributes @{ env = "test" } -ErrorAction Stop
                $ok = $true
            }
            catch {
                $msg = $_.Exception.Message
                write-host "Caught error: $msg" -ForegroundColor Yellow
                $ok = $msg -like '*connection*' -or $msg -like '*Unable to connect*'
            }
            $ok | Should -BeTrue
        }

        It 'sends a trace or reports collector connection error' {
            $startTime = Get-Date
            Start-Sleep -Milliseconds 50
            $endTime = Get-Date
            try {
                Send-OtelTrace -Name "TestOperation" -TraceId $traceId -SpanId $spanId -Kind "INTERNAL" -StartTime $startTime -EndTime $endTime -Attributes @{ operation = "test" } -Status "OK" -ErrorAction Stop
                $ok = $true
            }
            catch {
                $msg = $_.Exception.Message
                $ok = $msg -like '*connection*' -or $msg -like '*Unable to connect*'
            }
            $ok | Should -BeTrue
        }
    }

    Context 'All log severity levels' {
        $severities = @('TRACE','DEBUG','INFO','WARN','ERROR','FATAL')
        foreach ($severity in $severities) {
            It "handles severity <Severity> (or connection error)" -TestCases @{ Severity = $severity } {
                param($Severity)
                try {
                    Send-OtelLog -Message "Test $Severity message" -Severity $Severity -ErrorAction Stop
                    $ok = $true
                }
                catch {
                    $msg = $_.Exception.Message
                    $ok = $msg -like '*connection*' -or $msg -like '*Unable to connect*'
                }
                $ok | Should -BeTrue
            }
        }
    }

    Context 'All metric types' {
        $metricTypes = @('Gauge','Counter','Histogram')
        foreach ($type in $metricTypes) {
            It "handles metric type <Type> (or connection error)" -TestCases @{ Type = $type } {
                param($Type)
                try {
                    Send-OtelMetric -Name "test.$($Type.ToLower())" -Value 100 -Type $Type -ErrorAction Stop
                    $ok = $true
                }
                catch {
                    $msg = $_.Exception.Message
                    $ok = $msg -like '*connection*' -or $msg -like '*Unable to connect*'
                }
                $ok | Should -BeTrue
            }
        }
    }

    Context 'All span kinds' {
        $spanKinds = @('INTERNAL','SERVER','CLIENT','PRODUCER','CONSUMER')
        foreach ($kind in $spanKinds) {
            It "handles span kind <Kind> (or connection error)" -TestCases @{ Kind = $kind } {
                param($Kind)
                $testSpanId = New-OtelSpanId
                try {
                    Send-OtelTrace -Name "Test$Kind" -TraceId $traceId -SpanId $testSpanId -Kind $Kind -ErrorAction Stop
                    $ok = $true
                }
                catch {
                    $msg = $_.Exception.Message
                    $ok = $msg -like '*connection*' -or $msg -like '*Unable to connect*'
                }
                $ok | Should -BeTrue
            }
        }
    }

}
