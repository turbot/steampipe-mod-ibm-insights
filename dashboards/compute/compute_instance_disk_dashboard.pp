dashboard "ibm_compute_instance_disk_dashboard" {

  title         = "IBM Compute Instance Disk Dashboard"
  documentation = file("./dashboards/compute/docs/compute_instance_disk_dashboard.md")

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis

    card {
      query = query.ibm_compute_instance_disk_count
      width = 2
    }

    card {
      query = query.ibm_compute_instance_disk_total_storage
      width = 2
    }

    # Assessments

    card {
      query = query.ibm_compute_unused_instance_disk_count
      width = 2
    }
  }

  container {

    title = "Assessments"
    width = 12

    chart {
      title = "Disk State"
      query = query.ibm_compute_instance_disk_by_instance_state
      type  = "donut"
      width = 3

      series "count" {
        point "in-use" {
          color = "ok"
        }
        point "unused" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Disks by Account"
      query = query.ibm_compute_instance_disk_by_account
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by Region"
      query = query.ibm_compute_instance_disk_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by Interface Type"
      query = query.ibm_compute_instance_disk_by_interface_type
      type  = "column"
      width = 3
    }

    chart {
      title = "Disks by Age"
      query = query.ibm_compute_instance_disk_by_creation_month
      type  = "column"
      width = 3
    }
  }

  container {

    chart {
      title = "Storage by Account (GB)"
      query = query.ibm_compute_instance_disk_storage_by_account
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      query = query.ibm_compute_instance_disk_storage_by_region
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Interface Type (GB)"
      query = query.ibm_compute_instance_disk_storage_by_interface_type
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      query = query.ibm_compute_instance_disk_storage_by_creation_month
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }
  }
}

# Card Queries

query "ibm_compute_instance_disk_count" {
  sql = <<-EOQ
    select count(*) as "Disks" from ibm_is_instance_disk;
  EOQ
}

query "ibm_compute_instance_disk_total_storage" {
  sql = <<-EOQ
    select
      sum(size) as "Total Storage (GB)"
    from
      ibm_is_instance_disk;
  EOQ
}

query "ibm_compute_unused_instance_disk_count" {
  sql = <<-EOQ
    select
      count(d.*) as value,
      'Unused' as label,
      case count(d.*) when 0 then 'ok' else 'alert' end as "type"
    from
      ibm_is_instance_disk as d,
  	  ibm_is_instance as i
    where
      d.instance_id = i.id
  	  and i.status <> 'running';
  EOQ
}

# Assessment Queries

query "ibm_compute_instance_disk_by_instance_state" {
  sql = <<-EOQ
    with disks as (
      select
        case
          when i.status <> 'running' then 'unused'
          else 'in-use' 
		  end as state
		from
			ibm_is_instance_disk as d,
			ibm_is_instance as i
		where
			d.instance_id = i.id
	)
    select
      state,
      count(*)
    from
      disks
    group by
      state;
  EOQ
}

# Analysis Queries

query "ibm_compute_instance_disk_by_account" {
  sql = <<-EOQ
    select
      a.name as "account",
      count(d.*) as "disks"
    from
      ibm_is_instance_disk as d,
      ibm_account as a
    where
      a.customer_id = d.account_id
    group by
      account
    order by count(d.*) desc;
  EOQ
}

query "ibm_compute_instance_disk_by_region" {
  sql = <<-EOQ
    select
      region,
      count(*) as "disks"
    from
      ibm_is_instance_disk
    group by
      region;
  EOQ
}

query "ibm_compute_instance_disk_by_interface_type" {
  sql = <<-EOQ
    select
      interface_type as "Interface Type",
      count(i.*) as "disks"
    from
      ibm_is_instance_disk as i
    group by
      interface_type;
  EOQ
}

query "ibm_compute_instance_disk_by_creation_month" {
  sql = <<-EOQ
    with disks as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        ibm_is_instance_disk
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
                from disks)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    disks_by_month as (
      select
        creation_month,
        count(*)
      from
        disks
      group by
        creation_month
    )
    select
      months.month,
      disks_by_month.count
    from
      months
      left join disks_by_month on months.month = disks_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "ibm_compute_instance_disk_storage_by_account" {
  sql = <<-EOQ
    select
      a.name as "account",
      sum(d.size) as "GB"
    from
      ibm_is_instance_disk as d,
      ibm_account as a
    where
      a.customer_id = d.account_id
    group by
      account
    order by count(d.*) desc;
  EOQ
}

query "ibm_compute_instance_disk_storage_by_region" {
  sql = <<-EOQ
    select
      region,
      sum(size) as "GB"
    from
      ibm_is_instance_disk
    group by
      region;
  EOQ
}

query "ibm_compute_instance_disk_storage_by_interface_type" {
  sql = <<-EOQ
    select
      interface_type as "Interface Type",
      sum(size) as "GB"
    from
      ibm_is_instance_disk
    group by
      interface_type;
  EOQ
}

query "ibm_compute_instance_disk_storage_by_creation_month" {
  sql = <<-EOQ
    with disks as (
      select
        title,
        created_at,
		size,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        ibm_is_instance_disk
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
                from disks)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    disks_by_month as (
      select
        creation_month,
        sum(size)
      from
        disks
      group by
        creation_month
    )
    select
      months.month,
      disks_by_month.sum as "GB"
    from
      months
      left join disks_by_month on months.month = disks_by_month.creation_month
    order by
      months.month;
  EOQ
}
