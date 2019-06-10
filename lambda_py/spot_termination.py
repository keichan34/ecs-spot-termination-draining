"""
A simple Lambda function that receives an EC2 Spot Instance
Termination Warning and changes its ECS state to "DRAINING".
"""

import json
import os

import boto3

CLUSTER_NAME = os.getenv("CLUSTER_NAME", "default")

def log(msg, level="INFO", **kwargs):
  """
  Prints a simple JSON-formatted log message to stdout.
  """
  defaults = {
    "ecs_cluster_name": CLUSTER_NAME
  }
  details = {**kwargs, **defaults}
  print(json.dumps({
    "msg": msg,
    "level": level,
    "spot_termination": details
  }))

def get_container_instance_id(client, instance_id):
  """
  Gets the ECS Container Instance ID from the EC2 Instance ID
  """

  cluster_list_resp = client.list_container_instances(
    cluster=CLUSTER_NAME,
    status="ACTIVE",
    filter=f"ec2InstanceId == {instance_id}"
  )
  instance_arns = cluster_list_resp['containerInstanceArns']
  return next(iter(instance_arns or []), None)

def start_draining(client, instance_id):
  """
  Starts draining `instance_id`.
  """

  container_instance_id = get_container_instance_id(client, instance_id)
  if not container_instance_id:
    log(
      f"{instance_id} was not found in ECS cluster: {CLUSTER_NAME} (or is draining)",
      instance_id=instance_id
    )
    return

  client.update_container_instances_state(
    cluster=CLUSTER_NAME,
    containerInstances=[container_instance_id],
    status='DRAINING'
  )

  log(f"Done.", instance_id=instance_id)

  return True

def lambda_handler(event, _context):
  """
  Main Lambda handler.
  """

  ecs_client = boto3.client('ecs')

  event_body_json = event['Records'][0]['Sns']['Message']
  event_body = json.loads(event_body_json)

  source = event_body['source']
  if source != "aws.ec2":
    log(f"Unsupported event source. Got: {source}", level="ERROR")
    return

  detail_type = event_body['detail-type']
  if detail_type != "EC2 Spot Instance Interruption Warning":
    log(f"Unsupported event detail type. Got: {detail_type}", level="ERROR")
    return

  instance_id = event_body['detail']['instance-id']
  instance_action = event_body['detail']['instance-action']
  if instance_action != "terminate":
    log(
      f"Instance {instance_id} is not scheduled to be terminated: {instance_action}",
      level="ERROR",
      instance_id=instance_id
    )
    return

  start_draining(ecs_client, instance_id)
