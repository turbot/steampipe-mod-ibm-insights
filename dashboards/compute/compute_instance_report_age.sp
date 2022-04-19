dashboard "ibm_compute_instance_age_report" {

  title         = "IBM Compute Instance Age Report"
  documentation = file("./dashboards/compute/docs/compute_instance_report_age.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

   container {

    card {
      sql   = query.ibm_compute_instance_count.sql
      width = 2
    }

    card {
      type  = "info"
      width = 2
      sql   = query.ibm_compute_instance_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.ibm_compute_instance_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.ibm_compute_instance_30_90_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.ibm_compute_instance_90_365_days_count.sql
    }

    card {
      width = 2
      type  = "info"
      sql   = query.ibm_compute_instance_1_year_count.sql
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "CRN" {
      display = "none"
    }
    sql = query.ibm_compute_instance_age_table.sql
  }

}

query "ibm_compute_instance_24_hours_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      ibm_is_instance
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "ibm_compute_instance_30_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      ibm_is_instance
    where
      created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "ibm_compute_instance_30_90_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      ibm_is_instance
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "ibm_compute_instance_90_365_days_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      ibm_is_instance
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "ibm_compute_instance_1_year_count" {
  sql   = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      ibm_is_instance
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "ibm_compute_instance_age_table" {
  sql = <<-EOQ
    select
      i.id as "ID",
      i.name as "Name",
      now()::date - i.created_at::date as "Age in Days",
      i.created_at as "Created At",
      i.status as "Status",
      a.name as "Account",
      i.account_id as "Account ID",
      i.region as "Region",
      i.crn as "CRN"
    from
      ibm_is_instance as i,
      ibm_account as a
    where
      i.account_id = a.customer_id
    order by
      i.id;
  EOQ
}
