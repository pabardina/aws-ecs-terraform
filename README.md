Deploying a Flask app on AWS ECS with Terraform and Github Actions
=====

The project deploys :
* A VPC with all needed resources
* An ECR repository
* 2 ALB (development + production). **Only the production one uses HTTPS**
* 2 ECS clusters (development + production)
* Autoscaling for each ECS clusting based on CPU usage
* Cloudwatch alarm


**Requirements**: 
* AWS account (free tier)
* Domain name
* Bucket S3 to be used by terraform as backend to store tfsate file.
* Create a certificate in ACM in your aws account pointing to your domain name and keep the ARN of your certificate
* At the end of the deployment, create a CNAME in your domain name provider and add a CNAME pointing to your ALB
 
# How to deploy the stack 
## Locally

Requirements: 
* Terraform > 0.13.*


```
$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"
$ export AWS_DEFAULT_REGION="ca-canada-1"
```

Edit the `terraform.tfvars` as you wish to override default variables.

Example of my `terraform.tfvars` :

```
alb_tls_cert_arn     = "arn:aws:acm:ca-central-1:xxxxxxxx:certificate/xxxxxxx"
alarm_email          = "fake@fakemail.fake"
s3_terraform_backend = "terraform-pa-ecs"
```

Deploy:

```
terraform init -backend-config "bucket=your-bucket-name"
terraform plan
terraform apply
```

Once everthing is deployed. Get the URL of your ALB and create a CNAME in your domain name provider pointing to this URL.


## Using CI/CD

There are two Github Actions.

* `terraform.yml` which is executed only when there is a changed in the `terraform` folder. It executes `terraform apply`.
* `deploy.yml` which is executed only when there is a changed in the `src` folder. It pushes a new image on ECR and update the image in the ECS task.

Secrets to add in github secret:

```
AWS_ACCESS_KEY_ID
AWS_DEFAULT_REGION
AWS_SECRET_ACCESS_KEY
ECR_REGISTRY
```


# Auto Scaling

You can try to scale the cluster using [Vegeta](https://github.com/tsenart/vegeta)

Example : 

`echo "GET https://yourdomain.com" | vegeta attack -duration=60s  -rate 100 | tee results.bin | vegeta report`

Output of the command:

```
Requests      [total, rate, throughput]         6000, 100.02, 99.97
Duration      [total, attack, wait]             1m0s, 59.99s, 25.281ms
Latencies     [min, mean, 50, 90, 95, 99, max]  13.974ms, 27.281ms, 24.708ms, 30.826ms, 40.388ms, 65.228ms, 423.677ms
Bytes In      [total, mean]                     1044000, 174.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:6000
```