# 🚀 AWS Auto Scaling with Application Load Balancer

<p align="center">
  <img src="architecture.png" alt="Architecture Diagram" width="800"/>
</p>

A complete project demonstrating **AWS Auto Scaling** with an **Application Load Balancer (ALB)** for high availability and scalability. This setup automatically adjusts compute capacity based on CPU utilization using CloudWatch alarms.

---

## 📋 Project Overview

| Component | Value |
|-----------|-------|
| **Project Name** | aws-auto-scaling-load-balancer-project |
| **Region** | us-east-1 (N. Virginia) |
| **Instance Type** | t3.micro |
| **Auto Scaling Group** | projectautoscaling |
| **Desired Capacity** | 2 instances |
| **Min Capacity** | 1 instance |
| **Max Capacity** | 2 instances |
| **Load Balancer** | Application Load Balancer (Internet-facing) |
| **Health Check** | HTTP:80/ |
| **Scaling Trigger** | CPUUtilization > 50% |

---

## 🏗️ Architecture

```
                                    ┌─────────────────────┐
                                    │   Internet Users    │
                                    └──────────┬──────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │ Application Load    │
                                    │ Balancer (ALB)      │
                                    │ DNS: project-alb-   │
                                    │ xxx.elb.amazonaws.com│
                                    └──────────┬──────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │  Target Group       │
                                    │  (HTTP:80)          │
                                    └──────────┬──────────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
                    ▼                          ▼                          ▼
          ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
          │  EC2 Instance   │       │  EC2 Instance   │       │  EC2 Instance   │
          │  (i-xxx)        │       │  (i-xxx)        │       │  (i-xxx)        │
          │  AZ: us-east-1a │       │  AZ: us-east-1b │       │  AZ: us-east-1c │
          │  t3.micro       │       │  t3.micro       │       │  t3.micro       │
          │  Apache/Nginx   │       │  Apache/Nginx   │       │  Apache/Nginx   │
          └────────┬────────┘       └────────┬────────┘       └────────┬────────┘
                   │                         │                         │
                   └─────────────────────────┼─────────────────────────┘
                                             │
                                             ▼
                                  ┌─────────────────────┐
                                  │ Auto Scaling Group  │
                                  │ projectautoscaling  │
                                  │ Desired: 2          │
                                  │ Min: 1 | Max: 2     │
                                  └──────────┬──────────┘
                                             │
                                             ▼
                                  ┌─────────────────────┐
                                  │  CloudWatch Alarm   │
                                  │  CPU > 50%          │
                                  │  Scale Out Policy   │
                                  └─────────────────────┘
```

### How It Works

1. **User Request** → Hits ALB DNS endpoint
2. **Load Balancer** → Distributes traffic across healthy instances in target group
3. **Health Checks** → ALB continuously checks instance health
4. **Auto Scaling** → Monitors CPU metrics via CloudWatch
5. **Scaling Trigger** → When CPU > 50% for 3 minutes, scale out to max capacity
6. **Instance Registration** → New instances automatically register with ALB target group

---

## 📁 Project Structure

```
aws-auto-scaling-load-balancer-project/
├── app/
│   └── index.html              # Sample web app with instance metadata
├── scripts/
│   └── setup.sh                # EC2 user data script (auto-installs Apache)
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD workflow for deployments
├── screenshots/
│   ├── cloudwatch.png          # CloudWatch CPU alarm screenshot
│   ├── autoscaling.png         # Auto Scaling group details
│   ├── loadbalancer.png        # Load balancer status
│   ├── ec2-instance.png        # EC2 instance running
│   └── architecture.png        # Architecture diagram
├── architecture.png            # Main architecture diagram
└── README.md                   # This file
```

---

## 🔧 AWS Setup - Step by Step

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Key Pair for EC2 access

---

### Step 1: Create Security Groups

#### 1.1 ALB Security Group (Inbound HTTP)
```bash
aws ec2 create-security-group \
    --group-name alb-security-group \
    --description "Security group for Application Load Balancer" \
    --vpc-id <YOUR-VPC-ID>
```

```bash
aws ec2 authorize-security-group-ingress \
    --group-name alb-security-group \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
```

