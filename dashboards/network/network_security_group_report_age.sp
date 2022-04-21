dashboard "ibm_is_security_group_age_report" {

  title         = "IBM Security Group Age Report"
  documentation = file("./dashboards/network/docs/network_security_group_report_age.md")

  tags = merge(local.network_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.ibm_is_security_group_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_is_security_group_24_hours_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_security_group_30_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_security_group_30_90_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_security_group_90_365_days_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.ibm_is_security_group_1_year_count.sql
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

    sql = query.ibm_is_security_group_age_table.sql
  }

}

query "ibm_is_security_group_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      ibm_is_security_group
    where
      created_at > now() - '1 days' :: interval;
  EOQ
}

query "ibm_is_security_group_30_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      ibm_is_security_group
    where
      created_at between symmetric now() - '1 days' :: interval
      and now() - '30 days' :: interval;
  EOQ
}

query "ibm_is_security_group_30_90_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      ibm_is_security_group
    where
      created_at between symmetric now() - '30 days' :: interval
      and now() - '90 days' :: interval;
  EOQ
}

query "ibm_is_security_group_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      ibm_is_security_group
    where
      created_at between symmetric (now() - '90 days'::interval)
      and (now() - '365 days'::interval);
  EOQ
}

query "ibm_is_security_group_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      ibm_is_security_group
    where
      created_at <= now() - '1 year' :: interval;
  EOQ
}

query "ibm_is_security_group_age_table" {
  sql = <<-EOQ
    select
      sg.id as "ID",
      sg.name as "Name",
      now()::date - sg.created_at::date as "Age in Days",
      sg.created_at as "Created At",
      a.name as "Account",
      sg.account_id as "Account ID",
      sg.region as "Region",
      sg.crn as "CRN"
    from
      ibm_is_security_group as sg,
      ibm_account as a
    where
      sg.account_id = a.customer_id
    order by
      sg.name ;
  EOQ
}
