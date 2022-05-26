dashboard "ibm_blockstorage_volume_detail" {

  title         = "IBM Block Storage Volume Detail"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_volume_detail.md")

  tags = merge(local.blockstorage_common_tags, {
    type = "Detail"
  })

  input "volume_crn" {
    title = "Select a volume:"
    sql   = query.ibm_is_volume_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ibm_is_volume_storage
      args = {
        crn = self.input.volume_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_is_volume_iops
      args = {
        crn = self.input.volume_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_is_volume_attached_instances_count
      args = {
        crn = self.input.volume_crn.value
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
        query = query.ibm_is_volume_overview
        args = {
          crn = self.input.volume_crn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.ibm_is_volume_tags
        args = {
          crn = self.input.volume_crn.value
        }
      }
    }

    container {

      width = 6

      table {
        title = "Attached To"
        query = query.ibm_is_volume_attached_instances
        args = {
          crn = self.input.volume_crn.value
        }

        column "Instance CRN" {
          display = "none"
        }

        column "Instance Name" {
          href = "${dashboard.ibm_compute_instance_detail.url_path}?input.instance_crn={{.'Instance CRN' | @uri}}"
        }
      }

      table {
        title = "Encryption Details"

        query = query.ibm_is_volume_encryption_status
        args = {
          crn = self.input.volume_crn.value
        }
      }
    }
  }

}

query "ibm_is_volume_input" {
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
      ibm_is_volume
    order by
      title;
  EOQ
}

query "ibm_is_volume_storage" {
  sql = <<-EOQ
    select
      'Capacity (GB)' as label,
      sum(capacity) as value
    from
      ibm_is_volume
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_volume_iops" {
  sql = <<-EOQ
    select
      'IOPS' as label,
      iops as value
    from
      ibm_is_volume
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_volume_state" {
  sql = <<-EOQ
    select
      'Status' as label,
      status as value
    from
      ibm_is_volume
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_volume_attached_instances_count" {
  sql = <<-EOQ
    select
      'Attached Instances' as label,
      case
        when jsonb_array_length(volume_attachments) = 0 then 0
        else jsonb_array_length(volume_attachments)
      end as value,
      case
        when jsonb_array_length(volume_attachments) > 0 then 'ok'
        else 'alert'
      end as "type"
    from
      ibm_is_volume
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_volume_encryption" {
  sql = <<-EOQ
    select
      'Encryption Type' as label,
      encryption as value
    from
      ibm_is_volume
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_volume_attached_instances" {
  sql = <<-EOQ
    select
      a -> 'instance' ->> 'name' as "Instance Name",
      a -> 'instance' ->> 'id' as "Instance ID",
      a -> 'delete_volume_on_instance_delete' as "Delete Volume On Instance Delete",
      a -> 'instance' ->> 'crn' as "Instance CRN"
    from
      ibm_is_volume as v,
      jsonb_array_elements(volume_attachments) as a
    where
      v.crn = $1
    order by
      a -> 'instance' ->> 'name';
  EOQ

  param "crn" {}
}

query "ibm_is_volume_encryption_status" {
  sql = <<-EOQ
    select
      case when encryption = 'user_managed' then 'User Managed' else 'Provider Managed' end as "Encryption Type",
      encryption_key as "Encryption Key"
    from
      ibm_is_volume
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_volume_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "ID",
      status as "Status",
      title as "Title",
      href as "HREF",
      resource_group ->> 'name' as "Resource Group",
      zone ->> 'name' as "Zone",
      region as "Region",
      account_id as "Account ID",
      crn as "CRN"
    from
      ibm_is_volume
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_volume_tags" {
  sql = <<-EOQ
    select
      (trim('"' from tag::text)) as "User Tag"
    from
      ibm_is_volume,
      jsonb_array_elements(tags) as tag
    where
      crn = $1
    order by
      tag;
  EOQ

  param "crn" {}
}
