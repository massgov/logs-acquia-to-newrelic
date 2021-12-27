name_prefix = "itd-dv-elk"
keypair = "DSBastion"

domain = "dev.logs.digital.mass.gov"
create_es_service_role = true

cluster_instance_backup = "na"
cluster_instance_patch_group = "nonprod-linux2"
cluster_instance_schedule = "0700_1900_weekdays"
cluster_schedule = true

instance_type = "m5.large.elasticsearch"
instance_volume_size = "100"
environment_name = "Dev"
instance_count = 2

# Elasticsearch indices retentions days
massgov_es_retention_days = 7
other_es_retention_days = 30

chamber_namespace = "apps/mds-elk/nonprod"

tags = {
  environment = "dev"
  secretariat = "eotss"
  agency = "itd"
  application = "elk"
  createdby = "eotss-dl-digitalcloud@massmail.state.ma.us"
  businessowner = "eotss-dl-digitalcloud@massmail.state.ma.us"
  itowner = "eotss-dl-digitalcloud@massmail.state.ma.us"
  terraform_managed = "yes"
}
