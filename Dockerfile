# Define build stage for creating ROS packages
ARG ROS_DISTRO=humble
ARG PREFIX=

# =========================== package builder ===============================
FROM husarnet/ros:$ROS_DISTRO-ros-base AS pkg-builder

WORKDIR /ros2_ws

# Setup workspace
RUN git clone https://github.com/Livox-SDK/livox_ros_driver2.git /ros2_ws/src/livox_ros_driver2 && \
    rosdep update --rosdistro $ROS_DISTRO && \
    rosdep install --from-paths src --ignore-src -y && \
    apt update -y && \
    apt install -y libpcl-dev cmake ros-$ROS_DISTRO-pcl-conversions ros-$ROS_DISTRO-pcl-ros

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

# Build Livox SDK2
RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git /ros2_ws/src/Livox-SDK2 && \
    cd /ros2_ws/src/Livox-SDK2 && \
    mkdir build && \
    cd build && \
    cmake .. && make -j && \
    make install

# Build
RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    /ros2_ws/src/livox_ros_driver2/build.sh $ROS_DISTRO && \
    echo $(cat /ros2_ws/src/livox_ros_driver2/package.xml | grep '<version>' | sed -r 's/.*<version>([0-9]+.[0-9]+.[0-9]+)<\/version>/\1/g') > /version.txt && \
    rm -rf build log && \
    mv /ros2_ws/install/livox_ros_driver2/share/livox_ros_driver2/launch_ROS2 \
        /ros2_ws/install/livox_ros_driver2/share/livox_ros_driver2/launch
# # =========================== final stage ===============================
FROM husarnet/ros:${PREFIX}${ROS_DISTRO}-ros-core AS final-stage

ARG PREFIX

COPY --from=pkg-builder /ros2_ws /ros2_ws
COPY --from=pkg-builder /version.txt  /version.txt
COPY --from=pkg-builder /usr/local/lib/liblivox_lidar_sdk_* /usr/local/lib/
COPY --from=pkg-builder /usr/local/include/livox_lidar_*  /usr/local/include/

COPY ./husarion_utils /husarion_utils


HEALTHCHECK --interval=2s --timeout=1s --start-period=20s --retries=1 \
    CMD ["/husarion_utils/healthcheck.sh"]
