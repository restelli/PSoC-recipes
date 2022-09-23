FROM ubuntu:16.04 as clean_build

RUN export DEBIAN_FRONTEND="noninteractive" && \
export TZ="America/New_York" && \
apt-get update -y && \
apt-get install -y apt-utils &&\
apt-get install -y sudo && \
apt-get install -y ksh && \
apt-get install -y csh && \
apt-get install -y gzip && \
apt-get install -y wget && \
apt-get install -y bzip2 && \
apt-get install -y net-tools && \
apt-get install -y iproute2 && \
apt-get install -y git && \
echo "Dependencies for Petalinux" && \
sudo dpkg --add-architecture i386 && \
sudo apt update && \
apt-get -y install gawk \
gcc \
xterm \
autoconf \
libtool \
texinfo \
zlib1g-dev \
gcc-multilib \
build-essential \
xz-utils \
libncurses5-dev \
libncursesw5-dev \
zlib1g:i386 && \
echo "Getting rid of unnecessary files" && \
rm -rf /tmp/* /usr/share/doc/* /usr/share/info/* /var/tmp/*


RUN echo "Setting up a user called pynq to avoid running the container as root" && \
echo "For convenience pynq will be a passwordless sudo user on the container" && \
useradd -d /home/pynq -s /bin/bash -m pynq && \
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >>  /etc/sudoers && \
usermod -aG sudo pynq

ARG PYNQ_TAG=v2.7.0
RUN cd /home/pynq && \
git clone -b $PYNQ_TAG https://github.com/Xilinx/PYNQ.git && \
sudo chown -R pynq /home/pynq/PYNQ



RUN export TZ="America/New_York" && \
apt-get update -y && \
apt-get install -y python3 \
lsb-release \
software-properties-common &&\
apt-get update -y && \
/home/pynq/PYNQ/sdbuild/scripts/setup_host.sh


# Installation of Vivado, Vitis and Petalinux

FROM clean_build as bloated_build

# The following arguments are for v2020.2 that is used for PYNQ2.7
#ARG PETALINUX=petalinux-v2020.2-final-installer.run
#ARG VIVADO=Xilinx_Unified_2020.2_1118_1232

# Currently we are using this
ARG PETALINUX=petalinux-v2020.1-final-installer.run
ARG VIVADO=Xilinx_Unified_2020.1_0602_1208


#Note that ADD automatically extracts tar files
ADD downloads/$VIVADO.tar.gz /home/pynq/downloads
ADD downloads/$PETALINUX /home/pynq/downloads/$PETALINUX
ADD cfg/vitis.cfg /home/pynq/vitis.cfg
ADD cfg/vitis.cfg /home/pynq/vitis.cfg
ADD cfg/petalinux.cfg /home/pynq/petalinux.cfg

RUN cd /home/pynq/downloads && \
cd $VIVADO && \
./xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config /home/pynq/vitis.cfg && \
cd ../.. && \
chown -R pynq downloads && \
cd downloads && \
chmod +x $PETALINUX && \
sudo -H -u pynq ./$PETALINUX --skip_license -d /home/pynq/petalinux


FROM clean_build
COPY --from=bloated_build /tools /tools
COPY --chown=pynq --from=bloated_build /home/pynq/petalinux /home/pynq/petalinux
ARG VITIS_VERSION=2020.1

USER pynq

ENV DISPLAY ':1'
ENV HOME /home/pynq
SHELL ["/bin/bash", "-c"]
CMD /bin/bash --rcfile <(echo '. ~/.bashrc \
source /tools/Xilinx/Vitis/$VITIS_VERSION/settings64.sh \
source /home/pynq/petalinux/settings.sh \
petalinux-util --webtalk off; cd')
