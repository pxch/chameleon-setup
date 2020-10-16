#!/bin/bash

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

TMUX_VER=3.0a
ICDIFF_VER=1.9.5

CUDA_VERSION=10.0
INSTALL_CUDA=false
INSTALL_DOCKER=false
LAMBADA=false
MRQA=false

while :; do
    case $1 in
        --cuda)
            shift
            CUDA_VERSION=$1
            ;;
        --install-cuda)
            INSTALL_CUDA=true
            ;;
        --install-docker)
            INSTALL_DOCKER=true
            ;;
        --lambada)
            LAMBADA=true
            ;;
        --mrqa)
            MRQA=true
            ;;
        *)
            break
    esac
    shift
done

# echo $CUDA_VERSION $INSTALL_CUDA $LAMBADA $MRQA
if [[ ${CUDA_VERSION} != "10.0" && ${CUDA_VERSION} != "10.1" ]]; then
    printf "${RED}CUDA version can only be 10.0 or 10.1\nExit ...\n"
    exit 0
fi

print_msg() {
    printf "\n${GREEN}$1${NC}\n"
}

safe_delete() {
    if [ -d $1 ]; then
        print_msg "$1 already exists, deleting it ..."
        sudo rm -rf $1
    fi
}

configure_zsh() {
    print_msg "Configuring zsh"

    print_msg "Installing zsh"
    sudo apt install -y zsh

    print_msg "Installing oh-my-zsh"
    ZSH=${HOME}/.oh-my-zsh
    safe_delete $ZSH
    git clone https://github.com/robbyrussell/oh-my-zsh.git $ZSH
    cp "$ZSH"/templates/zshrc.zsh-template ~/.zshrc
    # sed "/^export ZSH=/ c\\
    # export ZSH=\"$ZSH\"
    # " ~/.zshrc > ~/.zshrc-omztemp
    # mv -f ~/.zshrc-omztemp ~/.zshrc
    print_msg "Setting HYPHEN_INSENSITIVE to true in ~/.zshrc"
    sed -i 's/# HYPHEN_INSENSITIVE/HYPHEN_INSENSITIVE/g' ~/.zshrc

    print_msg "Setting ulimit in ~/.zshrc"
    printf "\nulimit -n 16384\n" >> ~/.zshrc

    print_msg "Switching to zsh as the default shell"
    sudo chsh -s /usr/bin/zsh `whoami`

    print_msg "Successfully installed `zsh --version`"
}

configure_vim() {
    print_msg "Configuring vim"
    sudo apt install -y libncurses5-dev

    print_msg "Getting latest vim from source"
    safe_delete ~/vim
    git clone https://github.com/vim/vim.git ~/vim

    print_msg "Compiling and installing vim"
    cd ~/vim/src
    make >/dev/null || make
    sudo make install >/dev/null
    cd && rm -rf ~/vim
    printf "\n# Link vi alias to latest version of vim\nalias vi=/usr/local/bin/vim\n" >> ~/.zshrc
    # source ~/.zshrc

    print_msg "Installing the Ultimate vimrc configuration"
    safe_delete ~/.vim_runtime
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh

    print_msg "Successfully installed `/usr/local/bin/vim --version | head -n 1`"
}

configure_tmux() {
    print_msg "Configuring tmux"
    sudo apt install -y libevent-dev

    print_msg "Getting tmux-${TMUX_VER} from source"
    safe_delete ~/tmux-${TMUX_VER}
    wget https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz
    tar xf tmux-${TMUX_VER}.tar.gz

    print_msg "Compiling and installing tmux"
    cd tmux-${TMUX_VER} && ./configure -q
    make >/dev/null || make
    sudo make install >/dev/null
    cd && rm -rf tmux-${TMUX_VER} && rm tmux-${TMUX_VER}.tar.gz
    # source ~/.zshrc

    print_msg "Installing Oh My Tmux! configuration"
    safe_delete ~/.tmux
    git clone https://github.com/gpakosz/.tmux.git ~/.tmux
    ln -s -f ~/.tmux/.tmux.conf
    cp ~/.tmux/.tmux.conf.local .

    print_msg "Adding customized key bindings to ~/.tmux.conf.local"
    printf "\nbind -n C-t new-window -a\nbind -n S-left prev\nbind -n S-right next\n" >> ~/.tmux.conf.local

    print_msg "Successfully installed `/usr/local/bin/tmux -V`"
}

