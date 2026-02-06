# Changelog

All notable changes to the OtelCollector PowerShell Module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-05

### Added
- Initial release of OtelCollector PowerShell Module
- `Initialize-OtelCollector` function for configuration
- `Send-OtelLog` function for sending structured logs
  - Support for severity levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
  - Custom attributes support
  - Trace and span correlation
- `Send-OtelMetric` function for sending metrics
  - Support for Gauge, Counter, and Histogram metrics
  - Custom units and attributes
- `Send-OtelTrace` function for distributed tracing
  - Support for all span kinds: INTERNAL, SERVER, CLIENT, PRODUCER, CONSUMER
  - Parent-child span relationships
  - Span status tracking
- `New-OtelTraceId` helper function for generating trace IDs
- `New-OtelSpanId` helper function for generating span IDs
- Comprehensive documentation and examples
- Docker Compose configuration for easy OTEL stack setup
- Example scripts demonstrating various use cases
- Test suite for module validation

### Features
- OTLP/HTTP JSON protocol implementation
- Configurable endpoints and headers
- Resource attributes support
- Service identification
- Timestamp handling in nanoseconds
- Verbose logging support

### Documentation
- Complete README with usage examples
- Quick Start guide
- Advanced tracing examples
- Error handling patterns
- Docker setup instructions

## [Unreleased]

### Planned
- gRPC protocol support
- Batch sending for improved performance
- Compression support
- Additional metric types (Summary, ExponentialHistogram)
- Span events and links
- Performance optimizations
- PowerShell Gallery publication
