# chameleon-setup
Script to quickly setup [Chameleon](https://www.chameleoncloud.org/) computing nodes.

Start a Chameleon instance with the latest official CC-Ubuntu18.04 (or CC-Ubuntu18.04-CUDA10 if running on GPU nodes) image.

Then run the script by:

```
curl -fSsL https://raw.githubusercontent.com/pxch/chameleon-setup/master/setup_chameleon.sh | bash -s --
```
By default, the script will do the following:

* Install zsh and the zsh configuration from [robbyrussell/oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh).
* Change the default login shell to zsh.
* Install the latest vim from [source](https://github.com/vim/vim) and the vim configuration from [amix/vimrc](https://github.com/amix/vimrc).
* Install the latest tmux from [source](https://github.com/tmux/tmux) and the tmux configuration from [gpakosz/.tmux](https://github.com/gpakosz/.tmux).
* Install some common tools: [htop](https://hisham.hm/htop/), [ncdu](https://dev.yorhel.nl/ncdu), and [icdiff](https://www.jefftk.com/icdiff).
* Install [Miniconda3](https://docs.conda.io/en/latest/miniconda.html)

Optional configurations:

* Specify `--install_cuda` to install CUDA manually, this is useful when starting with a CC-Ubuntu18.04 image on a GPU node.
* Use `--cuda xx.x` to specify the CUDA versions, by default it is 10.0, and currently only 10.0 and 10.1 supported.
* If `--lambada` is specified, a new conda environment named "lambada" will be created, and [PyTorch](https://pytorch.org/) (v1.1.0) and [AllenNLP](https://allennlp.org/) (v0.8.3) will be installed in the environment.
* If `--mrqa` is specified, a new conda environment named "mrqa" will be created, and [PyTorch](https://pytorch.org/) (v1.2.0 or 1.3.1 depending on the CUDA version) will be installed in the environment.
