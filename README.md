```bash
# Terraform-code
This is task 1 of MultiCloud batch 
In this task we automate everything with the help of terraform 
Step 1 -> Crete the ssh key and security group which allow the port 22 and port 80
Step 2 -> Lunch ec2 instance with the above creted ssh key and security group
Step 3 -> Launch one ebs volume  and attach it with the instance then mount it with the /var/www/html folder
Step 4 -> Developer have uploaded the  code into github repo also the repo has some images
Step 5 -> Copy the github repo code into /var/www/html folder
Step 6 -> Create s3 bucket , and copy/deploy the images from github repo into s3 bucket and change the permission to public readable
Step 7 -> Create cloudfront using s3 bucket(which contains images) and use the cloudfront URL to update in code in /var/www/html
Conclusion these all things are a done by a single terraform code which is uploaded hear
```
