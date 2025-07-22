import boto3

codedeploy = boto3.client('codedeploy')
autoscaling = boto3.client('autoscaling')
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    print("Received event:", event)

    try:
        detail = event['detail']
        instance_id = detail['EC2InstanceId']
        lifecycle_hook_name = detail['LifecycleHookName']
        asg_name = detail['AutoScalingGroupName']
    except KeyError as e:
        print(f"Missing key in event: {e}")
        return

    tags = get_instance_tags(instance_id)
    environment = tags.get("environment")
    component_abbr = tags.get("component")

    if not environment or not component_abbr:
        print("[ERROR] 'environment' or 'component' tag not found")
        return
    
    print(f"[INFO] Instance Tags - environment: {environment}, component: {component_abbr}")

    component_map = {
        "be": "backend",
        "fe": "frontend"
    }

    component_full = component_map.get(component_abbr)
    if not component_full:
        print(f"[ERROR] Unknown component abbreviation: {component_abbr}")
        return

    app_name = f"{component_full}-{environment}-codedeploy-app"
    deploy_group = f"{component_full}-{environment}-deployment-group"

    revision = get_last_successful_revision(app_name, deploy_group)
    if not revision:
        print("[ERROR] No previous successful revision found.")
        return
    
    print(f"[INFO] Triggering CodeDeploy - app: {app_name}, group: {deploy_group}")

    try:
        response = codedeploy.create_deployment(
            applicationName=app_name,
            deploymentGroupName=deploy_group,
            deploymentConfigName='CodeDeployDefault.AllAtOnce',
            revision=revision
        )
        print(f"[SUCCESS] Deployment started: {response['deploymentId']}")  
    except Exception as e:
        print(f"[ERROR] Failed to trigger CodeDeploy: {e}")
        return

    try:
        autoscaling.complete_lifecycle_action(
            LifecycleHookName=lifecycle_hook_name,
            AutoScalingGroupName=asg_name,
            LifecycleActionResult='CONTINUE',
            InstanceId=instance_id
        )
        print(f"[SUCCESS] Lifecycle hook completed for instance: {instance_id}")
    except Exception as e:
        print(f"[ERROR] Failed to complete lifecycle action: {e}")
        raise

def get_instance_tags(instance_id):
    try:
        reservations = ec2.describe_instances(InstanceIds=[instance_id]).get("Reservations", [])
        for reservation in reservations:
            for instance in reservation.get("Instances", []):
                return {tag["Key"]: tag["Value"] for tag in instance.get("Tags", [])}
    except Exception as e:
        print(f"[ERROR] Failed to retrieve tags for {instance_id}: {e}")
    return {}

def get_last_successful_revision(application_name, deployment_group_name):
    try:
        deployments = codedeploy.list_deployments(
            applicationName=application_name,
            deploymentGroupName=deployment_group_name,
            includeOnlyStatuses=['Succeeded'],
        )

        if not deployments['deployments']:
            print("[WARN] No successful deployments found.")
            return None

        deployment_id = deployments['deployments'][0]
        detail = codedeploy.get_deployment(deploymentId=deployment_id)
        revision = detail['deploymentInfo'].get('revision')
        return revision

    except Exception as e:
        print(f"[ERROR] Failed to get last successful revision: {e}")
        return None
