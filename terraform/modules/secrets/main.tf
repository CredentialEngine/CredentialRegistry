resource "aws_secretsmanager_secret" "this" {
  name        = var.secret_name
  description = var.description
  tags        = var.tags
}

# Store the JSON-encoded map as the latest version of the secret.
resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(var.secret_values)

  lifecycle {
    # After the initial creation we usually want to manage the secret values
    # outside of Terraform (for example via AWS Console or CI pipelines).  By
    # ignoring changes to `secret_string` we avoid drift whenever the local
    # variables contain placeholder or outdated values that differ from the
    # real secret in AWS.
    ignore_changes = [secret_string]
  }
}
