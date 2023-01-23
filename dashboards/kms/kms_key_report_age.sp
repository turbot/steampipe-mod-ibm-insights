dashboard "kms_key_age_report" {

  title         = "IBM KMS Key Age Report"
  documentation = file("./dashboards/kms/docs/kms_key_report_age.md")

  tags = merge(local.kms_common_tags, {
    type     = "Report"
    category = "Age"
  })

   container {

    card {
      width = 2
      sql   = query.kms_key_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.kms_key_24_hours_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.kms_key_30_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.kms_key_30_90_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.kms_key_90_365_days_count.sql
    }

    card {
      type  = "info"
      width = 2
      sql   = query.kms_key_1_year_count.sql
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
      href = "${dashboard.kms_key_detail.url_path}?input.key_crn={{.CRN | @uri}}"
     }

    sql = query.kms_key_age_table.sql

  }

}

query "kms_key_24_hours_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      ibm_kms_key
    where
      creation_date > now() - '1 days' :: interval
      and state <> '5';
  EOQ
}

query "kms_key_30_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '1-30 Days' as label
    from
      ibm_kms_key
    where
      creation_date between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
      and state <> '5';
  EOQ
}

query "kms_key_30_90_days_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      '30-90 Days' as label
    from
      ibm_kms_key
    where
      creation_date between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
      and state <> '5';
  EOQ
}

query "kms_key_90_365_days_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      ibm_kms_key
    where
      creation_date between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
      and state <> '5';
  EOQ
}

query "kms_key_1_year_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      ibm_kms_key
    where
      creation_date <= now() - '1 year' :: interval
      and state <> '5';
  EOQ
}

query "kms_key_age_table" {
  sql = <<-EOQ
    select
      k.name as "Name",
      now()::date - k.creation_date::date as "Age in Days",
      k.creation_date as "Create Date",
      case
        when k.state = '0' then 'Pre-activation'
        when k.state = '1' then 'Active'
        when k.state = '2' then 'Suspended'
        when k.state = '3' then 'Deactivated'
        when k.state = '5' then 'Destroyed'
        else k.state
      end as "State",
      a.name as "Account",
      k.account_id as "Account ID",
      k.region as "Region",
      k.crn as "CRN",
      k.id as "Key ID"
    from
      ibm_kms_key as k,
      ibm_account as a
    where
      k.account_id = a.customer_id
      and k.state <> '5'
    order by
      k.name;
  EOQ
}