# Instructions to build the image

<font color=#ff0000 size=5> ATTENTION!!!! THIS INSTRUCTIONS CONTAINS A DEAD END APPROACH TO BUILD IMAGES. IT IS PRESERVED IN CASE THE AUTHOR WANT TO PICK UP THIS APPROACH IN THE FUTURE HOWEVER MOST OF THE RECIPES HERE WILL NOT WORK</font>




The goal of this repository is to facilitate the automatic generation of custom PYNQ images for different Xilinx platforms that are not generally readily available. This is done in two steps. The first step is to produce a Docker image with Vivado, Petalinux and all the software requisites for PYNQ. The second step is to run a Docker container that will produce the required image (with minimal interaction from the user).
At first we will rely on existing recipes, but over time we will build our own configuration files and we will cover more and more architectures.
At the moment the following architectures are targeted:

| Architecture      | Pynq Version | Vitis version | Petalinux Version | Linux Version |
| ----------------- | ------------ | ------------- | ----------------- |
| Microzed 7020 | 2.6.0 | 2021.1 | 2021.1 | 18.04 |
| Microzed 7010   | 2.6.0 | 2021.1 | 2021.1 | 18.04 |   

Additional architectures we are planning to add:

| Architecture      | Pynq Version | Vitis version | Petalinux Version |
| ----------------- | ------------ | ------------- | ----------------- |
| Red Pitaya 125-14 | 2.6.0 | 2021.1 | 2021.1 | 18.04 |
| ADALM Pluto   | 2.6.0 | 2021.1 | 2021.1 | 18.04 |

## Phase 1: Creating the Docker container

Download the following files:

[Xilinx_Unified_2020.1_0602_1208.tar.gz](https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Unified_2020.1_0602_1208.tar.gz)

[petalinux-v2020.1-final-installer.run](https://www.xilinx.com/member/forms/download/xef.html?filename=petalinux-v2020.1-final-installer.run)


Place the downloaded files in the folder [./downloads](./downloads).
It is very important that the name of the files is not changed.

At this point everything is ready for the automatic generation of a Docker container that can be used to develop with Xilinx© tools.

Before running the container the user must agree to Xilinx© licenses as explained in [Xilinx© instructions for batch installation and licensing for Vivado](https://docs.xilinx.com/v/u/2020.1-English/ug973-vivado-release-notes-install-license#page=51#page=51 and for Petalinux one must agree to the licensing terms on the files `$PETALINUX/etc/license/petalinux_EULA.txt` EULA that specifies in detail the rights and restrictions that apply to PetaLinux, and the file `$PETALINUX/etc/license/Third_Party_Software_End_User_License_Agree
ment.txt` that is the third party license agreement details the licenses of the distributable and non-distributable components in PetaLinux tools.

When this is sorted out run the command:
```
docker build -t pynq_image .
```

## Phase 2: generating pynq images

At this point it is possible to generate the Zynq images.
We will need to use the Docker image to compile PYNQ boards.
first go to this very repository main folder, then run:

```
docker run -it \
--mount type=bind,source="$(pwd)",target=/home/pynq/shared \
--rm \
--name pynq_test \
--net=host \
pynq_image

```
That will log to a container that will map the current folder to `~/shared`.
The container will run as a passwordless sudo user called *pynq*.

### Microzed

To compile the Microzed image we will use [FredKellerman](https://github.com/FredKellerman/Microzed-PYNQ) recipe.

From within the Docker container to generate an image for the Microzed-7020 we need to run:

```
source /tools/Xilinx/Vitis/2020.1/settings64.sh
source /home/pynq/petalinux/settings.sh
petalinux-util --webtalk off
sudo rm /usr/bin/qemu-arm-static
sudo ln -s /opt/qemu/bin/qemu-arm-static /usr/bin/qemu-arm-static
sudo ln -s /opt/crosstool-ng/bin/ct-ng /usr/bin/ct-ng
sudo ln -s /usr/bin/python3 /usr/bin/python
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
export LC_ALL="C"
sudo apt install cpio


cd Microzed-PYNQ
./buildfast.sh
```
The project will fail!
To fix the issue it will be necessary to run:

```
sudo apt install vim
vim PYNQ-git/sdbuild/Makefile
```

Then change QEMU_VERSION to 5.2.0


```
./buildfast.sh
```

And go for a walk.

```
mv microzed-x-x.x.x.img ~/shared
```


```
git clone https://github.com/Xilinx/PYNQ.git
cd PYNQ
git checkout tags/v2.6.0
vagrant up bionic
```
This will bring up and provision a virtual machine. After that a reboot will be necessary:

```
vagrant halt bionic
vagrant up bionic
```

Now either login in the graphical interface of the virtual machine and open a terminal or (more conveniently) open a ssh connection using the command:

```
vagrant ssh bionic
```

Run the following commands to install Vivado and the Microzed-PYNQ package:

```
sudo /pynq/Xilinx_Unified_2020.1_0602_1208/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config /pynq/vitis.cfg
/pynq/petalinux-v2020.1-final-installer.run --skip_license -d /workspace/petalinux
cd /workspace
git clone https://github.com/FredKellerman/Microzed-PYNQ.git
cd Microzed-PYNQ
git checkout fb4d7b3b58f5a3e3b70b7c91142ece0f2e56f73c
```

Now it is possible to turn off the virtual machine with `vagrant halt bionic`  that will be ready for development invoking `vagrant up bionic`.


To create an image for Zynq7020 the following commands are required.

```
cd /workspace/Microzed-PYNQ
source /workspace/tools/Xilinx/Vivado/2020.1/settings64.sh
source /workspace/petalinux/settings.sh
petalinux-util --webtalk off
./buildfast.sh
```


If we need to generate for the 7010 we need to edit buildfast.sh first

To exit from the container simply run the command `exit`.
The image file will be on this repository main folder



### Kria
Followed the [getting started Instructions](https://www.xilinx.com/products/som/kria/kr260-robotics-starter-kit/kr260-getting-started/getting-started.html)

To ensure connectivity while using the UART terminal I did the following:

```
sudo ifconfig eth0 192.168.0.<local>
sudo route add default gw 192.168.0.<remote_pc_address> eth0
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo vim /etc/hosts
```
and add `192.168.0.<local> kria`


## Notes:
An incredibly good resource about how to build the kernel for Vivado Linux can be found in this CERN presentation:
[How to use petalinux](https://indico.cern.ch/event/952288/contributions/4033881/attachments/2116542/3561511/2020-10-06_Creating_a_BSP_for_PetaLinux.pdf)



[Xilinx_Unified_2020.2_1118_1232.tar.gz](https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Unified_2020.2_1118_1232.tar.gz)
[petalinux-v2020.2-final-installer.run](https://www.xilinx.com/member/forms/download/xef.html?filename=petalinux-v2020.2-final-installer.run)

[focal.arm.2.7.0_2021_11_17.tar.gz](https://www.xilinx.com/bin/public/openDownload?filename=focal.arm.2.7.0_2021_11_17.tar.gz )

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
