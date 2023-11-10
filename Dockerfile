from ubuntu:20.04 as builder

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  patchelf build-essential ca-certificates coreutils curl environment-modules gfortran git gpg lsb-release file python3 python3-dev python3-distutils python3-venv unzip zip sudo && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo && \
    mkdir /home/demo && \
    chown demo:demo /home/demo
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
COPY --chown=demo:demo container_startup.sh /etc/profile.d/container_startup.sh
COPY --chown=demo:demo spack.yaml /app/
COPY --chown=demo:demo spack_packages /app/robertu94_packages
RUN su demo -c "git clone --depth=1 --branch develop-2023-11-05 https://github.com/spack/spack /app/spack"
WORKDIR /app
USER demo
RUN . /etc/profile &&\
    spack compiler find && \
    spack repo add /app/robertu94_packages && \
    spack mirror add binary_mirror  https://binaries.spack.io/develop-2023-11-05 && \
    spack buildcache keys --install --trust && \
    spack install --reuse --fail-fast
RUN find -L /app/.spack-env/view/* -type f -exec readlink -f '{}' \; | \
    grep -v 'nsight-compute' | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s


from ubuntu:20.04 as final
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y sudo build-essential gfortran python3-dev git curl zip latexmk texlive-latex-extra libpng-dev gnuplot && \
    groupadd demo && \
    useradd demo -d /home/demo -g demo && \
    mkdir /home/demo && \
    mkdir /zchecker && \
    chown demo:demo /zchecker /home/demo
RUN echo "demo    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/demo
COPY container_startup.sh /etc/profile.d/container_startup.sh
COPY --from=builder --chown=demo:demo /app /app
COPY --chown=demo:demo ./example_data/ /usecases
USER demo
RUN git clone https://github.com/codarcode/z-checker-installer /zchecker && \
    cd /zchecker && \
    . /etc/profile && \
    ./z-checker-install.sh && \
    ./manageCompressor -d SZauto -c ./manageCompressor-SZauto.cfg && \
    ./manageCompressor -d digitrounding -c ./manageCompressor-dr.cfg  &&\
    ./manageCompressor -d bitgrooming -c manageCompressor-bg.cfg && \
    ./manageCompressor -d fpzip -c manageCompressor-fpzip-fd.cfg
WORKDIR /app
CMD ["bash", "-l"]
