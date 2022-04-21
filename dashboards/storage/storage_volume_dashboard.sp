dashboard "ibm_is_volume_dashboard" {

  title         = "IBM Block Storage Volume Dashboard"
  #documentation = file("./dashboards/ebs/docs/ebs_volume_dashboard.md")

  tags = merge(local.storage_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.ibm_is_volume_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_is_volume_storage_total.sql
      width = 2
    }

    # Assessments

    card {
      sql   = query.ibm_is_volume_unattached_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Attachment Status"
      sql   = query.ibm_is_volume_attachment_status.sql
      type  = "donut"
      width = 3

      series "count" {
        point "attached" {
          color = "ok"
        }
        point "unattached" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Volumes by Account"
      sql   = query.ibm_is_volume_by_account.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Region"
      sql   = query.ibm_is_volume_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Zone"
      sql   = query.ibm_is_volume_by_zone.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Age"
      sql   = query.ibm_is_volume_by_creation_month.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volume by Encryption Type"
      sql   = query.ibm_is_volume_by_encryption_type.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volume by Profile"
      sql   = query.ibm_is_volume_by_profile.sql
      type  = "column"
      width = 3

    }

  }

  container {

    chart {
      title = "Storage by Account (GB)"
      sql   = query.ibm_is_volume_storage_by_account.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region"
      sql   = query.ibm_is_volume_storage_by_region.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Zone (GB)"
      sql   = query.ibm_is_volume_storage_by_zone.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      sql   = query.ibm_is_volume_storage_by_creation_month.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

  }

}

# Card Queries

query "ibm_is_volume_count" {
  sql = <<-EOQ
    select
      count(*) as "Volumes"
    from
      ibm_is_volume;
  EOQ
}

query "ibm_is_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(capacity) as "Total Storage (GB)"
    from
      ibm_is_volume;
  EOQ
}

query "ibm_is_volume_unattached_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unattached' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      ibm_is_volume
    where
      jsonb_array_length(volume_attachments) = 0;
  EOQ
}


# Assessment Queries

query "ibm_is_volume_attachment_status" {
  sql = <<-EOQ
    with attachment_state as (
      select
        case
          when jsonb_array_length(volume_attachments) > 0 then 'attached'
          else 'unattached'
        end as attachment_status
      from
        ibm_is_volume
    )
    select
      attachment_status,
      count(*)
    from
      attachment_state
    group by
      attachment_status;
  EOQ
}

# Analysis Queries

query "ibm_is_volume_by_account" {
  sql = <<-EOQ
    select
      a.name as "account",
      count(v.*) as "volumes"
    from
      ibm_is_volume as v,
      ibm_account as a
    where
      a.customer_id = v.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "ibm_is_volume_storage_by_account" {
  sql = <<-EOQ
    select
      a.name as "account",
      sum(v.capacity) as "GB"
    from
      ibm_is_volume as v,
      ibm_account as a
    where
      a.customer_id = v.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "ibm_is_volume_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "volumes"
    from
      ibm_is_volume
    group by
      region
    order by
      region;
  EOQ
}

query "ibm_is_volume_by_zone" {
  sql = <<-EOQ
    select
      zone -> 'name' as "Zone",
      count(*) as "volumes"
    from
      ibm_is_volume
    group by
      zone -> 'name'
    order by
      zone -> 'name';
  EOQ
}

query "ibm_is_volume_by_profile" {
  sql = <<-EOQ
    select
      profile -> 'name' as "Profile",
      count(*) as "volumes"
    from
      ibm_is_volume
    group by
      profile -> 'name'
    order by
      profile -> 'name';
  EOQ
}


query "ibm_is_volume_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(capacity) as "GB"
    from
      ibm_is_volume
    group by
      region
    order by
      region;
  EOQ
}

query "ibm_is_volume_storage_by_zone" {
  sql = <<-EOQ
    select
      zone -> 'name' as "Zone",
      sum(capacity) as "GB"
    from
      ibm_is_volume
    group by
      zone -> 'name'
    order by
      zone -> 'name';
  EOQ
}

query "ibm_is_volume_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        ibm_is_volume
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_at)
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
      select
        creation_month,
        count(*)
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      volumes_by_month.count
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "ibm_is_volume_storage_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        capacity,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        ibm_is_volume
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_at)
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
      select
        creation_month,
        sum(capacity) as size
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      volumes_by_month.size as "GB"
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "ibm_is_volume_by_encryption_type" {
  sql = <<-EOQ
    select
      encryption as "Encryption Type",
      count(*) as "Volumes"
    from
      ibm_is_volume
    group by
      encryption
    order by
      encryption;
  EOQ
}
