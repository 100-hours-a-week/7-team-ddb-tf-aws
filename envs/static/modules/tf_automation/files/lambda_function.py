import os
import json
import urllib.request
from typing import List, Dict

import boto3

secrets_client = boto3.client("secretsmanager")
rds_client = boto3.client("rds")
tagging_client = boto3.client("resourcegroupstaggingapi")
asg_client = boto3.client("autoscaling")
ec2 = boto3.client("ec2")


def generate_cloudwatch_log_url(function_name: str, region: str) -> str:
    log_group = f"/aws/lambda/{function_name}"
    encoded = log_group.replace("/", "%252F")
    return (
        f"https://{region}.console.aws.amazon.com/cloudwatch/home"
        f"?region={region}#logsV2:log-groups/log-group/{encoded}"
    )


def get_webhook_url(secret_id: str = "discord/webhook") -> str:
    try:
        resp = secrets_client.get_secret_value(SecretId=secret_id)
        return json.loads(resp["SecretString"])["url"]
    except Exception as e:
        print(f"Webhook URL 조회 실패: {e}")
        raise


def send_embed_to_discord(
    env: str,
    action: str,
    results: List[Dict[str, str]],
    log_url: str,
    webhook_url: str,
) -> None:
    fields = [
        {"name": r["type"], "value": r["status"], "inline": True} for r in results
    ]
    embed = {
        "title": f"{env.upper()} {action.upper()}",
        "url": log_url,
        "fields": fields,
    }
    payload = {"username": "InfraController", "embeds": [embed]}

    try:
        req = urllib.request.Request(
            webhook_url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "User-Agent": "MyLambdaBot/1.0",
            },
        )
        with urllib.request.urlopen(req) as res:
            print(f"Discord 응답: {res.status}")
    except Exception as e:
        print(f"Discord 전송 실패: {e}")


def get_tagged_asg_names(env: str) -> List[str]:
    try:
        resp = asg_client.describe_tags(
            Filters=[
                {"Name": "key", "Values": ["Environment"]},
                {"Name": "value", "Values": [env]},
            ]
        )
        return list({tag["ResourceId"] for tag in resp.get("Tags", [])})
    except Exception as e:
        print(f"ASG 태그 조회 실패: {e}")
        return []


def scale_asg(
    name: str, action: str, min_size: int, desire_size: int, max_size: int
) -> bool:
    try:
        asg_client.update_auto_scaling_group(
            AutoScalingGroupName=name,
            MinSize=int(min_size),
            DesiredCapacity=int(desire_size),
            MaxSize=int( max_size),
        )
        print(f"ASG {name} {action} 성공")
        return True
    except Exception as e:
        print(f"ASG {name} {action} 실패: {e}")
        return False


def handle_asg(
    env: str,
    action: str,
    min_size: int,
    desire_size: int,
    max_size: int,
    results: List[Dict[str, str]],
) -> None:
    asg_names = get_tagged_asg_names(env)
    if not asg_names:
        print(f"ASG 대상 없음 (Environment={env})")
        results.append({"type": "ASG", "status": "skip"})
        return

    resp = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=asg_names)
    for grp in resp.get("AutoScalingGroups", []):
        name = grp["AutoScalingGroupName"]
        success = scale_asg(name, action, min_size, desire_size, max_size)
        results.append(
            {"type": f"ASG:{name}", "status": "success" if success else "fail"}
        )


def handle_rds(env: str, action: str, results: List[Dict[str, str]]) -> None:
    rds_ids = []
    for db in rds_client.describe_db_instances()["DBInstances"]:
        arn = db["DBInstanceArn"]
        state = db["DBInstanceStatus"]
        tags = rds_client.list_tags_for_resource(ResourceName=arn)["TagList"]
        if not any(t["Key"] == "Environment" and t["Value"] == env for t in tags):
            continue
        if (action == "start" and state == "stopped") or (
            action == "stop" and state == "available"
        ):
            rds_ids.append(db["DBInstanceIdentifier"])

    if not rds_ids:
        print(f"RDS 대상 없음 (Environment={env})")
        results.append({"type": "RDS", "status": "skip"})
        return

    for db_id in rds_ids:
        try:
            if action == "start":
                rds_client.start_db_instance(DBInstanceIdentifier=db_id)
            else:
                rds_client.stop_db_instance(DBInstanceIdentifier=db_id)
            print(f"RDS {db_id} {action} 성공")
        except Exception as e:
            print(f"RDS {db_id} {action} 실패: {e}")
            results.append({"type": f"RDS:{db_id}", "status": "fail"})
            return

    results.append({"type": "RDS", "status": "success"})


def handle_ec2(env: str, action: str, results: List[Dict[str, str]]) -> None:
    try:
        ec2_res = ec2.describe_instances(
            Filters=[{"Name": "tag:Environment", "Values": [env]}]
        )
    except Exception as e:
        print(f"EC2 인스턴스 조회 실패: {e}")
        results.append({"type": "EC2", "status": "fail"})
        return

    ec2_ids = []
    for res in ec2_res.get("Reservations", []):
        for inst in res.get("Instances", []):
            state = inst["State"]["Name"]
            if (action == "start" and state == "stopped") or (
                action == "stop" and state == "running"
            ):
                ec2_ids.append(inst["InstanceId"])

    if not ec2_ids:
        print(f"EC2 {action} 대상 없음 (Environment={env})")
        results.append({"type": "EC2", "status": "skip"})
        return

    try:
        if action == "start":
            ec2.start_instances(InstanceIds=ec2_ids)
        else:
            ec2.stop_instances(InstanceIds=ec2_ids)
        print(f"EC2 {ec2_ids} {action} 성공")
        results.append({"type": "EC2", "status": "success"})
    except Exception as e:
        print(f"EC2 {action} 실패: {e}")
        results.append({"type": "EC2", "status": "fail"})


def lambda_handler(event, context):
    action = event.get("action")
    env = event.get("env")
    min_size = event.get("min_size")
    desire_size = event.get("desire_size")
    max_size = event.get("max_size")

    if action not in ("start", "stop") or not env:
        print(f"Invalid invocation. action={action}, Environment={env}")
        return

    region = "ap-northeast-2"
    results: List[Dict[str, str]] = []

    webhook_url = get_webhook_url()
    log_url = generate_cloudwatch_log_url(context.function_name, region)

    handle_asg(env, action, min_size, desire_size, max_size, results)
    handle_rds(env, action, results)
    handle_ec2(env, action, results)

    send_embed_to_discord(env, action, results, log_url, webhook_url)