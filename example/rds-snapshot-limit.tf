/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */

module "rds-snapshot-limit-alert" {

  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-snapshot-limit-alert?ref=v1.0"
  slack_hook_url = "<SLACK_HOOK_URL>"
  schedule      = "<SCHEDULE>"
  # To execute a test job, uncomment the below var and leave as false. This will execute a 'job' instead of a 'cron job'.
  # cronjob       = false
}