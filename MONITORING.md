# Cloud Notes Hub - Monitoring & Observability

This document describes the monitoring and observability setup for Cloud Notes Hub.

## Overview

The application uses **Azure Application Insights** and **Azure Monitor** for comprehensive monitoring, logging, and alerting.

## Components

### 1. Application Insights
- **Resource:** `cloud-notes-hub-prod-ai`
- **Type:** Web application monitoring
- **Workspace:** Log Analytics Workspace (`cloud-notes-hub-prod-law`)
- **Retention:** 30 days

**Capabilities:**
- Real-time performance monitoring
- Exception tracking
- Request/response tracking
- User analytics
- Custom events and metrics

### 2. Log Analytics Workspace
- **Resource:** `cloud-notes-hub-prod-law`
- **SKU:** PerGB2018
- **Retention:** 30 days

### 3. Alert Configuration

#### High Error Rate Alert
- **Name:** `cloud-notes-hub-prod-high-error-rate`
- **Condition:** More than 10 exceptions in 15 minutes
- **Severity:** Warning (2)
- **Frequency:** Every 5 minutes
- **Action:** Email notification

####Low Availability Alert
- **Name:** `cloud-notes-hub-prod-low-availability`
- **Condition:** Availability below 95%
- **Severity:** Error (1)
- **Frequency:** Every 5 minutes
- **Action:** Email notification

### 4. Action Groups
- **Name:** `cloud-notes-hub-prod-action-group`
- **Email:** codecloudevops@outlook.com
- **Schema:** Common Alert Schema enabled

## Accessing Monitoring Data

### Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to Resource Group: `cloud-notes-hub-prod-rg`
3. Select **Application Insights**: `cloud-notes-hub-prod-ai`

### Key Dashboards

#### Application Map
Shows dependencies and performance across components
- **Path:** Application Insights → Investigate → Application Map

#### Live Metrics
Real-time monitoring of requests, failures, and performance
- **Path:** Application Insights → Investigate → Live Metrics

#### Failures
Analysis of exceptions and failed requests
- **Path:** Application Insights → Investigate → Failures

#### Performance
Request duration, dependency calls, and bottlenecks
- **Path:** Application Insights → Investigate → Performance

#### Logs (Kusto Queries)
Custom queries on telemetry data
- **Path:** Application Insights → Monitoring → Logs

## Useful Kusto Queries

### Top 10 Slowest Requests
```kusto
requests
| where timestamp > ago(24h)
| summarize avg(duration) by name
| top 10 by avg_duration desc
```

### Exception Count by Type
```kusto
exceptions
| where timestamp > ago(24h)
| summarize count() by type
| order by count_ desc
```

### User Activity (Page Views)
```kusto
pageViews
| where timestamp > ago(7d)
| summarize count() by bin(timestamp, 1h)
| render timechart
```

### Failed Requests
```kusto
requests
| where success == false
| where timestamp > ago(24h)
| project timestamp, name, resultCode, duration
| order by timestamp desc
```

### Dependency Failures
```kusto
dependencies
| where success == false
| where timestamp > ago(24h)
| project timestamp, name, type, resultCode, duration
| order by timestamp desc
```

## Metrics to Monitor

### Performance Metrics
- **Response Time:** Average request duration
- **Server Response Time:** Time to first byte
- **Page Load Time:** Client-side page load duration
- **Dependency Duration:** External API call times

### Availability Metrics
- **Uptime Percentage:** Overall availability
- **Failed Requests:** HTTP 4xx and 5xx errors
- **Dependency Failures:** Failed external calls

### Usage Metrics
- **User Sessions:** Active user sessions
- **Page Views:** Total page views
- **Users:** Unique users
- **New vs Returning Users:** User engagement

### Error Metrics
- **Exception Count:** Total exceptions thrown
- **Exception Types:** Distribution of error types
- **Error Rate:** Exceptions per minute
- **Failed Dependency Calls:** External API failures

## Alert Response Procedures

### High Error Rate Alert
1. Check Application Insights → Failures dashboard
2. Identify the exception type and affected endpoints
3. Review recent deployments or changes
4. Check application logs in Log Analytics
5. If critical, rollback to previous version
6. Investigate root cause and apply fix

### Low Availability Alert
1. Check Live Metrics for real-time status
2. Verify Azure service health
3. Check Static Web App deployment status
4. Review recent configuration changes
5. Check Supabase status if database-related
6. Scale resources if needed (upgrade SKU)

## Cost Management

### Current Configuration Costs
- **Application Insights:** Pay-as-you-go (first 5GB/month free)
- **Log Analytics:** PerGB2018 ($2.30/GB after 5GB free)
- **Data Retention:** 30 days (included)
- **Alerts:** Free (first 1000 alerts/month)

### Cost Optimization Tips
1. Use sampling to reduce telemetry volume
2. Set appropriate retention periods
3. Use log Analytics query optimization
4. Archive old logs to cheaper storage
5. Monitor daily data ingestion

## Terraform Management

### Apply Monitoring Infrastructure
```bash
cd terraform
terraform plan
terraform apply
```

### Get Connection String
```bash
terraform output -raw application_insights_connection_string
```

### Update Alert Email
Edit `terraform/terraform.tfvars`:
```hcl
alert_email = "your-email@example.com"
```

Then apply:
```bash
terraform apply
```

## Troubleshooting

### No Telemetry Data
1. Verify Application Insights connection string is configured
2. Check network connectivity
3. Verify instrumentation is correctly set up
4. Check for sampling that might be dropping data

### Alert Not Firing
1. Verify alert rules are enabled
2. Check metric thresholds are appropriate
3. Verify action group email is confirmed
4. Review alert rule condition logic

### High Costs
1. Check daily data ingestion in Application Insights
2. Enable sampling to reduce volume
3. Review retention settings
4. Identify noisy telemetry sources
5. Optimize logging levels

## Best Practices

1. **Set up availability tests** for critical endpoints
2. **Create custom dashboards** for your specific KPIs
3. **Use application map** to understand dependencies
4. **Configure sampling** to control costs
5. **Set up anomaly detection** for proactive monitoring
6. **Review alerts weekly** and adjust thresholds
7. **Document incident response** procedures
8. **Regular health checks** of monitoring infrastructure

## Additional Resources

- [Azure Application Insights Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Kusto Query Language (KQL) Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Azure Monitor Alerts](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview)
- [Application Insights Sampling](https://docs.microsoft.com/en-us/azure/azure-monitor/app/sampling)
