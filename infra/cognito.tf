// Cognito for customer
resource "aws_cognito_user_pool" "fastfood-user-pool" {
  name = "fastfood-user-pool"

  mfa_configuration = "OFF"
  auto_verified_attributes = ["email"]
  
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  password_policy {
    minimum_length = 8
    require_lowercase = false
    require_numbers = false
    require_symbols = false
    require_uppercase = false
    temporary_password_validity_days = 0
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "fastfood-client" {
  name = "fastfood-client"

  user_pool_id = aws_cognito_user_pool.fastfood-user-pool.id
  generate_secret = false
  refresh_token_validity = 90
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "fastfood-domain" {
  domain          = "fastfood-domain-ratl"
  user_pool_id    = aws_cognito_user_pool.fastfood-user-pool.id
}

resource "aws_cognito_user" "unknown-user" {
  user_pool_id = aws_cognito_user_pool.fastfood-user-pool.id
  username     = "unknown-user"
  password = "unknown-user"
  enabled = true
  attributes = {
    name           = "unknown-user"
    email          = "unknown-user@fastfood.com"
    email_verified = true
  }
}

resource "aws_cognito_user_group" "group-users" {
  user_pool_id = aws_cognito_user_pool.fastfood-user-pool.id
  name         = "group-users"
}

resource "aws_cognito_user_group" "group-admin" {
  user_pool_id = aws_cognito_user_pool.fastfood-user-pool.id
  name         = "group-admin"
}

resource "aws_cognito_user_in_group" "usergroup-users" {
  user_pool_id = aws_cognito_user_pool.fastfood-user-pool.id
  group_name   = aws_cognito_user_group.group-users.name
  username     = aws_cognito_user.unknown-user.username
}
