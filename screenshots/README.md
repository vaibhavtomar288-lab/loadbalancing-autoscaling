# Screenshots Placeholder

This folder should contain the following screenshots after you complete the AWS setup:

## Required Screenshots

### 1. cloudwatch.png
- **What to capture**: CloudWatch alarm showing CPU utilization > 50%
- **Location**: AWS Console → CloudWatch → Alarms
- **Should show**: 
  - Alarm name: `cpu-high-projectautoscaling`
  - State: In Alarm
  - CPU utilization graph above threshold line

### 2. autoscaling.png
- **What to capture**: Auto Scaling group details
- **Location**: AWS Console → EC2 → Auto Scaling Groups
- **Should show**:
  - Group Name: `projectautoscaling`
  - Desired Capacity: 2
  - Min: 1, Max: 2
  - Instances in "InService" state

### 3. loadbalancer.png
- **What to capture**: Load balancer status
- **Location**: AWS Console → EC2 → Load Balancers
- **Should show**:
  - Load Balancer Name: `project-alb`
  - State: Active
  - DNS Name: `project-alb-xxx.elb.amazonaws.com`

### 4. ec2-instance.png
- **What to capture**: Running EC2 instances
- **Location**: AWS Console → EC2 → Instances
- **Should show**:
  - Instance(s) running with status "running"
  - Instance type: t3.micro
  - Health status from ELB: "Healthy"

### 5. architecture.png
- **What to capture**: Visual diagram of the architecture
- **Recommended tools**: draw.io, Lucidchart, or the included architecture.svg

---

## How to Take Screenshots

### Windows
- **Full screen**: Press `Win + Shift + S`, then select area
- **Snipping Tool**: Start → type "Snipping Tool"
- **Print Screen**: `PrtScn` key → paste in Paint

### Mac
- **Full screen**: `Cmd + Shift + 3`
- **Selection**: `Cmd + Shift + 4`

---

## Tips for Good Screenshots

1. **Crop to relevant area** - Show only the AWS Console section needed
2. **Include timestamps** - Shows when the screenshot was taken
3. **Highlight important info** - Use arrows or circles to point to key values
4. **Dark mode** - Consider using AWS dark mode for better visibility

---

## After Taking Screenshots

1. Save images to this folder with the exact names listed above
2. Update README.md if you want to include them in documentation
3. Commit to GitHub to show your working setup!