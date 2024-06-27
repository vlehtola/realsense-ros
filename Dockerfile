FROM nvcr.io/nvidia/l4t-base:r32.5.0

ENV REALSENSE_BASE=/root
ENV REALSENSE_DIR=$REALSENSE_BASE/librealsense

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    sudo \
    curl \
    gnupg2 \
    lsb-release \
    apt-transport-https \
    build-essential \
    cmake \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*


# Add the public key for the Intel RealSense repository
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE

# Add the Intel RealSense repository
RUN add-apt-repository "deb https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" -u

RUN apt-get purge -y '*python2*'

RUN apt install -y python3.8 python3-pybind11 python3-pip

RUN pip3 install --upgrade pip

#RUN pip3 install pyinterp

RUN apt install -y libssl-dev xorg-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev

RUN apt install -y libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev at

# clone librealsense SKD
RUN git clone https://github.com/IntelRealSense/librealsense.git $REALSENSE_DIR \
    && cd $REALSENSE_DIR \
    && mkdir build

# compile librealsense SDK
RUN cd $REALSENSE_DIR/build \
  && sed  -i 's/if (CMAKE_VERSION VERSION_LESS 3.12)/if (CMAKE_VERSION VERSION_LESS 3.19)/g' ../wrappers/python/CMakeLists.txt \
  && cmake \
    -DCMAKE_BUILD_TYPE=release \
    -DBUILD_EXAMPLES=true \
    -DFORCE_RSUSB_BACKEND=ON \
    -DBUILD_WITH_CUDA=true \
    -DBUILD_PYTHON_BINDINGS=bool:true \
    -DPYBIND11_INSTALL=ON \
    -DPYTHON_EXECUTABLE:FILEPATH=$(python3 -c "import sys; print(sys.executable)") \
    -DPYTHON_INCLUDE_DIR:PATH=$(python3 -c "import sysconfig; print(sysconfig.get_path('include'))") \
    -DPYTHON_LIBRARY:FILEPATH=$(python3 -c "import sysconfig; import glob; print(glob.glob('/*/'.join(sysconfig.get_config_vars('LIBDIR', 'INSTSONAME')))[0])") \
    .. \
  && make -j`nproc` install

# Install realsense ROS 2 wrapper dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-rosdep python3-rosinstall-generator

RUN DEBIAN_FRONTEND=noninteractive apt install -y python-rosinstall-generator

RUN pip3 install -U colcon-common-extensions rospkg

RUN pip install -U vcstool
#RUN apt install -y python3-vcstools

# to make the "source" works
SHELL ["/bin/bash", "-c"]

ENV ROS_ROOT=/root/librealsense/

WORKDIR ${REALSENSE_DIR}

#RUN cd ${ROS_ROOT} \
RUN cd ${REALSENSE_DIR} \
  && rosinstall_generator diagnostic_updater --rosdistro foxy | vcs import src \
  && colcon build --merge-install --packages-select diagnostic_updater

#RUN apt-get install -y python-rosdep

RUN pip install -U rosdep rosinstall_generator wstool rosinstall

RUN mkdir -p /root/ros2_pre_installed/src
# Install realsense ROS 2 wrapper
RUN cd /root/ros2_pre_installed/src \
  && git clone https://github.com/IntelRealSense/realsense-ros.git -b ros2-development \
  && cd realsense-ros \
  && git checkout 6dcdc1fc0b898e38081e83edde8d5cea0e1e7c8b \
  && cd /root/ros2_pre_installed \
  && rosdep init \
  && rosdep update \
  && rosdep install -i --from-path src --ignore-src -r -y --rosdistro $ROS_DISTRO --skip-keys=librealsense2

WORKDIR ${ROS_ROOT}

##RUN source /root/ros2_pre_installed/install/setup.bash \
#RUN source ${REALSENSE_DIR}/install/setup.bash \
#  && colcon build --merge-install\
#    --packages-up-to realsense2_camera realsense2_camera_msgs realsense2_description

#RUN curl https://raw.githubusercontent.com/IntelRealSense/librealsense/master/config/99-realsense-libusb.rules \
#  -o /etc/udev/rules.d/99-realsense-libusb.rules

#RUN echo '# Intel Realsense PYTHON PATH' >> /etc/bash.bashrc \
#  && echo 'PYTHONPATH=$PYTHONPATH:'"$REALSENSE_DIR"'/usr/local/lib' >> /etc/bash.bashrc \
#  && echo "source /root/ros2_pre_installed/install/setup.bash" >> /etc/bash.bashrc
