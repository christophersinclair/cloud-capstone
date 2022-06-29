resource "aws_backup_vault" "fauna_backup_vault" {
    name = "fauna-vault-REPLACE_ME_UUID"
}


resource "aws_backup_plan" "fauna_backup_plan" {
    name = "fauna-plan-REPLACE_ME_UUID"

    rule {
      rule_name = "fauna-backup-rule"
      target_vault_name = aws_backup_vault.fauna_backup_vault.name
      schedule = "cron(0 12 * * ? *)"

      lifecycle {
        delete_after = 14
      } 
    }   
}

resource "aws_backup_selection" "fauna_backup_selection" {
    iam_role_arn = aws_iam_role.backup_role.arn
    name = "fauna-select-REPLACE_ME_UUID"
    plan_id = aws_backup_plan.fauna_backup_plan.id

    resources = [aws_db_instance.fauna_db.arn]
}

