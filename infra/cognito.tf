// Resources
resource "aws_cognito_user_pool" "fastfood-user-pool" {
  name = "fastfood-user-pool"

  mfa_configuration = "OFF"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
  
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
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