# chameleon-setup
Script to quickly setup [Chameleon](https://www.chameleoncloud.org/) computing nodes.

Start a Chameleon instance with the latest official CC-Ubuntu16.04 image.

Then run the script by:

```
curl -fSsL https://raw.githubusercontent.com/pxch/chameleon-setup/master/setup_chameleon.sh | \
    bash -s -- [--cuda] [--conda] [--pytorch]
```
By default, the script will do the following:

* Install zsh and the zsh configuration from [robbyrussell/oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh).
* Change the default login shell to zsh.
* Install the latest vim from [source](https://github.com/vim/vim) and the vim configuration from [amix/vimrc](https://github.com/amix/vimrc).
* Install the latest tmux from [source](https://github.com/tmux/tmux) and the tmux configuration from [gpakosz/.tmux](https://github.com/gpakosz/.tmux).
* Install some common tools: [htop](https://hisham.hm/htop/), [ncdu](https://dev.yorhel.nl/ncdu), and [icdiff](https://www.jefftk.com/icdiff).

Optional configurations:

* If `--cuda` is specified, CUDA 10.1 will be installed.
* If `--conda` is specified, Miniconda3 will be installed.
* If `--pytorch` is specified, a new conda environment named "pytorch" will be created, and the latest version of [PyTorch](https://pytorch.org/) and [AllenNLP](https://allennlp.org/) will be installed in the environment.
