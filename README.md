# PSoC recipes

The goal of this repository is to facilitate the automatic generation of custom Linux PSoC images for different hardware platforms that are not generally readily available.
At the moment the following architectures are targeted:


| Architecture | Pynq Version | Vitis version | Petalinux Version | Linux Version |
| ----------------- | ------------ | ------------- | ----------------- |----------- |
| Microzed 7020 | 2.6.0 | 2021.1 | 2021.1 | 18.04 |
| Microzed 7010   | 2.6.0 | 2021.1 | 2021.1 | 18.04 |
| Kria SK-KR260-G |?|?|?|?|

Additional architectures we are planning to add:

| Architecture      | Pynq Version | Vitis version | Petalinux Version | Linux version |
| ----------------- | ------------ | ------------- | ----------------- |---------------|
| Red Pitaya 125-14 | 2.6.0 | 2021.1 | 2021.1 | 18.04 |
| ADALM Pluto   | 2.6.0 | 2021.1 | 2021.1 | 18.04 |

### Kria SK-KR260-G with the pre-made Linux distribution
To develop with *Kria SK-KR260-G* one has simply to follow the [getting started Instructions](https://www.xilinx.com/products/som/kria/kr260-robotics-starter-kit/kr260-getting-started/getting-started.html)

To ensure connectivity while using the UART terminal this is a list of commands that might help with troubleshooting:

```
sudo ifconfig eth0 192.168.0.<local>
sudo route add default gw 192.168.0.<remote_pc_address> eth0
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo vim /etc/hosts
```
and add `192.168.0.<local> kria`

For boards other than *Kria SK-KR260-G* the procedure is more involved and requires the creation of a virtual machine.

## Phase 1: Creating Vagrant virtual machine

Exit from the folder of this project and run the following code:

```
git clone https://github.com/Xilinx/PYNQ.git
cd PYNQ
git checkout tags/v2.6.0
```

Download the following files:

[Xilinx_Unified_2020.1_0602_1208.tar.gz](https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Unified_2020.1_0602_1208.tar.gz)

[petalinux-v2020.1-final-installer.run](https://www.xilinx.com/member/forms/download/xef.html?filename=petalinux-v2020.1-final-installer.run)

[vitis.cfg](https://raw.githubusercontent.com/restelli/PSoC-recipes/main/cfg/vitis.cfg?token=GHSAT0AAAAAABX6ZFYIUFCURHBW3R2XVK2SYZN7W5A)


Place the downloaded files in the folder PYNQ:
It is very important that the name of the files is not changed.

Then it is possibile to create the virtual machine to create PYNQ images.
From within PYNQ folder run:

```
vagrant up bionic
```

This will bring up and provision a virtual machine. After that a reboot will be necessary:

```
vagrant halt bionic
vagrant up bionic
```

At this point everything is ready for the installation of Xilinx© tools.

Before installing the user must agree to Xilinx© licenses as explained in [Xilinx© instructions for batch installation and licensing for Vivado](https://docs.xilinx.com/v/u/2020.1-English/ug973-vivado-release-notes-install-license#page=51#page=51) while for Petalinux one must agree to the licensing terms on the files `$PETALINUX/etc/license/petalinux_EULA.txt` EULA that specifies in detail the rights and restrictions that apply to PetaLinux, and the file `$PETALINUX/etc/license/Third_Party_Software_End_User_License_Agree
ment.txt` that is the third party license agreement that details the licenses of the distributable and non-distributable components in PetaLinux tools.


Now either login in the graphical interface of the virtual machine and open a terminal or (more conveniently) open a ssh connection using the command:

```
vagrant ssh bionic
```
Run the following commands to install Vivado as well as a few remaining dependencies that are not checked during the VM provisioning:

```
sudo apt update
sudo apt install -y xvfb
sudo /pynq/Xilinx_Unified_2020.1_0602_1208/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config /pynq/vitis.cfg
/pynq/petalinux-v2020.1-final-installer.run --skip_license -d /workspace/petalinux
```

Now it is possible to turn off the virtual machine with `vagrant halt bionic`  that will be ready for development invoking `vagrant up bionic`.


## Phase 2: generating PYNQ images



### Microzed

To compile the Microzed image we will use [FredKellerman](https://github.com/FredKellerman/Microzed-PYNQ) recipe.

from within the vagrant machine [FredKellerman](https://github.com/FredKellerman/Microzed-PYNQ) recipe can be installed with the commands

```
cd /workspace
git clone https://github.com/FredKellerman/Microzed-PYNQ.git
cd Microzed-PYNQ
git checkout fb4d7b3b58f5a3e3b70b7c91142ece0f2e56f73c
```

To create an image for Zynq7020 the following commands are required.

```
cd /workspace/Microzed-PYNQ
export PACKAGE_FEED_URIS="http://petalinux.xilinx.com/sswreleases/rel-v2021.2/generic-updates http://petalinux.xilinx.com/sswreleases/rel-v2021.2/generic"
export PACKAGE_FEED_BASE_PATHS="rpm"
source /workspace/tools/Xilinx/Vivado/2020.1/settings64.sh
source /workspace/petalinux/settings.sh
petalinux-util --webtalk off
./buildfast.sh
```

If we need to generate the image for the Microzed 7010 we need to edit `buildfast.sh` first and set the target to 7010 instead of 7020



## Notes:
An incredibly good resource about how to build the kernel for Vivado Linux can be found in this CERN presentation:
[How to use petalinux](https://indico.cern.ch/event/952288/contributions/4033881/attachments/2116542/3561511/2020-10-06_Creating_a_BSP_for_PetaLinux.pdf)



[Xilinx_Unified_2020.2_1118_1232.tar.gz](https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Unified_2020.2_1118_1232.tar.gz)
[petalinux-v2020.2-final-installer.run](https://www.xilinx.com/member/forms/download/xef.html?filename=petalinux-v2020.2-final-installer.run)

[focal.arm.2.7.0_2021_11_17.tar.gz](https://www.xilinx.com/bin/public/openDownload?filename=focal.arm.2.7.0_2021_11_17.tar.gz )

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
