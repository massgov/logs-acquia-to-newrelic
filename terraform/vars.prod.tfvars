name_prefix = "itd-pr-elk"
keypair = "DSBastion"

domain = "logs.digital.mass.gov"
create_es_service_role = false

cluster_instance_backup = "na"
cluster_instance_patch_group = "prod-linux2"
cluster_instance_schedule = "na"

schedule_expression = {
  hourly = "rate(1 hour)"
}

instance_type = "m5.xlarge.elasticsearch"
instance_volume_size = "1024"
environment_name = "Prod"
instance_count = 2

# Elasticsearch indices retentions days
massgov_es_retention_days = 30
other_es_retention_days = 365

chamber_namespace = "apps/logs-acquia-to-newrelic/prod"

tags = {
  environment = "prod"
  secretariat = "eotss"
  agency = "itd"
  application = "elk"
  createdby = "eotss-dl-digitalcloud@massmail.state.ma.us"
  businessowner = "eotss-dl-digitalcloud@massmail.state.ma.us"
  itowner = "eotss-dl-digitalcloud@massmail.state.ma.us"
  terraform_managed = "yes"
}
