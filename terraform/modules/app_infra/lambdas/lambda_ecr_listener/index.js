import { EC2Client, DescribeInstancesCommand } from "@aws-sdk/client-ec2";
import { SSMClient, SendCommandCommand } from "@aws-sdk/client-ssm";

const ec2 = new EC2Client();
const ssm = new SSMClient();

export const handler = async () => {
  console.log("Fetching EC2 instances...");

  const instances = await ec2.send(
    new DescribeInstancesCommand({
      Filters: [
        { Name: "tag:Name", Values: ["app1-asg-instance"] },
        { Name: "instance-state-name", Values: ["running"] },
      ],
    })
  );

  const instanceIds = instances.Reservations.flatMap((r) => r.Instances.map((i) => i.InstanceId));

  if (instanceIds.length === 0) {
    console.log("No running instances found.");
    return;
  }

  console.log(`Target instances: ${instanceIds.join(", ")}`);

  const repo = process.env.ECR_REPOSITORY;
  const region = process.env.REGION;

  const image = `\$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${region}.amazonaws.com/${repo}:latest`;

  const commands = [
    `aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin \$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${region}.amazonaws.com`,
    "docker rm -f app1 || true",
    `docker pull ${image}`,
    `docker run -d --name app1 -p 80:8000 ${image}`,
  ];

  await ssm.send(
    new SendCommandCommand({
      InstanceIds: instanceIds,
      DocumentName: "AWS-RunShellScript",
      Comment: "Restart app1 from latest image",
      Parameters: { commands },
    })
  );

  console.log("Command sent to instances.");
};
