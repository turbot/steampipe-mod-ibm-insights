dashboard "blockstorage_volume_report_age" {

  title         = "IBM Block Storage Volume Age Report"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_volume_report_age.md")

  tags = merge(local.blockstorage_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      width = 2
      sql   = query.blockstorage_volume_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.blockstorage_volume_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.blockstorage_volume_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.blockstorage_volume_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.blockstorage_volume_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.blockstorage_volume_1_year_count.sql
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "CRN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.blockstorage_volume_detail.url_path}?input.volume_arn={{.CRN | @uri}}"
    }

    sql = query.blockstorage_volume_age_table.sql
  }

}

query "blockstorage_volume_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      ibm_is_volume
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "blockstorage_volume_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      ibm_is_volume
    where
      created_at between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "blockstorage_volume_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      ibm_is_volume
    where
      created_at between symmetric now() - '30 days' :: interval
      and now() - '90 days' :: interval;
  EOQ
}

query "blockstorage_volume_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      ibm_is_volume
    where
      created_at between symmetric (now() - '90 days'::interval)
      and (now() - '365 days'::interval);
  EOQ
}

query "blockstorage_volume_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      ibm_is_volume
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "blockstorage_volume_age_table" {
  sql = <<-EOQ
    select
      v.name as "Name",
      now()::date - v.created_at::date as "Age in Days",
      v.created_at as "Create Time",
      v.status as "Status",
      a.name as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.zone ->> 'name' as "Zone",
      v.crn as "CRN",
      v.id as "ID"
    from
      ibm_is_volume as v,
      ibm_account as a
    where
      v.account_id = a.customer_id
    order by
      v.name;
  EOQ
}
