# Test
Connect to s3 from a private instance
## Getting Started
Deploy vpc endpoint for s3 and depoly a public instance in public subnet and a private instance in private subnet. Private subnet does not need/have nat gateway.
### Deploy
```
terraform init
terraform validate
terraform plan
terraform apply --auto-approve
```
### Test
Copy ssh private key to public instance:
```
chmod 400 monitoring.pem
scp -i monitoring.pem ./monitoring.pem ec2-user@public_ip_address:/home/ec2-user
```
SSH into private instance from public instance:
```
ssh -i monitoring.pem ec2-user@private_ip_address
export AWS_DEFAULT_REGION=ap-south-1
aws s3api create-bucket --bucket name --create-bucket-configuration LocationConstraint=ap-south-1
```