dashboard "compute_instance_disk_detail" {

  title         = "IBM Compute Instance Disk Detail"
  documentation = file("./dashboards/compute/docs/compute_instance_disk_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "disk_id" {
    title = "Select a disk:"
    query = query.compute_instance_disk_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.compute_instance_disk_storage
      args = [self.input.disk_id.value]
    }

    card {
      width = 3
      query = query.compute_unused_instance_disk
      args = [self.input.disk_id.value]
    }
  }

  container {

    container {

      table {
        title = "Overview"
        type  = "line"
        width = 4
        query = query.compute_instance_disk_overview
        args = [self.input.disk_id.value]
      }

      table {
        title = "Attached To"
        width = 8
        query = query.compute_instance_disk_attached_instances
        args = [self.input.disk_id.value]

        column "CRN" {
          display = "none"
        }

        column "Instance Name" {
          href = "${dashboard.compute_instance_detail.url_path}?input.instance_crn={{.CRN | @uri}}"
        }
      }
    }
  }
}


query "compute_instance_disk_input" {
  sql = <<-EOQ
    select
      title as label,
      id as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'id', id
      ) as tags
    from
      ibm_is_instance_disk
    order by
      title;
  EOQ
}

query "compute_instance_disk_storage" {
  sql = <<-EOQ
    select
      'Storage (GB)' as label,
      sum(size) as value
    from
      ibm_is_instance_disk
    where
      id = $1;
  EOQ
}

query "compute_unused_instance_disk" {
  sql = <<-EOQ
    select
      'Status' as label,
      case when i.status = 'running' then 'In-Use' else 'Unused' end as value,
      case when i.status = 'running' then 'ok' else 'alert' end as type
    from
      ibm_is_instance_disk as d,
  	  ibm_is_instance as i
    where
      d.instance_id = i.id
      and d.id = $1;
  EOQ
}

query "compute_instance_disk_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "ID",
      created_at as "Create Time",
      interface_type as "Interface Type",
      title as "Title",
      region as "Region",
      account_id as "Account ID"
    from
      ibm_is_instance_disk
    where
      id = $1;
  EOQ
}

query "compute_instance_disk_attached_instances" {
  sql = <<-EOQ
    select
      i.name as "Instance Name",
      i.id as "Instance ID",
      i.crn as "CRN",
      i.status as "Status",
      i.created_at as "Create Time"
    from
      ibm_is_instance_disk as d,
      ibm_is_instance as i
    where
      d.instance_id = i.id
      and d.id = $1
    order by
      i.name;
  EOQ
}
