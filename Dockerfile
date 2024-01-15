FROM continuumio/miniconda3:23.5.2-0

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=/opt/bin:/opt/conda/bin:$PATH

# update ubuntu packages
RUN apt-get update --fix-missing && \
    yes|apt-get upgrade && \
    apt-get install -y \
        wget \
        bzip2 \
        make \
        g++ \
        libboost-graph-dev && \
    rm -rf /bar/lib/apt/lists/*

RUN conda install --no-deps -y -n base conda-libmamba-solver && \
conda config --set solver libmamba && \
conda install -y -n base conda-libmamba-solver

WORKDIR /opt/bin

# install anaconda
RUN  conda config --add channels defaults && \
conda config --add channels bioconda && \
conda config --add channels conda-forge && \
conda create -n clair3 python=3.9.0 -y

ENV PATH /opt/conda/envs/clair3/bin:$PATH
ENV CONDA_DEFAULT_ENV clair3

RUN /bin/bash -c "source activate clair3" && \
    conda install -c conda-forge pypy3.6 -y && \
    conda install -c defaults nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 scipy scikit-learn numexpr -y && \
    pypy3 -m ensurepip && \
    pypy3 -m pip install mpmath==1.2.1 && \
    conda install -c defaults nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 tensorflow==2.12.0 -y && \
    conda install -c conda-forge nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 pytables -y && \
    pip install tensorflow-addons && \
    conda install -c conda-forge nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 pigz -y && \
    conda install -c conda-forge nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 cffi=1.14.4 -y && \
    conda install -c conda-forge nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 parallel=20191122 zstd -y && \
    conda install -c conda-forge -c bioconda nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 samtools=1.15.1 -y && \
    conda install -c conda-forge -c bioconda nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 whatshap=1.7 -y && \
    conda install -c conda-forge nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 xz zlib bzip2 -y && \
    conda install -c conda-forge nomkl "blas=*=*openblas" "libblas=*=*openblas" numpy==1.23.5 automake curl -y && \
    rm -rf /opt/conda/pkgs/* && \
    rm -rf /root/.cache/pip && \
    echo "source activate clair3" > ~/.bashrc

COPY . .

RUN cd /opt/bin/preprocess/realign && \
    g++ -march=native -std=c++14 -O3 -shared -fPIC -o realigner ssw_cpp.cpp ssw.c realigner.cpp && \
    g++ -march=native -std=c++11 -O3 -shared -fPIC -o debruijn_graph debruijn_graph.cpp && \
    wget http://www.bio8.cs.hku.hk/clair3/clair3_models/clair3_models.tar.gz -P /opt/models && \
    tar -zxvf /opt/models/clair3_models.tar.gz -C /opt/models && \
    rm /opt/models/clair3_models.tar.gz && \
    cd /opt/bin && \
    make USE_NATIVE=1 PREFIX=/opt/conda/envs/clair3 PYTHON=/opt/conda/envs/clair3/bin/python && \
    rm -rf /opt/bin/samtools-* /opt/bin/longphase-*
