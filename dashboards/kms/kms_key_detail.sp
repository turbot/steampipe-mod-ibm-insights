dashboard "ibm_kms_key_detail" {

  title         = "IBM KMS Key Detail"
  documentation = file("./dashboards/kms/docs/kms_key_detail.md")

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })


  input "key_crn" {
    title = "Select a key:"
    sql   = query.ibm_kms_key_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ibm_kms_key_type
      args  = {
        crn = self.input.key_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_kms_key_ring
      args  = {
        crn = self.input.key_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_kms_key_state_details
      args  = {
        crn = self.input.key_crn.value
      }
    }



    card {
      width = 2
      query = query.ibm_kms_root_key_rotation_enabled
      args  = {
        crn = self.input.key_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_kms_key_dual_authentication
      args  = {
        crn = self.input.key_crn.value
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
        query = query.ibm_kms_key_overview
        args  = {
          crn = self.input.key_crn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.ibm_kms_key_tags
        args  = {
          crn = self.input.key_crn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Key Age"
        query = query.ibm_kms_key_age
        args  = {
          crn = self.input.key_crn.value
        }
      }

      table {
        title = "Key Aliases"
        query = query.ibm_kms_key_aliases
        args  = {
          crn = self.input.key_crn.value
        }
      }

    }

  }

}

query "ibm_kms_key_input" {
  sql = <<-EOQ
    select
      title as label,
       crn as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      ibm_kms_key
    where
      state <> '5'
    order by
      title;
  EOQ
}

query "ibm_kms_key_type" {
  sql = <<-EOQ
    select
      'Key Type' as label,
      case when extractable then 'Standard' else 'Root' end  as value
    from
      ibm_kms_key
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_kms_key_ring" {
  sql = <<-EOQ
    select
      'Key Ring' as label,
      key_ring_id  as value
    from
      ibm_kms_key
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_kms_key_state_details" {
  sql = <<-EOQ
    select
      'State' as label,
      case
        when state = '0' then 'Pre-activation'
        when state = '1' then 'Active'
        when state = '2' then 'Suspended'
        when state = '3' then 'Deactivated'
        when state = '5' then 'Destroyed'
        else state end as value,
      case when state in ('1','0') then 'ok' else 'alert' end as "type"
    from
      ibm_kms_key
    where
      state <> '5'
      and crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_kms_root_key_rotation_enabled" {
  sql = <<-EOQ
    select
      'Root Key Rotation' as label,
      case
        when extractable then 'N/A'
        when not extractable and rotation_policy = '{}' then 'Disabled' else 'Enabled' end as value,
      case when not extractable and rotation_policy = '{}' then 'alert' else 'ok' end as type
    from
      ibm_kms_key
    where
      crn = $1;
  EOQ

  param "crn" {}
}


query "ibm_kms_key_dual_authentication" {
  sql = <<-EOQ
    select
      'Dual Authorization Disabled' as label,
      case when dual_auth_delete ->> 'enabled' = 'true' then 'enabled' else 'disabled' end as value,
      case when dual_auth_delete ->> 'enabled' = 'true' then 'ok' else 'alert' end as type
    from
      ibm_kms_key
    where
      crn = $1
  EOQ

  param "crn" {}
}

query "ibm_kms_key_age" {
  sql = <<-EOQ
    select
      creation_date as "Creation Date",
      deletion_date as "Deletion Date",
      extract(day from deletion_date - current_date)::int as "Deleting After Days"
    from
      ibm_kms_key
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_kms_key_aliases" {
  sql = <<-EOQ
    select
      trim((a::text), '""') as "Alias Name"
    from
      ibm_kms_key,
      jsonb_array_elements(aliases) as a
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_kms_key_overview" {
  sql = <<-EOQ
    select
      id as "ID",
      name as "Name",
      instance_id as "Instance ID",
      type as "Type",
      created_by as "Created By",
      title as "Title",
      region as "Region",
      account_id as "Account ID",
      crn as "CRN"
    from
      ibm_kms_key
    where
      crn = $1
    EOQ

  param "crn" {}
}

query "ibm_kms_key_tags" {
  sql = <<-EOQ
    select
      tag ->> 'Key' as "Key",
      tag ->> 'Value' as "Value"
    from
      ibm_kms_key,
      jsonb_array_elements(tags) as tag
    where
      crn = $1
    order by
      tag ->> 'Key';
    EOQ

  param "crn" {}
}
