# sudo sh -c 'echo 2200 > /sys/module/usbcore/parameters/usbfs_memory_mb'
# cat /sys/module/usbcore/parameters/usbfs_memory_mb
# xhost +"local:docker@"
# #sudo docker run --rm -it --net=host -e DISPLAY=unix$DISPLAY --privileged -v ~/data:/usr/data xos/bionic bash 
# sudo docker run --rm -it --runtime nvidia --gpus all --net=host -e DISPLAY=130.89.211.74:0 --privileged -v $XSOCK -v $XAUTH   -v /tmp/.X11-unix:/tmp/.X11-unix hesai_pandar_xt32:latest

#!/bin/bash
xhost +local:root
docker run -it --rm \
  --privileged \
  --runtime nvidia \
  --gpus all \
  --network host \
  -e DISPLAY=$DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -e XDG_RUNTIME_DIR=/tmp/runtime-root \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $HOME/.Xauthority:/root/.Xauthority \
  handheld_ros2:latest
xhost -local:root