configure_tools() {
    print_msg "Configuring other tools"

    print_msg "Installing htop and ncdu"
    sudo apt install -y htop ncdu

    print_msg "Installing icdiff"
    curl -s https://raw.githubusercontent.com/jeffkaufman/icdiff/release-${ICDIFF_VER}/icdiff \
      | sudo tee /usr/local/bin/icdiff > /dev/null \
      && sudo chmod ugo+rx /usr/local/bin/icdiff
}

configure_cuda() {
    print_msg "Configuring CUDA"

    print_msg "Verifying NVIDIA devices"
    lspci | grep -i nvidia
    print_msg "Verifying Linux distribution version"
    uname -m && cat /etc/*release
    print_msg "Verifying gcc version"
    gcc --version
    print_msg "Installing kernel headers and development packages"
    sudo apt-get install -y linux-headers-$(uname -r)

    # TODO: install CUDA based on $cuda_version
    print_msg "Downloading local Debian installer for CUDA 10.0"
    wget https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64
    print_msg "Installing CUDA 10.0"
    sudo dpkg -i cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64
    sudo apt-key add /var/cuda-repo-10-0-local-10.0.130-410.48/7fa2af80.pub
    sudo apt-get update
    sudo apt-get install -y cuda-10-0
    printf "\n# CUDA variables\nexport PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}\nexport LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}\n" >> ~/.zshrc

    print_msg "Verifying nvidia-smi"
    /usr/bin/nvidia-smi

    print_msg "Removing the Debian installer"
    rm cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64
}

configure_docker() {
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo docker run hello-world
    sudo usermod -aG docker cc
}

configure_conda() {
    print_msg "Configuring conda"

    print_msg "Installing Miniconda3"
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
    safe_delete ~/miniconda3
    sh ./Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3

    print_msg "Configuring conda channels"
    source ~/miniconda3/etc/profile.d/conda.sh
    conda config --set show_channel_urls true && conda config --set channel_priority true && conda config --append channels conda-forge
    printf "\n# Conda command\nsource ${HOME}/miniconda3/etc/profile.d/conda.sh\n" >> ~/.zshrc
    # source ~/.zshrc
    # conda clean -a
    rm Miniconda3-latest-Linux-x86_64.sh
}

configure_lambada() {
    print_msg "Configuring conda environment for lambada experiments"
    source ~/miniconda3/etc/profile.d/conda.sh

    print_msg "Creating new conda environment"
    conda create -y -n lambada python pip
    conda activate lambada

    print_msg "Installing PyTorch"
    conda install -y pytorch=1.1.0 torchvision cudatoolkit=10.0 -c pytorch

    print_msg "Verifying PyTorch installation"
    python -c "import torch; print(torch.cuda.is_available())"

    print_msg "Installing AllenNLP"
    pip install allennlp==0.8.3

    print_msg "Clean up conda environment"
    conda clean -a -y
    conda deactivate
}

configure_mrqa() {
    print_msg "Configuring conda environment for mrqa experiments"
    source ~/miniconda3/etc/profile.d/conda.sh

    print_msg "Creating new conda environment"
    conda create -y -n mrqa python=3.7 pip
    conda activate mrqa

    print_msg "Installing PyTorch"
    if [ "$CUDA_VERSION" = "10.1" ]; then
        conda install -y pytorch==1.3.1 torchvision==0.4.2 cudatoolkit=10.1 -c pytorch
    else
        conda install -y pytorch==1.2.0 torchvision==0.4.0 cudatoolkit=10.0 -c pytorch
    fi

    print_msg "Verifying PyTorch installation"
    python -c "import torch; print(torch.cuda.is_available())"

    # print_msg "Installing AllenNLP"
    # pip install allennlp==0.9.0

    cd
    mkdir -p mrqa/sem_bert && mkdir -p mrqa/datasets && mkdir -p mrqa/exp_outputs

    print_msg "Installing Apex"
    cd mrqa
    safe_delete apex
    git clone https://github.com/NVIDIA/apex
    cd apex
    pip install -q --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./

    print_msg "Clean up conda environment"
    conda clean -q -a -y
    conda deactivate
}

sudo apt update

configure_zsh
configure_vim
configure_tmux
configure_tools

configure_conda

if [ "$INSTALL_CUDA" = true ]; then
    configure_cuda
fi

if [ "$INSTALL_DOCKER" = true ]; then
    configure_docker
fi

if [ "$LAMBADA" = true ]; then
    configure_lambada
fi

if [ "$MRQA" = true ]; then
    configure_mrqa
fi

# Cleanup
print_msg "Clean up"
sudo apt clean
sudo apt autoclean
sudo apt autoremove

print_msg "SUCCESSFUL!"
print_msg "You'll need to log out and login back again to apply the new default shell (zsh) and all configurations"

