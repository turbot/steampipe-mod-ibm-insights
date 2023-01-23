dashboard "compute_instance_detail" {

  title         = "IBM Compute Instance Detail"
  documentation = file("./dashboards/compute/docs/compute_instance_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "instance_crn" {
    title = "Select an instance:"
    sql   = query.compute_instance_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.compute_instance_status
      args  = [self.input.instance_crn.value]
    }

    card {
      width = 2
      query = query.compute_instance_total_vcpu_count
      args  = [self.input.instance_crn.value]
    }

    card {
      width = 2
      query = query.compute_instance_memory
      args  = [self.input.instance_crn.value]
    }

    card {
      width = 2
      query = query.compute_instance_bandwidth
      args  = [self.input.instance_crn.value]
    }

    card {
      width = 2
      query = query.compute_instance_architecture
      args  = [self.input.instance_crn.value]
    }

    card {
      width = 2
      query = query.compute_public_instance
      args  = [self.input.instance_crn.value]
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.compute_instance_overview
        args = [self.input.instance_crn.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_instance_tags
        args  = [self.input.instance_crn.value]
      }
    }
    container {
      width = 6

      table {
        title = "Boot Volume"
        query = query.compute_instance_boot_volume
        args  = [self.input.instance_crn.value]
      }

      table {
        title = "Data Volumes"
        query = query.compute_instance_data_volume
        args  = [self.input.instance_crn.value]
      }
    }

  }

  container {
    width = 12

    table {
      title = "Instance Storage Disks"
      query = query.compute_instance_disks
      args  = [self.input.instance_crn.value]
    }

  }

  container {
    width = 12

    table {
      title = "Image"
      query = query.compute_instance_image
      args  = [self.input.instance_crn.value]
    }

  }



  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.compute_instance_network_interfaces
      args  = [self.input.instance_crn.value]
    }

  }

  container {

    table {
      title = "VPC"
       width = 6
      query = query.compute_instance_vpc
      args  = [self.input.instance_crn.value]
    }

    table {
      title = "Zone"
       width = 6
      query = query.compute_instance_zone
      args  = [self.input.instance_crn.value]
    }

  }

}

query "compute_instance_input" {
  sql = <<-EOQ
    select
      title as label,
      crn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'id', id
      ) as tags
    from
      ibm_is_instance
    order by
      title;
  EOQ
}

query "compute_instance_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      initcap(status) as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}

query "compute_instance_total_vcpu_count" {
  sql = <<-EOQ
    select
      'vCPUs' as label,
      sum((vcpu ->> 'count')::int) as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}

query "compute_instance_memory" {
  sql = <<-EOQ
    select
      'Memory (GiB)' as label,
      memory  as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}

query "compute_instance_bandwidth" {
  sql = <<-EOQ
    select
      'Bandwidth (Mbps)' as label,
      bandwidth  as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}

query "compute_instance_architecture" {
  sql = <<-EOQ
    select
      'Architecture' as label,
      vcpu ->> 'architecture' as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}

query "compute_public_instance" {
  sql = <<-EOQ
    select
      'Public Access' as label,
      case when jsonb_array_length(floating_ips) <> 0 then 'Enabled' else 'Disabled' end as value,
      case When jsonb_array_length(floating_ips) <> 0 then 'alert' else 'ok' end as "type"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}

query "compute_instance_image" {
  sql = <<-EOQ
    select
      image ->> 'name' as "Name",
      image ->> 'id' as "ID",
      image ->> 'href' as "HREF"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}


query "compute_instance_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "ID",
      created_at as "Created At",
      title as "Title",
      href as "HREF",
      region as "Region",
      account_id as "Account ID",
      crn as "CRN"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}


query "compute_instance_boot_volume" {
  sql = <<-EOQ
    select
      boot_volume_attachment -> 'volume' ->> 'name' as "Name",
      boot_volume_attachment -> 'volume' ->> 'id' as "ID",
      boot_volume_attachment ->> 'name' as "Attachment Name",
      boot_volume_attachment ->> 'id'  as "Attachment ID"
    from
      ibm_is_instance
    where
      crn = $1
    order by
      boot_volume_attachment -> 'volume' ->> 'name';
  EOQ
}

query "compute_instance_data_volume" {
  sql = <<-EOQ
    select
      a -> 'volume' ->> 'name' as "Name",
      a -> 'volume' ->> 'id'  as "ID",
      a ->> 'name' as "Attachment Name",
      a ->> 'id'  as "Attachment ID"
    from
      ibm_is_instance,
      jsonb_array_elements(volume_attachments) as a
    where
      a ->> 'id' <> boot_volume_attachment ->> 'id'
      and crn = $1
    order by
      a -> 'volume' ->> 'name';
  EOQ
}

query "compute_instance_disks" {
  sql = <<-EOQ
    select
      d ->> 'name' as "Name",
      d ->> 'id' as "ID",
      d ->> 'size' as "Size",
      d ->> 'interface_type' as "Interface Type",
      d ->> 'resource_type' as "Resource Type",
      d ->> 'created_at' as "Create Time",
      d ->> 'href' as "HREF"
    from
      ibm_is_instance,
      jsonb_array_elements(disks) as d
    where
      crn = $1
    order by
      d ->> 'name';
  EOQ
}

query "compute_instance_vpc" {
  sql = <<-EOQ
    select
      vpc ->> 'name'  as "Name",
      vpc ->> 'id' as "ID",
      vpc ->> 'href' as "HREF",
      vpc ->> 'crn' as "CRN"
    from
      ibm_is_instance
    where
      crn = $1
    order by
      vpc ->> 'name';
  EOQ
}

query "compute_instance_network_interfaces" {
  sql = <<-EOQ
    select
      i ->> 'name' as "Name",
      i ->> 'id' as "ID",
      i ->> 'primary_ipv4_address' as "Primary IPv4 Address",
      i -> 'subnet' ->> 'name' as "Subnet Name",
      i -> 'subnet' ->> 'id' as "Subnet ID"
    from
      ibm_is_instance,
      jsonb_array_elements(network_interfaces) as i
    where
      crn = $1
    order by
      i ->> 'name';
  EOQ
}

query "compute_instance_zone" {
  sql = <<-EOQ
    select
      zone ->> 'name' as "Name",
      zone ->> 'href' as "HREF"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ
}

query "compute_instance_tags" {
  sql = <<-EOQ
    select
      (trim('"' FROM tag::text)) as "User Tags"
    from
      ibm_is_instance,
      jsonb_array_elements(tags) as tag
    where
      crn = $1
    order by
      tag;
  EOQ
}