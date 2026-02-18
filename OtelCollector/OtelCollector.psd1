@{
    RootModule = 'OtelCollector.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Baldator'
    Copyright = 'MIT License'
    Description = 'PowerShell module for sending logs, metrics, and traces to OpenTelemetry collectors using OTLP/HTTP JSON protocol.'
    PowerShellVersion = '5.1'

    # Explicitly list files to include in the module package
    # This excludes docker-compose.yml, otel-collector-config.yaml, and other root-level files
    FileList = @(
        'OtelCollector.psd1',
        'OtelCollector.psm1'
    )

    FunctionsToExport = @(
        'Initialize-OtelCollector',
        'Send-OtelLog',
        'Send-OtelMetric',
        'Send-OtelTrace',
        'New-OtelTraceId',
        'New-OtelSpanId'
    )

    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('OpenTelemetry', 'OTEL', 'Telemetry', 'Logging', 'Metrics', 'Tracing', 'Observability')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/Baldator/OtelCollector'
            IconUri = ''
            ReleaseNotes = 'Initial release of OpenTelemetry PowerShell module with support for logs, metrics, and traces.'
        }
    }
}
