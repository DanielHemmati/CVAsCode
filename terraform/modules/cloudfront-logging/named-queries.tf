locals {
  athena_named_queries = {
    requests_by_day = {
      description = "Count CloudFront requests for one projected day."
      query       = <<-SQL
        SELECT
          CAST(from_unixtime(TRY_CAST(timestamp_ms AS DOUBLE) / 1000) AS DATE) AS request_day,
          COUNT(*) AS request_count
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
        GROUP BY 1
        ORDER BY 1
      SQL
    }

    most_requested_paths = {
      description = "List the most requested CloudFront paths for one projected day."
      query       = <<-SQL
        SELECT
          cs_uri_stem,
          COUNT(*) AS request_count,
          SUM(COALESCE(TRY_CAST(sc_bytes AS BIGINT), 0)) AS response_bytes
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
        GROUP BY cs_uri_stem
        ORDER BY request_count DESC
        LIMIT 100
      SQL
    }

    http_errors = {
      description = "Count CloudFront HTTP 4xx and 5xx responses for one projected day."
      query       = <<-SQL
        SELECT
          TRY_CAST(sc_status AS INTEGER) AS status_code,
          cs_uri_stem,
          COUNT(*) AS response_count
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
          AND TRY_CAST(sc_status AS INTEGER) BETWEEN 400 AND 599
        GROUP BY 1, 2
        ORDER BY response_count DESC, status_code, cs_uri_stem
        LIMIT 100
      SQL
    }

    cache_hit_and_miss_rates = {
      description = "Calculate CloudFront cache-hit and cache-miss rates for one projected day."
      query       = <<-SQL
        SELECT
          COUNT(*) AS request_count,
          COUNT_IF(x_edge_result_type IN ('Hit', 'RefreshHit')) AS cache_hit_count,
          COUNT_IF(x_edge_result_type = 'Miss') AS cache_miss_count,
          ROUND(100.0 * COUNT_IF(x_edge_result_type IN ('Hit', 'RefreshHit')) / NULLIF(COUNT(*), 0), 2) AS cache_hit_percent,
          ROUND(100.0 * COUNT_IF(x_edge_result_type = 'Miss') / NULLIF(COUNT(*), 0), 2) AS cache_miss_percent
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
      SQL
    }

    requests_by_country = {
      description = "Count CloudFront requests by country for one projected day."
      query       = <<-SQL
        SELECT
          COALESCE(NULLIF(c_country, '-'), 'Unknown') AS country,
          COUNT(*) AS request_count
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
        GROUP BY 1
        ORDER BY request_count DESC
      SQL
    }

    response_time = {
      description = "Calculate average and percentile response times by hour for one projected day."
      query       = <<-SQL
        SELECT
          hour,
          AVG(TRY_CAST(time_taken AS DOUBLE)) AS average_seconds,
          approx_percentile(TRY_CAST(time_taken AS DOUBLE), 0.50) AS p50_seconds,
          approx_percentile(TRY_CAST(time_taken AS DOUBLE), 0.95) AS p95_seconds,
          approx_percentile(TRY_CAST(time_taken AS DOUBLE), 0.99) AS p99_seconds
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
        GROUP BY hour
        ORDER BY hour
      SQL
    }

    top_referrers = {
      description = "List the top CloudFront request referrers for one projected day."
      query       = <<-SQL
        SELECT
          cs_referer,
          COUNT(*) AS request_count
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
          AND cs_referer NOT IN ('', '-')
        GROUP BY cs_referer
        ORDER BY request_count DESC
        LIMIT 100
      SQL
    }

    top_user_agents = {
      description = "List the top CloudFront request user agents for one projected day."
      query       = <<-SQL
        SELECT
          cs_user_agent,
          COUNT(*) AS request_count
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
          AND cs_user_agent NOT IN ('', '-')
        GROUP BY cs_user_agent
        ORDER BY request_count DESC
        LIMIT 100
      SQL
    }

    missing_files = {
      description = "List CloudFront paths that returned HTTP 403 or 404 for one projected day."
      query       = <<-SQL
        SELECT
          TRY_CAST(sc_status AS INTEGER) AS status_code,
          cs_uri_stem,
          COUNT(*) AS response_count
        FROM "${aws_glue_catalog_table.cloudfront_access_logs.name}"
        WHERE distributionid = '${var.cloudfront_distribution_id}'
          AND year = date_format(current_date - INTERVAL '1' DAY, '%Y')
          AND month = date_format(current_date - INTERVAL '1' DAY, '%m')
          AND day = date_format(current_date - INTERVAL '1' DAY, '%d')
          AND TRY_CAST(sc_status AS INTEGER) IN (403, 404)
        GROUP BY 1, 2
        ORDER BY response_count DESC, status_code, cs_uri_stem
        LIMIT 100
      SQL
    }
  }
}

resource "aws_athena_named_query" "cloudfront_access_logs" {
  for_each = local.athena_named_queries

  name        = "cloudfront-${replace(each.key, "_", "-")}"
  description = each.value.description
  database    = aws_glue_catalog_database.cloudfront_access_logs.name
  query       = each.value.query
  workgroup   = aws_athena_workgroup.cloudfront_access_logs.name
}
