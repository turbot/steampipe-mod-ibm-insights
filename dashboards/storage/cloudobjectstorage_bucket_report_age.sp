dashboard "ibm_cos_bucket_age_report" {

  title         = "IBM Cloud Object Storage Bucket Age Report"
  documentation = file("./dashboards/storage/docs/cloudobjectstorage_report_age.md")

  tags = merge(local.storage_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.ibm_cos_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_cos_bucket_24_hours_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_cos_bucket_30_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_cos_bucket_30_90_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_cos_bucket_90_365_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_cos_bucket_1_year_count.sql
      width = 2
      type  = "info"
    }

  }

  table {

    column "Name" {
      href = "${dashboard.ibm_cos_bucket_detail.url_path}?input.bucket_name={{.Name | @uri}}"
    }

    sql = query.ibm_cos_bucket_age_table.sql
  }

}

query "ibm_cos_bucket_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      ibm_cos_bucket
    where
      creation_date > now() - '1 days' :: interval;
  EOQ
}

query "ibm_cos_bucket_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      ibm_cos_bucket
    where
      creation_date between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "ibm_cos_bucket_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      ibm_cos_bucket
    where
      creation_date between symmetric now() - '30 days' :: interval
      and now() - '90 days' :: interval;
  EOQ
}

query "ibm_cos_bucket_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      ibm_cos_bucket
    where
      creation_date between symmetric (now() - '90 days'::interval)
      and (now() - '365 days'::interval);
  EOQ
}

query "ibm_cos_bucket_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      ibm_cos_bucket
    where
      creation_date <= now() - '1 year' :: interval;
  EOQ
}

query "ibm_cos_bucket_age_table" {
  sql = <<-EOQ
    select
      b.name as "Name",
      now()::date - b.creation_date::date as "Age in Days",
      b.creation_date as "Create Time",
      b.region as "Region"
    from
      ibm_cos_bucket as b
    order by
      b.name;
  EOQ
}
