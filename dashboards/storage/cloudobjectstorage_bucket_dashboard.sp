dashboard "ibm_cos_bucket_dashboard" {

  title         = "IBM Cloud Object Storage Bucket Dashboard"
  documentation = file("./dashboards/storage/docs/cloudobjectstorage_bucket_dashboard.md")

  tags = merge(local.storage_common_tags, {
    type = "Dashboard"
  })

  container {

    #Analysis
    card {
      sql   = query.ibm_cos_bucket_count.sql
      width = 2
    }

    # Assessments

    card {
      sql   = query.ibm_cos_bucket_unencrypted_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_cos_bucket_versioning_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_cos_bucket_versioning_mfa_disabled_count.sql
      width = 2
    }

  }

  container {
    title = "Assessments"
    width = 6

    chart {
      title = "Encryption Status"
      sql   = query.ibm_cos_bucket_encryption_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Versioning Status"
      sql   = query.ibm_cos_bucket_versioning_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Versioning MFA Status"
      sql   = query.ibm_cos_bucket_versioning_mfa_status.sql
      type  = "donut"
      width = 4

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }


  container {
    title = "Analysis"

    chart {
      title = "Buckets by Account"
      sql   = query.ibm_cos_bucket_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Region"
      sql   = query.ibm_cos_bucket_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Age"
      sql   = query.ibm_cos_bucket_by_creation_month.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "ibm_cos_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from ibm_cos_bucket;
  EOQ
}

query "ibm_cos_bucket_unencrypted_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      ibm_cos_bucket
    where
      not sse_kp_enabled;
  EOQ
}

query "ibm_cos_bucket_versioning_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      ibm_cos_bucket
    where
      not versioning_enabled;
  EOQ
}


query "ibm_cos_bucket_versioning_mfa_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning MFA Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      ibm_cos_bucket
    where
      not versioning_mfa_delete;
  EOQ
}


# Assessment Queries

query "ibm_cos_bucket_encryption_status" {
  sql = <<-EOQ
    with encryption as (
      select
        case when sse_kp_enabled then 'enabled' else 'disabled'
        end as visibility
      from
        ibm_cos_bucket
    )
    select
      visibility,
      count(*)
    from
      encryption
    group by
      visibility;
  EOQ
}

query "ibm_cos_bucket_versioning_status" {
  sql = <<-EOQ
    with versioning_status as (
      select
        case
          when versioning_enabled then 'enabled' else 'disabled'
        end as visibility
      from
        ibm_cos_bucket
    )
    select
      visibility,
      count(*)
    from
      versioning_status
    group by
      visibility;
  EOQ
}


query "ibm_cos_bucket_versioning_mfa_status" {
  sql = <<-EOQ
    with versioning_mfa_status as (
      select
        case
          when versioning_mfa_delete then 'enabled' else 'disabled'
        end as visibility
      from
        ibm_cos_bucket
    )
    select
      visibility,
      count(*)
    from
      versioning_mfa_status
    group by
      visibility;
  EOQ
}

# Analysis Queries

query "ibm_cos_bucket_by_account" {
  sql = <<-EOQ
    select
      a.name as "account",
      count(b.*) as "Buckets"
    from
      ibm_cos_bucket as b,
      ibm_account as a
    where
      a.customer_id = b.account_id
    group by
      account
    order by count(b.*) desc;
  EOQ
}


query "ibm_cos_bucket_by_region" {
  sql = <<-EOQ
    select
      region as "account",
      count(b.*) as "total"
    from
      ibm_cos_bucket as b
    group by
      region;
  EOQ
}

query "ibm_cos_bucket_by_creation_month" {
  sql = <<-EOQ
    with buckets as (
      select
        title,
        creation_date,
        to_char(creation_date,
          'YYYY-MM') as creation_month
      from
        ibm_cos_bucket
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(creation_date)
                from buckets)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    buckets_by_month as (
      select
        creation_month,
        count(*)
      from
        buckets
      group by
        creation_month
    )
    select
      months.month,
      buckets_by_month.count
    from
      months
      left join buckets_by_month on months.month = buckets_by_month.creation_month
    order by
      months.month;
  EOQ
}

