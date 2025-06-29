import boto3
import json
import urllib.request
import datetime
import os

secrets_client = boto3.client('secretsmanager')
ec2 = boto3.client("ec2")
rds = boto3.client("rds")

def generate_cloudwatch_log_url(context):
    region = os.environ.get("AWS_REGION", "us-east-1")
    function_name = context.function_name
    log_group = f"/aws/lambda/{function_name}"
    encoded_log_group = log_group.replace("/", "%252F")
    return (
        f"https://{region}.console.aws.amazon.com/cloudwatch/home"
        f"?region={region}#logsV2:log-groups/log-group/{encoded_log_group}"
    )

def get_webhook_url(secret_id="discord/webhook"):
    try:
        response = secrets_client.get_secret_value(SecretId=secret_id)
        secret_dict = json.loads(response["SecretString"])
        return secret_dict["url"]
    except Exception as e:
        print(f"❌ Webhook URL을 Secrets Manager에서 불러오는 데 실패했습니다: {e}")
        raise
    
def send_embed_to_discord(env, action, results, log_url, webhook_url):
    fields = [
        {"name": r["type"], "value": r["status"], "inline": True}
        for r in results
    ]

    embed = {
        "title": f"{env} {action}",
        "description": f"🔗 [로그 보기]({log_url})",
        "fields": fields
    }

    payload = {
        "username": "AWS Resource Controller",
        "embeds": [embed],
    }

    try:
        req = urllib.request.Request(
            webhook_url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json", "User-Agent": "MyLambdaBot/1.0"}
        )
        with urllib.request.urlopen(req) as res:
            print(f"✅ Discord 응답 코드: {res.status}")
    except Exception as e:
        print(f"❌ Discord 전송 실패: {e}")


def lambda_handler(event, context):
    action = event.get("action")
    env = event.get("env")
    webhook_url = get_webhook_url()
    log_url = generate_cloudwatch_log_url(context)

    if action not in ["start", "stop"]:
        print("❌ Invalid action")
        return

    results = []

    ec2_res = ec2.describe_instances(Filters=[{"Name": "tag:env", "Values": [env]}])
    ec2_ids = []
    for res in ec2_res["Reservations"]:
        for inst in res["Instances"]:
            state = inst["State"]["Name"]
            if (action == "start" and state == "stopped") or (action == "stop" and state == "running"):
                ec2_ids.append(inst["InstanceId"])

    if ec2_ids:
        try:
            if action == "start":
                ec2.start_instances(InstanceIds=ec2_ids)
            else:
                ec2.stop_instances(InstanceIds=ec2_ids)
            results.append({"type": "EC2", "status": "success"})
        except Exception as e:
            print(f"EC2 {action} 실패: {e}")
            results.append({"type": "EC2", "status": "fail"})
    else:
        print(f"EC2 {action} 대상 없음")
        results.append({"type": "EC2", "status": "skip"})

    rds_ids = []
    for db in rds.describe_db_instances()["DBInstances"]:
        arn = db["DBInstanceArn"]
        db_id = db["DBInstanceIdentifier"]
        state = db["DBInstanceStatus"]
        tags = rds.list_tags_for_resource(ResourceName=arn)["TagList"]
        has_env = any(tag["Key"] == "env" and tag["Value"] == env for tag in tags)
        if not has_env:
            continue
        if (action == "start" and state == "stopped") or (action == "stop" and state == "available"):
            rds_ids.append(db_id)

    if rds_ids:
        for db_id in rds_ids:
            try:
                if action == "start":
                    rds.start_db_instance(DBInstanceIdentifier=db_id)
                else:
                    rds.stop_db_instance(DBInstanceIdentifier=db_id)
            except Exception as e:
                print(f"RDS {db_id} {action} 실패: {e}")
                results.append({"type": "RDS", "status": "partial-fail"})
                break
        else:
            results.append({"type": "RDS", "status": "success"})
    else:
        print(f"RDS {action} 대상 없음")
        results.append({"type": "RDS", "status": "skip"})

    send_embed_to_discord(env, action, results, log_url, webhook_url)