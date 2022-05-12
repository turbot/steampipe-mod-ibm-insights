dashboard "ibm_vpc_age_report" {

  title         = "IBM VPC Age Report"
  documentation = file("./dashboards/vpc/docs/vpc_report_age.md")

  tags = merge(local.vpc_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.ibm_is_vpc_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_is_vpc_24_hours_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_vpc_30_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_vpc_30_90_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_vpc_90_365_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_vpc_1_year_count.sql
      width = 2
      type  = "info"
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
      href = "${dashboard.ibm_vpc_detail.url_path}?input.vpc_crn={{.CRN | @uri}}"
    }

    sql = query.ibm_is_vpc_age_table.sql
  }

}

query "ibm_is_vpc_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      ibm_is_vpc
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "ibm_is_vpc_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      ibm_is_vpc
    where
      created_at between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "ibm_is_vpc_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      ibm_is_vpc
    where
      created_at between symmetric now() - '30 days' :: interval
      and now() - '90 days' :: interval;
  EOQ
}

query "ibm_is_vpc_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      ibm_is_vpc
    where
      created_at between symmetric (now() - '90 days'::interval)
      and (now() - '365 days'::interval);
  EOQ
}

query "ibm_is_vpc_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      ibm_is_vpc
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "ibm_is_vpc_age_table" {
  sql = <<-EOQ
    select
      v.name as "Name",
      now()::date - v.created_at::date as "Age in Days",
      v.created_at as "Create Time",
      v.status as "Status",
      a.name as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.crn as "CRN"
    from
      ibm_is_vpc as v,
      ibm_account as a
    where
      v.account_id = a.customer_id
    order by
      v.name;
  EOQ
}
