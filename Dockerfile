FROM debian:buster

LABEL maintainer="campbell.andrew86@yahoo.com"


# Install dependencies
RUN apt-get -y update

RUN echo "deb http://ftp.de.debian.org/debian buster main contrib non-free" | tee -a /etc/apt/sources.list

RUN apt-get -y update

RUN apt-get -y install git build-essential cmake automake libtool autoconf wget pciutils


# Add debian stretch source for gcc-6 and g++-6
RUN echo "deb http://ftp.de.debian.org/debian stretch main contrib non-free" | tee -a /etc/apt/sources.list

RUN apt-get -y update

RUN apt-get install -y gcc-6 g++-6


#Install Xmrig
RUN git clone https://github.com/xmrig/xmrig.git

RUN mkdir xmrig/build

WORKDIR /xmrig/scripts

RUN ./build_deps.sh

WORKDIR /xmrig/build

RUN cmake .. -DXMRIG_DEPS=scripts/deps

RUN make -j$(nproc)

WORKDIR /


# Install Nvidia driver
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install nvidia-legacy-390xx-driver firmware-misc-nonfree


# Install Cuda
RUN wget https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux

RUN chmod +x cuda_9.1.85_387.26_linux

RUN sh cuda_9.1.85_387.26_linux -silent --verbose --toolkit --override

ENV PATH "$PATH:/usr/local/cuda-9.1/bin"

ENV LD_LIBRARY_PATH "/usr/local/cuda-9.1/lib64"


# Output about nvidia and cuda
RUN lspci | grep -i nvidia

RUN nvidia-settings --version

RUN nvcc -V

RUN gcc -v


# Set gcc-6 and g++-6 for compile
ENV CC "/usr/bin/gcc-6"

ENV CXX "/usr/bin/g++-6"


# Install Xmrig cuda
RUN git clone https://github.com/xmrig/xmrig-cuda.git

WORKDIR /xmrig-cuda/build

RUN cmake .. -DCUDA_LIB=/usr/local/cuda/lib64/stubs/libcuda.so -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda

RUN make CC=gcc-6 CPP=g++-6 CXX=g++-6 LD=g++-6 -j$(nproc)

WORKDIR /


# Verify binary dependencies
WORKDIR /xmrig/build

RUN ldd ./xmrig

ENTRYPOINT ./xmrig -o $POOL:$PORT -u $WALLET -k --tls -p $HOSTNAME