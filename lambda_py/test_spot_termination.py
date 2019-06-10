import botocore.session
from botocore.stub import Stubber

import spot_termination

def test_start_draining():
  ecs = botocore.session.get_session().create_client('ecs', region_name='ap-northeast-1')

  instance_arn = "arn:aws:ecs:ap-northeast-1:00:container-instance/6789aa4f-b810-48ce-bf11-705d9d3bb61d"
  instance_id = "i-00000000000000000"

  list_container_instances = {
    "containerInstanceArns": [
      instance_arn
    ]
  }

  list_container_instances_params = {
    "cluster": "default",
    "status": "ACTIVE",
    "filter": f"ec2InstanceId == {instance_id}"
  }

  update_container_instances_state = {}

  update_container_instances_state_params = {
    "cluster": "default",
    "containerInstances": [instance_arn],
    "status": "DRAINING"
  }

  with Stubber(ecs) as stubber:
    stubber.add_response(
      'list_container_instances',
      list_container_instances,
      list_container_instances_params
    )

    container_instance_id_result = spot_termination.get_container_instance_id(
      ecs,
      instance_id
    )



    stubber.add_response(
      'list_container_instances',
      list_container_instances,
      list_container_instances_params
    )

    stubber.add_response(
      'update_container_instances_state',
      update_container_instances_state,
      update_container_instances_state_params
    )

    start_draining_result = spot_termination.start_draining(
      ecs,
      instance_id
    )

  assert container_instance_id_result == instance_arn
  assert start_draining_result == True
