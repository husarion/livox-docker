from launch import LaunchDescription
from launch.actions import (
    DeclareLaunchArgument,
    GroupAction,
    OpaqueFunction,
)
from launch.conditions import IfCondition
from launch_ros.actions import Node, PushRosNamespace
from launch.substitutions import (
    EnvironmentVariable,
    LaunchConfiguration,
    PathJoinSubstitution,
)
from launch_ros.substitutions import FindPackageShare


def create_health_status_file():
    with open("/var/tmp/health_status.txt", "w") as file:
        file.write("healthy")


def launch_setup(context, *args, **kwargs):
    robot_namespace = LaunchConfiguration("robot_namespace").perform(context)
    device_namespace = LaunchConfiguration("device_namespace").perform(context)

    ns = "/"
    if device_namespace:
        frame_id = device_namespace + "_link"
        ns = f"/{device_namespace}"
    else:
        frame_id = "laser"

    if robot_namespace:
        ns_ext = robot_namespace + "/"
        ns = f"/{robot_namespace}{ns}"
    else:
        ns_ext = ""
    frame_id = ns_ext + frame_id

    # Device Namespace
    livox_actions = []
    livox_actions.append(PushRosNamespace(device_namespace))

    livox_ns = GroupAction(actions=livox_actions)

    # Retrieve the healthcheck argument
    healthcheck = LaunchConfiguration("healthcheck").perform(context)

    # Conditional file creation based on the healthcheck argument
    if healthcheck == "False":
        create_health_status_file()

    # Define the healthcheck node
    healthcheck_node = Node(
        package="healthcheck_pkg",
        executable="healthcheck_node",
        name="healthcheck_livox",
        namespace=ns,
        output="screen",
        condition=IfCondition(healthcheck),
    )

    xfer_format = 0  # 0-Pointcloud2(PointXYZRTL), 1-customized pointcloud format
    multi_topic = 0  # 0-All LiDARs share the same topic, 1-One LiDAR one topic
    data_src = 0  # 0-lidar, others-Invalid data src
    publish_freq = 10.0  # frequency of publish, 5.0, 10.0, 20.0, 50.0, etc.
    output_type = 0
    lvx_file_path = "/home/livox/livox_test.lvx"
    cmdline_bd_code = "livox0000000001"
    user_config_path = PathJoinSubstitution(
        [FindPackageShare("livox_ros_driver2"), "config", "MID360_config.json"]
    )

    livox_ros2_params = [
        {"xfer_format": xfer_format},
        {"multi_topic": multi_topic},
        {"data_src": data_src},
        {"publish_freq": publish_freq},
        {"output_data_type": output_type},
        {"frame_id": frame_id},
        {"lvx_file_path": lvx_file_path},
        {"user_config_path": user_config_path},
        {"cmdline_input_bd_code": cmdline_bd_code},
    ]

    livox_driver = Node(
        package="livox_ros_driver2",
        executable="livox_ros_driver2_node",
        name="livox_lidar_publisher",
        output="screen",
        parameters=livox_ros2_params,
        namespace=ns,
    )

    return [PushRosNamespace(robot_namespace), livox_ns, healthcheck_node, livox_driver]


def generate_launch_description():
    return LaunchDescription(
        [
            DeclareLaunchArgument(
                "robot_namespace",
                default_value=EnvironmentVariable("ROBOT_NAMESPACE", default_value=""),
                description="Namespace which will appear in front of all topics.",
            ),
            DeclareLaunchArgument(
                "device_namespace",
                default_value="",
                description="Sensor namespace that will appear before all non absolute topics and TF frames, used for distinguishing multiple cameras on the same robot.",
            ),
            DeclareLaunchArgument(
                "healthcheck",
                default_value="False",
                description="Enable health check for livox.",
            ),
            OpaqueFunction(function=launch_setup),
        ]
    )
