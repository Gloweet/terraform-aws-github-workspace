provider "github" {
  owner = var.github_organization
  # App authentication doesn't allow setting repo environment variables nor secrets, use token_auth instead
  # app_auth {
  #   id              = var.github_app_id              # or `GITHUB_APP_ID`
  #   installation_id = var.github_app_installation_id # or `GITHUB_APP_INSTALLATION_ID`
  #   pem_file        = file(var.github_app_pem_file)  # or `GITHUB_APP_PEM_FILE`
  # }
  token = var.github_token
}
