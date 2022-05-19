from fedora:35 as builder

RUN dnf update -y && \
    dnf install -y gcc-g++ gfortran glib-devel libtool findutils file pkg-config lbzip2 git tar zip patch xz \
                   python3-devel coreutils m4 automake autoconf cmake openssl-devel openssh-server openssh \
                   bison bison-devel gawk ghostscript && \
    dnf clean all -y && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
COPY --chown=demo:demo container_startup.sh /etc/profile.d/container_startup.sh
COPY --chown=demo:demo spack.yaml /app/
COPY --chown=demo:demo robertu94_packages /app/robertu94_packages
RUN su demo -c "git clone --depth=1 https://github.com/spack/spack /app/spack"
WORKDIR /app
USER demo
RUN source /etc/profile &&\
    spack compiler find && \
    spack external find && \
    spack repo add /app/robertu94_packages && \
    spack install --reuse --fail-fast
RUN find -L /app/.spack-env/view/* -type f -exec readlink -f '{}' \; | \
    grep -v 'nsight-compute' | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s


from fedora:35 as final
RUN dnf update -y && \
    dnf install -y gcc-g++ gfortran libtool m4 automake autoconf cmake \
                    python3-devel libstdc++ openssh-clients git ghostscript \
                    libpng-devel libtiff-devel boost-devel unzip vim nano \
                    texlive texlive-comment texlive-morefloats \
                    texlive-nopageno texlive-subfigure latexmk gnuplot \
                    zip && \
    dnf clean all -y && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo && \
    mkdir /zchecker && \
    chown demo:demo /zchecker
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
COPY container_startup.sh /etc/profile.d/container_startup.sh
RUN ln -s /usr/lib64/libpthread.so.0 /usr/lib64/libpthread.so
COPY --from=builder --chown=demo:demo /app /app
COPY --chown=demo:demo ./example_data/ /usecases
USER demo
RUN git clone https://github.com/codarcode/z-checker-installer /zchecker && \
    cd /zchecker && \
    ./z-checker-install.sh && \
    ./manageCompressor -d SZauto -c ./manageCompressor-SZauto.cfg && \
    ./manageCompressor -d digitrounding -c ./manageCompressor-dr.cfg  &&\
    ./manageCompressor -d bitgrooming -c manageCompressor-bg.cfg && \
    ./manageCompressor -d fpzip -c manageCompressor-fpzip-fd.cfg
WORKDIR /app