#### 1.2 EC2 Security Group (Allow HTTP from ALB)
```bash
aws ec2 create-security-group \
    --group-name ec2-security-group \
    --description "Security group for EC2 instances" \
    --vpc-id <YOUR-VPC-ID>
```

```bash
# Allow HTTP from ALB security group
aws ec2 authorize-security-group-ingress \
    --group-name ec2-security-group \
    --protocol tcp \
    --port 80 \
    --source-group <ALB-SECURITY-GROUP-ID>

# Allow SSH from your IP
aws ec2 authorize-security-group-ingress \
    --group-name ec2-security-group \
    --protocol tcp \
    --port 22 \
    --cidr <YOUR-IP>/32
```

---

### Step 2: Create Launch Template

```bash
aws ec2 create-launch-template \
    --launch-template-name project-lt \
    --version-description "Version 1" \
    --launch-template-data '{
        "ImageId": "ami-0c55b159cbfafe1f0",  # Amazon Linux 2 AMI (us-east-1)
        "InstanceType": "t3.micro",
        "KeyName": "your-key-pair",
        "SecurityGroupIds": ["<EC2-SECURITY-GROUP-ID>"],
        "UserData": "<BASE64-ENCODED-SETUP.SH>",
        "IamInstanceProfile": {
            "Arn": "arn:aws:iam::123456789012:instance-profile/aws-ssm-managed-instance-core"
        },
        "MetadataOptions": {
            "HttpEndpoint": "enabled",
            "HttpPutResponseHopLimit": 1
        }
    }'
```

**To encode user data:**
```bash
base64 -w0 scripts/setup.sh
```

---

### Step 3: Create Application Load Balancer

#### 3.1 Create Target Group
```bash
aws elbv2 create-target-group \
    --name project-target-group \
    --protocol HTTP \
    --port 80 \
    --vpc-id <YOUR-VPC-ID> \
    --health-check-path / \
    --health-check-interval-seconds 30 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2
```

#### 3.2 Create ALB
```bash
aws elbv2 create-load-balancer \
    --name project-alb \
    --scheme internet-facing \
    --type application \
    --subnets <SUBNET-ID-1> <SUBNET-ID-2> <SUBNET-ID-3> \
    --security-groups <ALB-SECURITY-GROUP-ID>
```

#### 3.3 Create Listener
```bash
aws elbv2 create-listener \
    --load-balancer-arn <ALB-ARN> \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=<TARGET-GROUP-ARN>
```

---

### Step 4: Create Auto Scaling Group

```bash
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name projectautoscaling \
    --launch-template LaunchTemplateId=<LT-ID>,Version="1" \
    --min-size 1 \
    --max-size 2 \
    --desired-capacity 2 \
    --vpc-zone-identifier "<SUBNET-ID-1>,<SUBNET-ID-2>,<SUBNET-ID-3>" \
    --target-group-arns <TARGET-GROUP-ARN> \
    --health-check-type ELB \
    --health-check-grace-period 300
```

---

### Step 5: Create CloudWatch Alarm & Scaling Policy

#### 5.1 Create Scale-Out Policy
```bash
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name projectautoscaling \
    --policy-name scale-out-cpu \
    --policy-type SimpleScaling \
    --adjustment-type ChangeInCapacity \
    --scaling-adjustment 1 \
    --cooldown 300
```

#### 5.2 Create Scale-In Policy
```bash
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name projectautoscaling \
    --policy-name scale-in-cpu \
    --policy-type SimpleScaling \
    --adjustment-type ChangeInCapacity \
    --scaling-adjustment -1 \
    --cooldown 300
```

#### 5.3 Create CloudWatch Alarm (Scale Out)
```bash
aws cloudwatch put-metric-alarm \
    --alarm-name cpu-high-projectautoscaling \
    --alarm-description "Scale out when CPU > 50%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 50 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=AutoScalingGroupName,Value=projectautoscaling \
    --alarm-actions <SCALE-OUT-POLICY-ARN>
```

#### 5.4 Create CloudWatch Alarm (Scale In)
```bash
aws cloudwatch put-metric-alarm \
    --alarm-name cpu-low-projectautoscaling \
    --alarm-description "Scale in when CPU < 30%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 30 \
    --comparison-operator LessThanThreshold \
    --dimensions Name=AutoScalingGroupName,Value=projectautoscaling \
    --alarm-actions <SCALE-IN-POLICY-ARN>
```

