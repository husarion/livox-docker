# Define build stage for creating ROS packages
ARG ROS_DISTRO=jazzy
ARG PREFIX=

# =========================== package builder ===============================
FROM husarnet/ros:$ROS_DISTRO-ros-base AS pkg-builder

WORKDIR /ros2_ws

# Setup workspace
RUN git clone https://github.com/tu-darmstadt-ros-pkg/livox_ros_driver2 -b $ROS_DISTRO /ros2_ws/src/livox_ros_driver2 && \
    git clone https://github.com/tu-darmstadt-ros-pkg/Livox-SDK2 -b $ROS_DISTRO /ros2_ws/src/livox_sdk2 && \
    apt-get update -y && \
    rosdep update --rosdistro $ROS_DISTRO && \
    rosdep install --from-paths src --ignore-src -y


# Optional: Create healthcheck package
RUN cd src/ && \
    source /opt/ros/$ROS_DISTRO/setup.bash && \
    ros2 pkg create healthcheck_pkg --build-type ament_cmake --dependencies rclcpp sensor_msgs && \
    sed -i '/find_package(sensor_msgs REQUIRED)/a \
            add_executable(healthcheck_node src/healthcheck.cpp)\n \
            ament_target_dependencies(healthcheck_node rclcpp sensor_msgs)\n \
            install(TARGETS healthcheck_node DESTINATION lib/${PROJECT_NAME})' \
            /ros2_ws/src/healthcheck_pkg/CMakeLists.txt
COPY ./husarion_utils/healthcheck.cpp /ros2_ws/src/healthcheck_pkg/src/

# Build
RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    echo $(cat /ros2_ws/src/livox_ros_driver2/package.xml | grep '<version>' | sed -r 's/.*<version>([0-9]+.[0-9]+.[0-9]+)<\/version>/\1/g') > /version.txt && \
    rm -rf build log

RUN apt update -y && \
    apt-get install -y ros-$ROS_DISTRO-nav2-common && \
    apt-get clean && \
    rm -rf src && \
    rm -rf /var/lib/apt/lists/*

COPY ./husarion_utils /husarion_utils

HEALTHCHECK --interval=2s --timeout=1s --start-period=20s --retries=1 \
    CMD ["/husarion_utils/healthcheck.sh"]


# Ensure LIDAR stops spinning on container shutdown
STOPSIGNAL SIGINT
