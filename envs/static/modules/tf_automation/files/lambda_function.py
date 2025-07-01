import os
import json
import urllib.request
from typing import List, Dict

import boto3

secrets_client = boto3.client("secretsmanager")
rds_client = boto3.client("rds")
tagging_client = boto3.client("resourcegroupstaggingapi")
asg_client = boto3.client("autoscaling")

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
    fields = [{"name": r["type"], "value": r["status"], "inline": True} for r in results]
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
            headers={"Content-Type": "application/json", "User-Agent": "MyLambdaBot/1.0"},
        )
        with urllib.request.urlopen(req) as res:
            print(f"Discord 응답: {res.status}")
    except Exception as e:
        print(f"Discord 전송 실패: {e}")

def get_tagged_asg_names(env: str) -> List[str]:
    try:
        resp = asg_client.describe_tags(
            Filters=[
                {'Name': 'key', 'Values': ['Environment']},
                {'Name': 'value', 'Values': [env]},
            ]
        )
        return list({tag['ResourceId'] for tag in resp.get('Tags', [])})
    except Exception as e:
        print(f"ASG 태그 조회 실패: {e}")
        return []

def scale_asg(name: str, action: str) -> bool:
    try:
        if action == "stop":
            asg_client.update_auto_scaling_group(
                AutoScalingGroupName=name, MinSize=0, DesiredCapacity=0, MaxSize=0
            )
        else:
            asg_client.update_auto_scaling_group(
                AutoScalingGroupName=name,
                MinSize=int(os.getenv("ASG_MIN", 1)),
                DesiredCapacity=int(os.getenv("ASG_DESIRED", 1)),
                MaxSize=int(os.getenv("ASG_MAX", 1)),
            )
        print(f"ASG {name} {action} 성공")
        return True
    except Exception as e:
        print(f"ASG {name} {action} 실패: {e}")
        return False

def handle_asg(env: str, action: str, results: List[Dict[str, str]]) -> None:
    asg_names = get_tagged_asg_names(env)
    if not asg_names:
        print(f"ASG 대상 없음 (Environment={env})")
        results.append({"type": "ASG", "status": "skip"})
        return

    resp = asg_client.describe_auto_scaling_groups(AutoScalingGroupNames=asg_names)
    for grp in resp.get("AutoScalingGroups", []):
        name = grp["AutoScalingGroupName"]
        success = scale_asg(name, action)
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

def lambda_handler(event, context):
    action = event.get("action")
    env = event.get("env")
    if action not in ("start", "stop") or not env:
        print(f"Invalid invocation. action={action}, Environment={env}")
        return

    region = os.environ.get("AWS_REGION", "ap-northeast-2")
    results: List[Dict[str, str]] = []

    webhook_url = get_webhook_url()
    log_url = generate_cloudwatch_log_url(context.function_name, region)

    handle_asg(env, action, results)
    handle_rds(env, action, results)

    send_embed_to_discord(env, action, results, log_url, webhook_url)

if __name__ == "__main__":
    # 로컬 테스트용 이벤트
    test_event = {"action": "start", "env": "prod"}

    # 최소한의 context 모킹
    class Context:
        function_name = "local-test-function"
    test_context = Context()

    lambda_handler(test_event, test_context)
