dashboard "ibm_kms_key_dashboard" {

  title         = "IBM KMS Key Dashboard"
  documentation = file("./dashboards/kms/docs/kms_key_dashboard.md")

  tags = merge(local.kms_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.ibm_kms_key_count.sql
      width = 2
    }

    #https://www.ibm.com/docs/en/cloud-private/3.2.0?topic=apis-key-management-service
    card {
      sql   = query.ibm_kms_standard_key_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_kms_root_key_count.sql
      width = 2
    }

    # Assessments
    card {
      sql   = query.ibm_kms_root_key_rotation_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_kms_key_dual_auth_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_kms_key_disabled_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"
    width = 12

    chart {
      title = "Root Key Rotation Status"
      sql   = query.ibm_kms_root_key_rotation_status.sql
      type  = "donut"
      width = 3

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
      title = "Dual Authorization Status"
      sql   = query.ibm_kms_key_dual_auth_status.sql
      type  = "donut"
      width = 3

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
      title = "Key State"
      sql   = query.ibm_kms_key_state.sql
      type  = "donut"
      width = 3

      series "count" {
        point "ok" {
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
      title = "Keys by Account"
      sql   = query.ibm_kms_key_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Region"
      sql   = query.ibm_kms_key_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Age"
      sql   = query.ibm_kms_key_by_creation_month.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by State"
      sql   = query.ibm_kms_key_by_state.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Algorithm"
      sql   = query.ibm_kms_key_by_algorithm.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "ibm_kms_key_count" {
  sql = <<-EOQ
    select count(*) as "Keys" from ibm_kms_key where state <> '5';
  EOQ
}

query "ibm_kms_standard_key_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      'Standard Keys' as label
    from
      ibm_kms_key
    where
      extractable
      and state <> '5';
  EOQ
}

query "ibm_kms_root_key_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      'Root Keys' as label
    from
      ibm_kms_key
    where
      not extractable
      and state <> '5';
  EOQ
}

query "ibm_kms_key_disabled_count" {
  sql = <<-EOQ
    select
    count(*) as value,
    'Disabled' as label,
    case count(*) when 0 then 'ok' else 'alert' end as "type"
  from
    ibm_kms_key
  where
    state in ('2', '3');
  EOQ
}

query "ibm_kms_root_key_rotation_disabled_count" {
  sql = <<-EOQ
     select
      count(*) as value,
      'Root Key Rotation Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      ibm_kms_key
    where
      rotation_policy = '{}'
      and not extractable
      and state <> '5';
  EOQ
}

query "ibm_kms_key_dual_auth_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Dual Authorization Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      ibm_kms_key
    where
      dual_auth_delete ->> 'enabled' = 'false'
      and state <> '5';
  EOQ
}

# Assessment Queries

query "ibm_kms_root_key_rotation_status" {
  sql = <<-EOQ
    select
      rotation_status,
      count(*)
    from (
      select
        case when rotation_policy = '{}' then
          'disabled'
        else
          'enabled'
        end rotation_status
      from
        ibm_kms_key
      where
        not extractable
        and state <> '5'
     ) as t
    group by
      rotation_status
    order by
      rotation_status desc;
  EOQ
}

query "ibm_kms_key_dual_auth_status" {
  sql = <<-EOQ
    select
      case when dual_auth_delete ->> 'enabled' = 'true'  then 'enabled' else 'disabled' end as status,
      count(*)
    from
      ibm_kms_key
    where
      state <> '5'
    group by
      status;
  EOQ
}

query "ibm_kms_key_state" {
  sql = <<-EOQ
    select
      case when state in ('2', '3') then 'disabled' else 'ok' end as status,
      count(*)
    from
      ibm_kms_key
    where
      state <> '5'
    group by
      status;
  EOQ
}

# Analysis Queries

query "ibm_kms_key_by_account" {
  sql = <<-EOQ
    select
      a.name as "Account",
      count(k.*) as "Keys"
    from
      ibm_kms_key as k,
      ibm_account as a
    where
      k.account_id = a.customer_id
      and k.state <> '5'
    group by
      a.name
    order by
      a.name;
  EOQ
}

query "ibm_kms_key_by_region" {
  sql = <<-EOQ
    select
      region,
      count(k.*) as "Keys"
    from
      ibm_kms_key as k
    where
      k.state <> '5'
    group by
      region;
  EOQ
}

query "ibm_kms_key_by_state" {
  sql = <<-EOQ
    select
      case
        when state = '0' then 'Pre-activation'
        when state = '1' then 'Enabled'
        when state = '2' then 'Disabled'
        when state = '3' then 'Deactivated'
        when state = '5' then 'Deleted'
        else state
        end as state_code,
      count(*)
    from
      ibm_kms_key
    group by
      state_code;
  EOQ
}

query "ibm_kms_key_by_creation_month" {
  sql = <<-EOQ
    with keys as (
      select
        title,
        creation_date,
        to_char(creation_date,
          'YYYY-MM') as creation_month
      from
        ibm_kms_key
      where
        state <> '5'
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
                from keys)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    keys_by_month as (
      select
        creation_month,
        count(*)
      from
        keys
      group by
        creation_month
    )
    select
      months.month,
      keys_by_month.count
    from
      months
      left join keys_by_month on months.month = keys_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "ibm_kms_key_by_algorithm" {
  sql = <<-EOQ
    select
      algorithm_type,
      count(k.*) as "Keys"
    from
      ibm_kms_key as k
    where
      k.state <> '5'
    group by
      algorithm_type;
  EOQ
}
