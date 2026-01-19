terraform {
  # Production: Use Swift (Object Store) for state
  # backend "swift" {
  #   container = "terraform-state"
  #   archive_container = "terraform-state-archive"
  #   state_name = "openstack-kind/terraform.tfstate"
  #   region_name = "RegionOne"
  # }
}
