dashboard "compute_instance_disk_age_report" {

  title         = "IBM Compute Instance Disk Age Report"
  documentation = file("./dashboards/compute/docs/compute_instance_disk_report_age.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.compute_instance_disk_count
      width = 2
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_instance_disk_24_hours_count
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_instance_disk_30_days_count
    }

    card {
      type  = "info"
      width = 2
      query = query.compute_instance_disk_30_90_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.compute_instance_disk_90_365_days_count
    }

    card {
      width = 2
      type  = "info"
      query = query.compute_instance_disk_1_year_count
    }

  }

  table {
    column "Account ID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.compute_instance_disk_detail.url_path}?input.disk_id={{.ID | @uri}}"
    }

    query = query.compute_instance_disk_age_table
  }

}

query "compute_instance_disk_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      ibm_is_instance_disk
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "compute_instance_disk_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      ibm_is_instance_disk
    where
      created_at between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "compute_instance_disk_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      ibm_is_instance_disk
    where
      created_at between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "compute_instance_disk_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      ibm_is_instance_disk
    where
      created_at between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "compute_instance_disk_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      ibm_is_instance_disk
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "compute_instance_disk_age_table" {
  sql = <<-EOQ
    select
      d.name as "Name",
      d.id as "ID",
      now()::date - d.created_at::date as "Age in Days",
      d.created_at as "Create Time",
      a.name as "Account",
      d.account_id as "Account ID",
      d.region as "Region"
    from
      ibm_is_instance_disk as d,
      ibm_account as a
    where
      d.account_id = a.customer_id
    order by
      d.name;
  EOQ
}
