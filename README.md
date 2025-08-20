<h1 align="center">
  Docker Images for Livox LIDARs
</h1>

The repository includes a GitHub Actions workflow that automatically deploys built Docker images to the [husarion/livox-docker](https://hub.docker.com/r/husarion/livox) Docker Hub repositories. This process is based on the [Livox-SDK/livox_ros_driver2](https://github.com/Livox-SDK/livox_ros_driver2)repository.

[![ROS Docker Image](https://github.com/husarion/livox-docker/actions/workflows/ros-docker-image.yaml/badge.svg)](https://github.com/husarion/livox-docker/actions/workflows//ros-docker-image.yaml)


## Prepare Environment

1. Plugin the Device

Connect the device to the power supply and plug the ethernet cable to your PC or Husarion UGV router.

2. Check connection

Read the serial number of a Livox MID360 and remember last 2 numbers. These numbers are the part of its ip `192.168.1.1xx`.

To check the connection use the `ping` command:
```bash
ping 192.168.1.1xx
```

## Demo


1. Clone the Repository

   ```bash
   git clone https://github.com/husarion/livox-docker.git
   cd livox-docker/demo
   ```

2. Set the Appropriate IP
  In [configuration](./demo/MID360_config.json) `lidar_config` > `ip` in the 28th line set this ip.

  Your SBC should have ip `192.168.1.50`. For Husarion UGV SBC you can add to the ethernet interface configuration additional IP.
  In file `/etc/netplan/01-network-manager-all.yaml` add to `addresses` `- 192.168.1.50/24`.

3. Activate the Device

   ```bash
   docker compose up livox
   ```

4. Launch Visualization

   ```bash
   xhost local:root
   docker compose up rviz
   ```
