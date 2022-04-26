dashboard "ibm_cos_bucket_detail" {

  title         = "IBM Cloud Object Storage Bucket Detail"
  documentation = file("./dashboards/cloudobjectstorage/docs/cloudobjectstorage_bucket_detail.md")

  tags = merge(local.cos_common_tags, {
    type = "Detail"
  })

  input "bucket_name" {
    title = "Select a bucket:"
    sql   = query.ibm_cos_bucket_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ibm_cos_bucket_encryption
      args = {
        name = self.input.bucket_name.value
      }
    }

    card {
      width = 2
      query = query.ibm_cos_bucket_versioning
      args = {
        name = self.input.bucket_name.value
      }
    }

    card {
      width = 2
      query = query.ibm_cos_bucket_versioning_mfa
      args = {
        name = self.input.bucket_name.value
      }
    }

    card {
      width = 2
      query = query.ibm_cos_bucket_cross_region_resource_sharing
      args = {
        name = self.input.bucket_name.value
      }
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        query = query.ibm_cos_bucket_overview
        args = {
          name = self.input.bucket_name.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "Encryption Details"
        query = query.ibm_cos_bucket_encryption_details
        args = {
          name = self.input.bucket_name.value
        }
      }

    }

    container {
      width = 12
      table {
        title = "Lifecycle Rules"
        query = query.ibm_cos_bucket_lifecycle_rules
        args = {
          name = self.input.bucket_name.value
        }
      }
    }

    container {
      width = 12
      table {
        title = "Retention Configuration"
        query = query.ibm_cos_bucket_retention_configuration
        args = {
          name = self.input.bucket_name.value
        }
      }
    }

  }

}
query "ibm_cos_bucket_input" {
  sql = <<-EOQ
    select
      title as label,
      name as value,
      json_build_object(
        'account_id', account_id,
        'region', region
      ) as tags
    from
      ibm_cos_bucket
    order by
      title;
  EOQ
}

query "ibm_cos_bucket_versioning" {
  sql = <<-EOQ
    select
      'Versioning' as label,
      case when versioning_enabled then 'Enabled' else 'Disabled' end as value,
      case when versioning_enabled then 'ok' else 'alert' end as type
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}

query "ibm_cos_bucket_versioning_mfa" {
  sql = <<-EOQ
    select
      'Versioning MFA' as label,
      case when versioning_mfa_delete then 'Enabled' else 'Disabled' end as value,
      case when versioning_mfa_delete then 'ok' else 'alert' end as type
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}

query "ibm_cos_bucket_encryption" {
  sql = <<-EOQ
    select
      'Encryption' as label,
      case when sse_kp_enabled then 'Enabled' else 'Disabled' end as value,
      case when sse_kp_enabled then 'ok' else 'alert' end as type
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}

query "ibm_cos_bucket_cross_region_resource_sharing" {
  sql = <<-EOQ
    select
      'Cross-Origin Resource Sharing' as label,
      case when cors_rules is not null then 'Enabled' else 'Disabled' end as value,
      case when cors_rules is not null then 'ok' else 'alert' end as type
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}

query "ibm_cos_bucket_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      creation_date as "Creation Date",
      title as "Title",
      region as "Region",
      account_id as "Account ID"
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}

query "ibm_cos_bucket_encryption_details" {
  sql = <<-EOQ
    select
      sse_kp_enabled as "Key Protect Enabled",
      sse_kp_customer_root_key_crn as "Customer Root Key Crn"
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}


query "ibm_cos_bucket_public_access" {
  sql = <<-EOQ
    select
      bucket_policy_is_public as "Has Public Bucket Policy",
      block_public_acls as "Block New Public ACLs",
      block_public_policy as "Block New Public Bucket Policies",
      ignore_public_acls as "Public ACLs Ignored",
      restrict_public_buckets as "Public Bucket Policies Restricted"
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}

query "ibm_cos_bucket_lifecycle_rules" {
  sql = <<-EOQ
    select
      r ->> 'ID' as "ID",
      r ->> 'Status' as "Status",
      r -> 'Expiration' ->> 'Date' as "Expiration Date",
      r -> 'Expiration' ->> 'Days' as "Expiration Days",
      r -> 'Filter' ->> 'Prefix'as "Filter Prefix",
      r -> 'Transitions' ->> 'StorageClass' as "Transitions Storage Class",
      r -> 'Transitions' ->> 'Date' as "Transitions Date",
      r -> 'Transitions' ->> 'Days' as "Transitions Days"
    from
      ibm_cos_bucket,
      jsonb_array_elements(lifecycle_rules) as r
    where
      name = $1
    order by
      r ->> 'ID';
  EOQ

  param "name" {}
}


query "ibm_cos_bucket_retention_configuration" {
  sql = <<-EOQ
    select
      retention -> 'ProtectionConfiguration' ->> 'DefaultRetention' as "Default Retention",
      retention -> 'ProtectionConfiguration' ->> 'EnablePermanentRetention' as "Permanent Retention Enabled",
      retention -> 'ProtectionConfiguration' ->> 'MaximumRetention' as "Maximum Retention",
      retention -> 'ProtectionConfiguration' ->> 'MinimumRetention' as "IMinimum RetentionD",
      retention -> 'ProtectionConfiguration' ->> 'Status' as "Status"
    from
      ibm_cos_bucket
    where
      name = $1;
  EOQ

  param "name" {}
}