---

## 🧪 Testing the Setup

### 1. Verify Instances are Running

```bash
# Check Auto Scaling group
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names projectautoscaling \
    --query 'AutoScalingGroups[0].Instances'
```

### 2. Get ALB DNS Name

```bash
aws elbv2 describe-load-balancers \
    --names project-alb \
    --query 'LoadBalancers[0].DNSName'
```

### 3. Test via Browser

Open: `http://<ALB-DNS-NAME>`

You should see:
- "Hello from Auto Scaling Instance!"
- Dynamic instance ID (e.g., `i-0abc123...`)
- Availability zone

### 4. Simulate CPU Load (Bonus!)

SSH into an instance and run:

```bash
# Install stress tool (Amazon Linux)
sudo yum install -y stress

# Generate CPU load
stress --cpu 2 --timeout 300

# Alternative: Use yes command
yes > /dev/null &
```

### 5. Watch Scaling in Action

```bash
# Monitor Auto Scaling group
watch -n 10 'aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names projectautoscaling \
    --query "AutoScalingGroups[0].Instances"'
```

---

## 📸 Screenshots Guide

After setting up, capture these screenshots for documentation:

| Screenshot | What to Capture | Location in AWS Console |
|------------|-----------------|------------------------|
| `cloudwatch.png` | CPU utilization graph showing >50% | CloudWatch → Alarms → cpu-high-projectautoscaling |
| `autoscaling.png` | ASG with desired=2, min=1, max=2 | EC2 → Auto Scaling Groups → projectautoscaling |
| `loadbalancer.png` | ALB with state "active" | EC2 → Load Balancers → project-alb |
| `ec2-instance.png` | Running instances with health status | EC2 → Instances |
| `architecture.png` | Visual diagram of the setup | Custom (use draw.io or similar) |

---

## 🔄 How Scaling Works

### Scale-Out Process (CPU > 50%)

```
1. CloudWatch monitors CPU every 5 minutes
2. CPU exceeds 50% for 2 consecutive periods (10 min)
3. CloudWatch triggers ALARM: cpu-high-projectautoscaling
4. Auto Scaling executes "scale-out-cpu" policy
5. ASG launches 1 new instance (desired: 2→3, max: 2→3)
6. New instance runs user-data script (installs Apache)
7. Instance passes health checks (ELB)
8. ALB registers instance to target group
9. Traffic now distributed to 3 instances
10. CPU load decreases across instances
```

### Scale-In Process (CPU < 30%)

```
1. CPU drops below 30% for 2 consecutive periods
2. CloudWatch triggers ALARM: cpu-low-projectautoscaling
3. Auto Scaling executes "scale-in-cpu" policy
4. ASG terminates 1 instance (desired: 2→1)
5. Instance deregistered from ALB target group
6. Traffic continues to remaining instance
```

---

## 🛠️ Troubleshooting

### Instance not registering with ALB

1. Check security groups allow traffic on port 80
2. Verify user-data script ran successfully
3. Check Apache is running: `systemctl status httpd`
4. Test locally: `curl localhost`

### Health checks failing

1. Verify health check path is `/`
2. Check instance can reach ALB (security group)
3. Review target group health check settings

### Scaling not triggering

1. Verify CloudWatch alarm exists: `aws cloudwatch describe-alarms`
2. Check metric data is being collected
3. Verify scaling policies are attached to ASG

---

## 🔐 Security Best Practices

- ✅ Use IAM roles instead of access keys
- ✅ Restrict SSH access to your IP only
- ✅ Enable VPC flow logs
- ✅ Use HTTPS in production
- ✅ Implement proper backup strategies
- ✅ Enable AWS CloudTrail

---

## 📞 Additional Resources

- [AWS Auto Scaling Documentation](https://docs.aws.amazon.com/autoscaling/)
- [Application Load Balancer User Guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)

---

## 🤝 Contributing

Feel free to submit issues and pull requests!

---

## 📄 License

MIT License - Feel free to use this project for learning and demonstration purposes.

---

<p align="center">
  <strong>Built with ❤️ for AWS Cloud Learning</strong>
</p>