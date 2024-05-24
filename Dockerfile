ARG OS_NAME=ubuntu
ARG OS_VERSION=20.04

ARG CUDA_VERSION=11.1.1
ARG CUDNN_VERSION=8
ARG CUDA_FLAVOR=runtime    #runtime, devel

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-${CUDA_FLAVOR}-${OS_NAME}${OS_VERSION}

ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:-compute,utility}

RUN apt update && \
    apt install -y \
        wget build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev \
        libreadline-dev libffi-dev libsqlite3-dev libbz2-dev liblzma-dev && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*


ARG PYTHON_VERSION=3.8.10

RUN cd /tmp && \
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xvf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make && make install && \
    cd .. && rm Python-${PYTHON_VERSION}.tgz && rm -r Python-${PYTHON_VERSION} && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /usr/local/bin/pip3 /usr/local/bin/pip && \
    python -m pip install --upgrade pip && \
    rm -r /root/.cache/pip


ARG PYTORCH_VERSION=1.10.0
ARG TORCHVISION_VERSION=0.11.0
# ARG TORCHAUDIO_VERSION=0.10.0
ARG TORCH_VERSION_SUFFIX=+cu111
ARG PYTORCH_DOWNLOAD_URL=https://download.pytorch.org/whl/torch_stable.html

RUN if [ ! $TORCHAUDIO_VERSION ]; \
    then \
        TORCHAUDIO=; \
    else \
        TORCHAUDIO=torchaudio==${TORCHAUDIO_VERSION}${TORCH_VERSION_SUFFIX}; \
    fi && \
    if [ ! $PYTORCH_DOWNLOAD_URL ]; \
    then \
        pip install \
            torch==${PYTORCH_VERSION}${TORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCH_VERSION_SUFFIX} \
            ${TORCHAUDIO}; \
    else \
        pip install \
            torch==${PYTORCH_VERSION}${TORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCH_VERSION_SUFFIX} \
            ${TORCHAUDIO} \
            -f ${PYTORCH_DOWNLOAD_URL}; \
    fi && \
    rm -r /root/.cache/pip

# FROM nvcr.io/nvidia/pytorch:21.10-py3

RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update 
RUN apt-get install -y build-essential curl lsb-release 

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

RUN apt-get update 
RUN apt-get install -y ros-noetic-desktop-full
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc \
    && source ~/.bashrc

RUN apt-get install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool
RUN apt install -y python3-rosdep && rosdep init && rosdep update \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /workspace

CMD ["bash"]