# RDS Snapshot Limit Alert - Installation / Configuration

The module 

This module iterates through each teams' namespace to capture the limit set for the teams RDS manual snapshots and compares this against the actual number of manual RDS snapshots.

If the actual number of manual snapshot exceeds the limit then a slack notification is sent to the Cloud Platform channel with details as follows:

* Actual snapshot count vs Limit set
* RDS Server name
* Team name
* Link navigating to the snapshot AWS console

## Usage

The module takes three arguments as follows:

slack_hook_id (string): This is the full slack webhook url. Alerts will be sent to this channel. 
schedule (string): The schedule of the job in 'cron schedule expression' (e.g see https://crontab.guru/)
crontjob (boolean): Default is true, in which case the job will run as a cron job. If set to false a one-time job will be created.

As the 'slack_hook_url' variable is sensitive then the file containing it should be git-encrypted. 

example of the module's usage is as follows:

```{r, engine='bash', count_lines}

module "rds-snapshot-limit-alert" {

  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-snapshot-limit-alert?ref=v1.0"
  slack_hook_url = "<SLACK_HOOK_URL>"
  schedule      = "<SCHEDULE>"
  # To execute a test job, uncomment the below var and leave as false. This will execute a 'job' instead of a 'cron job'.
  #cronjob       = "<CRONJOB>"

}

```

* Set the backend and provider (see example/main.tf)
* From the directory that contains the terraform file that references the module, run 'terraform plan' > 'terraform apply. Confirm apply.

Once terraform applied the following resources are created. 

* AWS User: AWS credentials used by the job to read the RDS snapshots
* Kubernetes Job: Depending on the 'cronjob' flag this will either be a standard 'Job or a 'CronJob'. The job executes bash / python code that
  dynamically fetch the limit of snapshots specified in each teams namespace as an annotation. This limit is then compared to the actual number of snapshots for that team. If the actual number exceeds the limit set then an alert is sent to the channel as per the slack hook ID. 
* RBAC - ClusterRoldBinding resource is created to give the k8s job permissions to read each teams namespaces