dashboard "ibm_compute_instance_detail" {

  title         = "IBM Compute Instance Detail"
  documentation = file("./dashboards/compute/docs/compute_instance_detail.md")

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "instance_crn" {
    title = "Select an instance:"
    sql   = query.ibm_compute_instance_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ibm_compute_instance_status
      args  = {
        crn = self.input.instance_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_compute_instance_total_vcpu_count
      args  = {
        crn = self.input.instance_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_compute_instance_memory
      args  = {
        crn = self.input.instance_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_compute_instance_bandwidth
      args  = {
        crn = self.input.instance_crn.value
      }
    }


    card {
      width = 2
      query = query.ibm_compute_instance_architecture
      args  = {
        crn = self.input.instance_crn.value
      }
    }
  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.ibm_compute_instance_overview
        args = {
          crn = self.input.instance_crn.value
        }

      }

      # table {
      #   title = "Tags"
      #   width = 6
      #   query = query.ibm_compute_instance_tags
      #   args  = {
      #     crn = self.input.instance_crn.value
      #   }
      # }
    }
    container {
      width = 6

      table {
        title = "Boot Volume"
        query = query.ibm_compute_instance_boot_volume
        args  = {
          crn = self.input.instance_crn.value
        }
      }

      table {
        title = "Volume"
        query = query.ibm_compute_instance_volume
        args  = {
          crn = self.input.instance_crn.value
        }
      }
    }

  }

  container {
    width = 12

    table {
      title = "Image"
      query = query.ibm_compute_instance_image
      args  = {
        crn = self.input.instance_crn.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Disks"
      query = query.ibm_compute_instance_disks
      args  = {
        crn = self.input.instance_crn.value
      }
    }

  }

  container {
    width = 12

    table {
      title = "Network Interfaces"
      query = query.ibm_compute_instance_network_interfaces
      args  = {
        crn = self.input.instance_crn.value
      }
    }

  }

  container {

    table {
      title = "VPC"
       width = 6
      query = query.ibm_compute_instance_vpc
      args  = {
        crn = self.input.instance_crn.value
      }
    }

    table {
      title = "Zone"
       width = 6
      query = query.ibm_compute_instance_zone
      args  = {
        crn = self.input.instance_crn.value
      }
    }

  }

}

query "ibm_compute_instance_input" {
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

query "ibm_compute_instance_status" {
  sql = <<-EOQ
    select
      'Status' as label,
      status as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}

}

query "ibm_compute_instance_total_vcpu_count" {
  sql = <<-EOQ
    select
      'Total vCPU' as label,
      sum((vcpu ->> 'count')::int) as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_compute_instance_memory" {
  sql = <<-EOQ
    select
      'Memory (GiB)' as label,
      memory  as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}


query "ibm_compute_instance_bandwidth" {
  sql = <<-EOQ
    select
      'Bandwidth' as label,
      bandwidth  as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_compute_instance_architecture" {
  sql = <<-EOQ
    select
      'Architecture' as label,
      vcpu ->> 'architecture' as value
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}


query "ibm_compute_instance_image" {
  sql = <<-EOQ
    select
      image ->> 'name' as "Name",
      image ->> 'id' as "ID",
      image ->> 'href' as "HREF",
      image ->> 'crn' as "CRN"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}


query "ibm_compute_instance_overview" {
  sql = <<-EOQ
    select
      'name' as "Name",
      id as "ID",
      created_at as "Created At",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      crn as "CRN"
    from
      ibm_is_instance
    where
      crn = $1
  EOQ

  param "crn" {}
}

# query "ibm_compute_instance_tags" {
#   sql = <<-EOQ
#     with jsondata as (
#       select
#         tags::json as tags
#       from
#         ibm_is_instance
#       where
#         crn = 'crn:v1:bluemix:public:is:us-south-2:a/76aa4877fab6436db86f121f62faf221::instance:0727_4708987f-5fc9-4a33-8586-147a5e147ec9'
#       )
#     select
#       key as "Key",
#       value as "Value"
#     from
#       ibm_is_instance,
#       json_array_elements_text(tags);
#     EOQ

#     param "crn" {}
# }

query "ibm_compute_instance_boot_volume" {
  sql = <<-EOQ
    select
      boot_volume_attachment ->> 'name' as "Boot Volume Attachment Name",
      boot_volume_attachment ->> 'id'  as "Boot Volume Attachment ID",
      boot_volume_attachment -> 'volume' ->> 'name' as "Boot Volume Name",
      boot_volume_attachment -> 'volume' ->> 'id'  as "Boot Volume ID"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_compute_instance_volume" {
  sql = <<-EOQ
    select
      a ->> 'name' as "Volume Attachment Name",
      a ->> 'id'  as "Volume Attachment ID",
      a -> 'volume' ->> 'name' as "Volume Name",
      a -> 'volume' ->> 'id'  as "Volume ID"
    from
      ibm_is_instance,
      jsonb_array_elements(volume_attachments) as a
    where
      a ->> 'id' <> boot_volume_attachment ->> 'id'
      and crn = $1
  EOQ

  param "crn" {}
}

query "ibm_compute_instance_disks" {
  sql = <<-EOQ
    select
      d ->> 'name'  as "Name",
      d ->> 'size' as "Size",
      d ->> 'interface_type' as "Interface Type",
      d ->> 'resource_type' as "Resource Type",
      d ->> 'created_at' as "Created At",
      d ->> 'id' as "ID",
      d ->> 'href' as "HREF"
    from
      ibm_is_instance,
      jsonb_array_elements(disks) as d
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_compute_instance_vpc" {
  sql = <<-EOQ
    select
      vpc ->> 'name'  as "Name",
      vpc ->> 'id' as "ID",
      vpc ->> 'href' as "HREF",
      vpc ->> 'crn' as "CRN"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_compute_instance_network_interfaces" {
  sql = <<-EOQ
    select
      i ->> 'id' as "ID",
      i ->> 'name' as "Name",
      i ->> 'primary_ipv4_address' as "Primary IPV4 Address",
      i -> 'subnet' ->> 'name' as "Subnet Name",
      i -> 'subnet' ->> 'id' as "Subnet ID"
    from
      ibm_is_instance,
      jsonb_array_elements(network_interfaces) as i
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_compute_instance_zone" {
  sql = <<-EOQ
    select
      zone ->> 'name' as "Name",
      zone ->> 'href' as "HREF"
    from
      ibm_is_instance
    where
      crn = $1;
  EOQ

  param "crn" {}
}
