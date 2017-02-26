FROM ubuntu:xenial

# Install curl so we can fetch things, and the required deps for emscripten.
RUN apt-get update && \
    apt-get install -y \
        curl \
        python \
        build-essential \
        cmake \
        git \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install emscripten so we can compile asm.js and wasm
RUN curl -LO https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz && \
    tar -zxvf emsdk-portable.tar.gz && \
    cd emsdk_portable && \
    ./emsdk update && \
    ./emsdk install -j2 --build=MinSizeRel latest && \
    ./emsdk activate latest && \
    echo "source $(pwd)/emsdk_env.sh" >> ~/.bashrc && \
    rm -rf emscripten/master/.git  && \
    rm -rf emscripten/master/tests && \
    rm -rf clang/fastcomp/src && \
    rm -rf clang/fastcomp/build_master_64/tools && \
    find clang/fastcomp/build_master_64/lib -not -name \*.so -type f -delete

# Install rust via rustup
ARG RUST_VERSION=1.15.1
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $RUST_VERSION && \
    . /root/.cargo/env && \
    echo "source ~/.cargo/env" >> ~/.bashrc && \
    rustup target add asmjs-unknown-emscripten && \
    rustup target add wasm32-unknown-emscripten

# Do a dummy build, to install binaryen
RUN ["/bin/bash", "-c", "mkdir dummy && \
    cd dummy && \
    . /root/.cargo/env && \
    . /emsdk_portable/emsdk_env.sh && \
    echo 'fn main() { println!(\"Hello, Emscripten!\"); }' > hello.rs && \
    rustc --target=wasm32-unknown-emscripten hello.rs && \
    cd ../ && \
    rm -rf dummy"]

ENTRYPOINT /bin/bash
