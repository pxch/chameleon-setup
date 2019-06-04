#!/bin/bash

install_cuda=false
install_conda=false
install_pytorch=false

while :; do
    case $1 in
        --cuda|--install-cuda)
            install_cuda=true
            ;;
        --conda|--install-conda)
            install_conda=true
            ;;
        --pytorch|--install-pytorch)
            install_pytorch=true
            ;;
        *)
            break
    esac
    shift
done

TMUX_VER=2.9
ICDIFF_VER=1.9.4

print_msg() {
    printf "\n#### CHAMELEON #### $1\n"
}

safe_delete() {
    if [ -d $1 ]; then
        echo "$1 already exists, deleting it ..."
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

    print_msg "Installing latest vim from source"
    sudo apt install -y libncurses5-dev
    safe_delete ~/vim
    git clone https://github.com/vim/vim.git ~/vim
    cd ~/vim/src && make && sudo make install
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

    print_msg "Installing latest tmux from source"
    sudo apt install -y libevent-dev
    wget https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz
    tar xf tmux-${TMUX_VER}.tar.gz
    cd tmux-${TMUX_VER} && ./configure && make && sudo make install
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

    print_msg "Downloading local Debian installer for CUDA 10.1"
    wget https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-ubuntu1604-10-1-local-10.1.105-418.39_1.0-1_amd64.deb
    print_msg "Installing CUDA 10.1"
    sudo dpkg -i cuda-repo-ubuntu1604-10-1-local-10.1.105-418.39_1.0-1_amd64.deb
    sudo apt-key add /var/cuda-repo-10-1-local-10.1.105-418.39/7fa2af80.pub
    sudo apt-get update
    sudo apt-get install -y cuda-10-1
    printf "\n# CUDA variables\nexport PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}\nexport LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}\n" >> ~/.zshrc

    print_msg "Verifying nvidia-smi"
    /usr/bin/nvidia-smi

    print_msg "Removing the Debian installer"
    rm cuda-repo-ubuntu1604-10-1-local-10.1.105-418.39_1.0-1_amd64.deb
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

configure_pytorch() {
    print_msg "Configuring PyTorch"
    source ~/miniconda3/etc/profile.d/conda.sh

    print_msg "Creating new conda environment"
    conda create -y -n pytorch python pip
    conda activate pytorch

    print_msg "Installing PyTorch"
    conda install -y pytorch torchvision cudatoolkit=10.0 -c pytorch

    print_msg "Verifying PyTorch installation"
    python -c "import torch; print(torch.cuda.is_available())"

    print_msg "Installing AllenNLP"
    pip install --upgrade allennlp==0.8.3

    print_msg "Clean up conda environment"
    conda clean -a -y
    conda deactivate
}

sudo apt update

configure_zsh
configure_vim
configure_tmux
configure_tools

if [ "$install_cuda" = true ]; then
    configure_cuda
fi

if [ "$install_conda" = true ]; then
    configure_conda
fi

if [ "$install_pytorch" = true ]; then
    configure_pytorch
fi

# Cleanup
print_msg "Clean up"
sudo apt clean
sudo apt autoclean
sudo apt autoremove

print_msg "SUCCESSFUL!"
print_msg "You'll need to log out and login back again to apply the new default shell (zsh) and all configurations"

