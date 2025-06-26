import boto3
import json
import datetime
import urllib.request

# AWS 클라이언트 생성
secrets_client = boto3.client('secretsmanager')
ce = boto3.client('ce')

# Secrets Manager에서 Discord Webhook URL 가져오기
def get_webhook_url():
    try:
        response = secrets_client.get_secret_value(SecretId="discord/webhook")
        secret_dict = json.loads(response['SecretString'])
        return secret_dict['url']
    except Exception as e:
        print(f"❌ Secrets Manager에서 Webhook URL 조회 실패: {e}")
        raise

# Discord로 Embed 메시지 전송
def send_embed_to_discord(period_label, cost, now, start, webhook_url, monthly_cost=None):
    fields = [
        {"name": "📅 기준일", "value": f"{start}", "inline": True},
    ]

    try:
        formatted_cost = f"${float(cost):,.2f}"
    except ValueError:
        formatted_cost = str(cost)

    fields.append({"name": "💵 비용", "value": formatted_cost, "inline": True})

    if monthly_cost is not None:
        try:
            formatted_monthly_cost = f"${float(monthly_cost):,.2f}"
        except ValueError:
            formatted_monthly_cost = str(monthly_cost)

        fields.append({"name": "📊 이번 달 총 지출", "value": formatted_monthly_cost, "inline": False})

    embed = {
        "title": f"AWS 비용 보고서",
        "fields": fields
    }

    payload = {
        "username": "AWS Cost Report",
        "embeds": [embed]
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

# Lambda 핸들러 함수
def lambda_handler(event, context):
    print("📥 받은 이벤트:", json.dumps(event))
    now = datetime.datetime.utcnow()
    webhook_url = get_webhook_url()

    start = (now - datetime.timedelta(days=1)).strftime('%Y-%m-%d')
    end = now.strftime('%Y-%m-%d')
    label = "어제 하루"

    try:
        daily_cost_data = ce.get_cost_and_usage(
            TimePeriod={'Start': start, 'End': end},
            Granularity='DAILY',
            Metrics=['UnblendedCost']
        )
        daily_amount = daily_cost_data['ResultsByTime'][0]['Total']['UnblendedCost']['Amount']

        # 이번 달 누적 비용 조회
        start_of_month = now.replace(day=1).strftime('%Y-%m-%d')
        monthly_cost_data = ce.get_cost_and_usage(
            TimePeriod={'Start': start_of_month, 'End': end},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost']
        )
        monthly_amount = monthly_cost_data['ResultsByTime'][0]['Total']['UnblendedCost']['Amount']

        send_embed_to_discord(label, daily_amount, now, start, webhook_url, monthly_amount)

    except Exception as e:
        print(f"❌ 비용 조회 실패: {str(e)}")
        send_embed_to_discord("조회 실패", "N/A", now, start, webhook_url)
