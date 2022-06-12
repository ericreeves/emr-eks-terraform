terraform {
  cloud {
	# Create an Organization in Terraform Cloud and provide it here:
    organization = "<ORGANIZATION>"

	# Create a Workspace within the aforementioned Organization and provide it here:
    workspaces {
      name = "<WORKSPACE>"
    }
  }
}